#!/bin/bash

# Directorio base del proyecto (calculado dinámicamente)
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MAC_FILE="$PROJECT_ROOT/inventory/mac_addresses.txt"

if [ ! -f "$MAC_FILE" ]; then
    echo "[$(date)] Error: No se encontró el archivo $MAC_FILE."
    exit 1
fi

echo "[$(date)] Iniciando protocolo Wake-On-LAN dual (Unicast + Broadcast)..."

# Leer IPs y MACs dinámicamente ignorando la PC actual (servidor lab12) y comentarios
while read -r IP MAC; do
    [[ "$IP" =~ ^#.*$ ]] || [[ -z "$IP" ]] && continue
    # No despertar al propio servidor orquestador si por error está en la lista
    if [[ "$IP" == "192.168.68.112" ]]; then
        continue
    fi
    
    echo "Despertando PC en $IP (MAC: $MAC)"
    # 1. Intento Unicast (Atraviesa routers)
    wakeonlan -i "$IP" "$MAC" >/dev/null
    # 2. Intento Broadcast estándar (Red local)
    wakeonlan "$MAC" >/dev/null
    sleep 0.2
done < "$MAC_FILE"

echo "[$(date)] ¡Paquetes mágicos enviados! Esperando 10 minutos (600s) para que el laboratorio arranque..."
sleep 600

echo "[$(date)] Iniciando actualizaciones con Ansible..."
cd "$PROJECT_ROOT" || exit 1
ansible-playbook -i inventory/hosts.ini playbooks/maintenance/mantenimiento.yml

echo "[$(date)] Mantenimiento nocturno finalizado con éxito."
