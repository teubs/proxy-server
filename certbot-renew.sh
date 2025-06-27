#!/bin/bash

# Log-Datei mit Zeitstempel
LOGFILE="/var/log/certbot-renew.log"

# Funktion zum Loggen mit Zeitstempel
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

log "🔄 Starte Certbot-Erneuerung..."

# Stoppe Nginx
log "🛑 Stoppe proxy-server..."
if sudo docker container stop proxy_server 2>&1 | tee -a "$LOGFILE"; then
    log "✅ Nginx gestoppt."
else
    log "❌ Fehler beim Stoppen von Nginx!"
    exit 1
fi

# Dry-Run für die Erneuerung
log "🔍 Starte Dry-Run für Zertifikatserneuerung..."
if sudo certbot renew --dry-run 2>&1 | tee -a "$LOGFILE"; then
    log "✅ Dry-Run erfolgreich."
else
    log "❌ Dry-Run fehlgeschlagen! Siehe Logs für Details."
    exit 1
fi

# Zertifikate erneuern
log "🔄 Starte echte Zertifikatserneuerung..."
if sudo certbot renew 2>&1 | tee -a "$LOGFILE"; then
    log "✅ Zertifikate erneuert."
else
    log "❌ Erneuerung fehlgeschlagen! Siehe Logs."
    exit 1
fi

# Starte Nginx neu
log "🚀 Starte proxy-server..."
if sudo docker container start proxy_server 2>&1 | tee -a "$LOGFILE"; then
    log "✅ Nginx erfolgreich gestartet."
else
    log "❌ Fehler beim Starten von Nginx!"
    exit 1
fi

log "🎉 Erneuerung abgeschlossen."
