# Build Android App Bundle (.aab) for Google Play Console.
# Prereqs: Android SDK, Flutter. For signed release uploads, create android/key.properties
# and upload-keystore.jks (see android/key.properties.example).

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

flutter build appbundle --release

Write-Host ""
Write-Host "Output: build\app\outputs\bundle\release\app-release.aab"
Write-Host "Upload in Play Console -> Release -> App bundle explorer."
