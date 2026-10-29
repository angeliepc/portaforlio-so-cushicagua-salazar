# =============================================================================
# informe_arranque.ps1 - Informe de arranque (Windows / PowerShell)
# Sistemas Operativos - EPN - Periodo 2026-B - Deber 3
#
# Autores : <Erick Salazar> y <Paulette Cushicagua>
# Paralelo: <GR1>
# Fecha   : <28/10/2026>
#
# Uso de IA generativa:
#   Herramienta: Claude (Anthropic)
#   Para que   : entender los comandos y revisar la estructura del script.
#
# Uso: .\informe_arranque.ps1      (no requiere administrador)
# Salida: pantalla + archivo informe_<equipo>_<fecha>.txt en la carpeta actual
# Nota: guardar este archivo como UTF-8 con BOM para que se vean las tildes.
# =============================================================================

# --- Funciones de apoyo ------------------------------------------------------

# EsAdministrador: devuelve $true si PowerShell se abrió como administrador
function EsAdministrador {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $id).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Archivo de informe: se guarda con el nombre del equipo y la fecha
$informe = Join-Path (Get-Location) ("informe_{0}_{1}.txt" -f $env:COMPUTERNAME, (Get-Date -Format 'yyyy-MM-dd'))
Set-Content -Path $informe -Value $null -Encoding UTF8

# Escribir: imprime en pantalla y agrega la línea al informe
function Escribir($texto) {
    Write-Host $texto
    Add-Content -Path $informe -Value $texto -Encoding UTF8
}
function Seccion($titulo) { Escribir ""; Escribir "=== $titulo ===" }
function Aviso($texto)    { Escribir "AVISO: $texto" }

$admin = EsAdministrador

Escribir "INFORME DE ARRANQUE (Windows)"
Escribir "Equipo : $env:COMPUTERNAME"
Escribir ("Fecha  : {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Escribir "Autores: <Integrante 1> y <Integrante 2>"

# Se consulta una sola vez; se usa en las secciones 1 y 2
try { $so = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop }
catch { $so = $null }

# --- 1 · Sistema operativo, versión y núcleo ---------------------------------
Seccion "1 · Sistema operativo, versión y núcleo"
if ($so) {
    Escribir "Sistema: $($so.Caption)"
    Escribir "Versión: $($so.Version) (compilación $($so.BuildNumber), $($so.OSArchitecture))"
} else {
    Aviso "No se pudo consultar Win32_OperatingSystem."
}

# --- 2 · Último arranque y tiempo encendido ----------------------------------
Seccion "2 · Último arranque y tiempo encendido"
if ($so) {
    $arranque = $so.LastBootUpTime
    $tiempo = (Get-Date) - $arranque
    Escribir ("Arrancó: {0:yyyy-MM-dd HH:mm:ss}" -f $arranque)
    Escribir ("Encendida: {0} días, {1} h, {2} min" -f $tiempo.Days, $tiempo.Hours, $tiempo.Minutes)
} else {
    Aviso "No se pudo obtener LastBootUpTime."
}

# --- 3 · Desglose del arranque -----------------------------------------------
Seccion "3 · Desglose del arranque"
# Firmware (no requiere administrador)
try {
    $fw = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -ErrorAction Stop).FwPOSTTime
    if ($null -ne $fw) { Escribir ("Firmware (FwPOSTTime): {0} ms ({1:N1} s)" -f $fw, ($fw / 1000)) }
    else { Aviso "FwPOSTTime no está disponible en este equipo." }
} catch {
    Aviso "No se pudo leer FwPOSTTime."
}
# Evento 100 (requiere administrador)
if (-not $admin) {
    Aviso "Sin permisos de administrador: no se muestra el evento 100. Abra PowerShell como administrador."
} else {
    try {
        $e = Get-WinEvent -FilterHashtable @{
            LogName = 'Microsoft-Windows-Diagnostics-Performance/Operational'; Id = 100 } `
            -MaxEvents 1 -ErrorAction Stop
        Escribir "Evento 100 registrado el: $($e.TimeCreated)"
        # Si el evento es anterior al último arranque, los valores son de un arranque previo
        if ($so -and $e.TimeCreated -lt $so.LastBootUpTime) {
            Aviso "El evento 100 es anterior al último arranque (inicio rápido): los valores son de un arranque previo. Use Reiniciar para generar uno nuevo."
        }
        $datos = ([xml]$e.ToXml()).Event.EventData.Data
        foreach ($n in 'BootTime', 'MainPathBootTime', 'BootPostBootTime') {
            $v = ($datos | Where-Object Name -eq $n).'#text'
            if ($v) { Escribir ("  {0}: {1} ms ({2:N1} s)" -f $n, $v, ([double]$v / 1000)) }
            else    { Escribir ("  {0}: no disponible" -f $n) }
        }
    } catch {
        Aviso "No se encontró el evento 100 (¿no hubo un arranque completo reciente por el inicio rápido?)."
    }
}

# --- 4 · Servicios -----------------------------------------------------------
Seccion "4 · Servicios"
try {
    $en = Get-CimInstance Win32_Service -Filter "State='Running'" -ErrorAction Stop
    Escribir "Servicios en ejecución: $(@($en).Count)"
    $detenidos = Get-CimInstance Win32_Service -Filter "StartMode='Auto' AND State='Stopped'" -ErrorAction Stop
    Escribir "Automáticos detenidos: $(@($detenidos).Count)"
    $detenidos | Select-Object -First 5 | ForEach-Object { Escribir "  $($_.Name)" }
} catch {
    Aviso "No se pudieron consultar los servicios."
}
# Eventos 101-103 (opcional, requiere administrador)
if ($admin) {
    try {
        $lentos = Get-WinEvent -FilterHashtable @{
            LogName = 'Microsoft-Windows-Diagnostics-Performance/Operational'; Id = 101, 102, 103 } `
            -MaxEvents 5 -ErrorAction Stop
        Escribir "Últimos eventos de degradación (101-103):"
        $lentos | ForEach-Object {
            $m = ($_.Message -replace '\s+', ' ')
            if ($m.Length -gt 90) { $m = $m.Substring(0, 90) + '...' }
            Escribir ("  [{0}] id {1}: {2}" -f $_.TimeCreated, $_.Id, $m)
        }
    } catch {
        Escribir "Eventos 101-103: no hay registros."
    }
} else {
    Aviso "Eventos 101-103 omitidos (requieren administrador)."
}

# --- 5 · Controladores -------------------------------------------------------
Seccion "5 · Controladores"
try {
    $total = (driverquery /fo csv | ConvertFrom-Csv).Count
    Escribir "Controladores instalados (driverquery): $total"
} catch {
    Aviso "driverquery no está disponible."
}
try {
    $drv = Get-CimInstance Win32_SystemDriver -Filter "State='Running'" -ErrorAction Stop
    Escribir "Controladores en ejecución (Win32_SystemDriver): $(@($drv).Count)"
    $drv | Select-Object -First 5 | ForEach-Object { Escribir "  $($_.Name)" }
} catch {
    Aviso "No se pudo consultar Win32_SystemDriver."
}

# --- 6 · Cierre --------------------------------------------------------------
Seccion "6 · Cierre"
try {
    $hb = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -ErrorAction Stop).HiberbootEnabled
    if ($hb -eq 1) { Escribir "Inicio rápido (HiberbootEnabled): 1 (activado)" }
    elseif ($hb -eq 0) { Escribir "Inicio rápido (HiberbootEnabled): 0 (desactivado)" }
    else { Aviso "HiberbootEnabled no está definido en este equipo." }
} catch {
    Aviso "No se pudo leer HiberbootEnabled."
}

Escribir ""
Escribir "Informe guardado en: $informe"