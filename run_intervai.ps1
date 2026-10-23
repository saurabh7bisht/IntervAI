[CmdletBinding()]
param(
    [int]$Port = 8000,
    [string]$HostAddress = "127.0.0.1",
    [switch]$KillExistingPort
)

$appDir = $PSScriptRoot
$venvPython = Join-Path $appDir ".venv\Scripts\python.exe"

if (-not (Test-Path $venvPython)) {
    Write-Error "Virtual environment python not found at $venvPython."
    exit 1
}

$existingConn = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Listen' }
if ($existingConn) {
    $existingPid = $existingConn.OwningProcess | Select-Object -First 1
    if ($KillExistingPort) {
        Write-Host "Port $Port is occupied by PID $existingPid. Terminating existing process..." -ForegroundColor Yellow
        Stop-Process -Id $existingPid -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    } else {
        Write-Warning "Port $Port is already in use by PID $existingPid."
        Write-Host "Application is available at http://${HostAddress}:${Port}" -ForegroundColor Cyan
        Write-Host "To restart, run: .\run_intervai.ps1 -KillExistingPort" -ForegroundColor Yellow
        return
    }
}

Set-Location $appDir

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                Starting IntervAI Application               " -ForegroundColor Cyan
Write-Host "  URL: http://${HostAddress}:${Port}                        " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan

& $venvPython -m uvicorn main:app --host $HostAddress --port $Port --reload
