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

    # Hacemos un solo ping rápido (espera máximo 1 segundo)
    if ! ping -c 1 -W 1 "$IP" > /dev/null 2>&1; then
        # Si el ping falla, intentamos encenderla
        wakeonlan -i "$IP" "$MAC" >/dev/null
        wakeonlan "$MAC" >/dev/null
    fi
done < "$MAC_FILE"
