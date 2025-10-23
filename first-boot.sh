#!/bin/bash
set -e

FLAG_FILE="/etc/provisioned"
ENV_FILE="/opt/app/current/.env"

# If this script has already run, do nothing.
if [ -f "$FLAG_FILE" ]; then
    exit 0
fi

# Wait until the internet connection is up
while ! ping -c 1 -W 1 8.8.8.8; do
    sleep 5
done

# Call the API to get the key
# NOTE: Name and HMAC are placeholders here. These would be passed into the
# build pipeline as variables in a real production setup.
API_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
  -d '{"name": "Raspberry-Pi-01", "hmac": "BdahEbCiBiXNnNK8gRKg1BhuXmU+fSiqh3L/INQmcE0="}' \
  "https://owedwdgfeeazlqumfikx.supabase.co/functions/v1/raspberry-apiKey")

API_KEY=$(echo "$API_RESPONSE" | jq -r '.apiKey')

# If we got a key, save it, create the flag file, and disable this service
if [[ ! -z "$API_KEY" && "$API_KEY" != "null" ]]; then
    echo "RASPBERRY_API_KEY=$API_KEY" >> "$ENV_FILE"
    touch "$FLAG_FILE"
    systemctl disable first-boot.service
fi
