# Guía de Despliegue

Sigue estos pasos para desplegar la infraestructura del laboratorio de cómputo en un ambiente de producción.

## 1. Prerrequisitos

- Un servidor maestro (Control Node) ejecutando Ubuntu 24.04 o similar.
- Ansible instalado en el servidor maestro (`sudo apt install ansible`).
- sshpass instalado en el servidor maestro (`sudo apt install sshpass`) para el script inicial de llaves.
- Acceso por red a los clientes.

## 2. Configurar Secretos (Ansible Vault)

1. Copia la plantilla de la bóveda (vault) de Ansible:
   ```bash
   cp vault.sample.yml vault.yml
   ```
2. Edita `vault.yml` e introduce las contraseñas reales (la contraseña SSH global, la de administrador y el hash de la contraseña de los alumnos).
3. Encripta el archivo usando Ansible Vault:
   ```bash
   ansible-vault encrypt vault.yml
   ```
   > [!IMPORTANT]
   > Te pedirá una contraseña para encriptar el archivo. Anótala, ya que la necesitarás al ejecutar los playbooks.

## 3. Configurar Inventario y Red

1. Edita `inventory/hosts.ini` para asegurarte de que las IPs coincidan con tu infraestructura.
2. Copia la configuración de red MAC:
   ```bash
   cp inventory/mac_addresses.sample.txt inventory/mac_addresses.txt
   ```
3. Edita `inventory/mac_addresses.txt` con el formato `IP MAC` de todos los equipos físicos de tu laboratorio.

## 4. Distribución de Llaves SSH (Solo la Primera Vez)

Para evitar que Ansible pida contraseñas por cada máquina durante su ejecución, reparte tu llave SSH a todos los clientes.

1. Asegúrate de tener una llave en el servidor maestro:
   ```bash
   ssh-keygen -t ed25519
   ```
2. Ejecuta el script de repartición:
   ```bash
   ./scripts/repartir_llaves.sh
   ```
   *Se te pedirá la contraseña general de administrador de forma segura.*

## 5. Aprovisionamiento Total

Una vez que el nodo de control tiene las llaves SSH distribuidas y los secretos configurados, ejecuta el playbook principal:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --ask-vault-pass
```

## 6. Mantenimiento Rutinario

Para mantener los equipos actualizados y limpiar usuarios fantasmas sin alterar las configuraciones gráficas, ejecuta:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/mantenimiento.yml --ask-vault-pass
```
