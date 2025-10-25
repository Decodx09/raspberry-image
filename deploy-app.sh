#!/bin/bash
set -e

# --- Configuration ---
# Source directory of your Python app code (Hardcoded to fix SUDO_USER path issue)
APP_SOURCE_DIR="/home/paka/something"
# Production directory (active deployment)
APP_DEST_DIR="/opt/app/blue"
# Main app file to rename
MAIN_APP_FILE="run_app_com8.py"
# Get the user who owns the app (e.g., paka)
CURRENT_USER=$(stat -c "%U" /opt/app/current)
VENV_PYTHON="/opt/app/current/venv/bin/python3"
VENV_PIP="/opt/app/current/venv/bin/pip"
FINAL_ENV_FILE="$APP_DEST_DIR/.env"

echo "--- Deploying Container Return System ---"
echo "Source: $APP_SOURCE_DIR"
echo "Destination: $APP_DEST_DIR"

# --- 1. PRESERVE THE FETCHED API KEY ---
# Attempt to read the RASPBERRY_API_KEY from the existing .env file
# This preserves the key set by first-boot.sh before we overwrite the file.
PRESERVED_RPI_KEY=""
if [ -f "$FINAL_ENV_FILE" ]; then
    PRESERVED_RPI_KEY=$(grep '^RASPBERRY_API_KEY=' "$FINAL_ENV_FILE" | cut -d'=' -f2)
fi

# --- 2. Stop and Clean ---
echo "Stopping main application service and clearing old code..."
sudo systemctl stop myapp.service || true # Continue if it fails
# Clear old code destination
sudo rm -rf "$APP_DEST_DIR/src" "$APP_DEST_DIR/app.py" "$APP_DEST_DIR/requirements.txt"

# --- 3. Copy Application Files ---
echo "Copying application files..."
sudo cp -r "$APP_SOURCE_DIR/src" "$APP_DEST_DIR/"
sudo cp "$APP_SOURCE_DIR/$MAIN_APP_FILE" "$APP_DEST_DIR/app.py"
sudo cp "$APP_SOURCE_DIR/requirements.txt" "$APP_DEST_DIR/"

# --- 4. Install Python Dependencies ---
echo "Installing Python dependencies from requirements.txt..."
sudo $VENV_PIP install -r "$APP_DEST_DIR/requirements.txt"

# --- 5. Configure App for Production (Port and Simulator Fixes) ---
echo "Configuring app.py for production (/dev/input/qr)..."
# Fix 1: Replace dev port with the production QR port
sudo sed -i "s|^    app_port = os.getenv('DEV_UART_PORT_APP', '/dev/pts/3')|    app_port = os.getenv('UART_PORT', '/dev/input/qr')|" "$APP_DEST_DIR/app.py"
# Fix 2: Remove the simulator port definition and print lines (resolved NameError)
sudo sed -i "/DEV_UART_PORT_SIMULATOR/d" "$APP_DEST_DIR/app.py"
sudo sed -i "/Hardware simulator should use/d" "$APP_DEST_DIR/app.py"

# --- 6. Rewrite .env File (Guaranteeing All 3 Keys) ---
echo "Rewriting .env file with all mandatory keys..."

# Use tee to overwrite the entire .env file content
sudo tee "$FINAL_ENV_FILE" > /dev/null << EOF
# --- Application Configuration ---
# Required for API authentication (PLACEHOLDER: Must be replaced with real value)
API_KEY=PLACEHOLDER_NEEDS_REAL_VALUE
# Required for device identification
RASPBERRY_NAME=Raspberry-Pi-01
# Fetched from API (The key we worked so hard to get!)
RASPBERRY_API_KEY=$PRESERVED_RPI_KEY
EOF

# --- 7. Set Final Ownership and Start ---
echo "Setting file ownership for $CURRENT_USER..."
sudo chown -R $CURRENT_USER:$CURRENT_USER "$APP_DEST_DIR"

echo "Starting main application service..."
sudo systemctl start myapp.service

echo "--- Deployment Complete ---"
echo "Check status with: sudo systemctl status myapp.service"