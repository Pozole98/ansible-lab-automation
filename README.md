# Automatización de Laboratorio Vasconcelos

![Ansible](https://img.shields.io/badge/Ansible-2.15+-red.svg?logo=ansible)
![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04_LTS-orange.svg?logo=ubuntu)
![Lubuntu](https://img.shields.io/badge/Lubuntu-24.04_LTS-blue.svg?logo=lubuntu)
![License](https://img.shields.io/badge/License-MIT-green.svg)

Este repositorio contiene la infraestructura como código (IaC) basada en **Ansible** para la automatización, gestión y despliegue del Laboratorio de Cómputo Vasconcelos. 

**📚 Documentación Completa**:
- [Diagramas y Arquitectura del Sistema](docs/arquitectura.md)
- [Guía Paso a Paso de Despliegue](docs/guia_despliegue.md)
- [Automatización Nocturna y Wake-On-LAN](docs/automatizacion_nocturna.md)

## Estructura del Repositorio
El proyecto ha sido estandarizado utilizando roles de Ansible para garantizar modularidad y escalabilidad:

- `inventory/`: Define los hosts y las variables específicas por grupo (ej. `lubuntu`, `edubuntu`).
- `roles/`:
  - `base_system`: Gestión de usuarios dinámicos (basados en IP), auditoría, limpieza de usuarios fantasma y configuración SSH.
  - `desktop_env`: Configuración del entorno gráfico (fondos de pantalla corporativos, paneles LXQt, accesos rápidos, autologin en SDDM).
  - `security_policies`: Bloqueo de aplicaciones (Terminal, Discover) mediante ACLs, políticas restrictivas en Firefox (bloqueo de telemetría y gestor de contraseñas).
  - `software_management`: Despliegue de software de control (Veyon) y entornos de desarrollo (IDEs).
- `playbooks/`: Playbooks principales de alto nivel (`site.yml` para aprovisionamiento total, `mantenimiento.yml` para actualizaciones).
- `scripts/`: Scripts Bash para tareas rutinarias del servidor local.

## Seguridad y Gestión de Secretos
Para proteger las credenciales de administración y hashes de contraseñas, este repositorio utiliza **Ansible Vault**.
1. Copie el archivo `vault.sample.yml` a `vault.yml`.
2. Reemplace los valores con sus contraseñas reales.
3. Encriptar el archivo:
   ```bash
   ansible-vault encrypt vault.yml
   ```
El archivo `vault.yml` está excluido del control de versiones mediante `.gitignore`.

## Ejecución
Para aprovisionar todo el laboratorio:
```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --ask-vault-pass
```

Para ejecutar tareas de mantenimiento de forma aislada (ej. auditoría de usuarios):
```bash
ansible-playbook -i inventory/hosts.ini playbooks/mantenimiento.yml --ask-vault-pass --tags "auditoria"
```
