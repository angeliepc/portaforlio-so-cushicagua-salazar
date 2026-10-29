# Memoria de comandos: Windows (PowerShell) y Linux (Bash)

Comandos del Taller 2 de la semana 3 (arranque, módulos, apagado programado y Deber 3), organizados por bloque. Los de Linux se ejecutan en **Bash** y los de Windows en **PowerShell**.

## 1. Tiempo de arranque

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `systemd-analyze` | Muestra el tiempo de arranque por etapa: kernel, initrd y espacio de usuario. |
| Linux | `systemd-analyze blame --no-pager \| head -n 5` | Muestra las cinco unidades que más tardaron en iniciarse, de la más lenta a la más rápida. |
| Linux | `systemd-analyze critical-chain --no-pager` | Muestra la cadena crítica de unidades que hizo esperar al target final, con `@` (cuándo empezó) y `+` (cuánto tardó). |
| Linux | `uptime -s` | Muestra la fecha y hora del último arranque. |
| Windows | `(Get-CimInstance Win32_OperatingSystem).LastBootUpTime` | Muestra la fecha y hora del último arranque completo. |
| Windows | `(Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power').FwPOSTTime` | Muestra el tiempo del firmware (BIOS/UEFI) en milisegundos. |
| Windows (administrador) | `$e = Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-Diagnostics-Performance/Operational'; Id = 100 } -MaxEvents 1` | Guarda en `$e` el último evento 100, que contiene el desglose del arranque. Requiere PowerShell como administrador. |
| Windows (administrador) | `$e.TimeCreated` | Muestra la fecha y hora en que se registró el evento 100. |
| Windows (administrador) | `([xml]$e.ToXml()).Event.EventData.Data \| Where-Object Name -in 'BootTime','MainPathBootTime','BootPostBootTime'` | Muestra el tiempo total de arranque, la ruta principal y el posarranque, en milisegundos. |

## 2. Registro del sistema

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `journalctl -b -p warning --no-pager \| head -n 8` | Muestra las primeras ocho advertencias y errores del arranque actual. |
| Linux | `sudo dmesg \| head -n 5` | Muestra las primeras cinco líneas del registro del núcleo, con tiempos desde 0.000000. |
| Windows | `Get-WinEvent` | Consulta los registros de eventos de Windows (se usa en el desglose del arranque). |

## 3. Módulos y controladores

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `lsmod \| head -n 5` | Muestra los primeros cinco módulos del núcleo cargados. |
| Linux | `lsmod \| wc -l` | Cuenta los módulos cargados. |
| Linux | `modinfo dummy \| head -n 4` | Muestra la ficha del módulo `dummy`: archivo, descripción y licencia. |
| Linux | `ip -brief link` | Lista las interfaces de red en formato resumido (permite ver aparecer y desaparecer `dummy0`). |
| Linux | `sudo modprobe dummy` | Carga el módulo `dummy` en caliente, sin reiniciar. |
| Linux | `lsmod \| grep dummy` | Comprueba que el módulo `dummy` está cargado. |
| Linux | `sudo rmmod dummy` | Descarga el módulo `dummy`. |
| Linux | `sudo ip link delete dummy0` | Elimina la interfaz `dummy0` si `rmmod` indica que el módulo está en uso. |
| Windows | `driverquery \| Select-Object -First 8` | Muestra los primeros ocho controladores (`.sys`) con su tipo. |
| Windows | `(driverquery /fo csv \| ConvertFrom-Csv).Count` | Cuenta los controladores instalados. |
| Windows | `driverquery /v` | Muestra la lista detallada de controladores: estado, ruta del archivo y otros datos. |

## 4. Apagado programado e inicio rápido

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `sudo shutdown -r +5 "Prueba del taller: no se reiniciará"` | Programa un reinicio en 5 minutos y avisa a los usuarios conectados. |
| Linux | `sudo shutdown -c` | Cancela la parada programada. |
| Linux | `systemctl reboot` | Reinicia el sistema de forma completa. |
| Windows | `shutdown /r /t 300 /c "Prueba del taller: no se reiniciará"` | Programa un reinicio en 300 segundos con un mensaje. |
| Windows | `shutdown /a` | Anula el reinicio programado. |
| Windows | `shutdown /s /full` | Apaga el equipo con un arranque completo posterior, sin usar el inicio rápido. |
| Windows | `powercfg /a` | Lista los estados de suspensión disponibles e indica si el inicio rápido está disponible. |
| Windows | `(Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power').HiberbootEnabled` | Muestra 1 si el inicio rápido está activado y 0 si no. |

## 5. Deber 3: script de informe de arranque (secciones 1 a 3)

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `cat /etc/os-release` | Muestra los datos del sistema operativo (`PRETTY_NAME`). |
| Linux | `uname -r` | Muestra la versión del núcleo. |
| Linux | `uname -m` | Muestra la arquitectura del equipo. |
| Linux | `uptime -p` | Muestra el tiempo que lleva encendido el sistema en formato legible. |
| Linux | `systemd-analyze time` | Muestra el desglose del arranque para la sección 3 del informe. |
| Windows | `Get-CimInstance Win32_OperatingSystem \| Select-Object Caption, Version, BuildNumber, OSArchitecture` | Muestra el nombre, versión, compilación y arquitectura de Windows. |
| Windows | `(Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime` | Calcula el tiempo que lleva encendido el equipo. |

## 6. Archivos y Git

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `cd ~/<repositorio-de-la-pareja> && git pull` | Entra al repositorio y trae los últimos cambios. |
| Linux | `mkdir -p semana03` | Crea la carpeta `semana03`. |
| Linux | `cp ~/Descargas/informe_arranque_base.sh semana03/informe_arranque.sh` | Copia el esqueleto del script a la carpeta de la semana. |
| Linux | `chmod +x semana03/informe_arranque.sh` | Da permiso de ejecución al script. |
| Linux | `./informe_arranque.sh` | Ejecuta el script de informe de arranque. |
| Windows | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` | Permite ejecutar scripts `.ps1` (se hace una sola vez). |
| Windows | `.\informe_arranque.ps1` | Ejecuta el script de informe de arranque. |
| Ambos | `git add semana03/informe_arranque.sh` | Prepara el script para el commit (en Windows, el `.ps1`). |
| Ambos | `git commit -m "Semana 3: informe de arranque (Linux), secciones 1-3"` | Crea el commit con un mensaje descriptivo. |
| Ambos | `git push` | Sube el commit al repositorio de GitHub. |