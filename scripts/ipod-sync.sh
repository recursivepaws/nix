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

# Configuration
IPOD_MOUNT="/mnt/IPOD"
SMB_HOST="192.168.1.167"
SMB_USER="vera"
SMB_SHARE="data/media/"
SMB_MOUNT="/mnt/MeowStationSMB"
SECRET_FILE="/run/agenix/secrets"
MAX_WAIT=30 # seconds to wait for device

show_zenity() {
  sudo -u vera DISPLAY=:0 XAUTHORITY=/home/vera/.Xauthority zenity "$@"
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

  # Unmount SMB share if mounted
  if mountpoint -q "$SMB_MOUNT" 2>/dev/null; then
    log "Unmounting SMB share..."
    umount "$SMB_MOUNT" 2>/dev/null || umount -l "$SMB_MOUNT" 2>/dev/null
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

# ---------------------------------------------------------------------------
# Stage 1: Wait for iPod (0–20%)
# ---------------------------------------------------------------------------
log "Looking for iPod device..."
DEVICE=""

zmsg "Waiting for iPod to connect..."
zpct 0

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
  zpct "$((i * 20 / MAX_WAIT))"
  sleep 1
done

if [ -z "$DEVICE" ]; then
  log "ERROR: iPod device not found after ${MAX_WAIT}s"
  exec 3>&-
  exit 1
fi

log "Found iPod device: $DEVICE"

# ---------------------------------------------------------------------------
# Stage 2: Mount iPod + SMB share (20%)
# ---------------------------------------------------------------------------
zmsg "Mounting iPod..."
zpct 20

mkdir -p "$IPOD_MOUNT"
mkdir -p "$SMB_MOUNT"

if mountpoint -q "$IPOD_MOUNT"; then
  log "iPod already mounted at $IPOD_MOUNT"
else
  log "Mounting iPod from $DEVICE to $IPOD_MOUNT..."
  mount -t vfat -o "codepage=437,uid=$(id -u vera),gid=$(id -g vera),fmask=0022,dmask=0022,iocharset=utf8,shortname=mixed" "$DEVICE" "$IPOD_MOUNT"
  log "iPod mounted successfully"
fi

if [ ! -f "$SECRET_FILE" ]; then
  log "ERROR: Secret file not found at $SECRET_FILE"
  exec 3>&-
  exit 1
fi

# shellcheck disable=SC1090
source "$SECRET_FILE"

if [ -z "$SMB_PASSWORD" ]; then
  log "Secret file did not contain SMB password"
  exec 3>&-
  exit 1
fi

if mountpoint -q "$SMB_MOUNT"; then
  log "SMB share already mounted at $SMB_MOUNT"
else
  log "Mounting SMB share..."
  mount -t cifs "//$SMB_HOST/$SMB_SHARE" "$SMB_MOUNT" \
    -o "username=$SMB_USER,password=$SMB_PASSWORD,uid=$(id -u vera),gid=$(id -g vera)"
  log "SMB share mounted successfully"
fi

# ---------------------------------------------------------------------------
# Stage 3: Space check before music sync
# ---------------------------------------------------------------------------
zmsg "Checking available space..."
log "Checking available space on iPod..."

server_music_size=$(du -sb "$SMB_MOUNT/beets/" | cut -f1)
ipod_music_size=$(du -sb "$IPOD_MOUNT/Music" 2>/dev/null | cut -f1 || echo 0)
ipod_free=$(df -B1 --output=avail "$IPOD_MOUNT" | tail -1 | tr -d ' ')
available=$((ipod_free + ipod_music_size))

log "Server music size:      $((server_music_size / 1048576)) MiB"
log "iPod Music folder size: $((ipod_music_size / 1048576)) MiB"
log "iPod free space:        $((ipod_free / 1048576)) MiB"
log "Effective available:    $((available / 1048576)) MiB"

if [ "$server_music_size" -gt "$available" ]; then
  needed=$(((server_music_size - available) / 1048576))
  log "ERROR: Not enough space on iPod (need ${needed} MiB more)"
  exec 3>&-
  show_zenity --error \
    --title="iPod Sync: Not Enough Space" \
    --text="Not enough space on iPod to sync music.\n\nNeed $((server_music_size / 1048576)) MiB, but only $((available / 1048576)) MiB available (${needed} MiB short)."
  exit 1
fi

log "Space check passed"

# ---------------------------------------------------------------------------
# Stage 4: Sync music (20–60%)
# ---------------------------------------------------------------------------
log "Starting music sync..."
zmsg "Syncing music..."
zpct 20

rsync -av \
  --size-only \
  --info=progress2 \
  "$SMB_MOUNT/beets/" \
  "$IPOD_MOUNT/Music" |
  while IFS= read -r -d $'\r' line; do
    pct=$(printf '%s' "$line" | grep -oP '\d+(?=%)' | head -1)
    if [[ -n "$pct" && "$pct" =~ ^[0-9]+$ && "$pct" -le 100 ]]; then
      zpct "$((20 + pct * 40 / 100))"
    fi
  done || true

log "Music sync completed"
zmsg "Music sync complete"
zpct 60

# ---------------------------------------------------------------------------
# Stage 5: Sync podcasts (60–95%)
# ---------------------------------------------------------------------------
log "Starting podcast sync..."
zmsg "Syncing podcasts..."

rsync -av \
  --size-only \
  --info=progress2 \
  --delete \
  "$SMB_MOUNT/podcasts/" \
  "$IPOD_MOUNT/Podcasts" |
  while IFS= read -r -d $'\r' line; do
    pct=$(printf '%s' "$line" | grep -oP '\d+(?=%)' | head -1)
    if [[ -n "$pct" && "$pct" =~ ^[0-9]+$ && "$pct" -le 100 ]]; then
      zpct "$((60 + pct * 35 / 100))"
    fi
  done || true

log "Podcast sync completed"
zmsg "Podcast sync complete"
zpct 95

# ---------------------------------------------------------------------------
# Stage 6: Unmount (95–100%)
# ---------------------------------------------------------------------------
zmsg "Unmounting iPod..."
log "Unmounting iPod..."

umount "$IPOD_MOUNT" 2>/dev/null || umount -l "$IPOD_MOUNT" 2>/dev/null || true
umount "$SMB_MOUNT" 2>/dev/null || umount -l "$SMB_MOUNT" 2>/dev/null || true

log "Sync complete"
zmsg "Done!"
zpct 100

exec 3>&-
