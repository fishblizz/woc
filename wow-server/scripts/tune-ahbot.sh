#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

MIN_ITEMS="${AHBOT_MIN_ITEMS:-750}"
MAX_ITEMS="${AHBOT_MAX_ITEMS:-750}"

dc() {
  if command -v docker-compose >/dev/null 2>&1; then
    docker-compose -f docker-compose.yml "$@"
  else
    docker compose -f compose.yaml "$@"
  fi
}

dc exec -T ac-database sh -c \
  "mysql -uroot -p\"\$MYSQL_ROOT_PASSWORD\" acore_world" <<SQL
UPDATE mod_auctionhousebot
SET minitems=${MIN_ITEMS},
    maxitems=${MAX_ITEMS}
WHERE auctionhouse IN (2, 6, 7);

SELECT auctionhouse, name, minitems, maxitems
FROM mod_auctionhousebot
ORDER BY auctionhouse;
SQL
