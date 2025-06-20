#!/usr/bin/env bash

set -euo pipefail

DOMAIN="example.com"
LIVE_DIR="/etc/letsencrypt/live/$DOMAIN"
TARGET_DIR="/etc/example-certs"
CARGOSHIP_HOME="/home/ec2-user/work/example.com/cargoship"

# 1️⃣ Renew certificate
certbot renew --quiet --standalone

# 2️⃣ Check if target cert exists
if [ ! -f "$TARGET_DIR/fullchain.pem" ]; then
  echo "🔑 No target cert found, copying fresh certs..."
  mkdir -p "$TARGET_DIR"
  cp -L "$LIVE_DIR/"*.pem "$TARGET_DIR/"
  echo "✅ Certificates copied to $TARGET_DIR"
  exit 0
fi

# 3️⃣ Check if LIVE cert is newer than TARGET cert
LIVE_MTIME=$(stat -c %Y "$LIVE_DIR/fullchain.pem")
TARGET_MTIME=$(stat -c %Y "$TARGET_DIR/fullchain.pem")

if [ "$LIVE_MTIME" -gt "$TARGET_MTIME" ]; then
  echo "✅ Newer certificate found — copying real files..."
  mkdir -p "$TARGET_DIR"
  cp -L "$LIVE_DIR/"*.pem "$TARGET_DIR/"
  echo "✅ New certificates copied to $TARGET_DIR"

  # Optional: Reload your service
  # systemctl reload your-service
  # su - ec2-user -c "cd $CARGOSHIP_HOME && docker-compose restart traefik"

else
  echo "ℹ️  No update: target cert is up to date."
fi
