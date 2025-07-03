#!/bin/bash

set -e

echo "[+] Levantando contenedor Suricata desde imagen privada..."
docker-compose up -d

# Esperamos unos segundos para asegurar que el contenedor arranca
sleep 5

# Obtener el ID del contenedor de Suricata
CONTAINER_ID=$(docker-compose ps -q suricata)

if [ -z "$CONTAINER_ID" ]; then
    echo "[!] No se pudo obtener el ID del contenedor Suricata. ¿Está el servicio definido como 'suricata'?"
    exit 1
fi

echo "[+] Copiando archivo suricata.yaml del host al contenedor..."
docker cp ./suricata.yaml "$CONTAINER_ID":/etc/suricata/suricata.yaml

# Descargar reglas emergentes
RULES_TAR="emerging.rules.tar.gz"
RULES_URL="https://rules.emergingthreatspro.com/open/suricata-7.0.3/$RULES_TAR"

echo "[+] Descargando reglas emergentes..."
curl -L -o "$RULES_TAR" "$RULES_URL"
sleep 3

echo "[+] Copiando archivo de reglas al contenedor..."
docker cp "$RULES_TAR" "$CONTAINER_ID":/tmp/"$RULES_TAR"

echo "[+] Descomprimiendo reglas dentro del contenedor..."
docker exec "$CONTAINER_ID" tar -xzvf /tmp/"$RULES_TAR" -C /etc/suricata/

echo "[+] Eliminando archivo temporal de reglas en el contenedor..."
docker exec "$CONTAINER_ID" rm /tmp/"$RULES_TAR"

echo "[+] Eliminando archivo temporal de reglas en el host..."
rm "$RULES_TAR"

echo "[+] Reiniciando el contenedor Suricata para aplicar la configuración..."
docker restart "$CONTAINER_ID"

echo "[✓] Despliegue y configuración completados."
