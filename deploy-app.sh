#!/bin/bash
set -e

# --- Configuration ---
# Source directory of your Python app code
APP_SOURCE_DIR="/home/paka/something"
# Production directory (active deployment)
APP_DEST_DIR="/opt/app/blue"
# Main app file to rename
MAIN_APP_FILE="run_app_com8.py"
# Get the user who owns the app (e.g., paka)
CURRENT_USER=$(stat -c "%U" /opt/app/current)
VENV_PYTHON="/opt/app/current/venv/bin/python3"
VENV_PIP="/opt/app/current/venv/bin/pip"
ENV_FILE="$APP_DEST_DIR/.env"

echo "--- Deploying Container Return System ---"
echo "Source: $APP_SOURCE_DIR"
echo "Destination: $APP_DEST_DIR"

# --- 1. Stop the application service ---
echo "Stopping main application service..."
sudo systemctl stop myapp.service || true # Continue if it fails

# --- 2. Copy Application Files ---
echo "Copying application files..."
# Clear old destination
sudo rm -rf "$APP_DEST_DIR/src" "$APP_DEST_DIR/app.py" "$APP_DEST_DIR/requirements.txt"
# Copy the 'src' directory
sudo cp -r "$APP_SOURCE_DIR/src" "$APP_DEST_DIR/"
# Copy and rename the main app file
sudo cp "$APP_SOURCE_DIR/$MAIN_APP_FILE" "$APP_DEST_DIR/app.py"
# Copy requirements
sudo cp "$APP_SOURCE_DIR/requirements.txt" "$APP_DEST_DIR/"

# --- 3. Install Python Dependencies ---
echo "Installing Python dependencies from requirements.txt..."
sudo $VENV_PIP install -r "$APP_DEST_DIR/requirements.txt"

# --- 4. Configure App for Production (The CRITICAL Fixes) ---
echo "Configuring app.py for production (using /dev/input/qr)..."

# ROBUST FIX 1: Replace the entire app_port line to fix the port issue
sudo sed -i "s|^    app_port = .*|    app_port = os.getenv('UART_PORT', '/dev/input/qr')|" "$APP_DEST_DIR/app.py"
# This command removes the simulator port DEFINITION line
sudo sed -i "/DEV_UART_PORT_SIMULATOR/d" "$APP_DEST_DIR/app.py"
# This command removes the simulator port PRINT line
sudo sed -i "/Hardware simulator should use/d" "$APP_DEST_DIR/app.py"

# ROBUST FIX 2: Add missing Environment Variables to .env
echo "Adding missing configuration to .env file..."
# Add API_KEY (Needs real value from maintainer)
if ! grep -q "API_KEY=" "$ENV_FILE"; then
  echo "API_KEY=PLACEHOLDER_NEEDS_REAL_VALUE" | sudo tee -a "$ENV_FILE"
fi
# Add RASPBERRY_NAME
if ! grep -q "RASPBERRY_NAME=" "$ENV_FILE"; then
  echo "RASPBERRY_NAME=Raspberry-Pi-01" | sudo tee -a "$ENV_FILE"
fi
# Note: RASPBERRY_API_KEY is set by first-boot.sh, so we don't add it here.

# --- 5. Set Final Ownership ---
echo "Setting file ownership for $CURRENT_USER..."
sudo chown -R $CURRENT_USER:$CURRENT_USER "$APP_DEST_DIR"

# --- 6. Start the Application ---
echo "Starting main application service..."
sudo systemctl start myapp.service

echo "--- Deployment Complete ---"
echo "Check status with: sudo systemctl status myapp.service"

