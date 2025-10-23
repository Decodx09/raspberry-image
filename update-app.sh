#!/bin/bash
set -e

# Determine which directory is inactive
if [ "$(readlink -f /opt/app/current)" == "/opt/app/blue" ]; then
    INACTIVE_DIR="/opt/app/green"
else
    INACTIVE_DIR="/opt/app/blue"
fi

echo "Updating code in inactive directory: $INACTIVE_DIR"
# In a real scenario, you'd 'git pull' into the inactive directory.
# This script just handles the swap and restart.

echo "Switching live symlink to the new version."
ln -sfn "$INACTIVE_DIR" /opt/app/current

echo "Restarting application service..."
systemctl restart myapp.service

echo "Update complete."
