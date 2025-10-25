#!/bin/bash
set -e # Exit immediately if a command fails

echo "--- Starting Plug-and-Play Setup ---"

# --- 1. Install Required Software ---
echo "Installing required packages..."
sudo apt-get update
sudo apt-get install -y modemmanager python3-pip git curl jq

# --- 2. Create Application User ---
echo "Creating application user 'appuser'..."
if ! id -u appuser > /dev/null 2>&1; then
    sudo useradd --create-home --shell /bin/bash appuser
else
    echo "User 'appuser' already exists."
fi

# --- 3. Create Directories & Clone App Code ---
echo "Setting up application directories and cloning code..."
sudo mkdir -p /opt/app/blue /opt/app/green
sudo ln -sfn /opt/app/blue /opt/app/current
# Remove existing code if present, then clone the simple Flask app
sudo rm -rf /opt/app/blue/*
sudo GIT_TERMINAL_PROMPT=0 git clone https://github.com/hiteshkr/Hello-World-Flask.git /opt/app/blue # <-- Simple Flask App
# Ensure .env file exists and has correct initial permissions
sudo touch /opt/app/blue/.env
sudo chown -R appuser:appuser /opt/app

# --- 4. Copy Scripts to Final Location ---
echo "Installing custom scripts..."
# Assumes this script is run from the root of the cloned repo in the VM
sudo cp ./automonQR.sh /usr/local/bin/
sudo cp ./update-app.sh /usr/local/bin/
sudo cp ./first-boot.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/*.sh

# --- 5. Copy Service Files ---
echo "Installing systemd service files..."
sudo cp ./automon-qr.service /etc/systemd/system/
sudo cp ./myapp.service /etc/systemd/system/
sudo cp ./first-boot.service /etc/systemd/system/

# --- 6. Reload Systemd and Enable Services ---
echo "Enabling systemd services..."
sudo systemctl daemon-reload
sudo systemctl enable automon-qr.service
sudo systemctl enable myapp.service
sudo systemctl enable first-boot.service # Enabled by default, disables itself after first run

# --- 7. Final Cleanup ---
echo "Cleaning up..."
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
# Clean bash history
history -c && history -w

echo "--- Setup Complete! ---"
echo "You can now shut down this VM ('sudo shutdown now') and export its disk."