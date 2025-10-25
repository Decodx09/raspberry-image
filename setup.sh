#!/bin/bash
set -e # Exit immediately if a command fails

CURRENT_USER=$(whoami)

echo "--- Starting Plug-and-Play Setup (User: $CURRENT_USER) ---"

# --- 1. Configure Passwordless Sudo for Current User ---
echo "Configuring passwordless sudo for $CURRENT_USER..."
if ! sudo grep -q "$CURRENT_USER ALL=(ALL) NOPASSWD: ALL" /etc/sudoers; then
    echo "$CURRENT_USER ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers > /dev/null
    echo "Passwordless sudo enabled."
fi

# --- 2. Install Required Software ---
echo "Installing required packages (Modem, Python, Tools)..."
sudo apt-get update
sudo apt-get install -y modemmanager python3-pip python3-venv git curl jq

# --- 3. Create Application Directories & Placeholder Setup ---
echo "Setting up application directories..."
sudo mkdir -p /opt/app/blue /opt/app/green
# Create the symlink for the current version
sudo ln -sfn /opt/app/blue /opt/app/current

# Set ownership to the CURRENT_USER (critical for access)
sudo chown -R $CURRENT_USER:$CURRENT_USER /opt/app

# Ensure .env file exists for API key storage (Fulfills point 3 & 4)
touch /opt/app/blue/.env
chmod 644 /opt/app/blue/.env

# --- 4. Install Python Dependencies (Placeholder) ---
echo "Creating Python virtual environment and installing dependencies..."
# Create and use the virtual environment under CURRENT_USER
python3 -m venv /opt/app/blue/venv
# You may need to add pip install commands here if dependencies are not offline
# Example: /opt/app/blue/venv/bin/pip install requests

# --- 5. Copy Scripts and Services to Final Location & Update ---
echo "Installing custom scripts and services..."

# Assuming all service and script files are in the current directory
sudo cp ./automonQR.sh /usr/local/bin/
sudo cp ./first-boot.sh /usr/local/bin/
sudo cp ./myapp.service /etc/systemd/system/
sudo cp ./automon-qr.service /etc/systemd/system/
sudo cp ./first-boot.service /etc/systemd/system/
sudo chmod +x /usr/local/bin/*.sh

# Update myapp.service (Fulfills point 5 - Restart=always)
sudo sed -i "s|^User=.*|User=$CURRENT_USER|" /etc/systemd/system/myapp.service
sudo sed -i 's|^ExecStart=.*|ExecStart=/opt/app/current/venv/bin/python3 /opt/app/current/app.py|' /etc/systemd/system/myapp.service

# --- 6. Reload Systemd and Enable Services ---
echo "Enabling systemd services..."
sudo systemctl daemon-reload
# modemmanager handles internet connection (Fulfills point 1)
sudo systemctl enable automon-qr.service   # Fulfills point 2
sudo systemctl enable myapp.service        # Fulfills point 5
sudo systemctl enable first-boot.service   # Fulfills point 3 & 4

# --- 7. Final Cleanup ---
echo "Cleaning up..."
sudo apt-get clean

echo "--- Setup Complete! ---"
echo "REMINDER: You must ensure your application code (e.g., app.py) is placed in /opt/app/blue/"