#!/bin/bash

# Let's Encrypt Verzeichnis
LE_DIR="/etc/letsencrypt/live/"

# Prüfen, ob Let's Encrypt installiert ist
if ! command -v certbot &> /dev/null; then
    echo "❌ Certbot ist nicht installiert. Bitte mit 'sudo apt install certbot' installieren."
    exit 1
fi

echo "🔍 Suche nach bestehenden Zertifikaten..."
if [ ! -d "$LE_DIR" ]; then
    echo "⚠️  Das Let's Encrypt-Verzeichnis existiert nicht! Wurde Certbot bereits ausgeführt?"
    exit 1
fi

# Liste alle vorhandenen Zertifikate auf
CERT_NAMES=($(ls -1 "$LE_DIR"))
if [ ${#CERT_NAMES[@]} -eq 0 ]; then
    echo "⚠️  Keine Zertifikate gefunden. Starte zuerst ein Certbot-Setup!"
    exit 1
fi

echo "📜 Verfügbare Zertifikate:"
for i in "${!CERT_NAMES[@]}"; do
    echo "  [$((i+1))] ${CERT_NAMES[$i]}"
done

# Benutzer soll das Zertifikat auswählen
read -p "👉 Wähle eine Nummer für das Zertifikat, das du erweitern möchtest: " CERT_INDEX
CERT_INDEX=$((CERT_INDEX-1))

if [[ $CERT_INDEX -lt 0 || $CERT_INDEX -ge ${#CERT_NAMES[@]} ]]; then
    echo "❌ Ungültige Auswahl!"
    exit 1
fi

CERT_NAME="${CERT_NAMES[$CERT_INDEX]}"
echo "✅ Gewähltes Zertifikat: $CERT_NAME"

# Bestehende Domains auslesen
EXISTING_DOMAINS=$(sudo certbot certificates --cert-name "$CERT_NAME" | grep "DNS:" | sed 's/DNS://g' | tr -d ',')

echo "🔹 Aktuell registrierte Domains für $CERT_NAME: $EXISTING_DOMAINS"

# Benutzer fragen, ob neue Domains hinzugefügt werden sollen
read -p "➕ Möchtest du eine neue Domain hinzufügen? (y/n) " ADD_DOMAIN

if [[ "$ADD_DOMAIN" == "y" || "$ADD_DOMAIN" == "Y" ]]; then
    read -p "✍️  Gib die neue(n) Domain(s) ein (getrennt mit Leerzeichen): " NEW_DOMAINS
    if [[ -z "$NEW_DOMAINS" ]]; then
        echo "❌ Keine Domains eingegeben. Abbruch."
        exit 1
    fi

    # Alle Domains zusammenführen
    ALL_DOMAINS="$EXISTING_DOMAINS $NEW_DOMAINS"

    echo "🌍 Neue Zertifikatsliste: $ALL_DOMAINS"
    echo "🚀 Starte Certbot zur Erweiterung..."

    # Nginx-Container stoppen, da Certbot Port 80 benötigt
    echo "🛑 Stoppe den Nginx-Container..."
    sudo docker container stop nginx-container

    # Certbot mit --expand für das gewählte Zertifikat
    sudo certbot certonly --expand --cert-name "$CERT_NAME" -d $ALL_DOMAINS

    echo "✅ Zertifikat wurde erweitert."

    # Nginx-Container wieder starten
    echo "🚀 Starte den Nginx-Container..."
    sudo docker container start nginx-container

else
    echo "❌ Keine neuen Domains hinzugefügt."
fi

echo "✅ Fertig!"