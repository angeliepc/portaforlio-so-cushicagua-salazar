# demo_comandos.ps1 - Demostracion de comandos de Windows (PowerShell y winget)
# Uso:
#   .\demo_comandos.ps1             # solo comandos de consulta (seguro)
#   .\demo_comandos.ps1 -Instalar   # ademas instala jq con winget
#
# Si la politica de ejecucion lo bloquea:
#   powershell -ExecutionPolicy Bypass -File .\demo_comandos.ps1

param(
    [switch]$Instalar
)

function Seccion($titulo) {
    Write-Host ""
    Write-Host "=== $titulo ===" -ForegroundColor Cyan
}

function Tiene($nombre) {
    return [bool](Get-Command $nombre -ErrorAction SilentlyContinue)
}

# Carpeta temporal para no ensuciar el directorio actual
$tmp = Join-Path $env:TEMP ("demo_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp | Out-Null

try {
    # ---------------------------------------------------------------
    Seccion "1. Archivo de prueba"
    $notas = Join-Path $tmp "notas.txt"
    @("Comprar tomates", "Picar cebolla", "Reducir la salsa") | Set-Content -Path $notas
    Get-Content $notas

    # ---------------------------------------------------------------
    Seccion "2. Tipo de comando (equivale a 'type' en Linux)"
    Get-Command cd, Get-ChildItem, ping | Format-Table Name, CommandType, Source -AutoSize

    # ---------------------------------------------------------------
    Seccion "3. Top 3 procesos por memoria (Working Set en bytes)"
    Get-Process |
        Sort-Object WS -Descending |
        Select-Object -First 3 Name, Id, WS |
        Format-Table -AutoSize

    # ---------------------------------------------------------------
    Seccion "4. Los 5 archivos mas grandes de C:\Windows\Logs"
    Get-ChildItem C:\Windows\Logs -Recurse -File -ErrorAction SilentlyContinue |
        Sort-Object Length -Descending |
        Select-Object -First 5 Length, FullName |
        Format-Table -AutoSize

    # ---------------------------------------------------------------
    Seccion "5. Gestor de paquetes (winget)"
    if (Tiene "winget") {
        Write-Host "--- Fuentes ---"
        winget source list

        Write-Host ""
        Write-Host "--- Buscar e inspeccionar jq ---"
        winget search jq
        winget show jqlang.jq

        if ($Instalar) {
            Write-Host ""
            Write-Host "--- Instalando jq ---"
            winget install --id jqlang.jq -e
        }
        else {
            Write-Host ""
            Write-Host "(Omitida la instalacion; usa -Instalar para ejecutarla)"
        }

        Write-Host ""
        Write-Host "--- Paquetes instalados (primeros 10) ---"
        winget list | Select-Object -First 10
    }
    else {
        Write-Host "winget no esta disponible en este sistema"
    }
}
finally {
    Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Listo."