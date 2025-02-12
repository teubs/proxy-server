#!/bin/bash

# Macht das Skript ausführbar: chmod +x init-certbot.sh

echo "$(date) - Certbot erneuert von cron" >> /var/log/cron-certbot-debug.log

# Stoppe den Nginx-Container
echo "Stopping Nginx container..."
if ! sudo docker container stop proxy_server; then
  echo "Failed to stop Nginx container. Exiting."
  exit 1
fi

# Führe einen Dry-Run der Zertifikatserneuerung durch
echo "Performing Dry-Run for certificate renewal..."
if ! sudo certbot renew --dry-run; then
  echo "Dry-Run failed. Please check Certbot logs."
  exit 1
fi

# Erneuere die Zertifikate
echo "Renewing certificates..."
if ! sudo certbot renew; then
  echo "Certificate renewal failed. Please check Certbot logs."
  exit 1
fi

# Starte den Nginx-Container neu
echo "Starting Nginx container..."
if ! sudo docker container start proxy_server; then
  echo "Failed to start Nginx container. Exiting."
  exit 1
fi

echo "All done successfully."