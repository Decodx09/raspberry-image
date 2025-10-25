#!/bin/bash
set -e # Exit immediately if a command fails

echo "--- Starting Plug-and-Play Setup (Shivansh Admin) ---"

# --- 1. Install Required Software ---
echo "Installing required packages..."
sudo apt-get update
# Installing base tools required for system operation (ModemManager, git, curl/jq for API)
sudo apt-get install -y modemmanager python3-pip python3-venv git curl jq

# --- 2. Create Application Directories & Clone App Code ---
# NOTE: We assume 'shivansh' is the administrative user that owns the app.
echo "Setting up application directories and cloning demo app code..."
sudo mkdir -p /opt/app/blue /opt/app/green
sudo ln -sfn /opt/app/blue /opt/app/current
# Remove existing code directory if present, then clone fresh
sudo rm -rf /opt/app/blue
# Clone the simple Flask app, forcing non-interactive
sudo GIT_TERMINAL_PROMPT=0 git clone https://github.com/hiteshkr/Hello-World-Flask.git /opt/app/blue # <-- Simple Flask App
# Ensure .env file exists and set correct ownership to shivansh
sudo touch /opt/app/blue/.env
sudo chown -R shivansh:shivansh /opt/app

# --- 3. Install Python Dependencies (Flask) ---
echo "Installing Python dependencies (Flask)..."
# Create a virtual environment owned by shivansh
sudo -u shivansh python3 -m venv /opt/app/blue/venv
# Install Flask into the virtual environment
sudo /opt/app/blue/venv/bin/pip install Flask

# --- 4. Copy Scripts to Final Location ---
echo "Installing custom scripts..."
# Assumes this script is run from the root of the cloned repo in the VM
sudo cp ./automonQR.sh /usr/local/bin/
sudo cp ./update-app.sh /usr/local/bin/
sudo cp ./first-boot.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/*.sh

# --- 5. Copy & Update Service Files ---
echo "Updating myapp.service to use virtual environment and correct script name..."
# Update myapp.service: Use shivansh as user and use the correct venv path
sudo sed -i 's|^User=.*|User=shivansh|' ./myapp.service
sudo sed -i 's|^ExecStart=.*|ExecStart=/opt/app/current/venv/bin/python3 /opt/app/current/app.py|' ./myapp.service

echo "Installing systemd service files..."
sudo cp ./automon-qr.service /etc/systemd/system/
sudo cp ./myapp.service /etc/systemd/system/
sudo cp ./first-boot.service /etc/systemd/system/

# --- 6. Reload Systemd and Enable Services ---
echo "Enabling systemd services..."
sudo systemctl daemon-reload
sudo systemctl enable automon-qr.service
sudo systemctl enable myapp.service
sudo systemctl enable first-boot.service

# --- 7. Configure Auto-Login for SHIVANSH ---
echo "Configuring automatic login for 'shivansh' on tty1..."
# Create the override directory
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
# Create the override configuration file
sudo bash -c "cat <<'EOF' > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin shivansh --noclear %I \$TERM
EOF"
sudo systemctl daemon-reload # Apply autologin change

# --- 8. Final Cleanup ---
echo "Cleaning up..."
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
# Clean bash history
history -c && history -w

echo "--- Setup Complete! ---"
echo "You can now shut down this VM ('sudo shutdown now') and export its disk."