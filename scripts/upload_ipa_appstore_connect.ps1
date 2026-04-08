# Upload a built .ipa to App Store Connect using an API key (Admin or App Manager role).
# Run on macOS with Xcode / altool available.
#
# Prereq: place AuthKey_<KEY_ID>.p8 in ~/.appstoreconnect/private_keys/
# (see scripts/app_store_connect.env.example).
#
# Usage:
#   .\upload_ipa_appstore_connect.ps1 -IpaPath "build\ios\ipa\Runner.ipa"
#   Or set APP_STORE_CONNECT_ISSUER_ID and APP_STORE_CONNECT_KEY_ID in scripts/app_store_connect.env

param(
    [Parameter(Mandatory = $false)]
    [string] $IpaPath = ""
)

$ErrorActionPreference = "Stop"
$isMac = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
    [System.Runtime.InteropServices.OSPlatform]::OSX)
if (-not $isMac) {
    Write-Error "Run this script on macOS (requires xcrun altool)."
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path $scriptDir "app_store_connect.env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
        $pair = $_ -split '=', 2
        if ($pair.Length -eq 2) {
            $name = $pair[0].Trim()
            $value = $pair[1].Trim()
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
}

$issuer = $env:APP_STORE_CONNECT_ISSUER_ID
$keyId = $env:APP_STORE_CONNECT_KEY_ID
if (-not $issuer -or -not $keyId) {
    Write-Error "Set APP_STORE_CONNECT_ISSUER_ID and APP_STORE_CONNECT_KEY_ID (e.g. copy app_store_connect.env.example to app_store_connect.env)."
}

if (-not $IpaPath) {
    $defaultDir = Join-Path (Split-Path $scriptDir -Parent) "build/ios/ipa"
    if (Test-Path $defaultDir) {
        $ipa = Get-ChildItem -Path $defaultDir -Filter "*.ipa" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($ipa) { $IpaPath = $ipa.FullName }
    }
}
if (-not $IpaPath -or -not (Test-Path $IpaPath)) {
    Write-Error "Specify -IpaPath to your .ipa or build one with build_app_store.ps1 first."
}

$keyPath = Join-Path $HOME ".appstoreconnect/private_keys/AuthKey_$keyId.p8"
if (-not (Test-Path $keyPath)) {
    Write-Warning "Expected API key at: $keyPath"
    Write-Warning "Copy your AuthKey_$keyId.p8 there (e.g. from Downloads). Do not commit .p8 files."
}

Write-Host "Uploading: $IpaPath"
& xcrun altool --upload-app --file $IpaPath --type ios --apiKey $keyId --apiIssuer $issuer
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
Write-Host "Upload finished. Check App Store Connect → TestFlight / builds."
