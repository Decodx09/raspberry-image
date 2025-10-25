#!/bin/bash
set -e # Exit immediately if a command fails

CURRENT_USER=$(whoami)

echo "--- Starting Plug-and-Play Setup (User: $CURRENT_USER) ---"

# --- 1. Configure Passwordless Sudo for Current User ---
echo "Configuring passwordless sudo for $CURRENT_USER..."
# Check if the rule already exists to avoid duplication
if ! sudo grep -q "$CURRENT_USER ALL=(ALL) NOPASSWD: ALL" /etc/sudoers; then
    echo "$CURRENT_USER ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers > /dev/null
    echo "Passwordless sudo enabled."
else
    echo "Passwordless sudo already configured."
fi

# --- 2. Install Required Software ---
echo "Installing required packages..."
sudo apt-get update
sudo apt-get install -y modemmanager python3-pip python3-venv git curl jq

# --- 3. Create Application Directories & Clone App Code ---
echo "Setting up application directories and cloning demo app code..."
sudo mkdir -p /opt/app/blue /opt/app/green
sudo ln -sfn /opt/app/blue /opt/app/current
sudo rm -rf /opt/app/blue
sudo GIT_TERMINAL_PROMPT=0 git clone https://github.com/hiteshkr/Hello-World-Flask.git /opt/app/blue

# Set ownership to the CURRENT_USER
sudo chown -R $CURRENT_USER:$CURRENT_USER /opt/app

# Ensure .env file exists
touch /opt/app/blue/.env

# --- 4. Install Python Dependencies ---
echo "Installing Python dependencies (Flask)..."
# Create and use the virtual environment under CURRENT_USER
python3 -m venv /opt/app/blue/venv
/opt/app/blue/venv/bin/pip install Flask

# --- 5. Copy Scripts and Services to Final Location & Update ---
echo "Installing custom scripts and services..."

# Copy all files assuming they are in the current directory
sudo cp ./automonQR.sh /usr/local/bin/
sudo cp ./first-boot.sh /usr/local/bin/
sudo cp ./myapp.service /etc/systemd/system/
sudo cp ./automon-qr.service /etc/systemd/system/
sudo cp ./first-boot.service /etc/systemd/system/
sudo chmod +x /usr/local/bin/*.sh

# Update myapp.service to use CURRENT_USER and correct paths
sudo sed -i "s|^User=.*|User=$CURRENT_USER|" /etc/systemd/system/myapp.service
sudo sed -i 's|^ExecStart=.*|ExecStart=/opt/app/current/venv/bin/python3 /opt/app/current/app.py|' /etc/systemd/system/myapp.service

# --- 6. Reload Systemd and Enable Services ---
echo "Enabling systemd services..."
sudo systemctl daemon-reload
sudo systemctl enable automon-qr.service
sudo systemctl enable myapp.service
sudo systemctl enable first-boot.service

# --- 7. Final Cleanup ---
echo "Cleaning up..."
sudo apt-get clean

echo "--- Setup Complete! ---"
echo "The application is running as user $CURRENT_USER. You no longer need a password for sudo."