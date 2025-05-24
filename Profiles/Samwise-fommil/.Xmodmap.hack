#!/bin/sh

# xmodmap resets if the keyboard is unplugged
# so we hackily have to watch it over and over
# to see if it changed. I am unaware of any
# more elegant solution than this.

CHECK_KEYSYM="Hyper_L"
CHECK_MOD="mod3"
XMODMAP_FILE="$HOME/.Xmodmap.local"
INTERVAL=10

log() { echo "[xmodmap-watch] $*" >&2; }

while true; do
  if ! xmodmap -pm | grep -q "$CHECK_MOD.*$CHECK_KEYSYM"; then
    log "Modifier $CHECK_MOD lost $CHECK_KEYSYM — reapplying..."
    xmodmap "$XMODMAP_FILE"
  fi
  sleep "$INTERVAL"
done
