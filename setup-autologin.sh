#!/bin/bash
set -e

USERNAME="appuser" # The user to automatically log in

echo "Configuring automatic login for '$USERNAME' on tty1..."

# Create the override directory
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/

# Create the override configuration file
sudo bash -c "cat <<'EOF' > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
# Clear the existing ExecStart
ExecStart=
# Add the new ExecStart with autologin
ExecStart=-/sbin/agetty --autologin $USERNAME --noclear %I \$TERM
EOF"

# Reload systemd to apply the change
sudo systemctl daemon-reload

echo "Automatic login configured."