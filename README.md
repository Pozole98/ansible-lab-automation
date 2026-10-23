# Automatización y Resiliencia de Infraestructura: Laboratorio Vasconcelos

![Ansible](https://img.shields.io/badge/Ansible-2.15+-red.svg?logo=ansible)
![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04_LTS-orange.svg?logo=ubuntu)
![Lubuntu](https://img.shields.io/badge/Lubuntu-24.04_LTS-blue.svg?logo=lubuntu)
![Bash](https://img.shields.io/badge/Bash-Automation-4EAA25.svg?logo=gnu-bash)
![Security](https://img.shields.io/badge/Security-Polkit_%26_ACLs-green.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

Infraestructura como Código (IaC), orquestación de borde (*Edge Computing*) y mantenimiento desatendido para el aula de cómputo del Laboratorio Vasconcelos.

Este repositorio documenta e implementa una solución de ingeniería completa diseñada para resolver una restricción del mundo real: **garantizar alta disponibilidad, mantenimiento nocturno automático y auto-curación continua en un aula de 16 equipos de cómputo, sin contar con un presupuesto para servidores dedicados ni cuartos de racks aislados.**

---

## 📚 Documentación Técnica de Nivel Producción

Para explorar a fondo la arquitectura, el diseño de seguridad y los flujos operativos, consulte las guías especializadas:

- 🏛️ **[Arquitectura del Sistema y Topología de Red](docs/arquitectura.md):** Diagramas de red mesh Deco, inventario de flota híbrida (Lubuntu LXQt y Edubuntu GNOME) y secuencia de roles.
- 🛡️ **[Caso de Estudio: Hardening del Orquestador Edge (`lab12`)](docs/orquestador_edge_hardening.md):** Cómo se transformó una estación de trabajo usada por alumnos en un servidor de control permanente mediante un blindaje de 9 capas (BIOS, botón físico, `systemd-logind`, X11, DCONF y Polkit).
- 🌙 **[Automatización, Auto-Curación y Ciclo de Vida Nocturno](docs/automatizacion_nocturna.md):** Explicación del ciclo diario en 5 fases, el watchdog de ping ICMP escolar, el protocolo dual Wake-on-LAN y análisis de telemetría de producción.
- 🚀 **[Guía Paso a Paso de Aprovisionamiento](docs/guia_despliegue.md):** Procedimientos de arranque desde cero, inyección de llaves SSH y ejecución de playbooks.
- 📦 **[Plan Maestro de Migración a Ubuntu 26.04 LTS](docs/plan_migracion_ubuntu_26_04.md):** Estrategia desatendida por lotes, erradicación de RustDesk y forzado de X11 para Veyon.
- ⏱️ **[Plantilla de Tareas Programadas (Crontab)](docs/crontab.sample):** Crontab de producción verificado para programar las 5 etapas operativas.

---

## 💡 Capacidades Clave de la Infraestructura

### 1. Orquestador Edge Resiliente (Doble Rol Simultáneo)
El nodo de control (**`lab12` - Lenovo ThinkCentre M720s**) opera simultáneamente como estación pedagógica para estudiantes (`alumno12`) y como servidor maestro de automatización (`vasconceloslab12`):
- **Encendido Incondicional (BIOS):** Configurado con `State After G3 = Power On` para auto-arrancar inmediatamente después de cualquier corte de suministro eléctrico.
- **Inmunidad Física y por Software a Apagados:** Botón físico de chasis deshabilitado mecánicamente, eventos ACPI descartados por `systemd-logind` (`HandlePowerKey=ignore`), botones de GUI anulados por GNOME DCONF y llamadas de apagado/reinicio interceptadas por PolicyKit (`AUTH_ADMIN`).
- **Bloqueo de Terminales Virtuales:** Servidor X11 configurado con `DontVTSwitch` y `DontZap` para evitar que usuarios eludan el entorno gráfico.

### 2. Watchdog de Auto-Curación en Tiempo Real (`vigilante.sh`)
Durante la jornada de clases (`*/2 7-14 * * 1-5`), un script en segundo plano monitorea por ICMP (timeout de 1s) todas las estaciones de trabajo. Si un alumno apaga una máquina por accidente o se mueve un cable, el orquestador dispara un paquete **Wake-on-LAN dual** (Unicast directo + Broadcast a subred) para encenderla de inmediato sin que el docente deba intervenir.

### 3. Mantenimiento Nocturno Desatendido y Guillotina Failsafe
- **08:00 PM:** Envío masivo de Wake-on-LAN, periodo de espera de 600s para estabilización del sistema operativo y ejecución de Ansible para aplicar `apt-get dist-upgrade`, `autoremove` y `snap refresh`.
- **Apagado Selectivo Inteligente:** Las máquinas de los alumnos se apagan tras actualizar, mientras que el orquestador (`lab12`) y el equipo docente (`lab00`) se omiten automáticamente (`when: inventory_hostname not in ['lab00', 'lab12']`).
- **11:00 PM (Guillotina):** Barrido de emergencia de apagado para mitigar cualquier nodo que haya quedado colgado por un proceso zombi.

### 4. Identidad Dinámica y Redirección OAuth para IDEs
- **Cálculo Matemático de Identidad:** Los playbooks calculan el nombre de usuario local a partir del último octeto IP (`alumno{{ IP[-2:] }}`), purgando cuentas no autorizadas de forma determinista.
- **Soporte OAuth para Editores de Código:** Registro a nivel sistema y de usuario de los protocolos MIME `x-scheme-handler/vscode` y `x-scheme-handler/windsurf`, permitiendo a los alumnos autenticarse con GitHub en el navegador y volver al IDE sin fricción de permisos.

---

## 📂 Estructura del Repositorio

```text
├── ansible.cfg                    # Configuración estandarizada del cliente Ansible
├── docs/                          # Documentación técnica completa y casos de estudio
│   ├── arquitectura.md            # Diagramas de topología y modelo edge
│   ├── automatizacion_nocturna.md # Ciclo de 5 fases y watchdog de auto-curación
│   ├── crontab.sample             # Tareas programadas del orquestador
│   ├── guia_despliegue.md         # Guía de aprovisionamiento paso a paso
│   ├── orquestador_edge_hardening.md # Deep dive de blindaje del servidor lab12
│   └── plan_migracion_ubuntu_26_04.md # Plan de migración a Ubuntu 26.04 LTS
├── inventory/
│   ├── hosts.ini                  # Inventario categorizado por rol de escritorio (lubuntu/edubuntu)
│   ├── mac_addresses.txt          # Mapeo de IPs y MACs para paquetes mágicos Wake-on-LAN
│   └── group_vars/                # Variables desacopladas y sanitizadas por grupo
├── playbooks/
│   ├── site.yml                   # Playbook maestro de aprovisionamiento total
│   ├── mantenimiento.yml          # Playbook modular con tags para operaciones frecuentes
│   └── maintenance/               # Playbooks de tareas específicas del orquestador
│       ├── bloquear_apagado_orquestador.yml # Despliegue de Polkit y logind anti-apagado
│       ├── bloquear_red_polkit.yml          # Despliegue de Polkit anti-desconexión de red
│       ├── eliminar_rustdesk.yml            # Purgado completo y cierre de puertos de RustDesk
│       ├── forzar_x11.yml                   # Bloqueo de Wayland y persistencia de X11 para Veyon
│       ├── instalar_codeblocks.yml          # Instalación de Code::Blocks, GCC, GDB y soporte C
│       ├── mantenimiento.yml                # Actualización de APT/Snap y apagado nocturno
│       ├── reparardinamico.yml              # Corrección dinámica de permisos por IP
│       ├── reparar_login_editor.yml         # Registro de esquemas URI para VS Code/Windsurf
│       ├── solo_apagar.yml                  # Apagado selectivo de final de clases
│       └── rescate.yml                      # Extracción y respaldo comprimido de datos
├── roles/
│   ├── base_system/               # Usuarios dinámicos, llaves SSH y auditoría
│   ├── desktop_env/               # SDDM autologin, fondos institucionales y paneles
│   ├── security_policies/         # ACLs en terminales y políticas de privacidad en Firefox
│   └── software_management/       # Veyon Master/Client e instalación de IDEs
├── scripts/
│   ├── cron/                      # Scripts ejecutados por el planificador del orquestador
│   │   ├── orquestador.sh         # Orquestación de encendido, espera y mantenimiento
│   │   ├── solo_encender.sh       # Disparo veloz de Wake-on-LAN matutino
│   │   └── vigilante.sh           # Watchdog de ping y auto-encendido escolar
│   ├── encender_laboratorio.sh    # Utilidad interactiva CLI para encender el aula
│   ├── escanear_lab.sh            # Auditoría rápida de hosts activos en la subred
│   └── repartir_llaves.sh         # Inyección masiva de llaves públicas SSH
└── vault.sample.yml               # Plantilla de secretos para cifrado con Ansible Vault
```

---

## 🔒 Gestión de Secretos con Ansible Vault

El repositorio se encuentra 100% libre de credenciales en texto plano:
1. Copie la plantilla de secretos:
   ```bash
   cp vault.sample.yml vault.yml
   ```
2. Edite `vault.yml` con las contraseñas de su entorno.
3. Cifre el archivo con contraseña segura:
   ```bash
   ansible-vault encrypt vault.yml
   ```
El archivo `vault.yml` está ignorado en `.gitignore` para evitar cualquier fuga accidental a repositorios públicos.

---

## 🛠️ Comandos de Operación Rápida

### Aprovisionamiento Completo del Aula
```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --ask-vault-pass
```

### Instalar Code::Blocks y Cadena de Compilación C
```bash
ansible-playbook -i inventory/hosts.ini playbooks/maintenance/instalar_codeblocks.yml --ask-vault-pass
```

### Ejecutar Auditoría Rápida de Usuarios
```bash
ansible-playbook -i inventory/hosts.ini playbooks/mantenimiento.yml --ask-vault-pass --tags "auditoria"
```

### Aplicar Blindaje de Botones y Polkit en el Orquestador
```bash
ansible-playbook -i inventory/hosts.ini playbooks/maintenance/bloquear_apagado_orquestador.yml --ask-vault-pass
```

### Encender todo el Laboratorio Manualmente
```bash
./scripts/encender_laboratorio.sh
```

---

## 📄 Licencia

Distribuido bajo la Licencia MIT. Consulte `LICENSE` para más detalles.
