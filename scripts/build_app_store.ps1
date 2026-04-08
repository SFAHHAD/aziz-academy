# Build iOS archive for App Store Connect (run on macOS with Xcode installed).
# Prereqs: Apple Developer account; open ios/Runner.xcworkspace once and set Signing & Capabilities.
# Flutter runs CocoaPods as needed during the build.

$ErrorActionPreference = "Stop"
$isMac = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
    [System.Runtime.InteropServices.OSPlatform]::OSX)
if (-not $isMac) {
    Write-Host "This script must run on macOS (Xcode required for ipa export)."
    exit 1
}

Set-Location $PSScriptRoot\..

flutter build ipa --release

Write-Host ""
Write-Host "Output under build\ios\ipa\ — or use Xcode: open ios\Runner.xcworkspace -> Product -> Archive -> Distribute App."
