# Prints base64 of a file for pasting into GitHub Actions secrets (e.g. keystore, .p12, .p8, .mobileprovision).
# Usage: .\encode_file_base64.ps1 -Path "C:\path\upload-keystore.jks"
param(
    [Parameter(Mandatory = $true)]
    [string] $Path,
    [switch] $CopyToClipboard
)
$ErrorActionPreference = "Stop"
$bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $Path))
$b64 = [Convert]::ToBase64String($bytes)
if ($CopyToClipboard) {
    Set-Clipboard -Value $b64
    Write-Host "Base64 copied to clipboard."
} else {
    Write-Output $b64
}
