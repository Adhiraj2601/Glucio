# Glucio — Environment Setup Script (Idempotent)
# Sets up Flutter stable, Android SDK paths, JBR, and Android licenses.

$ErrorActionPreference = "Stop"

$sdkPath = "$env:LOCALAPPDATA\Android\Sdk"
$jbrPath = "C:\Program Files\Android\Android Studio\jbr"
$flutterRoot = "C:\src\flutter"
$flutterBin = "$flutterRoot\bin"
$platformTools = "$sdkPath\platform-tools"
$cmdlineToolsBin = "$sdkPath\cmdline-tools\latest\bin"

Write-Host "==> Checking Flutter installation..."
if (!(Test-Path $flutterRoot)) {
    Write-Host "Cloning Flutter SDK stable channel into $flutterRoot..."
    if (!(Test-Path "C:\src")) { New-Item -ItemType Directory -Path "C:\src" -Force | Out-Null }
    git clone --depth 1 https://github.com/flutter/flutter.git -b stable $flutterRoot
} else {
    Write-Host "Flutter is already installed at $flutterRoot."
}

Write-Host "==> Checking Android Command-line Tools..."
if (!(Test-Path "$cmdlineToolsBin\sdkmanager.bat")) {
    Write-Host "Android command-line tools not found. Downloading..."
    $zipPath = "$env:TEMP\cmdline-tools.zip"
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    curl.exe -L "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip" -o $zipPath
    
    if (!(Test-Path "$sdkPath\cmdline-tools")) { New-Item -ItemType Directory -Path "$sdkPath\cmdline-tools" -Force | Out-Null }
    if (Test-Path "$env:TEMP\cmdline-tools") { Remove-Item -Path "$env:TEMP\cmdline-tools" -Recurse -Force }
    
    tar.exe -xf $zipPath -C $env:TEMP
    $latestDir = "$sdkPath\cmdline-tools\latest"
    if (Test-Path $latestDir) { Remove-Item -Path $latestDir -Recurse -Force }
    Move-Item -Path "$env:TEMP\cmdline-tools" -Destination $latestDir -Force
    Remove-Item -Path $zipPath -Force
    Write-Host "Installed command-line tools into $latestDir."
} else {
    Write-Host "Android command-line tools exist at $cmdlineToolsBin."
}

Write-Host "==> Updating Environment PATH and JAVA_HOME..."
[System.Environment]::SetEnvironmentVariable('JAVA_HOME', $jbrPath, 'User')
$env:JAVA_HOME = $jbrPath

$userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
$pathsToAdd = @($flutterBin, $platformTools, $cmdlineToolsBin, "$jbrPath\bin")
$newPaths = @()
foreach ($p in $pathsToAdd) {
    if ($userPath -notlike "*$p*") {
        $newPaths += $p
    }
}
if ($newPaths.Count -gt 0) {
    $updatedUserPath = ($newPaths -join ';') + ';' + $userPath
    [System.Environment]::SetEnvironmentVariable('Path', $updatedUserPath, 'User')
    Write-Host "Added $($newPaths.Count) new paths to User PATH permanently."
}

$env:Path = "$flutterBin;$platformTools;$cmdlineToolsBin;$jbrPath\bin;$env:Path"

Write-Host "==> Configuring Flutter settings..."
& "$flutterBin\flutter.bat" config --no-analytics | Out-Null
& "$flutterBin\flutter.bat" config --android-sdk $sdkPath | Out-Null
& "$flutterBin\flutter.bat" config --jdk-dir $jbrPath | Out-Null

Write-Host "==> Verifying Android licenses..."
$licDir = "$sdkPath\licenses"
if (!(Test-Path "$licDir\android-sdk-license")) {
    Write-Host "Accepting Android SDK licenses..."
    & "C:\Program Files\Git\bin\bash.exe" -c "export JAVA_HOME='/c/Program Files/Android/Android Studio/jbr'; yes | '/c/Users/adhir/AppData/Local/Android/Sdk/cmdline-tools/latest/bin/sdkmanager.bat' --licenses" | Out-Null
}

Write-Host "==> Running flutter doctor..."
& "$flutterBin\flutter.bat" doctor -v

Write-Host "==> Environment setup completed successfully!"
