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

# 3. LOTE 1 (Completado previamente: lab01, lab02, lab03, lab04, lab05 y lab15)
log "Lote 1 y nodo canario (lab01, lab02, lab03, lab04, lab05, lab15) ya están en Ubuntu 26.04.1 LTS. Omitiendo."

# 4. LOTE 2 (5 PCs Lubuntu Alumnos: lab06, lab07, lab08, lab09, lab10)
log "Fase 4: Iniciando Lote 2 (lab06, lab07, lab08, lab09, lab10)..."
ansible-playbook -i inventory/hosts.ini playbooks/maintenance/actualizar_nodo_26_04.yml \
    -e "target_host=lab06,lab07,lab08,lab09,lab10" -e @vault.yml -f 5 >> "${LOG_FILE}" 2>&1 || true
log "Lote 2 procesado."

# 5. LOTE 3 (3 PCs Lubuntu Alumnos: lab11, lab13, lab14)
log "Fase 5: Iniciando Lote 3 (lab11, lab13, lab14)..."
ansible-playbook -i inventory/hosts.ini playbooks/maintenance/actualizar_nodo_26_04.yml \
    -e "target_host=lab11,lab13,lab14" -e @vault.yml -f 3 >> "${LOG_FILE}" 2>&1 || true
log "Lote 3 procesado."

# 6. APAGADO FINAL NOCTURNO DE FLOTA DE ALUMNOS (solo_apagar excluye lab00 y lab12)
log "Fase 6: Apagando estaciones de trabajo de los alumnos para ahorro nocturno..."
ansible-playbook -i inventory/hosts.ini playbooks/maintenance/solo_apagar.yml -e @vault.yml >> "${LOG_FILE}" 2>&1 || true
log "Flota de alumnos apagada correctamente."

# 7. NOTIFICACIÓN DE ESTADO (lab00 y lab12 reservados para fase final posterior)
log "=========================================================================="
log "MIGRACIÓN DE TODA LA FLOTA DE ALUMNOS (lab01-lab11, lab13-lab15) COMPLETADA"
log "lab00 (Docente) y lab12 (Servidor) permanecen intactos y en línea sin reinicios."
log "=========================================================================="
