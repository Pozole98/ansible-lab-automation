#!/bin/bash

# Tu subred de los Deco
SUBRED="192.168.68"

echo "Escaneando las 16 PCs del laboratorio..."
echo "Rango: $SUBRED.100 - $SUBRED.115"
echo "----------------------------------------"

# Bucle exacto para las IPs del 100 al 115
for i in {100..115}; do
  (
    # Envía 1 paquete y espera 1 segundo máximo
    if ping -c 1 -W 4 $SUBRED.$i &> /dev/null; then
      # Verde si responde
      echo -e "Equipo $SUBRED.$i -> \e[32mENCENDIDO\e[0m"
    else
      # Rojo si no responde
      echo -e "Equipo $SUBRED.$i -> \e[31mAPAGADO\e[0m"
    fi
  ) &
done

# Espera a que los 16 pings simultáneos terminen
wait

echo "----------------------------------------"
echo "Escaneo completado."
