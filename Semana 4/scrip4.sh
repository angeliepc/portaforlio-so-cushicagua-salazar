#!/usr/bin/env bash
# scrip4.sh - Demostracion de comandos de Linux (strace, ps, find, dnf)
# Uso:
#   ./scrip4.sh              # solo comandos de consulta (seguro)
#   ./scrip4.sh --instalar   # ademas instala jq con dnf (requiere sudo)

set -u

INSTALAR=0
[[ "${1:-}" == "--instalar" ]] && INSTALAR=1

# Directorio temporal para no ensuciar la carpeta actual
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

seccion() { printf '\n=== %s ===\n' "$1"; }
tiene()   { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------
seccion "1. Archivo de prueba"
printf 'Comprar tomates\nPicar cebolla\nReducir la salsa\n' > "$TMP/notas.txt"
cat "$TMP/notas.txt"

# ---------------------------------------------------------------
seccion "2. Llamadas al sistema con strace"
if tiene strace; then
    echo "--- Solo write ---"
    if [[ -x ./hola ]]; then
        strace -e trace=write ./hola
    else
        echo "(./hola no existe, uso /bin/echo)"
        strace -e trace=write /bin/echo hola
    fi

    echo
    echo "--- Ciclo de vida de un archivo: openat, read, write, close ---"
    strace -e trace=openat,read,write,close cat "$TMP/notas.txt"

    echo
    echo "--- Resumen estadistico de ls (el resumen sale por stderr) ---"
    strace -c ls > /dev/null

    echo
    echo "--- Apertura, escritura y salida ---"
    strace -e trace=openat,write,exit_group cat "$TMP/notas.txt"
else
    echo "strace no esta instalado (sudo dnf install strace)"
fi

# ---------------------------------------------------------------
seccion "3. Tipo de comando"
type cd ls echo

# ---------------------------------------------------------------
seccion "4. Top 3 procesos por memoria (RSS en KB)"
ps -eo pid,comm,rss --sort=-rss | head -n 4

# ---------------------------------------------------------------
seccion "5. Los 5 archivos mas grandes de /var/log"
find /var/log -type f -printf '%s %p\n' 2>/dev/null | sort -rn | head -n 5

# ---------------------------------------------------------------
seccion "6. Gestor de paquetes (dnf / rpm)"
if tiene dnf; then
    echo "--- Repositorios ---"
    dnf repolist

    echo
    echo "--- Buscar e inspeccionar jq ---"
    dnf search jq
    dnf info jq

    if [[ $INSTALAR -eq 1 ]]; then
        echo
        echo "--- Instalando jq ---"
        sudo dnf install -y jq
    else
        echo
        echo "(Omitida la instalacion; usa --instalar para ejecutarla)"
    fi

    echo
    echo "--- Paquetes instalados (primeros 10) ---"
    rpm -qa | head -n 10
    dnf list --installed | head -n 10
else
    echo "dnf no esta disponible en este sistema"
fi

# Ejemplos que dependen de archivos/repos que quiza no tengas:
#   sudo dnf install ./analizador-2.1-1.el9.x86_64.rpm
#   sudo dnf install analizador --enablerepo=terceros

echo
echo "Listo."