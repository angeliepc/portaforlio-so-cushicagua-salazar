# Linux vs Windows: comandos de referencia

## 1. Llamadas al sistema

### Rastrear con `strace` (Linux)

```bash
# Solo las escrituras de un programa
strace -e trace=write ./hola

# Crear un archivo de prueba
printf 'Comprar tomates\nPicar cebolla\nReducir la salsa\n' > notas.txt

# Ciclo de vida de un archivo con cat
strace -e trace=openat,read,write,close cat notas.txt

# Resumen estadístico de syscalls (el resumen sale por stderr)
strace -c ls > /dev/null

# Apertura, escritura y salida de un proceso
strace -e trace=openat,write,exit_group cat config.txt
```

### Equivalencias Linux ↔ Windows

| Operación | Linux (syscall) | Windows (API Win32) |
|---|---|---|
| Crear proceso | `fork` + `execve` | `CreateProcess` |
| Terminar proceso | `exit` (`exit_group`) | `ExitProcess` |
| Esperar proceso | `waitpid` | `WaitForSingleObject` |
| Abrir archivo | `open` / `openat` | `CreateFile` |
| Leer / escribir | `read` · `write` | `ReadFile` · `WriteFile` |
| Cerrar | `close` | `CloseHandle` |
| Atributos de archivo | `stat` | `GetFileAttributesEx` |
| Reservar memoria | `mmap` | `VirtualAlloc` |
| Obtener la hora | `clock_gettime` | `GetSystemTimeAsFileTime` |

## 2. Tipo de comando (integrado, alias o ejecutable)

```bash
# Linux (bash)
type cd ls echo
```

```powershell
# Windows (PowerShell), salida resumida
Get-Command cd, Get-ChildItem, ping
```

## 3. Procesos que más memoria usan

```bash
# Linux: top 3 por RSS (head -n 4 = encabezado + 3 filas)
ps -eo pid,comm,rss --sort=-rss | head -n 4
```

```powershell
# Windows: top 3 por Working Set
Get-Process | Sort-Object WS -Descending |
  Select-Object -First 3 Name, Id, WS
```

## 4. Gestores de paquetes

### Linux (dnf / rpm)

```bash
# Repositorios (baseos, appstream, extras)
dnf repolist

# Buscar e inspeccionar
dnf search jq
dnf info jq

# Instalar
sudo dnf install jq

# Paquetes instalados
rpm -qa
dnf list --installed

# Instalar un .rpm local
sudo dnf install ./analizador-2.1-1.el9.x86_64.rpm

# Instalar habilitando un repositorio de terceros
sudo dnf install analizador --enablerepo=terceros
```

### Windows (winget)

```powershell
# Fuentes (winget, msstore)
winget source list

# Buscar e inspeccionar
winget search jq
winget show jqlang.jq

# Instalar (-e = coincidencia exacta del ID)
winget install --id jqlang.jq -e

# Paquetes instalados
winget list
```

## 5. Los 5 archivos más grandes de los logs

```bash
# Linux
find /var/log -type f -printf '%s %p\n' 2>/dev/null | sort -rn | head -n 5
```

```powershell
# Windows
Get-ChildItem C:\Windows\Logs -Recurse -File -ErrorAction SilentlyContinue |
  Sort-Object Length -Descending |
  Select-Object -First 5 Length, FullName
```