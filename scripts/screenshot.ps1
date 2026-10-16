# Glucio — Physical Device Screenshot Script
# Captures a screenshot from the connected USB Android phone via adb.

param(
    [string]$name = ""
)

$sdkPath = "$env:LOCALAPPDATA\Android\Sdk"
$adb = "$sdkPath\platform-tools\adb.exe"

$screenshotsDir = Join-Path $PSScriptRoot "..\docs\screenshots"
if (!(Test-Path $screenshotsDir)) {
    New-Item -ItemType Directory -Path $screenshotsDir -Force | Out-Null
}

if ([string]::IsNullOrWhiteSpace($name)) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $name = "screen_$timestamp"
}

if (!$name.EndsWith(".png")) {
    $name = "$name.png"
}

$targetPath = Join-Path $screenshotsDir $name

& $adb start-server
for ($i = 0; $i -lt 5; $i++) {
    $devices = & $adb devices
    if ($devices -match '\tdevice(\r?\n|$)') { break }
    Start-Sleep -Seconds 1
}

Write-Host "Capturing screenshot to $targetPath..."
& $adb wait-for-device
& $adb shell screencap -p /sdcard/glucio_temp_cap.png
& $adb pull /sdcard/glucio_temp_cap.png $targetPath
& $adb shell rm /sdcard/glucio_temp_cap.png

if (Test-Path $targetPath) {
    $size = (Get-Item $targetPath).Length
    Write-Host "Screenshot saved successfully ($size bytes): $targetPath" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Failed to capture screenshot!" -ForegroundColor Red
    exit 1
}
