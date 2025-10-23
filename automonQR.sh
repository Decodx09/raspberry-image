#!/bin/bash
set -euo pipefail

DEVICE_NAME="Datalogic ADC, Inc. GFS4500"
VENDOR_ID="05f9"
PRODUCT_ID="223f"
TARGET_LINK="/dev/input/qr"

logger -t "qr-symlink" "Starting QR symlink script..."

# Try to find the device by its full name first
EVENT_PATH=$(grep -l "$DEVICE_NAME" /sys/class/input/event*/device/name 2>/dev/null | head -n 1)

# If not found by name, search by vendor and product ID
if [[ -z "$EVENT_PATH" ]]; then
  for ev_path in /sys/class/input/event*; do
    ven=$(cat "$ev_path/device/id/vendor" 2>/dev/null || true)
    pro=$(cat "$ev_path/device/id/product" 2>/dev/null || true)
    if [[ "$ven" == "$VENDOR_ID" && "$pro" == "$PRODUCT_ID" ]]; then
      EVENT_PATH="$ev_path/device/name"
      break
    fi
  done
fi

if [[ -z "$EVENT_PATH" ]]; then
  logger -t "qr-symlink" "QR scanner device not found."
  exit 1
fi

EVENT_DEV=$(echo "$EVENT_PATH" | awk -F'/' '{print $(NF-2)}')
EVENT_FILE="/dev/input/${EVENT_DEV}"

logger -t "qr-symlink" "Found QR scanner at $EVENT_FILE. Creating symlink at $TARGET_LINK."
ln -sf "$EVENT_FILE" "$TARGET_LINK"
