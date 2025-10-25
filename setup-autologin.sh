#!/bin/bash
set -e

USERNAME="paka" 
TTY_SERVICE="getty@tty1.service"

echo "--- Configuring Automatic Console Login for $USERNAME on tty1 ---"

# 1. Create the override directory
# Note: We use sudo here because this operation modifies system directories.
sudo mkdir -p /etc/systemd/system/${TTY_SERVICE}.d/

# 2. Create the override configuration file
echo "Creating systemd override file..."
sudo bash -c "cat <<EOF > /etc/systemd/system/${TTY_SERVICE}.d/override.conf
[Service]
# Clear the existing ExecStart configuration
ExecStart=
# Add the new ExecStart with autologin for user paka
ExecStart=-/sbin/agetty --autologin ${USERNAME} --noclear %I \$TERM
EOF"

# 3. Reload systemd to apply the change
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Automatic login for user '$USERNAME' is now configured."
echo "Please reboot to test the change."
