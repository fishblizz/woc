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

if [ -z "${LAN_IP:-}" ]; then
  echo "Set LAN_IP in .env first."
  exit 1
fi

REALM_ADDRESS="${PUBLIC_HOST:-$LAN_IP}"
LOCAL_SUBNET_MASK="${LOCAL_SUBNET_MASK:-255.255.255.0}"

docker compose exec -T ac-database sh -c \
  "mysql -uroot -p\"\$MYSQL_ROOT_PASSWORD\" acore_auth" <<SQL
UPDATE realmlist
SET address='${REALM_ADDRESS}',
    localAddress='${LAN_IP}',
    localSubnetMask='${LOCAL_SUBNET_MASK}'
WHERE id=1;
SELECT id, name, address, port, localAddress, localSubnetMask FROM realmlist;
SQL
