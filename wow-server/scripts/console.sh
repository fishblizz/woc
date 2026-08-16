#!/usr/bin/env sh
set -eu

cat <<'MSG'
Attaching to the AzerothCore worldserver console.
Detach safely with: Ctrl+p, then Ctrl+q
Do not use Ctrl+c, because that can stop the worldserver.
MSG

docker attach woc-ac-worldserver
