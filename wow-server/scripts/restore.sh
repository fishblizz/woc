#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

if [ "$#" -ne 1 ]; then
  echo "Usage: ./scripts/restore.sh ./backups/woc-wow-db-YYYYMMDD-HHMMSS.tar.gz"
  exit 1
fi

archive="$1"
tmp="./backups/restore-tmp"
rm -rf "$tmp"
mkdir -p "$tmp"
tar -xzf "$archive" -C "$tmp"

for db in acore_auth acore_characters acore_world; do
  if [ ! -f "${tmp}/${db}.sql" ]; then
    echo "Missing ${db}.sql in backup archive."
    exit 1
  fi
  docker compose exec -T ac-database sh -c \
    "mysql -uroot -p\"\$MYSQL_ROOT_PASSWORD\" ${db}" \
    < "${tmp}/${db}.sql"
done

rm -rf "$tmp"
echo "Restore completed. Restarting AzerothCore services..."
docker compose restart ac-authserver ac-worldserver
