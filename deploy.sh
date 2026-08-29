#!/usr/bin/env sh
set -eu

REPO_URL="${REPO_URL:-https://github.com/fishblizz/woc.git}"
BRANCH="${BRANCH:-main}"

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
WOW_DIR="$PROJECT_DIR/wow-server"

if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  SUDO="${SUDO:-sudo}"
fi

yellow() {
  printf '\033[43;30m %s \033[0m\n' "$1"
}

info() {
  printf '%s\n' "$1"
}

dc() {
  if command -v docker-compose >/dev/null 2>&1; then
    # shellcheck disable=SC2086
    $SUDO docker-compose -f docker-compose.yml "$@"
  else
    # shellcheck disable=SC2086
    $SUDO docker compose -f docker-compose.yml "$@"
  fi
}

docker_cli() {
  # shellcheck disable=SC2086
  $SUDO docker "$@"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing command: %s\n' "$1" >&2
    exit 1
  fi
}

yellow "Controleer basis"
require_command git
if ! command -v docker-compose >/dev/null 2>&1; then
  require_command docker
fi

if [ ! -d "$WOW_DIR" ]; then
  printf 'Kan wow-server niet vinden naast dit script: %s\n' "$WOW_DIR" >&2
  exit 1
fi

cd "$PROJECT_DIR"

if [ ! -d .git ]; then
  yellow "Eerste Git-koppeling"
  info "Deze map is nog geen Git-checkout. Ik koppel hem aan $REPO_URL."
  git init
  git remote add origin "$REPO_URL" 2>/dev/null || git remote set-url origin "$REPO_URL"
  git fetch origin "$BRANCH"
  git checkout -B "$BRANCH"
  git reset --hard "origin/$BRANCH"
else
  yellow "Pull laatste versie"
  git remote set-url origin "$REPO_URL"
  git fetch origin "$BRANCH"
  git checkout "$BRANCH"
  git pull --ff-only origin "$BRANCH"
fi

cd "$WOW_DIR"

yellow "Behoud lokale Synology-config"
if [ ! -f .env ]; then
  cp .env.example .env
  printf 'Er is een nieuwe .env gemaakt. Vul LAN_IP en DOCKER_DB_ROOT_PASSWORD in en draai deploy.sh daarna opnieuw.\n' >&2
  exit 1
fi

if [ -f compose.yaml ]; then
  cp compose.yaml docker-compose.yml
fi

yellow "Valideer Docker Compose"
dc config >/dev/null

yellow "Stop app-containers"
dc stop ac-authserver ac-worldserver woc-portal 2>/dev/null || true

yellow "Ruim herstartbare containers op"
dc rm -f ac-client-data-init ac-db-import ac-authserver ac-worldserver woc-portal 2>/dev/null || true

yellow "Start database"
dc up -d ac-database

yellow "Wacht op database"
attempt=0
while :; do
  health="$(docker_cli inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' woc-ac-database 2>/dev/null || true)"
  if [ "$health" = "healthy" ] || [ "$health" = "running" ]; then
    break
  fi
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 60 ]; then
    printf 'Database wordt niet gezond. Bekijk logs met: sudo docker-compose logs ac-database\n' >&2
    exit 1
  fi
  sleep 5
done

yellow "Initialiseer client-data en database"
dc up ac-client-data-init
dc up ac-db-import

yellow "Start authserver, worldserver en portal"
dc up -d --build --remove-orphans ac-authserver ac-worldserver woc-portal

yellow "Status"
dc ps

yellow "Volg worldserver-log"
info "Gebruik Ctrl+c om alleen het log volgen te stoppen; de containers blijven draaien."
dc logs -f ac-worldserver
