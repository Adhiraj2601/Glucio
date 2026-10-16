# Glucio — Run on Physical Phone Script
# Checks connected device and runs the app on the physical USB phone.

param(
    [switch]$release
)

$ErrorActionPreference = "Stop"

$checkScript = Join-Path $PSScriptRoot "check_device.ps1"
Write-Host "==> Verifying physical device..."
& $checkScript
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Physical device verification failed with exit code $LASTEXITCODE." -ForegroundColor Red
    exit $LASTEXITCODE
}

$idFile = "$env:TEMP\glucio_device_id.txt"
if (!(Test-Path $idFile)) {
    Write-Host "[ERROR] Could not read device id from $idFile" -ForegroundColor Red
    exit 1
}
$deviceId = (Get-Content $idFile).Trim()

$flutterBin = "C:\src\flutter\bin"
$env:Path = "$flutterBin;$env:LOCALAPPDATA\Android\Sdk\platform-tools;$env:Path"

$appDir = Join-Path $PSScriptRoot "..\app"
if (!(Test-Path $appDir)) {
    Write-Host "[ERROR] /app directory not found! Run Slice 0 scaffold first." -ForegroundColor Red
    exit 1
}

Push-Location $appDir
try {
    Write-Host "==> Launching Glucio on physical phone ($deviceId)..." -ForegroundColor Cyan
    if ($release) {
        & "$flutterBin\flutter.bat" run -d $deviceId --release
    } else {
        & "$flutterBin\flutter.bat" run -d $deviceId
    }
} finally {
    Pop-Location
}
