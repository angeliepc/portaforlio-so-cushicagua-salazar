#!/usr/bin/env bash
# =============================================================================
# informe_arranque.sh - Informe de arranque (Linux / AlmaLinux)
# Sistemas Operativos - EPN - Periodo 2026-B - Deber 3
#
# Autores : <Erick Salazar> y <Paulette Cushicagua>
# Paralelo: <GR1>
# Fecha   : <28/10/2026>
#
# Uso de IA generativa:
#   Herramienta: Claude (Anthropic)
#   Para qué   : entender los comandos y revisar la estructura del script.
#
# Uso: ./informe_arranque.sh      (no requiere sudo)
# Salida: pantalla + archivo informe_<equipo>_<fecha>.txt en la carpeta actual
# =============================================================================

# --- Funciones de apoyo ------------------------------------------------------

# tiene: devuelve 0 si el comando existe en el sistema
tiene() { command -v "$1" >/dev/null 2>&1; }

# seccion: imprime el título de una sección
seccion() { printf '\n=== %s ===\n' "$1"; }

# aviso: informa sin fallar cuando falta un dato o un permiso
aviso() { printf 'AVISO: %s\n' "$*"; }

# --- Archivo de informe: se guarda con el nombre del equipo y la fecha -------
INFORME="informe_$(hostname)_$(date +%F).txt"
exec > >(tee "$INFORME") 2>&1

echo "INFORME DE ARRANQUE (Linux)"
echo "Equipo : $(hostname)"
echo "Fecha  : $(date '+%F %T')"
echo "Autores: <Integrante 1> y <Integrante 2>"

# --- 1 · Sistema operativo, versión y núcleo ---------------------------------
seccion "1 · Sistema operativo, versión y núcleo"
if [ -r /etc/os-release ]; then
    . /etc/os-release
    echo "Sistema: ${PRETTY_NAME:-desconocido}"
else
    aviso "No se pudo leer /etc/os-release."
fi
if tiene uname; then
    echo "Núcleo:  $(uname -r) ($(uname -m))"
else
    aviso "El comando uname no existe."
fi

# --- 2 · Último arranque y tiempo encendido ----------------------------------
seccion "2 · Último arranque y tiempo encendido"
if tiene uptime; then
    echo "Arrancó: $(uptime -s 2>/dev/null || echo 'no disponible')"
    echo "Encendida: $(uptime -p 2>/dev/null || echo 'no disponible')"
else
    aviso "El comando uptime no existe."
fi

# --- 3 · Desglose del arranque (systemd-analyze) -----------------------------
seccion "3 · Desglose del arranque (systemd-analyze)"
if tiene systemd-analyze; then
    if salida=$(systemd-analyze time 2>&1); then
        echo "$salida" | head -n 2
    else
        aviso "systemd-analyze no pudo leer el arranque: $salida"
    fi
else
    aviso "systemd-analyze no existe en este equipo."
fi
# Registro del arranque: primeras advertencias del arranque actual
echo "Registro del arranque (primeras 8 advertencias):"
if tiene journalctl; then
    registro=$(journalctl -b -p warning --no-pager 2>&1 | head -n 8 | cut -c1-160)
    if [ -z "$registro" ] || echo "$registro" | grep -qiE 'no journal files|permission|not seeing'; then
        aviso "No hay permiso o no hay entradas en el journal (agregue el usuario al grupo systemd-journal)."
    else
        echo "$registro" | sed 's/^/  /'
    fi
else
    aviso "journalctl no existe en este equipo."
fi

# --- 4 · Cinco unidades más lentas -------------------------------------------
seccion "4 · Cinco unidades más lentas"
if tiene systemd-analyze; then
    if salida=$(systemd-analyze blame --no-pager 2>&1); then
        echo "$salida" | head -n 5
    else
        aviso "systemd-analyze blame falló: $salida"
    fi
else
    aviso "systemd-analyze no existe en este equipo."
fi

# --- 5 · Módulos del núcleo --------------------------------------------------
seccion "5 · Módulos del núcleo"
if tiene lsmod; then
    echo "Módulos cargados: $(lsmod | tail -n +2 | wc -l)"
    echo "Los 5 más grandes (módulo, tamaño en bytes):"
    lsmod | tail -n +2 | sort -k2 -n -r | head -n 5 | awk '{printf "  %-25s %s\n", $1, $2}'
else
    aviso "El comando lsmod no existe."
fi

# --- 6 · Cierre --------------------------------------------------------------
seccion "6 · Cierre"
if tiene systemctl; then
    echo "Target por defecto: $(systemctl get-default 2>/dev/null || echo 'no disponible')"
    fallidas=$(systemctl --failed --no-pager --no-legend 2>/dev/null)
    if [ -z "$fallidas" ]; then
        echo "Unidades fallidas: ninguna"
    else
        echo "Unidades fallidas:"
        echo "$fallidas" | sed 's/^/  /'
    fi
else
    aviso "systemctl no existe en este equipo."
fi

echo
echo "Informe guardado en: $(pwd)/$INFORME"