#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

./scripts/backup.sh

stamp="$(date +%Y%m%d-%H%M%S)"
tar -czf "./backups/woc-wow-config-${stamp}.tar.gz" \
  compose.yaml .env.example docs scripts config

echo "Created ./backups/woc-wow-config-${stamp}.tar.gz"
