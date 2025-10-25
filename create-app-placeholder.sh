#!/bin/bash
set -e
APP_FILE="/opt/app/blue/app.py"
CURRENT_USER=$(whoami)

# Create the minimal Python file
sudo bash -c "echo 'import os, sys; print(\"App OK. Key:\", os.getenv(\"RASPBERRY_API_KEY\")); sys.exit(0)' > $APP_FILE"

# Set correct ownership
sudo chown $CURRENT_USER:$CURRENT_USER $APP_FILE

# Restart the main application service
sudo systemctl restart myapp.service