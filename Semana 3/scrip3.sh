#!/usr/bin/env bash
# scrip3.sh - Diagnóstico Linux (Taller 2, semana 3)
# Genera Informacion_linux.txt con el mismo formato de la semana 2.
# Uso: ./scrip3.sh    (pedirá la contraseña de sudo una sola vez)

SALIDA="Informacion_linux.txt"
exec > >(tee "$SALIDA") 2>&1

tiene() { command -v "$1" >/dev/null 2>&1; }
titulo() { printf '\n=== %s ===\n' "$1"; }

# sudo opcional: si no hay sudo o no se puede usar, se omite el comando
HAY_SUDO=0
if tiene sudo && sudo -v 2>/dev/null; then HAY_SUDO=1; fi
con_sudo() {
    if [ "$HAY_SUDO" -eq 1 ]; then sudo "$@"; else echo "Sin sudo; se omite: $*"; fi
}

echo "=== Inicio del diagnóstico Linux (semana 3) ==="

# ---------------------------------------------------------------- 1
titulo "1. Tiempo de arranque"
if tiene systemd-analyze; then
    systemd-analyze 2>&1
    systemd-analyze blame --no-pager 2>&1 | head -n 5
    systemd-analyze critical-chain --no-pager 2>&1
else
    echo "No existe systemd-analyze; se omiten los tiempos de arranque."
fi
echo "Último arranque: $(uptime -s 2>/dev/null || echo 'no disponible')"

# ---------------------------------------------------------------- 2
titulo "2. Registro del sistema"
if tiene journalctl; then
    journalctl -b -p warning --no-pager 2>&1 | head -n 8 | cut -c1-160
else
    echo "No existe journalctl; se omite el registro del arranque."
fi
if dmesg 2>/dev/null | head -n 5 | grep -q .; then
    dmesg 2>/dev/null | head -n 5
else
    con_sudo dmesg 2>&1 | head -n 5
fi

# ---------------------------------------------------------------- 3
titulo "3. Módulos y controladores"
if tiene lsmod; then
    lsmod | head -n 5
    echo "Módulos cargados: $(lsmod | wc -l)"
    modinfo dummy 2>&1 | head -n 4
    echo "Interfaces antes de modprobe:"
    ip -brief link 2>&1
    con_sudo modprobe dummy 2>&1
    lsmod | grep dummy || echo "El módulo dummy no aparece en lsmod."
    echo "Interfaces después de modprobe:"
    ip -brief link 2>&1
    con_sudo rmmod dummy 2>&1
    echo "Interfaces después de rmmod:"
    ip -brief link 2>&1
else
    echo "No existe lsmod; se omite la parte de módulos."
fi

# ---------------------------------------------------------------- 4
titulo "4. Apagado programado"
if tiene shutdown; then
    con_sudo shutdown -r +5 "Prueba del taller: no se reiniciará" 2>&1
    con_sudo shutdown -c 2>&1
else
    echo "No existe shutdown; se omite el apagado programado."
fi
echo "systemctl reboot no se ejecuta aquí porque reiniciaría el equipo."

# ---------------------------------------------------------------- 5
titulo "5. Deber 3: secciones 1 a 3"
if [ -r /etc/os-release ]; then
    . /etc/os-release
    echo "Sistema: ${PRETTY_NAME:-desconocido}"
fi
echo "Núcleo:  $(uname -r) ($(uname -m))"
echo "Arrancó: $(uptime -s 2>/dev/null || echo 'no disponible')"
echo "Encendida: $(uptime -p 2>/dev/null || echo 'no disponible')"
if tiene systemd-analyze; then
    systemd-analyze time 2>&1 | head -n 2
else
    echo "No existe systemd-analyze; se omite el desglose."
fi

# ---------------------------------------------------------------- 6
titulo "6. Archivos y Git"
if tiene git; then
    git --version
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git status -s | head -n 5
        git log --oneline -n 3 2>&1
    else
        echo "No estás dentro de un repositorio git; se omite git status."
    fi
else
    echo "No existe git; se omiten los comandos de git."
fi
if [ -d semana03 ]; then ls -l semana03; else echo "No existe la carpeta semana03; se omite ls."; fi

echo
echo "=== Fin del diagnóstico Linux ==="k