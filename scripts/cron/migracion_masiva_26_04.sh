#!/usr/bin/env bash
# ==============================================================================
# ORQUESTADOR AUTÓNOMO DE MIGRACIÓN A UBUNTU 26.04 LTS
# ==============================================================================
# Diseñado para ejecutarse 100% de forma desatendida en el nodo servidor lab12.
# ==============================================================================

set -euo pipefail

REPO_DIR="/home/vasconceloslab12/ansible-lab-pro"
LOG_FILE="${REPO_DIR}/registro_migracion_26_04.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

cd "${REPO_DIR}"

log "=========================================================================="
log "INICIO DEL PROCESO DE MIGRACIÓN MASIVA A UBUNTU 26.04 LTS"
log "=========================================================================="

# 1. ENCENDIDO WAKE-ON-LAN Y ESPERA
log "Fase 1: Enviando Wake-on-LAN dual a todo el laboratorio..."
bash "${REPO_DIR}/scripts/cron/solo_encender.sh" >> "${LOG_FILE}" 2>&1
log "Esperando 300 segundos (5 min) para arranque completo del aula..."
sleep 300

# 2. DESCONTAMINACIÓN PREVIA DE RUSTDESK Y PERSISTENCIA DE X11
log "Fase 2: Purgando RustDesk y cerrando puertos de firewall..."
ansible-playbook -i inventory/hosts.ini playbooks/maintenance/eliminar_rustdesk.yml -e @vault.yml -f 16 >> "${LOG_FILE}" 2>&1 || true

log "Fase 3: Asegurando persistencia de servidor gráfico X11..."
ansible-playbook -i inventory/hosts.ini playbooks/maintenance/forzar_x11.yml -e @vault.yml -f 16 >> "${LOG_FILE}" 2>&1 || true

# 3. LOTE 1 (5 PCs Lubuntu: lab01, lab02, lab03, lab04, lab05)
log "Fase 4: Iniciando Lote 1 (lab01, lab02, lab03, lab04, lab05)..."
ansible-playbook -i inventory/hosts.ini playbooks/maintenance/actualizar_nodo_26_04.yml \
    -e "target_host=lab01,lab02,lab03,lab04,lab05" -e @vault.yml -f 5 >> "${LOG_FILE}" 2>&1
log "Lote 1 finalizado con éxito."

# 4. LOTE 2 (5 PCs Lubuntu: lab06, lab07, lab08, lab09, lab10)
log "Fase 5: Iniciando Lote 2 (lab06, lab07, lab08, lab09, lab10)..."
ansible-playbook -i inventory/hosts.ini playbooks/maintenance/actualizar_nodo_26_04.yml \
    -e "target_host=lab06,lab07,lab08,lab09,lab10" -e @vault.yml -f 5 >> "${LOG_FILE}" 2>&1
log "Lote 2 finalizado con éxito."

# 5. LOTE 3 (3 PCs Lubuntu: lab11, lab13, lab14 - omitiendo lab15 ya migrado)
log "Fase 6: Iniciando Lote 3 (lab11, lab13, lab14)..."
ansible-playbook -i inventory/hosts.ini playbooks/maintenance/actualizar_nodo_26_04.yml \
    -e "target_host=lab11,lab13,lab14" -e @vault.yml -f 3 >> "${LOG_FILE}" 2>&1
log "Lote 3 finalizado con éxito."

# 6. LOTE 4: ESTACIÓN DOCENTE (lab00)
log "Fase 7: Iniciando actualización de la máquina docente (lab00)..."
ansible-playbook -i inventory/hosts.ini playbooks/maintenance/actualizar_nodo_26_04.yml \
    -e "target_host=lab00" -e @vault.yml >> "${LOG_FILE}" 2>&1
log "Estación docente lab00 finalizada con éxito."

# 7. LOTE 5: SERVIDOR EDGE Y ORQUESTADOR (lab12)
log "Fase 8: Iniciando actualización del Orquestador (lab12)..."
ansible-playbook -i inventory/hosts.ini playbooks/maintenance/actualizar_nodo_26_04.yml \
    -e "target_host=lab12" -e @vault.yml >> "${LOG_FILE}" 2>&1
log "Orquestador lab12 actualizado a Ubuntu 26.04 LTS."

# 8. APAGADO FINAL NOCTURNO DE FLOTA
log "Fase 9: Apagando estaciones de trabajo de los alumnos para ahorro nocturno..."
ansible-playbook -i inventory/hosts.ini playbooks/maintenance/solo_apagar.yml -e @vault.yml >> "${LOG_FILE}" 2>&1 || true

log "=========================================================================="
log "MIGRACIÓN MASIVA COMPLETADA AL 100% EN TODO EL LABORATORIO"
log "=========================================================================="
