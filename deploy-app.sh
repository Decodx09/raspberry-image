#!/bin/bash
set -e

# --- Configuration ---
# Source directory of your Python app code
# Use $SUDO_USER to get the home dir of the user who ran sudo, not root
APP_SOURCE_DIR="/home/$SUDO_USER/something"
# Production directory (active deployment)
APP_DEST_DIR="/opt/app/blue"
# Main app file to rename
MAIN_APP_FILE="run_app_com8.py"
# Get the user who owns the app (e.g., paka)
CURRENT_USER=$(stat -c "%U" /opt/app/current)
VENV_PYTHON="/opt/app/current/venv/bin/python3"
VENV_PIP="/opt/app/current/venv/bin/pip"

echo "--- Deploying Container Return System ---"
echo "Source: $APP_SOURCE_DIR"
echo "Destination: $APP_DEST_DIR"

# --- 1. Stop the application service ---
echo "Stopping main application service..."
sudo systemctl stop myapp.service

# --- 2. Copy Application Files ---
echo "Copying application files..."
# Copy the 'src' directory
sudo cp -r "$APP_SOURCE_DIR/src" "$APP_DEST_DIR/"
# Copy and rename the main app file
sudo cp "$APP_SOURCE_DIR/$MAIN_APP_FILE" "$APP_DEST_DIR/app.py"
# Copy requirements
sudo cp "$APP_SOURCE_DIR/requirements.txt" "$APP_DEST_DIR/"

# --- 3. Install Python Dependencies ---
echo "Installing Python dependencies from requirements.txt..."
sudo $VENV_PIP install -r "$APP_DEST_DIR/requirements.txt"

# --- 4. Configure App for Production (The CRITICAL Fix) ---
echo "Configuring app.py for production (using /dev/input/qr)..."
# This command replaces the development port with the correct QR reader path
sudo sed -i "s|os.getenv('DEV_UART_PORT_APP', '/dev/pts/3')|os.getenv('UART_PORT', '/dev/input/qr')|" "$APP_DEST_DIR/app.py"
# This command removes the simulator port line
sudo sed -i "/DEV_UART_PORT_SIMULATOR/d" "$APP_DEST_DIR/app.py"


# --- 5. Set Final Ownership ---
echo "Setting file ownership for $CURRENT_USER..."
sudo chown -R $CURRENT_USER:$CURRENT_USER "$APP_DEST_DIR"

# --- 6. Start the Application ---
echo "Starting main application service..."
sudo systemctl start myapp.service

echo "--- Deployment Complete ---"
echo "Check status with: sudo systemctl status myapp.service"