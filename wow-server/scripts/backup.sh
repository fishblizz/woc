#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  echo "Missing .env. Copy .env.example to .env first."
  exit 1
fi

set -a
. ./.env
set +a

stamp="$(date +%Y%m%d-%H%M%S)"
dest="./backups/db-${stamp}"
mkdir -p "$dest"

for db in acore_auth acore_characters acore_world; do
  docker compose exec -T ac-database sh -c \
    "mysqldump -uroot -p\"\$MYSQL_ROOT_PASSWORD\" --single-transaction --quick ${db}" \
    > "${dest}/${db}.sql"
done

tar -czf "./backups/woc-wow-db-${stamp}.tar.gz" -C "$dest" .
rm -rf "$dest"

echo "Created ./backups/woc-wow-db-${stamp}.tar.gz"
