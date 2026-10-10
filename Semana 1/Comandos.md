# Memoria de comandos: Windows (PowerShell) y Linux (Bash)

Comandos para consultar el hardware del sistema, organizados por bloque. Los de Linux se ejecutan en **Bash** y los de Windows en **PowerShell**.

## Tabla resumen

| Bloque | Linux (Bash) | Windows (PowerShell) |
|---|---|---|
| **CPU** | `lscpu` · `cat /proc/cpuinfo` | `Get-CimInstance Win32_Processor` |
| **Memoria** | `free -h` · `cat /proc/meminfo` | `Get-CimInstance Win32_PhysicalMemory` |
| **Almacenamiento** | `lsblk` · `df -h` | `Get-PhysicalDisk` · `Get-Volume` |
| **Buses y E/S** | `lspci` · `lsusb` | `Get-PnpDevice -PresentOnly` |
| **Resumen** | `sudo lshw -short` | `systeminfo` · `msinfo32` |

---

## 1. CPU

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `lscpu` | Muestra un resumen del procesador: arquitectura, modelo, núcleos, hilos y caché. |
| Linux | `cat /proc/cpuinfo` | Muestra el detalle de cada procesador lógico (modelo, frecuencia, banderas). |
| Windows | `Get-CimInstance Win32_Processor` | Muestra nombre, fabricante, núcleos, procesadores lógicos y velocidad máxima. |

Variante útil en Windows, solo con los datos principales:

```powershell
Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors
```

## 2. Memoria

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `free -h` | Muestra RAM y swap (total, usada, libre) en unidades legibles (`-h` = *human readable*). |
| Linux | `cat /proc/meminfo` | Muestra el detalle de la memoria que reporta el kernel. |
| Windows | `Get-CimInstance Win32_PhysicalMemory` | Lista cada módulo de RAM: capacidad en bytes, fabricante y velocidad. |

Variante en Windows, con la capacidad en GB:

```powershell
Get-CimInstance Win32_PhysicalMemory | Select-Object Manufacturer, @{N='GB';E={$_.Capacity/1GB}}, Speed
```

## 3. Almacenamiento

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `lsblk` | Muestra los discos y sus particiones en forma de árbol. |
| Linux | `df -h` | Muestra el espacio usado y libre de cada sistema de archivos montado. |
| Windows | `Get-PhysicalDisk` | Lista los discos físicos: modelo, tipo (SSD/HDD), estado de salud y tamaño. |
| Windows | `Get-Volume` | Lista los volúmenes: letra de unidad, sistema de archivos, tamaño y espacio libre. |

## 4. Buses y E/S

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `lspci` | Lista los dispositivos del bus PCI (video, red, controladoras). |
| Linux | `lsusb` | Lista los dispositivos conectados por USB. |
| Windows | `Get-PnpDevice -PresentOnly` | Lista los dispositivos Plug and Play presentes en el equipo, de todos los buses. |

## 5. Resumen del sistema

| Sistema | Comando | ¿Qué hace? |
|---|---|---|
| Linux | `sudo lshw -short` | Muestra un resumen de todo el hardware. Necesita `sudo` (permisos de administrador). |
| Windows | `systeminfo` | Muestra sistema operativo, versión, fabricante, modelo, memoria y revisiones instaladas. |
| Windows | `msinfo32` | Abre la herramienta gráfica **Información del sistema**. |

Para generar el informe de `msinfo32` como archivo de texto, sin abrir la ventana:

```powershell
msinfo32 /report "$env:TEMP\informe.txt"
```

---

## Instalar las herramientas en Linux

Algunas distribuciones no traen `lspci`, `lsusb` ni `lshw`. En Ubuntu o Debian:

```bash
sudo apt update
sudo apt install -y pciutils usbutils lshw
```

> **Nota sobre WSL:** dentro de WSL, `lspci`, `lsusb` y `lshw` muestran poco o nada, porque WSL no accede directamente al hardware real.

## Scripts de esta semana

| Sistema | Script | Genera | Cómo ejecutarlo |
|---|---|---|---|
| Windows | `analisis_windows.ps1` | `estado_windows.txt` | En PowerShell: `.\analisis_windows.ps1` |
| Linux | `analisis_linux.sh` | `estado_linux.txt` | En Bash: `chmod +x analisis_linux.sh` y luego `./analisis_linux.sh` |

Ambos aceptan una opción para generar el reporte sin subirlo a GitHub: `-SinGit` en Windows y `--sin-git` en Linux.

Si Windows bloquea la ejecución de scripts, usa antes, en la misma ventana:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```
