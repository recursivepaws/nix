set -e # Exit on error

# immich login http://192.168.1.181:2283/api HFEJ38DNSDUEG

set -e # Exit on error

# Parse command-line arguments
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <vendor_id> <product_id>"
  echo "Example: $0 05ac 1209"
  exit 1
fi

CAMERA_VENDOR="$1"
CAMERA_PRODUCT="$2"

# Configuration
CAMERA_MOUNT="/mnt/CAMERA"
IMMICH_HOST="192.168.1.181:2283"
SECRET_FILE="/run/agenix/startup"

MAX_WAIT=30 # seconds to wait for device

# Logging
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/camera-sync.log
}

# Cleanup function to unmount everything
cleanup() {
  log "Cleaning up mounts..."

  # Unmount iPod if mounted
  if mountpoint -q "$CAMERA_MOUNT" 2>/dev/null; then
    log "Unmounting Camera..."
    umount "$CAMERA_MOUNT" 2>/dev/null || umount -l "$CAMERA_MOUNT" 2>/dev/null
  fi

  log "Cleanup complete"
}

# Set trap to cleanup on exit (both success and failure)
trap cleanup EXIT

# 0. Find and mount Camera
log "Looking for Camera device..."

# Find the device node for the iPod (it's /dev/sdc2 based on your Thunar message)
DEVICE=""
for i in $(seq 1 $MAX_WAIT); do
  # Look for block devices matching our USB vendor/product ID
  for syspath in /sys/bus/usb/devices/*; do
    if [ -f "$syspath/idVendor" ] && [ -f "$syspath/idProduct" ]; then
      vendor=$(cat "$syspath/idVendor" 2>/dev/null || echo "")
      product=$(cat "$syspath/idProduct" 2>/dev/null || echo "")

      if [ "$vendor" = "$CAMERA_VENDOR" ] && [ "$product" = "$CAMERA_PRODUCT" ]; then
        # Found the USB device, now find its block device partition
        # Look for partitions under this device
        for blockdev in /sys/block/sd*; do
          if [ -d "$blockdev" ]; then
            # Check if this block device belongs to our USB device
            dev_path=$(readlink -f "$blockdev/device" 2>/dev/null || echo "")
            if [[ "$dev_path" == *"$vendor"* ]] || udevadm info --query=property --path="$blockdev" 2>/dev/null | grep -q "ID_VENDOR_ID=$CAMERA_VENDOR"; then
              # Found the disk, now look for the partition (usually partition 2)
              blockname=$(basename "$blockdev")
              if [ -b "/dev/${blockname}2" ]; then
                DEVICE="/dev/${blockname}2"
                log "Found iPod device: $DEVICE"
                break 3
              elif [ -b "/dev/${blockname}1" ]; then
                DEVICE="/dev/${blockname}1"
                log "Found Camera device: $DEVICE"
                break 3
              fi
            fi
          fi
        done
      fi
    fi
  done

  if [ -z "$DEVICE" ]; then
    log "Waiting for Camera device... ($i/$MAX_WAIT)"
    sleep 1
  fi
done

if [ -z "$DEVICE" ]; then
  log "ERROR: Camera device not found after ${MAX_WAIT}s"
  exit 1
fi

# Ensure mount points exist
mkdir -p "$CAMERA_MOUNT"

# Check if already mounted, if not mount it
if mountpoint -q "$CAMERA_MOUNT"; then
  log "Camera already mounted at $CAMERA_MOUNT"
else
  log "Mounting iPod from $DEVICE to $CAMERA_MOUNT..."
  mount -t exfat -o "uid=$(id -u vera),gid=$(id -g vera),fmask=0022,dmask=0022" "$DEVICE" "$CAMERA_MOUNT"
  log "Camera mounted successfully"
fi

# 1. Check if secret file exists
if [ ! -f "$SECRET_FILE" ]; then
  log "ERROR: Secret file not found at $SECRET_FILE"
  exit 1
fi

# Read password from secret
# shellcheck disable=SC1090
source "$SECRET_FILE"

if [ -z "$IMMICH_API_KEY" ]; then
  log "Secret file did not contain Immich API Key"
  exit 1
fi

immich login "http://$IMMICH_HOST/api" "$IMMICH_API_KEY"

log "Successfully logged in to Immich"

immich upload --recursive --delete-duplicates --delete "$CAMERA_MOUNT/DCIM/"

log "Successfully uploaded images to Immich"
# 2. Mount SMB share if not already mounted

# 3. Sync from SMB server to iPod
# log "Starting rsync from server to iPod..."
#
# log "Sync podcasts completed successfully"
