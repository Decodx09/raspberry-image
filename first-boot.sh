#!/bin/bash
set -e

FLAG_FILE="/etc/provisioned"
ENV_FILE="/opt/app/current/.env"
API_ROOT="https://owedwdgfeeazlqumfikx.supabase.co/functions/v1"
RPI_NAME="Raspberry-Pi-01" # MUST be unique per device

# --- 1. Check if already run ---
if [ -f "$FLAG_FILE" ]; then
    exit 0
fi

# --- 2. Wait for network ---
logger -t "first-boot" "Waiting for network connectivity..."
while ! ping -c 1 -W 1 8.8.8.8; do
    sleep 5
done

# --- 3. Get the HMAC (If implemented by your backend) ---
logger -t "first-boot" "Generating HMAC..."
HMAC_RESPONSE=$(curl -X POST -H "Content-Type: application/json" \-H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im93ZWR3ZGdmZWVhemxxdW1maWt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA4NTE0NTIsImV4cCI6MjA2NjQyNzQ1Mn0.5jiovJMouMH-awzOPTG-Ilsly588bg0jHQ7TeQUaVk0"\
  -d "{\"name\": \"$RPI_NAME\"}" \
  "$API_ROOT/raspberry-generate-hmac")

HMAC_VALUE=$(echo "$HMAC_RESPONSE" | jq -r '.data.hmac')

if [[ -z "$HMAC_VALUE" || "$HMAC_VALUE" == "null" ]]; then
    logger -t "first-boot" "Failed to retrieve valid HMAC. Exiting."
    exit 1
fi

# --- 4. Call the API to get the key ---
logger -t "first-boot" "Calling API to retrieve RASPBERRY_API_KEY..."
API_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \-H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im93ZWR3ZGdmZWVhemxxdW1maWt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA4NTE0NTIsImV4cCI6MjA2NjQyNzQ1Mn0.5jiovJMouMH-awzOPTG-Ilsly588bg0jHQ7TeQUaVk0" \-d "{\"name\": \"$RPI_NAME\", \"hmac\": \"$HMAC_VALUE\"}" "$API_ROOT/raspberry-apiKey")

API_KEY=$(echo "$API_RESPONSE" | jq -r '.data.apiKey')

# --- 5. Save key, flag, and disable service ---
if [[ ! -z "$API_KEY" && "$API_KEY" != "null" ]]; then
    logger -t "first-boot" "API Key retrieved. Saving to .env and disabling service."
    
    # Use sed to replace the key if it exists, otherwise append
    if grep -q "RASPBERRY_API_KEY=" "$ENV_FILE"; then
        sed -i "/^RASPBERRY_API_KEY=/c\RASPBERRY_API_KEY=$API_KEY" "$ENV_FILE"
    else
        echo "RASPBERRY_API_KEY=$API_KEY" >> "$ENV_FILE"
    fi

    # Ensure the correct user owns the updated file
    TARGET_USER=$(stat -c "%U" /opt/app/current)
    chown "$TARGET_USER:$TARGET_USER" "$ENV_FILE"

    touch "$FLAG_FILE"
    systemctl disable first-boot.service
    logger -t "first-boot" "Provisioning complete and service disabled."
else
    logger -t "first-boot" "Failed to retrieve valid API Key. Check API response."
fi