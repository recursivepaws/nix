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
SECRET_FILE="/run/agenix/startup"
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

# 0. Find and mount iPod
log "Looking for iPod device..."

# Find the device node for the iPod
DEVICE=""

exec 3> >(show_zenity --progress \
  --title="Waiting for iPod" \
  --text="Connecting..." \
  --percentage=0 \
  --auto-close)

for i in $(seq 1 $MAX_WAIT); do
  # Look for block devices matching our USB vendor/product ID
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

  if [ -n "$DEVICE" ]; then
    echo "100" >&3
    echo "# iPod detected!" >&3
    break
  else
    echo "# Waiting for iPod device... ($i/$MAX_WAIT)" >&3
    echo "$((i * 100 / MAX_WAIT))" >&3
    sleep 1
  fi
done

exec 3>&- # Close the file descriptor

if [ -z "$DEVICE" ]; then
  log "ERROR: iPod device not found after ${MAX_WAIT}s"
  exit 1
fi

# Ensure mount points exist
mkdir -p "$IPOD_MOUNT"
mkdir -p "$SMB_MOUNT"

# Check if already mounted, if not mount it
if mountpoint -q "$IPOD_MOUNT"; then
  log "iPod already mounted at $IPOD_MOUNT"
else
  log "Mounting iPod from $DEVICE to $IPOD_MOUNT..."
  mount -t vfat -o "codepage=437,uid=$(id -u vera),gid=$(id -g vera),fmask=0022,dmask=0022,iocharset=utf8,shortname=mixed" "$DEVICE" "$IPOD_MOUNT"
  log "iPod mounted successfully"
fi

# 1. Check if secret file exists
if [ ! -f "$SECRET_FILE" ]; then
  log "ERROR: Secret file not found at $SECRET_FILE"
  exit 1
fi

# Read password from secret
# shellcheck disable=SC1090
source "$SECRET_FILE"

if [ -z "$SMB_PASSWORD" ]; then
  log "Secret file did not contain SMB password"
  exit 1
fi

# 2. Mount SMB share if not already mounted
if mountpoint -q "$SMB_MOUNT"; then
  log "SMB share already mounted at $SMB_MOUNT"
else
  log "Mounting SMB share..."
  mkdir -p "$SMB_MOUNT"

  mount -t cifs "//$SMB_HOST/$SMB_SHARE" "$SMB_MOUNT" \
    -o "username=$SMB_USER,password=$SMB_PASSWORD,uid=$(id -u vera),gid=$(id -g vera)"

  log "SMB share mounted successfully"
fi

# 3. Sync from SMB server to iPod
log "Starting rsync from server to iPod..."

rsync -av \
  --size-only \
  --info=progress2 \
  --delete \
  "$SMB_MOUNT/beets/" \
  "$IPOD_MOUNT/Music" |
  grep -oP '\d+(?=%)' |
  show_zenity --progress --title="IPod Music Sync" --text="Copying music files..." --auto-close

log "Sync music completed successfully"

rsync -av \
  --size-only \
  --info=progress2 \
  --delete \
  "$SMB_MOUNT/podcasts/" \
  "$IPOD_MOUNT/Podcasts" |
  grep -oP '\d+(?=%)' |
  show_zenity --progress --title="IPod Podcast Sync" --text="Copying files..." --auto-close

log "Sync podcasts completed successfully"
