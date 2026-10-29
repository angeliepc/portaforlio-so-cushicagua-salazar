#!/usr/bin/env bash
# Script de diagnóstico básico para Linux
# Algunos comandos pueden no estar disponibles en todas las distribuciones.
# Ejecutar con: bash scrip2.sh

set +e

echo "=== 1. Archivos y representación hexadecimal ==="
printf 'Año\n' > t.txt
xxd t.txt
# Muestra el archivo binario si existe:
if [[ -f n.bin ]]; then
    xxd n.bin
else
    echo "No existe n.bin; se omite xxd n.bin."
fi

echo
echo "=== 2. Memoria caché y CPU ==="
lscpu --caches
getconf LEVEL1_DCACHE_LINESIZE
nproc
grep -m1 "model name" /proc/cpuinfo

echo
echo "=== 3. Memoria RAM y procesos ==="
free -h
top -bn1 | sed -n '2p'
vmstat 1 2
head -n 3 /proc/meminfo
cat /proc/uptime

echo
echo "=== 4. Inicio y servicios del sistema ==="
systemd-analyze
systemd-analyze blame --no-pager | head -n 3
systemd-analyze critical-chain --no-pager
ps -p 1 -o pid,comm
pstree -p | head -n 12
systemctl list-units --type=service --state=running --no-pager | head -n 8
systemctl list-units --type=service --state=running --no-legend | wc -l

echo
echo "=== 5. Discos y almacenamiento ==="
lsblk

echo
echo "=== 6. Archivos y dispositivos del sistema ==="
ls /proc | head
ls -l /dev/null /dev/tty /dev/sda 2>/dev/null || ls -l /dev/null /dev/tty /dev/vda

echo
echo "=== 7. Medición del tiempo de ejecución ==="
read -r -p "Escribe tu nombre: " nombre
echo "Hola, $nombre"
time (for i in {1..2000000}; do :; done)
time find /usr -name "*.conf" > /dev/null 2>&1

echo
echo "=== Fin del diagnóstico Linux ==="
