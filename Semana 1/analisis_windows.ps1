<#
.SYNOPSIS
    Analisis del sistema Windows: genera estado_windows.log y lo sube a GitHub.
.DESCRIPTION
    Recopila CPU, memoria, almacenamiento, red, procesos, servicios y datos del
    sistema operativo. Funciona con Windows en cualquier idioma.
.PARAMETER SinGit
    Si se indica, solo genera el log y NO hace commit ni push.
.EXAMPLE
    .\analisis_windows.ps1
.EXAMPLE
    .\analisis_windows.ps1 -SinGit
#>

param(
    [switch]$SinGit
)

$ErrorActionPreference = 'Continue'

# El log se guarda junto al script, sin importar desde donde se ejecute
$archivoLog = Join-Path $PSScriptRoot 'estado_windows.log'

# Escribe una seccion en el log (codificacion UTF-8)
function Add-Seccion {
    param(
        [string]$Titulo,
        [scriptblock]$Codigo
    )
    "`r`n---------- $Titulo ----------" | Out-File -FilePath $archivoLog -Append -Encoding utf8
    try {
        & $Codigo | Out-String -Width 200 | Out-File -FilePath $archivoLog -Append -Encoding utf8
    }
    catch {
        "[AVISO] No se pudo obtener esta seccion: $($_.Exception.Message)" |
            Out-File -FilePath $archivoLog -Append -Encoding utf8
    }
}

# --- Encabezado (crea o reemplaza el log) -------------------------------------
@"
=================================================
    ANALISIS DEL SISTEMA - WINDOWS
=================================================
Fecha y hora de ejecucion: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Nombre del equipo: $env:COMPUTERNAME
Usuario actual: $env:USERNAME
"@ | Out-File -FilePath $archivoLog -Encoding utf8

# --- 1. CPU -------------------------------------------------------------------
Add-Seccion '1. PROCESADOR (CPU)' {
    Get-CimInstance Win32_Processor |
        Select-Object Name, Manufacturer, NumberOfCores,
                      NumberOfLogicalProcessors, MaxClockSpeed | Format-List
}

# --- 2. Memoria RAM -----------------------------------------------------------
Add-Seccion '2. MEMORIA RAM' {
    Get-CimInstance Win32_PhysicalMemory |
        Select-Object BankLabel, Manufacturer,
                      @{N = 'Capacidad_GB'; E = { [math]::Round($_.Capacity / 1GB, 2) }},
                      Speed | Format-Table -AutoSize
    $total = (Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum
    "Total instalado: {0} GB" -f [math]::Round($total / 1GB, 2)
}

# --- 3. Almacenamiento --------------------------------------------------------
Add-Seccion '3. ALMACENAMIENTO - DISCOS FISICOS' {
    Get-PhysicalDisk |
        Select-Object FriendlyName, MediaType, BusType, HealthStatus,
                      @{N = 'Tamano_GB'; E = { [math]::Round($_.Size / 1GB, 2) }} |
        Format-Table -AutoSize
}

Add-Seccion '3.1 ALMACENAMIENTO - VOLUMENES' {
    Get-Volume |
        Select-Object DriveLetter, FileSystemLabel, FileSystem, HealthStatus,
                      @{N = 'Tamano_GB'; E = { [math]::Round($_.Size / 1GB, 2) }},
                      @{N = 'Libre_GB';  E = { [math]::Round($_.SizeRemaining / 1GB, 2) }} |
        Format-Table -AutoSize
}

# --- 4. Red -------------------------------------------------------------------
Add-Seccion '4. CONEXIONES DE RED ACTIVAS' {
    Get-NetAdapter | Where-Object Status -eq 'Up' |
        Select-Object Name, InterfaceDescription, MacAddress, LinkSpeed | Format-Table -AutoSize
    Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.IPAddress -notlike '169.254*' } |
        Select-Object InterfaceAlias, IPAddress | Format-Table -AutoSize
}

# --- 5. Procesos --------------------------------------------------------------
Add-Seccion '5. TOP 10 PROCESOS QUE MAS CONSUMEN CPU' {
    Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 `
        Name, Id, @{N = 'CPU_seg'; E = { [math]::Round($_.CPU, 2) }},
        @{N = 'RAM_MB'; E = { [math]::Round($_.WorkingSet64 / 1MB, 1) }} |
        Format-Table -AutoSize
}

# --- 6. Servicios -------------------------------------------------------------
Add-Seccion '6. SERVICIOS EN EJECUCION (15 primeros)' {
    Get-Service | Where-Object Status -eq 'Running' |
        Select-Object -First 15 Name, DisplayName | Format-Table -AutoSize
}

# --- 7. Sistema operativo (independiente del idioma) --------------------------
Add-Seccion '7. RESUMEN DEL SISTEMA OPERATIVO' {
    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    [pscustomobject]@{
        Sistema_Operativo = $os.Caption
        Version           = $os.Version
        Arquitectura      = $os.OSArchitecture
        Fabricante        = $cs.Manufacturer
        Modelo            = $cs.Model
        Ultimo_Arranque   = $os.LastBootUpTime
    } | Format-List
}

Write-Host "Analisis completado. Log generado en: $archivoLog"

# --- Sincronizacion con GitHub ------------------------------------------------
if ($SinGit) {
    Write-Host 'Modo -SinGit: no se sube nada a GitHub.'
    return
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Warning 'Git no esta instalado o no esta en el PATH. Se omite la subida.'
    return
}

Push-Location $PSScriptRoot
try {
    git rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning 'Esta carpeta no es un repositorio Git. Se omite la subida.'
        return
    }

    Write-Host 'Iniciando subida automatica a GitHub...'
    git add estado_windows.log analisis_windows.ps1

    git diff --cached --quiet
    if ($LASTEXITCODE -eq 0) {
        Write-Host 'No hay cambios nuevos que subir.'
        return
    }

    git commit -m 'Actualiza registro automatico del sistema Windows'
    git push
    if ($LASTEXITCODE -eq 0) {
        Write-Host 'Archivos subidos correctamente al repositorio.'
    }
    else {
        Write-Warning 'El push fallo. Revisa tu conexion o credenciales de GitHub.'
    }
}
finally {
    Pop-Location
}