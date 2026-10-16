# Glucio — Device Verification Script
# Verifies that an authorized physical Android phone is connected via USB.

$flutterBin = "C:\src\flutter\bin"
$sdkPath = "$env:LOCALAPPDATA\Android\Sdk"
$adb = "$sdkPath\platform-tools\adb.exe"

$env:Path = "$flutterBin;$sdkPath\platform-tools;$env:Path"

Write-Host "==> Checking ADB server and connected devices..."
& $adb start-server

$adbOutput = & $adb devices
Write-Host $adbOutput

$deviceLines = $adbOutput -split "`r?`n" | Where-Object { $_ -match '\t(device|unauthorized|offline)$' }

if ($deviceLines.Count -eq 0) {
    Write-Host "`n[ERROR] No Android device detected over USB!" -ForegroundColor Red
    Write-Host "Troubleshooting steps:"
    Write-Host " 1. Re-plug the USB cable into your computer and phone (ensure it's a data cable, not charge-only)."
    Write-Host " 2. Ensure Developer Options are enabled (Settings > About Phone > tap Build Number 7 times)."
    Write-Host " 3. Ensure USB Debugging is toggled ON in Developer Options."
    Write-Host " 4. Set USB configuration on the phone to 'File Transfer / MTP'."
    Write-Host " 5. Try running: adb kill-server; adb start-server; adb devices`n"
    exit 1
}

$unauthorized = $deviceLines | Where-Object { $_ -match '\tunauthorized$' }
if ($unauthorized) {
    Write-Host "`n[ERROR] Device is UNAUTHORIZED!" -ForegroundColor Yellow
    Write-Host "Action required on your phone:"
    Write-Host " 1. Unlock your phone screen."
    Write-Host " 2. Check for the popup prompt: 'Allow USB debugging?'"
    Write-Host " 3. Check 'Always allow from this computer' and tap 'Allow'."
    Write-Host " 4. Run this script again.`n"
    exit 2
}

$offline = $deviceLines | Where-Object { $_ -match '\toffline$' }
if ($offline) {
    Write-Host "`n[ERROR] Device is OFFLINE!" -ForegroundColor Yellow
    Write-Host "Restarting ADB server..."
    & $adb kill-server
    & $adb start-server
    exit 3
}

# Physical authorized device found
$authorizedLine = $deviceLines | Where-Object { $_ -match '\tdevice$' } | Select-Object -First 1
$deviceId = ($authorizedLine -split '\s+')[0]

Write-Host "`n==> Success! Physical device detected: $deviceId" -ForegroundColor Green
Write-Host "==> Running flutter devices..."
& "$flutterBin\flutter.bat" devices

# Output device ID so callers can capture it
$deviceId | Out-File -FilePath "$env:TEMP\glucio_device_id.txt" -Encoding ASCII
Write-Output $deviceId
exit 0
