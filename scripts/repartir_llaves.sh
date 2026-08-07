#!/bin/bash

# Solicitar la contraseña de forma segura al inicio
read -s -p "Introduce la contraseña del administrador (para todos los equipos): " PASSWORD
echo ""

if [ -z "$PASSWORD" ]; then
    echo "La contraseña no puede estar vacía. Abortando."
    exit 1
fi

echo "Iniciando la distribución de llaves SSH en el Laboratorio..."

# Iteramos del 0 al 16 para cubrir de la IP .100 a la .116
for i in {0..16}; do
  # Formateamos el número a dos dígitos (00, 01, ..., 16)
  num=$(printf "%02d" $i)
  
  # Construimos la IP y el usuario
  ip="192.168.68.1$num"
  usuario="vasconceloslab$num"
  
  echo "------------------------------------------------"
  echo "Copiando llave a $usuario @ $ip..."
  
  # sshpass inyecta la contraseña. StrictHostKeyChecking=no evita que la terminal nos detenga preguntando "yes/no"
  sshpass -p "$PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no "$usuario@$ip"
done

echo "------------------------------------------------"
echo "¡Distribución completada! Ya puedes gobernar el laboratorio sin contraseñas."
