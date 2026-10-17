# Memoria de comandos: Windows (PowerShell) y Linux (Bash)

Comandos para consultar el hardware del sistema, organizados por bloque. Los de Linux se ejecutan en **Bash** y los de Windows en **PowerShell**.
## 1. Archivos y representación hexadecimal

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `printf 'Año\n' > t.txt` | Escribe la palabra "Año" en el archivo `t.txt`. |
| Linux | `xxd t.txt` | Muestra el contenido del archivo en formato hexadecimal y ASCII. |
| Linux | `xxd n.bin` | Muestra el contenido del archivo binario `n.bin` en hexadecimal y ASCII. |
| Windows | `'Año' \| Set-Content t.txt` | Escribe la palabra "Año" en el archivo `t.txt`. |
| Windows | `Format-Hex t.txt` | Muestra el contenido del archivo en formato hexadecimal. |

## 2. Memoria caché y CPU

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `lscpu --caches` | Muestra información sobre los niveles de memoria caché del procesador. |
| Linux | `getconf LEVEL1_DCACHE_LINESIZE` | Muestra el tamaño de línea de la caché de datos L1, en bytes. |
| Linux | `nproc` | Muestra el número de unidades de procesamiento disponibles. |
| Linux | `grep -m1 "model name" /proc/cpuinfo` | Muestra el modelo del procesador. |
| Windows | `Get-CimInstance Win32_CacheMemory` | Muestra información sobre la memoria caché del sistema. |
| Windows | `(Get-CimInstance Win32_Processor).NumberOfLogicalProcessors` | Muestra el número de procesadores lógicos disponibles. |

## 3. Memoria RAM y procesos

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `free -h` | Muestra la memoria RAM total, usada y disponible en formato legible. |
| Linux | `top -bn1 \| sed -n 2p` | Muestra la segunda línea de la salida de `top`, que contiene información general del sistema. |
| Linux | `vmstat 1 2` | Muestra estadísticas de memoria, procesos, CPU y actividad del sistema con intervalos de un segundo. |
| Linux | `head -n 3 /proc/meminfo` | Muestra las primeras tres líneas con información sobre la memoria del sistema. |
| Linux | `cat /proc/uptime` | Muestra el tiempo que lleva encendido el sistema y el tiempo de inactividad acumulado de la CPU. |
| Windows | `(Get-Process).Count` | Cuenta la cantidad de procesos en ejecución. |
| Windows | `Get-Process -Id 4` | Muestra información del proceso con identificador PID 4, normalmente asociado a System. |
| Windows | `Get-CimInstance Win32_OperatingSystem \| Select-Object TotalVisibleMemorySize, FreePhysicalMemory` | Muestra la memoria física total visible y la memoria física libre, en kilobytes. |

## 4. Inicio y servicios del sistema

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `systemd-analyze` | Muestra el tiempo de inicio del sistema y de sus componentes principales. |
| Linux | `systemd-analyze blame --no-pager \| head -3` | Muestra los tres servicios o componentes que más tardaron en iniciarse. |
| Linux | `systemd-analyze critical-chain --no-pager` | Muestra la cadena crítica de dependencias que influye en el tiempo de inicio. |
| Linux | `ps -p 1 -o pid,comm` | Muestra el PID y el nombre del proceso con identificador 1, normalmente el sistema de inicio. |
| Linux | `pstree -p \| head -n 12` | Muestra las primeras doce líneas del árbol de procesos, incluyendo sus identificadores PID. |
| Linux | `systemctl list-units --type=service --state=running --no-pager \| head -n 8` | Muestra las primeras ocho líneas de los servicios activos. |
| Linux | `systemctl list-units --type=service --state=running --no-legend \| wc -l` | Cuenta los servicios activos sin mostrar la cabecera. |
| Windows | `Get-Service \| Where-Object Status -eq Running \| Select-Object -First 8` | Muestra los primeros ocho servicios que están en ejecución. |
| Windows | `(Get-Service \| Where-Object Status -eq Running).Count` | Cuenta los servicios que están en ejecución. |

## 5. Discos y almacenamiento

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `lsblk` | Muestra los dispositivos de almacenamiento y sus particiones en forma de árbol. |
| Windows | `Get-CimInstance Win32_LogicalDisk \| Select-Object DeviceID, Size, FreeSpace` | Muestra las unidades lógicas, su identificador, tamaño total y espacio libre. |

## 6. Dispositivos y archivos del sistema

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `ls /proc \| head` | Muestra las primeras entradas del directorio `/proc`, donde se encuentra información del kernel y los procesos. |
| Linux | `ls -l /dev/null /dev/tty /dev/sda 2>/dev/null \|\| ls -l /dev/null /dev/tty /dev/vda` | Muestra información de los dispositivos indicados. Si `/dev/sda` no está disponible, intenta mostrar `/dev/vda`. |
| Windows | `Get-CimInstance Win32_OperatingSystem \| Select-Object Caption, Version, LastBootUpTime` | Muestra el nombre del sistema operativo, su versión y la fecha y hora del último inicio. |
| Windows | `Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'" \| Select-Object PercentIdleTime` | Muestra el porcentaje de tiempo en que los procesadores estuvieron inactivos. |

## 7. Medición del tiempo de ejecución

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `time read -p "Escribe tu nombre: " nombre` | Solicita un nombre y mide el tiempo que tarda en ejecutarse el comando. Escribe el nombre y pulsa Enter. |
| Linux | `time (for i in {1..2000000}; do :; done)` | Mide cuánto tarda en ejecutarse un bucle de dos millones de iteraciones vacías. |
| Linux | `time find /usr -name "*.conf" > /dev/null 2>&1` | Mide el tiempo que tarda en buscar archivos con extensión `.conf` dentro de `/usr`, descartando la salida y los errores. |