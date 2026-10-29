# scrip3.ps1 - Diagnostico Windows (Taller 2, semana 3)
# Genera informacion_windows.txt con el mismo formato de la semana 2.
# Uso: .\scrip3.ps1   (abrir PowerShell como administrador para ver el evento 100)
# Nota: guardar este archivo como UTF-8 con BOM para que se vean las tildes.

$salida = "informacion_windows.txt"
Set-Content -Path $salida -Value $null -Encoding UTF8

function Escribir($texto) {
    Write-Host $texto
    Add-Content -Path $salida -Value $texto -Encoding UTF8
}
function Titulo($texto) { Escribir ""; Escribir "=== $texto ===" }

# Mostrar: ejecuta un bloque y escribe su salida (incluidos los errores) como texto
function Mostrar([scriptblock]$bloque) {
    try {
        $txt = (& $bloque 2>&1 | Out-String -Width 200).TrimEnd()
        if ($txt) { Escribir $txt }
    } catch {
        Escribir "Error: $($_.Exception.Message)"
    }
}

function EsAdministrador {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $id).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

$admin = EsAdministrador
$rutaEnergia = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power'
$logPerf = 'Microsoft-Windows-Diagnostics-Performance/Operational'

Escribir "=== Inicio del diagnóstico Windows (semana 3) ==="

# ---------------------------------------------------------------- 1
Titulo "1. Tiempo de arranque"
try {
    $so = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    Escribir "Último arranque: $($so.LastBootUpTime)"
} catch {
    $so = $null
    Escribir "No se pudo leer LastBootUpTime; se omite."
}
try {
    $fw = (Get-ItemProperty $rutaEnergia -ErrorAction Stop).FwPOSTTime
    if ($null -ne $fw) { Escribir "FwPOSTTime: $fw ms" }
    else { Escribir "FwPOSTTime no está disponible en este equipo." }
} catch {
    Escribir "No se pudo leer FwPOSTTime; se omite."
}
if (-not $admin) {
    Escribir "Sin administrador: se omite el evento 100 (BootTime, MainPathBootTime, BootPostBootTime)."
} else {
    try {
        $e = Get-WinEvent -FilterHashtable @{ LogName = $logPerf; Id = 100 } -MaxEvents 1 -ErrorAction Stop
        Escribir "Evento 100 registrado el: $($e.TimeCreated)"
        if ($so -and $e.TimeCreated -lt $so.LastBootUpTime) {
            Escribir "AVISO: el evento 100 es anterior al último arranque (inicio rápido); los valores son de un arranque previo."
        }
        $datos = ([xml]$e.ToXml()).Event.EventData.Data
        foreach ($n in 'BootTime', 'MainPathBootTime', 'BootPostBootTime') {
            $v = ($datos | Where-Object Name -eq $n).'#text'
            Escribir "${n}: $v ms"
        }
    } catch {
        Escribir "No se encontró el evento 100 (¿no hubo un arranque completo reciente?)."
    }
}

# ---------------------------------------------------------------- 2
Titulo "2. Registro del sistema"
if (-not $admin) {
    Escribir "Sin administrador: se omite Get-WinEvent."
} else {
    Mostrar { Get-WinEvent -FilterHashtable @{ LogName = $logPerf; Id = 100, 101 } -MaxEvents 3 -ErrorAction Stop |
        Format-Table TimeCreated, Id, LevelDisplayName, Message -AutoSize }
}

# ---------------------------------------------------------------- 3
Titulo "3. Módulos y controladores"
if (Get-Command driverquery -ErrorAction SilentlyContinue) {
    Mostrar { driverquery | Select-Object -First 8 }
    try {
        Escribir "Controladores instalados: $((driverquery /fo csv | ConvertFrom-Csv).Count)"
    } catch {
        Escribir "No se pudo contar los controladores."
    }
    Mostrar { driverquery /v | Select-Object -First 3 }
} else {
    Escribir "No existe driverquery; se omite esta sección."
}

# ---------------------------------------------------------------- 4
Titulo "4. Apagado programado e inicio rápido"
Mostrar { shutdown /r /t 300 /c "Prueba del taller: no se reiniciará" }
Mostrar { shutdown /a }
Escribir "shutdown /s /full no se ejecuta aquí porque apagaría el equipo."
Mostrar { powercfg /a }
try {
    $hb = (Get-ItemProperty $rutaEnergia -ErrorAction Stop).HiberbootEnabled
    Escribir "HiberbootEnabled: $hb"
} catch {
    Escribir "No se pudo leer HiberbootEnabled; se omite."
}

# ---------------------------------------------------------------- 5
Titulo "5. Deber 3: secciones 1 a 3"
if ($so) {
    Escribir "Sistema: $($so.Caption)"
    Escribir "Versión: $($so.Version) (compilación $($so.BuildNumber), $($so.OSArchitecture))"
    $t = (Get-Date) - $so.LastBootUpTime
    Escribir "Arrancó: $($so.LastBootUpTime)"
    Escribir ("Encendida: {0} días, {1} h, {2} min" -f $t.Days, $t.Hours, $t.Minutes)
} else {
    Escribir "No se pudo consultar Win32_OperatingSystem; se omite."
}
if ($null -ne $fw) { Escribir "FwPOSTTime: $fw ms" }

# ---------------------------------------------------------------- 6
Titulo "6. Archivos y Git"
Escribir "Política de ejecución (usuario actual): $(Get-ExecutionPolicy -Scope CurrentUser)"
if (Get-Command git -ErrorAction SilentlyContinue) {
    Mostrar { git --version }
    git rev-parse --is-inside-work-tree 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Mostrar { git status -s | Select-Object -First 5 }
        Mostrar { git log --oneline -n 3 }
    } else {
        Escribir "No estás dentro de un repositorio git; se omite git status."
    }
} else {
    Escribir "No existe git; se omiten los comandos de git."
}
if (Test-Path "semana03") { Mostrar { Get-ChildItem semana03 } }
else { Escribir "No existe la carpeta semana03; se omite Get-ChildItem." }

Escribir ""
Escribir "=== Fin del diagnóstico Windows ==="