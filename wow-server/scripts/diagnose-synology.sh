#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

echo "== Docker =="
docker --version
docker compose version

echo
echo "== Platform settings =="
if [ -f .env ]; then
  grep -E '^(DOCKER_PLATFORM|DOCKER_WORLD_PLATFORM|DOCKER_WORLD_IMAGE|LAN_IP|PUBLIC_HOST|PORTAL_PUBLIC_URL)=' .env || true
else
  echo "Missing .env. Copy .env.example to .env first."
fi

echo
echo "== Host architecture =="
uname -m

echo
echo "== Required worldserver image =="
WORLD_IMAGE="$(grep -E '^DOCKER_WORLD_IMAGE=' .env 2>/dev/null | tail -n 1 | cut -d= -f2-)"
if [ -n "${WORLD_IMAGE:-}" ]; then
  docker image inspect "$WORLD_IMAGE" --format 'image={{.RepoTags}} os={{.Os}} arch={{.Architecture}}' || {
    echo "Worldserver image is missing locally: $WORLD_IMAGE"
    echo "Load it first with: gzip -dc ac-wotlk-worldserver-ahbot-autobalance-amd64.tar.gz | docker load"
  }
else
  echo "DOCKER_WORLD_IMAGE is not set in .env."
fi

echo
echo "== Compose validation =="
docker compose config >/dev/null
docker compose config | grep -E 'platform:|image: acore/ac-wotlk-worldserver|published: "?(3724|8085|8090)' || true

echo
echo "== Container status =="
docker compose ps
