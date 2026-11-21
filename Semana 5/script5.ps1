<#
 Semana 5 · Taller 1 · Guardias en la puerta (Windows PowerShell)
 Escuela Politécnica Nacional · Sistemas Operativos · 2026-B
 Integrantes: Paulette Cushicagua · Erick Salazar

 Uso (una sola vez para permitir scripts):
     Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
 Ejecución con captura:
     .\semana05_windows.ps1 | Out-File captura_windows.txt -Encoding utf8
 Con otra ruta para la muestra:
     .\semana05_windows.ps1 -Muestra 'C:\ruta\muestras_eventos_4625.csv'
#>
param([string]$Muestra = '.\muestras_eventos_4625.csv')

$esAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# ---------- funciones auxiliares ----------
function Titulo([string]$t) {
    Write-Output ""
    Write-Output "==================== $t ===================="
}

# Muestra el comando tal como está escrito, lo ejecuta y captura salida o error
function Paso([scriptblock]$bloque) {
    Write-Output ""
    Write-Output ("PS> " + $bloque.ToString().Trim())
    try {
        $ErrorActionPreference = 'Stop'
        $salida = & $bloque 2>&1 | Out-String -Width 200
        Write-Output $salida.TrimEnd()
    } catch {
        Write-Output ("Error: " + $_.Exception.Message)
    }
}

Write-Output "Semana 5 · Taller 1 · Guardias en la puerta (Windows)"
Write-Output ("Fecha: {0}  ·  Equipo: {1}  ·  Usuario: {2}  ·  Administrador: {3}" -f `
    (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $env:COMPUTERNAME, $env:USERNAME, $esAdmin)

# =====================================================================
Titulo "1. Puertas abiertas"
# =====================================================================
Paso { Get-NetTCPConnection -State Listen | Sort-Object LocalPort | Select-Object LocalAddress, LocalPort, OwningProcess -First 12 }
Paso { (Get-NetTCPConnection -State Listen).Count }
Paso { $c = Get-NetTCPConnection -State Listen -LocalPort 135
       Get-Process -Id $c[0].OwningProcess | Select-Object Id, ProcessName }

# =====================================================================
Titulo "2. El portero en Linux (firewalld)"
# =====================================================================
Write-Output "(Esta sección se ejecuta en Linux: ver semana05_linux.sh)"

# =====================================================================
Titulo "3. DROP frente a REJECT (nftables)"
# =====================================================================
Write-Output "(Esta sección se ejecuta en Linux: ver semana05_linux.sh)"

# =====================================================================
Titulo "4. El portero en Windows"
# =====================================================================
Paso { Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction }
Paso { Get-Service mpssvc, BFE | Select-Object Name, DisplayName, Status }
Paso { (Get-NetFirewallRule -Enabled True -Direction Inbound).Count }
Paso { Get-NetFirewallRule -Enabled True -Direction Inbound | Select-Object -First 5 DisplayName, Action }

Write-Output ""
Write-Output "# W6. Crear y quitar una regla (requiere administrador)"
Paso { New-NetFirewallRule -DisplayName 'Taller5' -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Block }
if ($esAdmin) {
    Paso { Get-NetFirewallRule -DisplayName 'Taller5' | Select-Object DisplayName, Enabled, Action }
    Paso { Remove-NetFirewallRule -DisplayName 'Taller5' }
} else {
    Write-Output "(Sin administrador: «Acceso denegado» es lo esperado en el laboratorio.)"
}

Write-Output ""
Write-Output "# W7. La lista del motor WFP (requiere administrador)"
Push-Location $env:TEMP
Remove-Item .\filters.xml -ErrorAction SilentlyContinue
Paso { netsh wfp show filters }
if (Test-Path .\filters.xml) {
    Paso { (Select-String -Path .\filters.xml -Pattern '<filterKey>').Count }
    Remove-Item .\filters.xml -ErrorAction SilentlyContinue
} else {
    Write-Output "(No se generó filters.xml: sin administrador es lo esperado en el laboratorio.)"
}
Pop-Location

# =====================================================================
Titulo "5. La bitácora de autenticación"
# =====================================================================
Write-Output "# W8. Eventos 4625 del registro de Seguridad (requiere administrador)"
Paso { Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625} -MaxEvents 5 | Select-Object TimeCreated, Id, Message | Format-List }

Write-Output ""
Write-Output "# W9. La misma cuenta con la muestra"
if (Test-Path $Muestra) {
    Write-Output ""
    Write-Output "PS> `$ev = Import-Csv $Muestra"
    $ev = Import-Csv $Muestra
    Paso { ($ev | Where-Object Id -eq '4625').Count }
    Paso { $ev | Where-Object Id -eq '4625' | Group-Object IpAddress | Sort-Object Count -Descending | Select-Object Count, Name }
} else {
    Write-Output "(No se encontró '$Muestra': usa -Muestra con la ruta completa o haz cd a la carpeta de la semana 5.)"
}

# =====================================================================
Titulo "6. Reto final: su propio IDS"
# =====================================================================
if ($ev) {
    Paso { $ev | Where-Object Id -eq '4625' | Group-Object IpAddress | Where-Object Count -ge 3 | Sort-Object Count -Descending | Select-Object Count, Name }
} else {
    Write-Output "(Sin muestra cargada: no se puede ejecutar el reto.)"
}

Write-Output ""
Write-Output "==================== Fin del script ===================="