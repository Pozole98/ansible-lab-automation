#!/bin/bash

# Directorio base del proyecto (calculado dinámicamente)
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MAC_FILE="$PROJECT_ROOT/inventory/mac_addresses.txt"

if [ ! -f "$MAC_FILE" ]; then
    echo "[$(date)] Error: No se encontró el archivo $MAC_FILE."
    exit 1
fi

while read -r IP MAC; do
    [[ "$IP" =~ ^#.*$ ]] || [[ -z "$IP" ]] && continue
    # Omitir el servidor (lab12)
    if [[ "$IP" == "192.168.68.112" ]]; then
        continue
    fi

    wakeonlan -i "$IP" "$MAC" >/dev/null
    wakeonlan "$MAC" >/dev/null
    sleep 0.1
done < "$MAC_FILE"
