#!/usr/bin/env sh
set -eu

if [ "$#" -ne 2 ]; then
  echo "Usage: ./scripts/create-account.sh <username> <password>"
  exit 1
fi

cat <<MSG
Open the worldserver console and run:

  account create $1 $2
  account set addon $1 2

For a GM/admin account, also run:

  account set gmlevel $1 3 -1

Opening console now. Detach with Ctrl+p, then Ctrl+q.
MSG

docker attach woc-ac-worldserver
