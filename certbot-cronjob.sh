#!/bin/bash

# Pfad zu deinem init-certbot.sh Skript
INIT_CERTBOT_PATH="/home/teubs/Repositories/proxy-server/certbot-renew.sh"

# Prüfen, ob das Skript existiert und ausführbar ist
if [ ! -f "$INIT_CERTBOT_PATH" ]; then
    echo "❌ Fehler: Datei $INIT_CERTBOT_PATH nicht gefunden!"
    exit 1
fi

chmod +x "$INIT_CERTBOT_PATH"

# Cron-Eintrag, der hinzugefügt werden soll (täglich um 3 Uhr)
CRON_ENTRY="* * * * * PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; /bin/bash $INIT_CERTBOT_PATH"

# Temporäre Datei erstellen
TEMP_CRON=$(mktemp)

# Aktuelle Crontab-Einträge in die temporäre Datei schreiben
sudo crontab -l > $TEMP_CRON 2>/dev/null

# Prüfen, ob der Eintrag bereits existiert
if ! grep -F "$CRON_ENTRY" $TEMP_CRON; then
  echo "$CRON_ENTRY" >> $TEMP_CRON
  echo "✅ Cron job hinzugefügt!"
else
  echo "⚠️  Cron job existiert bereits!"
fi

# Die temporäre Datei als neue Crontab setzen
sudo crontab $TEMP_CRON

# Temporäre Datei löschen
rm $TEMP_CRON

echo "✅ Crontab erfolgreich aktualisiert!"
echo "🔄 Aktive Cron-Jobs für $(whoami):"
crontab -l