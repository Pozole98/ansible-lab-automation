#!/bin/bash

# Archivo de configuración con las direcciones MAC e IPs
MAC_FILE="$(dirname "$0")/../inventory/mac_addresses.txt"

if [ ! -f "$MAC_FILE" ]; then
    echo "Error: No se encontró el archivo $MAC_FILE."
    echo "Por favor copia inventory/mac_addresses.sample.txt a inventory/mac_addresses.txt y configúralo."
    exit 1
fi

# Contar líneas válidas (que no estén vacías y no sean comentarios)
NUM_EQUIPOS=$(grep -cvE '^\s*#|^\s*$' "$MAC_FILE")
echo "Iniciando encendido Unicast (Directo a IP estática) de $NUM_EQUIPOS computadoras..."

# Leer archivo línea por línea
while read -r IP MAC; do
    # Ignorar comentarios y líneas vacías
    [[ "$IP" =~ ^#.*$ ]] || [[ -z "$IP" ]] && continue
    
    echo "Despertando PC en $IP (MAC: $MAC)"
    
    # Enviamos el Magic Packet apuntando a la IP específica para atravesar el Deco
    wol -i "$IP" "$MAC"
    
    # Un pequeño descanso entre envíos para no saturar la red mesh
    sleep 0.2
done < "$MAC_FILE"

echo "¡Listo! Todas las señales han sido enviadas a través del router."
