#!/bin/bash

# ================================
# Neue Domain zu Certbot hinzufügen (neues Zertifikat)
# ================================

LOGFILE="/var/log/certbot-new-domain.log"
DOMAIN=""
EMAIL=""
CERT_NAME=""
PROXY_CONTAINER="proxy_server"

function log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

echo "🔧 Neue Domain einrichten mit Certbot..."

read -p "🌐 Gib die neue Domain ein (z. B. my.sub.domain.de): " DOMAIN
if [[ -z "$DOMAIN" ]]; then
    echo "❌ Keine Domain eingegeben – Abbruch."
    exit 1
fi

read -p "📬 Gib deine E-Mail-Adresse für Let's Encrypt ein: " EMAIL
if [[ -z "$EMAIL" ]]; then
    echo "❌ Keine E-Mail-Adresse angegeben – Abbruch."
    exit 1
fi

read -p "🏷️  Wie soll das Zertifikat benannt werden (Certbot --cert-name)? " CERT_NAME
if [[ -z "$CERT_NAME" ]]; then
    echo "❌ Kein Zertifikatname eingegeben – Abbruch."
    exit 1
fi

log "🛑 Stoppe Docker-Proxy (${PROXY_CONTAINER})..."
if sudo docker container stop $PROXY_CONTAINER; then
    log "✅ Proxy gestoppt."
else
    log "⚠️  Proxy konnte nicht gestoppt werden – fahre fort..."
fi

log "🚀 Starte Certbot für neue Domain '$DOMAIN' mit Zertifikat '$CERT_NAME'..."
if sudo certbot certonly --standalone \
    --preferred-challenges http \
    --cert-name "$CERT_NAME" \
    --agree-tos \
    --no-eff-email \
    -m "$EMAIL" \
    -d "$DOMAIN" 2>&1 | tee -a "$LOGFILE"; then
    log "✅ Zertifikat erfolgreich erstellt."
else
    log "❌ Fehler beim Erstellen des Zertifikats!"
    sudo docker container start $PROXY_CONTAINER
    exit 1
fi

log "🚀 Starte Proxy wieder..."
if sudo docker container start $PROXY_CONTAINER; then
    log "✅ Proxy erfolgreich gestartet."
else
    log "❌ Fehler beim Starten des Proxys!"
    exit 1
fi

log "🎉 Neue Domain '$DOMAIN' erfolgreich hinzugefügt!"