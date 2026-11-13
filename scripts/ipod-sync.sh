#!/usr/bin/env bash
set -e # Exit on error

# Parse command-line arguments
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <vendor_id> <product_id>"
  echo "Example: $0 05ac 1209"
  exit 1
fi

IPOD_VENDOR="$1"
IPOD_PRODUCT="$2"

# Configuration (IPOD_USER, SYNCTHING_HOME, MUSIC_DIR, HUB_ID come from the unit's environment)
IPOD_MOUNT="/mnt/IPOD"
MAX_WAIT=30 # seconds to wait for device
ST_WAIT=30  # seconds to wait for syncthing to settle before asking
FOLDERS=(beets playlists)
EXCLUDES=(--exclude=.stfolder --exclude=.stignore --exclude=.stversions --exclude=@eaDir --exclude=musiclibrary.db)

show_zenity() {
  sudo -u "$IPOD_USER" DISPLAY=:0 XAUTHORITY="/home/$IPOD_USER/.Xauthority" zenity "$@"
}

# Logging
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/ipod-sync.log
}

# Cleanup function to unmount everything
cleanup() {
  log "Cleaning up mounts..."

  # Unmount iPod if mounted
  if mountpoint -q "$IPOD_MOUNT" 2>/dev/null; then
    log "Unmounting iPod..."
    umount "$IPOD_MOUNT" 2>/dev/null || umount -l "$IPOD_MOUNT" 2>/dev/null
  fi

  log "Cleanup complete"
}

# Set trap to cleanup on exit (both success and failure)
trap cleanup EXIT

# Open a single zenity progress dialog for the entire operation
exec 3> >(show_zenity --progress \
  --title="iPod Sync" \
  --text="Starting..." \
  --percentage=0 \
  --auto-close)

zpct() { echo "$1" >&3; }
zmsg() { echo "# $1" >&3; }

# rsync_progress <start%> <span%> <rsync args...>: rsync, mapping its total progress into the dialog.
rsync_progress() {
  local start="$1" span="$2" line pct
  shift 2
  rsync -av --size-only --info=progress2 "${EXCLUDES[@]}" "$@" |
    while IFS= read -r -d $'\r' line; do
      pct=$(printf '%s' "$line" | grep -oP '\d+(?=%)' | head -1)
      if [[ -n "$pct" && "$pct" =~ ^[0-9]+$ && "$pct" -le 100 ]]; then
        zpct "$((start + pct * span / 100))"
      fi
    done || true
}

# ---------------------------------------------------------------------------
# Stage 0: Syncthing gate (0-15%)
# ---------------------------------------------------------------------------
# "Up to date" = matches everything the connected peers have announced.
# The hub is always on, so requiring it rules out all but edits on powered-off machines.
key=$(grep -oP '(?<=<apikey>)[^<]+' "$SYNCTHING_HOME/config.xml" || true)
st() { curl -sf --max-time 5 -H "X-API-Key: $key" "http://127.0.0.1:8384/rest/$1" "${@:2}"; }

# Prints one reason per line; no output means up to date.
stale_reasons() {
  local conn started age f s c
  if ! conn=$(st system/connections); then
    echo "Syncthing API unreachable"
    return
  fi
  if [ "$(jq -r --arg d "$HUB_ID" '.connections[$d].connected // false' <<<"$conn")" != true ]; then
    echo "barkstation not connected"
  else
    # Index exchange runs right after connecting; until it settles the global view can be stale.
    started=$(jq -r --arg d "$HUB_ID" '.connections[$d].startedAt' <<<"$conn")
    age=$(($(date +%s) - $(date -d "$started" +%s)))
    [ "$age" -ge 30 ] || echo "barkstation connected only ${age}s ago"
  fi
  for f in "${FOLDERS[@]}"; do
    if ! s=$(st "db/status?folder=$f"); then
      echo "$f: status unavailable"
      continue
    fi
    jq -r --arg f "$f" '
      (select(.state != "idle") | "\($f): \(.state)"),
      (select(.needTotalItems > 0) | "\($f): \(.needTotalItems) items still to download"),
      (select(.pullErrors > 0) | "\($f): \(.pullErrors) pull errors")' <<<"$s"
    if ! c=$(st "db/completion?folder=$f&device=$HUB_ID"); then
      echo "$f: barkstation completion unavailable"
      continue
    fi
    jq -r --arg f "$f" 'select(.completion < 100 or .remoteState != "valid")
      | "\($f): barkstation is missing local changes (\(.completion | floor)%, \(.remoteState))"' <<<"$c"
  done
}

log "Checking Syncthing state..."
zmsg "Checking Syncthing..."
zpct 0

# Pick up local edits the watcher has not scanned yet.
for f in "${FOLDERS[@]}"; do
  st "db/scan?folder=$f" -X POST >/dev/null || true
done

reasons=""
for i in $(seq 1 $ST_WAIT); do
  reasons=$(stale_reasons)
  [ -z "$reasons" ] && break
  zmsg "Waiting for Syncthing... ($i/$ST_WAIT)"
  zpct "$((i * 15 / ST_WAIT))"
  sleep 1
done

if [ -n "$reasons" ]; then
  log "Syncthing not up to date: ${reasons//$'\n'/; }"
  # A dialog that cannot open also returns non-zero, so a headless run never syncs stale data.
  if ! show_zenity --question --no-markup \
    --title="iPod Sync: Syncthing Not Up To Date" \
    --text="The local music folders may be stale:

$reasons

Sync anyway?"; then
    log "Sync declined"
    exec 3>&-
    exit 0
  fi
  log "Syncing anyway at user request"
else
  log "Syncthing up to date"
fi

# ---------------------------------------------------------------------------
# Stage 1: Wait for iPod (15-25%)
# ---------------------------------------------------------------------------
log "Looking for iPod device..."
DEVICE=""

zmsg "Waiting for iPod to connect..."
zpct 15

for i in $(seq 1 $MAX_WAIT); do
  for syspath in /sys/bus/usb/devices/*; do
    if [ -f "$syspath/idVendor" ] && [ -f "$syspath/idProduct" ]; then
      vendor=$(cat "$syspath/idVendor" 2>/dev/null || echo "")
      product=$(cat "$syspath/idProduct" 2>/dev/null || echo "")
      if [ "$vendor" = "$IPOD_VENDOR" ] && [ "$product" = "$IPOD_PRODUCT" ]; then
        for blockdev in /sys/block/sd*; do
          if [ -d "$blockdev" ]; then
            dev_path=$(readlink -f "$blockdev/device" 2>/dev/null || echo "")
            if [[ "$dev_path" == *"$vendor"* ]] || udevadm info --query=property --path="$blockdev" 2>/dev/null | grep -q "ID_VENDOR_ID=$IPOD_VENDOR"; then
              blockname=$(basename "$blockdev")
              if [ -b "/dev/${blockname}2" ]; then
                DEVICE="/dev/${blockname}2"
                break 3
              elif [ -b "/dev/${blockname}1" ]; then
                DEVICE="/dev/${blockname}1"
                break 3
              fi
            fi
          fi
        done
      fi
    fi
  done

  zmsg "Waiting for iPod... ($i/$MAX_WAIT)"
  zpct "$((15 + i * 10 / MAX_WAIT))"
  sleep 1
done

if [ -z "$DEVICE" ]; then
  log "ERROR: iPod device not found after ${MAX_WAIT}s"
  exec 3>&-
  exit 1
fi

log "Found iPod device: $DEVICE"

# ---------------------------------------------------------------------------
# Stage 2: Mount iPod (25%)
# ---------------------------------------------------------------------------
zmsg "Mounting iPod..."
zpct 25

mkdir -p "$IPOD_MOUNT"

if mountpoint -q "$IPOD_MOUNT"; then
  log "iPod already mounted at $IPOD_MOUNT"
else
  log "Mounting iPod from $DEVICE to $IPOD_MOUNT..."
  mount -t vfat -o "codepage=437,uid=$(id -u "$IPOD_USER"),gid=$(id -g "$IPOD_USER"),fmask=0022,dmask=0022,iocharset=utf8,shortname=mixed" "$DEVICE" "$IPOD_MOUNT"
  log "iPod mounted successfully"
fi

# ---------------------------------------------------------------------------
# Stage 3: Space check
# ---------------------------------------------------------------------------
zmsg "Checking available space..."
log "Checking available space on iPod..."

source_size=$(du -scb "$MUSIC_DIR/beets/" "$MUSIC_DIR/playlists/" | tail -1 | cut -f1)
ipod_used=$(du -scb "$IPOD_MOUNT/Music" "$IPOD_MOUNT/Playlists" 2>/dev/null | tail -1 | cut -f1 || echo 0)
ipod_free=$(df -B1 --output=avail "$IPOD_MOUNT" | tail -1 | tr -d ' ')
available=$((ipod_free + ipod_used))

log "Local music + playlists:   $((source_size / 1048576)) MiB"
log "iPod Music + Playlists:    $((ipod_used / 1048576)) MiB"
log "iPod free space:           $((ipod_free / 1048576)) MiB"
log "Effective available:       $((available / 1048576)) MiB"

if [ "$source_size" -gt "$available" ]; then
  needed=$(((source_size - available) / 1048576))
  log "ERROR: Not enough space on iPod (need ${needed} MiB more)"
  exec 3>&-
  show_zenity --error \
    --title="iPod Sync: Not Enough Space" \
    --text="Not enough space on iPod to sync music.\n\nNeed $((source_size / 1048576)) MiB, but only $((available / 1048576)) MiB available (${needed} MiB short)."
  exit 1
fi

log "Space check passed"

# ---------------------------------------------------------------------------
# Stage 4: Sync music (25-70%)
# ---------------------------------------------------------------------------
log "Starting music sync..."
zmsg "Syncing music..."
zpct 25

rsync_progress 25 45 "$MUSIC_DIR/beets/" "$IPOD_MOUNT/Music"

log "Music sync completed"
zmsg "Music sync complete"
zpct 70

# ---------------------------------------------------------------------------
# Stage 5: Sync playlists (70-95%)
# ---------------------------------------------------------------------------
log "Starting playlist sync..."
zmsg "Syncing playlists..."

# Protect .m3u8 from --delete: generated ones are pruned below, hand-made Rockbox ones are kept.
rsync_progress 70 25 --delete --filter='P *.m3u8' "$MUSIC_DIR/playlists/" "$IPOD_MOUNT/Playlists"

# One Rockbox playlist per folder; paths are relative to /Playlists.
marker="# generated by ipod-sync"
for d in "$MUSIC_DIR/playlists"/*/; do
  [ -d "$d" ] || continue
  name=$(basename "$d")
  {
    printf '#EXTM3U\n%s\n' "$marker"
    # sort -V, as in mpd-playlists, so 100 sorts after 99.
    find "$d" -maxdepth 1 -type f \
      \( -iname '*.flac' -o -iname '*.mp3' -o -iname '*.m4a' \
      -o -iname '*.opus' -o -iname '*.ogg' -o -iname '*.wav' \
      -o -iname '*.aiff' \) \
      -printf '%f\n' | sort -V |
      while IFS= read -r track; do printf '%s/%s\n' "$name" "$track"; done
  } >"$IPOD_MOUNT/Playlists/$name.m3u8"
done

# Drop generated playlists whose folder is gone; hand-made ones lack the marker.
for f in "$IPOD_MOUNT/Playlists"/*.m3u8; do
  [ -f "$f" ] || continue
  grep -qxF "$marker" "$f" || continue
  [ -d "$MUSIC_DIR/playlists/$(basename "$f" .m3u8)" ] || rm -f "$f"
done

log "Playlist sync completed"
zmsg "Playlist sync complete"
zpct 95

# ---------------------------------------------------------------------------
# Stage 6: Unmount (95-100%)
# ---------------------------------------------------------------------------
zmsg "Unmounting iPod..."
log "Unmounting iPod..."

umount "$IPOD_MOUNT" 2>/dev/null || umount -l "$IPOD_MOUNT" 2>/dev/null || true

log "Sync complete"
zmsg "Done!"
zpct 100

exec 3>&-
