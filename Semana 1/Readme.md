# Guía de Administración de S.O. Linux y Windows

**Autores:** Paulette Cushicagua y Erick Salazar

Portafolio de la asignatura de Sistemas Operativos. Cada semana tiene su propia carpeta con la ayuda memoria de comandos, los scripts de aplicación y la captura de su salida.

## Estructura del repositorio

```text
portafolio-so-cushicagua-salazar/
└── Semana 1/
    ├── Comandos.md            # Ayuda memoria de comandos Windows / Linux
    ├── analisis_windows.ps1   # Script de Windows (PowerShell)
    ├── analisis_linux.sh      # Script de Linux (Bash)
    ├── estado_windows.txt     # Captura de la salida del script de Windows
    ├── estado_linux.txt       # Captura de la salida del script de Linux
    ├── suma.c                 # Función en C que suma dos enteros
    └── suma.s                 # Ensamblador generado a partir de suma.c
```

## Semana 1: consulta del hardware y estado del sistema

Los scripts recopilan información del equipo y la guardan en un archivo de texto: procesador, memoria, almacenamiento, buses y dispositivos, red, procesos con más uso de CPU, servicios en ejecución y resumen del sistema operativo. Al final, suben el resultado al repositorio.

| Sistema | Script | Salida |
|---|---|---|
| Windows (PowerShell) | `analisis_windows.ps1` | `estado_windows.txt` |
| Linux (Bash) | `analisis_linux.sh` | `estado_linux.txt` |

La explicación de cada comando está en [`Comandos.md`](Comandos.md).

### Cómo ejecutar el script de Windows

En PowerShell, dentro de la carpeta `Semana 1`:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\analisis_windows.ps1
```

Con `-SinGit` solo genera el archivo, sin subirlo a GitHub:

```powershell
.\analisis_windows.ps1 -SinGit
```

### Cómo ejecutar el script de Linux

En Bash, dentro de la carpeta `Semana 1`:

```bash
chmod +x analisis_linux.sh
./analisis_linux.sh
```

Con `--sin-git` solo genera el archivo, sin subirlo a GitHub:

```bash
./analisis_linux.sh --sin-git
```

Para incluir `lshw` en el reporte, instala las herramientas y ejecuta el script con `sudo`:

```bash
sudo apt install -y pciutils usbutils lshw
sudo ./analisis_linux.sh --sin-git
```

### Cómo generar el ensamblador de `suma.c`

```bash
gcc -S -O0 -masm=intel -fno-asynchronous-unwind-tables -fno-pie suma.c -o suma.s
```

## Entorno de pruebas

- **Windows:** PowerShell en Windows 11.
- **Linux:** Ubuntu ejecutado en WSL (Subsistema de Windows para Linux). En WSL, `lspci`, `lsusb` y `lshw` muestran poca información porque no acceden directamente al hardware real.
- **Compilador:** `gcc` instalado en Ubuntu (WSL).
