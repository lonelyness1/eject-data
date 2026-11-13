#!/bin/zsh
# eject-data.sh - quit apps using an external volume, then eject it.
#
# Usage:
#   eject-data.sh [--dry-run] [--force] [volume]
#
#   --dry-run   only list the processes using the volume
#   --force     send SIGTERM to processes still holding the volume
#   volume      mount point, defaults to /Volumes/Data
set -u

VOL=""
DRY=0
FORCE=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --force) FORCE=1 ;;
    /*) VOL="$arg" ;;
    *) echo "Unknown argument: $arg"; exit 2 ;;
  esac
done
VOL="${VOL:-/Volumes/Data}"

if [ ! -d "$VOL" ]; then
  echo "Volume not mounted: $VOL"
  exit 1
fi
case "$VOL" in
  /|/System/Volumes/Data|/System/Volumes/*)
    echo "Refusing to eject a system volume: $VOL"
    exit 1
    ;;
esac

cd / 2>/dev/null || true

users() {
  lsof -n -P 2>/dev/null | awk -v v="$VOL" 'index($NF, v) == 1 {print $2 "\t" $1}' | sort -u
}

echo "Processes using $VOL:"
if [ -z "$(users)" ]; then
  echo "  (none found by lsof)"
else
  users | while IFS=$'\t' read -r pid comm; do
    exe=$(ps -p "$pid" -o comm= 2>/dev/null)
    app=$(echo "$exe" | sed -nE 's|.*/([^/]+\.app)/Contents/MacOS/.*|\1|p')
    echo "  PID $pid  ${comm}  ${app:-(non-GUI)}"
  done
fi

if pgrep -f "/Applications/Docker.app/Contents/MacOS/Docker" >/dev/null 2>&1; then
  echo "Docker Desktop is running (its VM holds the disk image)."
fi

if [ "$DRY" = 1 ]; then
  echo "(dry-run: nothing was quit)"
  exit 0
fi

# 1) Docker first: its VM holds the disk image.
if pgrep -f "/Applications/Docker.app/Contents/MacOS/Docker" >/dev/null 2>&1; then
  echo "Quitting Docker..."
  osascript -e 'tell application id "com.docker.docker" to quit' 2>/dev/null || true
  for _ in {1..20}; do
    pgrep -f "/Applications/Docker.app/Contents/MacOS/com.docker" >/dev/null 2>&1 || break
    sleep 1
  done
  if pgrep -x "Docker Desktop" >/dev/null 2>&1; then
    pkill -TERM -x "Docker Desktop" 2>/dev/null || true
    sleep 2
  fi
fi

# 2) Quit GUI apps holding files on the volume.
users | while IFS=$'\t' read -r pid comm; do
  exe=$(ps -p "$pid" -o comm= 2>/dev/null)
  app=$(echo "$exe" | sed -nE 's|.*/([^/]+\.app)/Contents/MacOS/.*|\1|p')
  [ -z "$app" ] && continue
  name="${app%.app}"
  echo "Quitting $name..."
  osascript -e "tell application \"$name\" to quit" 2>/dev/null || true
done

# 3) Wait for the volume to be released.
for _ in {1..20}; do
  [ -z "$(users)" ] && break
  sleep 1
done

left=$(users)
if [ -n "$left" ]; then
  echo "Still in use:"
  echo "$left"
  if [ "$FORCE" = 1 ]; then
    echo "$left" | while IFS=$'\t' read -r pid comm; do
      [ "$pid" = "$$" ] && continue
      echo "  TERM $pid $comm"
      kill -TERM "$pid" 2>/dev/null || true
    done
    for _ in {1..10}; do
      [ -z "$(users)" ] && break
      sleep 1
    done
    left=$(users)
  fi
fi

if [ -n "$left" ]; then
  echo "Volume is still in use; not ejecting (try --force)."
  exit 1
fi

echo "Ejecting $VOL..."
if diskutil eject "$VOL"; then
  echo "Ejected. You can unplug now."
else
  echo "Eject failed. Current users:"
  lsof -n -P 2>/dev/null | awk -v v="$VOL" 'index($NF, v) == 1' | head -20
  exit 1
fi
