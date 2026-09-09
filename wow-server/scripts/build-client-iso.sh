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

REALM_ADDRESS="${PUBLIC_HOST:-${LAN_IP:-}}"
CLIENT_SOURCE_DIR="${CLIENT_SOURCE_DIR:-./client-source}"
CLIENT_ISO_NAME="${CLIENT_ISO_NAME:-woc-client-335a.iso}"
DOWNLOAD_DIR="${PORTAL_DOWNLOADS_DIR:-./portal-downloads}"

if [ -z "$REALM_ADDRESS" ]; then
  echo "Set PUBLIC_HOST or LAN_IP in .env first."
  exit 1
fi

if [ ! -d "$CLIENT_SOURCE_DIR" ]; then
  echo "Client source directory not found: $CLIENT_SOURCE_DIR"
  echo "Set CLIENT_SOURCE_DIR in .env to an extracted WoW 3.3.5a client directory."
  exit 1
fi

if [ ! -f "$CLIENT_SOURCE_DIR/Wow.exe" ] && [ ! -f "$CLIENT_SOURCE_DIR/WOW.EXE" ]; then
  echo "This does not look like an extracted WoW client: missing Wow.exe"
  exit 1
fi

if [ ! -d "$CLIENT_SOURCE_DIR/Data" ]; then
  echo "This does not look like an extracted WoW client: missing Data directory"
  exit 1
fi

mkdir -p "$DOWNLOAD_DIR"

tmp_root="${TMPDIR:-/tmp}/woc-client-iso.$$"
work_dir="$tmp_root/client"

cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT INT TERM

mkdir -p "$work_dir"

echo "Copying client files..."
if command -v rsync >/dev/null 2>&1; then
  rsync -a "$CLIENT_SOURCE_DIR"/ "$work_dir"/
else
  cp -R "$CLIENT_SOURCE_DIR"/. "$work_dir"/
fi

echo "Writing realmlist.wtf..."
found_locale=0
for locale_dir in "$work_dir"/Data/*; do
  if [ -d "$locale_dir" ]; then
    found_locale=1
    printf 'set realmlist %s\n' "$REALM_ADDRESS" > "$locale_dir/realmlist.wtf"
  fi
done

if [ "$found_locale" -eq 0 ]; then
  printf 'set realmlist %s\n' "$REALM_ADDRESS" > "$work_dir/Data/realmlist.wtf"
fi

output_iso="$DOWNLOAD_DIR/$CLIENT_ISO_NAME"
rm -f "$output_iso"

echo "Building ISO: $output_iso"
if command -v xorriso >/dev/null 2>&1; then
  xorriso -as mkisofs -J -R -V WOC_CLIENT_335A -o "$output_iso" "$work_dir"
elif command -v genisoimage >/dev/null 2>&1; then
  genisoimage -J -R -V WOC_CLIENT_335A -o "$output_iso" "$work_dir"
elif command -v mkisofs >/dev/null 2>&1; then
  mkisofs -J -R -V WOC_CLIENT_335A -o "$output_iso" "$work_dir"
elif command -v hdiutil >/dev/null 2>&1; then
  hdiutil makehybrid -iso -joliet -default-volume-name WOC_CLIENT_335A -o "$output_iso" "$work_dir"
else
  echo "No ISO builder found. Install xorriso/genisoimage/mkisofs, or run this script on macOS with hdiutil."
  exit 1
fi

echo "Done."
echo "Realmlist: set realmlist $REALM_ADDRESS"
echo "Download: $output_iso"
