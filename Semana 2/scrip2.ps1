# Script de diagnóstico básico para Windows PowerShell
# Ejecutar en PowerShell con: .\windows.ps1

Write-Output "=== 1. Archivos y representación hexadecimal ==="
'Año' | Set-Content -Path t.txt -Encoding UTF8
Format-Hex -Path t.txt

Write-Output "`n=== 2. Memoria caché y CPU ==="
Get-CimInstance Win32_CacheMemory
(Get-CimInstance Win32_Processor).NumberOfLogicalProcessors

Write-Output "`n=== 3. Memoria RAM y procesos ==="
(Get-Process).Count
Get-Process -Id 4
Get-CimInstance Win32_OperatingSystem |
    Select-Object TotalVisibleMemorySize, FreePhysicalMemory

Write-Output "`n=== 4. Servicios del sistema ==="
(Get-Service | Where-Object Status -eq Running).Count
Get-Service |
    Where-Object Status -eq Running |
    Select-Object -First 8

Write-Output "`n=== 5. Discos y almacenamiento ==="
Get-CimInstance Win32_LogicalDisk |
    Select-Object DeviceID, Size, FreeSpace

Write-Output "`n=== 6. Información del sistema ==="
Get-CimInstance Win32_OperatingSystem |
    Select-Object Caption, Version, LastBootUpTime

Write-Output "`n=== 7. Uso de CPU ==="
Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor `
    -Filter "Name='_Total'" |
    Select-Object PercentIdleTime

Write-Output "`n=== Fin del diagnóstico Windows ==="
