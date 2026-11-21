# Memoria de comandos: Windows (PowerShell) y Linux (Bash)

Comandos del Taller 1 de la semana 5 (Guardias en la puerta: puertos, cortafuegos y bitácora), organizados por bloque. Los de Linux se ejecutan en **Bash** y los de Windows en **PowerShell**.

## 1. Puertas abiertas

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `ss -tln` | Lista los puertos TCP en escucha (`-t` TCP, `-l` en escucha, `-n` números). |
| Linux | `sudo ss -tlnp` | Igual que el anterior, pero con `-p` muestra el programa y el PID dueño de cada puerto. |
| Linux | `python3 -m http.server 8080 &>/dev/null &` | Abre un servidor web propio en el puerto 8080, en segundo plano. |
| Linux | `ss -tln \| grep 8080` | Comprueba que el 8080 aparece en `0.0.0.0:8080` (puerta a la calle). |
| Linux | `curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080` | Pide la página al servidor propio y muestra solo el código HTTP (`200`). |
| Windows | `Get-NetTCPConnection -State Listen \| Sort-Object LocalPort \| Select-Object LocalAddress, LocalPort, OwningProcess -First 12` | Muestra los primeros 12 puertos TCP en escucha, ordenados por número, con el proceso dueño. |
| Windows | `(Get-NetTCPConnection -State Listen).Count` | Cuenta los puertos TCP en escucha. |
| Windows | `$c = Get-NetTCPConnection -State Listen -LocalPort 135` | Guarda en `$c` la conexión en escucha del puerto 135. |
| Windows | `Get-Process -Id $c[0].OwningProcess \| Select-Object Id, ProcessName` | Muestra qué programa atiende ese puerto (normalmente `svchost`). |

## 2. El portero en Linux (firewalld)

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `sudo firewall-cmd --state` | Indica si firewalld está en ejecución (`running`). |
| Linux | `sudo firewall-cmd --get-active-zones` | Muestra las zonas activas y su interfaz (normalmente `public`). |
| Linux | `sudo firewall-cmd --list-all` | Muestra la configuración de la zona: target, servicios y puertos permitidos. |

## 3. DROP frente a REJECT con nftables

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `sudo nft add table inet taller` | Crea una tabla propia llamada `taller`. |
| Linux | `sudo nft add chain inet taller entrada '{ type filter hook input priority 0; policy accept; }'` | Crea la cadena `entrada` enganchada a los paquetes entrantes, con política aceptar. |
| Linux | `time curl -s -o /dev/null -m 5 http://127.0.0.1:8080; echo "código: $?"` | Mide el tiempo y el código de salida de curl al 8080 (límite de 5 s). Se usa sin regla, con DROP y con REJECT. |
| Linux | `sudo nft add rule inet taller entrada tcp dport 8080 drop` | Descarta en silencio los paquetes al puerto 8080 (curl termina con código 28). |
| Linux | `sudo nft flush chain inet taller entrada` | Vacía la cadena para quitar la regla anterior. |
| Linux | `sudo nft add rule inet taller entrada tcp dport 8080 reject with tcp reset` | Rechaza de inmediato los paquetes al 8080 con un reinicio TCP (curl termina con código 7). |
| Linux | `sudo nft list table inet taller` | Muestra el contenido de la tabla `taller` con su regla. |
| Linux | `sudo nft list tables` | Lista todas las tablas de nftables (`inet firewalld` e `inet taller`). |
| Linux | `sudo nft list table inet firewalld \| head -n 20` | Muestra las primeras 20 líneas de la tabla de firewalld (`filter_INPUT`, `filter_IN_public`). |
| Linux | `sudo nft delete table inet taller` | Limpieza obligatoria: borra la tabla `taller` para desbloquear el 8080. |
| Linux | `kill %1` | Limpieza: detiene el servidor del puerto 8080 que quedó en segundo plano. |

## 4. El portero en Windows

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Windows | `Get-NetFirewallProfile \| Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction` | Muestra los perfiles Domain, Private y Public, si están habilitados y su política de entrada y salida. |
| Windows | `Get-Service mpssvc, BFE \| Select-Object Name, DisplayName, Status` | Muestra el estado del Firewall de Windows Defender (`mpssvc`) y del Motor de filtrado de base (`BFE`). |
| Windows | `(Get-NetFirewallRule -Enabled True -Direction Inbound).Count` | Cuenta las reglas de entrada habilitadas. |
| Windows | `Get-NetFirewallRule -Enabled True -Direction Inbound \| Select-Object -First 5 DisplayName, Action` | Muestra el nombre y la acción de las primeras cinco reglas de entrada. |
| Windows (administrador) | `New-NetFirewallRule -DisplayName 'Taller5' -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Block` | Crea una regla que bloquea la entrada TCP al puerto 8080. Sin administrador da «Acceso denegado». |
| Windows (administrador) | `Get-NetFirewallRule -DisplayName 'Taller5' \| Select-Object DisplayName, Enabled, Action` | Comprueba que la regla existe con acción `Block`. |
| Windows (administrador) | `Remove-NetFirewallRule -DisplayName 'Taller5'` | Borra la regla de prueba. |
| Windows (administrador) | `netsh wfp show filters` | Genera `filters.xml` con la lista de filtros del motor WFP. |
| Windows (administrador) | `(Select-String -Path .\filters.xml -Pattern '<filterKey>').Count` | Cuenta los filtros del archivo generado (cientos o miles). |

## 5. La bitácora de autenticación

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `ssh noexiste@localhost` | Provoca fallos con un usuario inexistente (escribir cualquier clave 3 veces). |
| Linux | `ssh $USER@localhost` | Provoca un fallo con el usuario propio (escribir mal la clave una vez). |
| Linux | `journalctl -u sshd --since '10 min ago' \| grep -E 'Failed\|Invalid'` | Muestra los intentos fallidos de SSH de los últimos 10 minutos. |
| Linux | `journalctl -u sshd --since '10 min ago' \| grep 'Failed password' \| awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' \| sort \| uniq -c \| sort -rn` | IDS a mano: cuenta los fallos por IP de origen, de mayor a menor. |
| Linux | `sudo grep -E 'Failed\|Invalid' /var/log/secure` | Busca los intentos fallidos en el archivo de registro de seguridad. |
| Linux | `sudo grep 'authentication failure' /var/log/secure` | Muestra los fallos de la pantalla de inicio de la VM (pam_unix), que no son de SSH. |
| Linux | `journalctl --file=<ruta_archivo.journal>` | Lee una bitácora guardada sin alterar el sistema en vivo. |
| Windows (administrador) | `Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625} -MaxEvents 5 \| Select-Object TimeCreated, Id, Message \| Format-List` | Muestra los últimos eventos 4625 (error de inicio de sesión) del registro de Seguridad. |
| Windows | `$ev = Import-Csv .\muestras_eventos_4625.csv` | Carga la muestra de eventos 4625 en la variable `$ev`. |
| Windows | `$ev \| Where-Object Id -eq '4625' \| Group-Object IpAddress \| Sort-Object Count -Descending \| Select-Object Count, Name` | Cuenta los eventos 4625 por IP, de mayor a menor. |

## 6. Reto final: su propio IDS

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `grep 'Failed password' muestras_auth.log \| awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' \| sort \| uniq -c \| sort -rn \| awk '$1>=3'` | Muestra solo las IP con 3 fallos o más en `muestras_auth.log`. |
| Windows | `$ev \| Where-Object Id -eq '4625' \| Group-Object IpAddress \| Where-Object Count -ge 3 \| Sort-Object Count -Descending \| Select-Object Count, Name` | Muestra solo las IP con 3 fallos o más en la muestra de eventos 4625. |

## 7. Preparación de la VM y errores frecuentes

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `chmod +x preparar_vm_alma.sh` | Da permiso de ejecución al script de preparación. |
| Linux | `sudo ./preparar_vm_alma.sh 5` | Deja la VM lista para la semana 5 (comprueba sshd, firewalld, nft, curl y python3). |
| Linux | `sudo dnf install iproute` | Instala `ss` si el comando no existe. |
| Linux | `ss -tlnp \| grep 8080` | Encuentra el proceso que ya ocupa el 8080 (error «Address already in use»). |
| Linux | `sudo systemctl enable --now sshd` | Activa sshd si SSH da «Connection refused». |
| Windows | `cd <carpeta-de-la-semana-5>` | Entra a la carpeta donde está la muestra si `Import-Csv` no la encuentra. |

## 8. Archivos y Git

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `cd ~/<repositorio-de-la-pareja> && git pull` | Entra al repositorio y trae los últimos cambios. |
| Linux | `mkdir -p semana05` | Crea la carpeta `semana05`. |
| Linux | `chmod +x semana05/semana05_linux.sh` | Da permiso de ejecución al script de la semana. |
| Linux | `./semana05/semana05_linux.sh` | Ejecuta el script de la semana 5. |
| Windows | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` | Permite ejecutar scripts `.ps1` (se hace una sola vez). |
