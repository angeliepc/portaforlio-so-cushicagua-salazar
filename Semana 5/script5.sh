#!/usr/bin/env bash
# =====================================================================
# Semana 5 · Taller 1 · Guardias en la puerta (Linux / AlmaLinux)
# Escuela Politécnica Nacional · Sistemas Operativos · 2026-B
# Integrantes: Paulette Cushicagua · Erick Salazar
#
# Uso:
#   chmod +x semana05_linux.sh
#   ./semana05_linux.sh [muestras_auth.log] | tee captura_linux.txt
# =====================================================================
set -u

PUERTO=8080
MUESTRA="${1:-muestras_auth.log}"
USUARIO="${USER:-$(id -un)}"
SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"
SERVER_PID=""

# ---------- funciones auxiliares ----------
titulo() { printf '\n==================== %s ====================\n' "$1"; }
paso()   { printf '\n$ %s\n' "$1"; }
tiene()  { command -v "$1" >/dev/null 2>&1; }
falta()  { echo "(omitido: no se encontró el comando '$1' en este equipo)"; }

# Mide el tiempo real y el código de salida de curl al puerto del taller
medir() {
  local t0 t1 codigo
  t0=$(date +%s.%N)
  curl -s -o /dev/null -m 5 "http://127.0.0.1:$PUERTO"
  codigo=$?
  t1=$(date +%s.%N)
  awk -v a="$t0" -v b="$t1" -v c="$codigo" \
    'BEGIN { printf "real: %.2f s · código: %d\n", b - a, c }'
}

# IDS a mano: cuenta cuántas veces aparece cada IP después de la palabra "from"
contar_ips() {
  awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' | sort | uniq -c | sort -rn
}

# Limpieza obligatoria (se ejecuta siempre al terminar)
limpiar() {
  $SUDO nft delete table inet taller 2>/dev/null
  [ -n "$SERVER_PID" ] && kill "$SERVER_PID" 2>/dev/null
  return 0
}
trap limpiar EXIT

echo "Semana 5 · Taller 1 · Guardias en la puerta (Linux)"
echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S')  ·  Equipo: $(hostname)  ·  Usuario: $USUARIO"

# =====================================================================
titulo "1. Puertas abiertas"
# =====================================================================
if tiene ss; then
  paso "ss -tln";       ss -tln
  paso "sudo ss -tlnp"; $SUDO ss -tlnp
  echo
  echo "N.º de puertas en escucha: $(ss -tln | tail -n +2 | wc -l)"
else
  falta ss
fi

paso "python3 -m http.server $PUERTO &>/dev/null &"
python3 -m http.server "$PUERTO" &>/dev/null &
SERVER_PID=$!
sleep 1

if tiene ss; then
  paso "ss -tln | grep $PUERTO"
  ss -tln | grep "$PUERTO"
fi
paso "curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:$PUERTO"
curl -s -o /dev/null -w '%{http_code}\n' "http://127.0.0.1:$PUERTO"

# =====================================================================
titulo "2. El portero en Linux (firewalld)"
# =====================================================================
if tiene firewall-cmd; then
  paso "sudo firewall-cmd --state";             $SUDO firewall-cmd --state
  paso "sudo firewall-cmd --get-active-zones";  $SUDO firewall-cmd --get-active-zones
  paso "sudo firewall-cmd --list-all";          $SUDO firewall-cmd --list-all
else
  falta firewall-cmd
fi

# =====================================================================
titulo "3. DROP frente a REJECT (nftables)"
# =====================================================================
if tiene nft; then
  $SUDO nft delete table inet taller 2>/dev/null    # empezar sin restos previos

  paso "sudo nft add table inet taller"
  $SUDO nft add table inet taller
  paso "sudo nft add chain inet taller entrada '{ type filter hook input priority 0; policy accept; }'"
  $SUDO nft add chain inet taller entrada '{ type filter hook input priority 0; policy accept; }'

  echo; echo "# 1) Sin regla (se espera ≈0,01 s y código 0)"
  paso "time curl -s -o /dev/null -m 5 http://127.0.0.1:$PUERTO; echo \"código: \$?\""
  medir

  echo; echo "# 2) DROP: el portero calla (se espera ≈5 s y código 28)"
  paso "sudo nft add rule inet taller entrada tcp dport $PUERTO drop"
  $SUDO nft add rule inet taller entrada tcp dport "$PUERTO" drop
  paso "time curl -s -o /dev/null -m 5 http://127.0.0.1:$PUERTO; echo \"código: \$?\""
  medir

  echo; echo "# 3) REJECT: el portero dice «no» (se espera ≈0,01 s y código 7)"
  paso "sudo nft flush chain inet taller entrada"
  $SUDO nft flush chain inet taller entrada
  paso "sudo nft add rule inet taller entrada tcp dport $PUERTO reject with tcp reset"
  $SUDO nft add rule inet taller entrada tcp dport "$PUERTO" reject with tcp reset
  paso "time curl -s -o /dev/null -m 5 http://127.0.0.1:$PUERTO; echo \"código: \$?\""
  medir

  paso "sudo nft list table inet taller"
  $SUDO nft list table inet taller

  echo; echo "# B3. ¿Dónde escribe firewalld?"
  paso "sudo nft list tables"
  $SUDO nft list tables
  paso "sudo nft list table inet firewalld | head -n 20"
  $SUDO nft list table inet firewalld | head -n 20

  echo; echo "# Limpieza obligatoria"
  paso "sudo nft delete table inet taller"
  $SUDO nft delete table inet taller
  paso "sudo nft list tables"
  $SUDO nft list tables
else
  falta nft
fi

# =====================================================================
titulo "4. El portero en Windows"
# =====================================================================
echo "(Esta sección se ejecuta en Windows: ver semana05_windows.ps1)"

# =====================================================================
titulo "5. La bitácora de autenticación"
# =====================================================================
echo "# C1. Dejar huellas en la bitácora"
if tiene ssh; then
  OPC="-o StrictHostKeyChecking=accept-new -o ConnectTimeout=5"
  if tiene sshpass; then
    paso "ssh noexiste@localhost   (3 intentos con clave incorrecta, simulados con sshpass)"
    for i in 1 2 3; do
      sshpass -p 'clave_incorrecta' ssh $OPC -o PubkeyAuthentication=no \
        -o PreferredAuthentications=password noexiste@localhost true 2>&1 | tail -n 1
    done
    paso "ssh $USUARIO@localhost   (1 intento con clave incorrecta)"
    sshpass -p 'clave_incorrecta' ssh $OPC -o PubkeyAuthentication=no \
      -o PreferredAuthentications=password "$USUARIO@localhost" true 2>&1 | tail -n 1
  else
    echo "(sshpass no está instalado: se generan intentos sin clave con BatchMode."
    echo " Para obtener líneas 'Failed password' haz C1 a mano y escribe una clave incorrecta.)"
    paso "ssh -o BatchMode=yes noexiste@localhost"
    ssh $OPC -o BatchMode=yes noexiste@localhost true 2>&1 | tail -n 1
  fi
else
  falta ssh
fi
sleep 2

if tiene journalctl; then
  echo; echo "# C2. Leer la bitácora"
  paso "journalctl -u sshd --since '10 min ago' | grep -E 'Failed|Invalid'"
  journalctl -u sshd --since '10 min ago' 2>&1 | grep -E 'Failed|Invalid'

  echo; echo "# C3. Contar fallos por IP (IDS a mano)"
  paso "journalctl -u sshd --since '10 min ago' | grep 'Failed password' | awk '{for(i=1;i<=NF;i++) if(\$i==\"from\") print \$(i+1)}' | sort | uniq -c | sort -rn"
  journalctl -u sshd --since '10 min ago' 2>&1 | grep 'Failed password' | contar_ips
else
  falta journalctl
fi

echo; echo "# Fallos del inicio de sesión de la VM (pam_unix, no SSH)"
paso "sudo grep 'authentication failure' /var/log/secure"
$SUDO grep 'authentication failure' /var/log/secure 2>&1 | tail -n 5

# =====================================================================
titulo "6. Reto final: su propio IDS"
# =====================================================================
if [ -f "$MUESTRA" ]; then
  paso "grep 'Failed password' $MUESTRA | awk '{for(i=1;i<=NF;i++) if(\$i==\"from\") print \$(i+1)}' | sort | uniq -c | sort -rn | awk '\$1>=3'"
  grep 'Failed password' "$MUESTRA" | contar_ips | awk '$1>=3'
else
  echo "(no se encontró '$MUESTRA': copia la muestra a esta carpeta o pásala como argumento)"
fi

echo
echo "==================== Fin del script ===================="