#!/usr/bin/env bash
# ==============================================================================
# analisis_linux.sh - Analisis del sistema Linux
# Genera estado_linux.txt junto al script y lo sube a GitHub.
#
# Uso:    ./analisis_linux.sh            (genera el reporte y sube a GitHub)
#         ./analisis_linux.sh --sin-git  (solo genera el reporte)
# ==============================================================================

set -u

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$DIR/estado_linux.txt"
SIN_GIT=0
[ "${1:-}" = "--sin-git" ] && SIN_GIT=1

# Escribe un titulo de seccion en el reporte
seccion() {
    {
        echo
        echo "---------- $1 ----------"
    } >> "$LOG"
}

# Ejecuta un comando y guarda su salida; si no existe, lo avisa sin abortar
ejecutar() {
    local cmd="$1"
    if command -v "$cmd" >/dev/null 2>&1; then
        {
            echo "\$ $*"
            "$@" 2>&1
            echo
        } >> "$LOG"
    else
        echo "[AVISO] El comando '$cmd' no esta instalado." >> "$LOG"
    fi
}

# --- Encabezado (crea o reemplaza el reporte) ---------------------------------
{
    echo "================================================="
    echo "    ANALISIS DEL SISTEMA - LINUX"
    echo "================================================="
    echo "Fecha y hora de ejecucion: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Nombre del equipo: $(hostname)"
    echo "Usuario actual: $(whoami)"
} > "$LOG"

# --- 1. CPU -------------------------------------------------------------------
seccion "1. PROCESADOR (CPU)"
ejecutar lscpu
{
    echo "\$ cat /proc/cpuinfo (resumen)"
    grep -m1 "model name" /proc/cpuinfo 2>/dev/null
    echo "Nucleos logicos: $(grep -c '^processor' /proc/cpuinfo 2>/dev/null)"
    echo
} >> "$LOG"

# --- 2. Memoria ---------------------------------------------------------------
seccion "2. MEMORIA"
ejecutar free -h
{
    echo "\$ cat /proc/meminfo (primeras 10 lineas)"
    head -n 10 /proc/meminfo 2>&1
    echo
} >> "$LOG"

# --- 3. Almacenamiento --------------------------------------------------------
seccion "3. ALMACENAMIENTO"
ejecutar lsblk
ejecutar df -h

# --- 4. Buses y E/S -----------------------------------------------------------
seccion "4. BUSES Y E/S"
ejecutar lspci
ejecutar lsusb

# --- 5. Red -------------------------------------------------------------------
seccion "5. CONEXIONES DE RED ACTIVAS"
if command -v ip >/dev/null 2>&1; then
    ejecutar ip -brief address
else
    ejecutar hostname -I
fi

# --- 6. Procesos --------------------------------------------------------------
seccion "6. TOP 10 PROCESOS QUE MAS CONSUMEN CPU"
{
    echo "\$ ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 11"
    ps -eo pid,comm,%cpu,%mem --sort=-%cpu 2>&1 | head -n 11
    echo
} >> "$LOG"

# --- 7. Servicios -------------------------------------------------------------
seccion "7. SERVICIOS EN EJECUCION (15 primeros)"
if command -v systemctl >/dev/null 2>&1 && systemctl is-system-running >/dev/null 2>&1 \
   || [ -d /run/systemd/system ]; then
    {
        echo "\$ systemctl list-units --type=service --state=running"
        systemctl list-units --type=service --state=running --no-pager --no-legend 2>&1 | head -n 15
        echo
    } >> "$LOG"
else
    echo "[AVISO] systemd no esta activo en este entorno (por ejemplo, WSL sin systemd)." >> "$LOG"
fi

# --- 8. Resumen del sistema ---------------------------------------------------
seccion "8. RESUMEN DEL SISTEMA OPERATIVO"
{
    echo "\$ cat /etc/os-release"
    grep -E '^(PRETTY_NAME|VERSION)=' /etc/os-release 2>/dev/null
    echo "\$ uname -a"
    uname -a
    echo
    echo "\$ sudo lshw -short"
} >> "$LOG"
if command -v lshw >/dev/null 2>&1; then
    if [ "$(id -u)" -eq 0 ]; then
        lshw -short >> "$LOG" 2>&1
    elif sudo -n true 2>/dev/null; then
        sudo lshw -short >> "$LOG" 2>&1
    else
        echo "[AVISO] lshw necesita permisos de administrador. Ejecuta el script con sudo para incluirlo." >> "$LOG"
    fi
else
    echo "[AVISO] El comando 'lshw' no esta instalado." >> "$LOG"
fi

echo "Analisis completado. Reporte generado en: $LOG"

# --- Sincronizacion con GitHub ------------------------------------------------
if [ "$SIN_GIT" -eq 1 ]; then
    echo "Modo --sin-git: no se sube nada a GitHub."
    exit 0
fi

if ! command -v git >/dev/null 2>&1; then
    echo "[AVISO] Git no esta instalado. Se omite la subida."
    exit 0
fi

cd "$DIR" || exit 1
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "[AVISO] Esta carpeta no es un repositorio Git. Se omite la subida."
    exit 0
fi

echo "Iniciando subida automatica a GitHub..."
git add estado_linux.txt analisis_linux.sh
if git diff --cached --quiet; then
    echo "No hay cambios nuevos que subir."
    exit 0
fi

git commit -m "Actualiza registro automatico del sistema Linux"
if git push; then
    echo "Archivos subidos correctamente al repositorio."
else
    echo "[AVISO] El push fallo. Revisa tu conexion o credenciales de GitHub."
fi
