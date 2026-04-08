# Windows helper: create Apple Distribution CSR (no Mac) or build .p12 from .cer + private.key.
# Requires OpenSSL (e.g. Git for Windows: C:\Program Files\Git\usr\bin\openssl.exe).
#
# Step 1 - CSR:
#   .\win_apple_distribution_cert.ps1 -Step Csr -OutputDir "$env:USERPROFILE\Desktop\apple_aziz_release"
# Step 2 - After downloading .cer from developer.apple.com:
#   .\win_apple_distribution_cert.ps1 -Step P12 -CerPath ...\ios_distribution.cer -KeyPath ...\private.key -P12Path ...\AppleDistribution.p12 -P12Password "your-password"

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Csr", "P12")]
    [string] $Step,
    [string] $OutputDir = "",
    [string] $CerPath = "",
    [string] $KeyPath = "",
    [string] $P12Path = "",
    [string] $P12Password = "",
    [string] $OpenSsl = ""
)

$ErrorActionPreference = "Stop"

function Find-OpenSsl {
    if ($OpenSsl -and (Test-Path $OpenSsl)) { return $OpenSsl }
    $candidates = @(
        "C:\Program Files\Git\usr\bin\openssl.exe",
        "C:\Program Files (x86)\Git\usr\bin\openssl.exe",
        "C:\OpenSSL-Win64\bin\openssl.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    $inPath = Get-Command openssl -ErrorAction SilentlyContinue
    if ($inPath) { return $inPath.Source }
    return $null
}

$openssl = Find-OpenSsl
if (-not $openssl) {
    Write-Error "OpenSSL not found. Install Git for Windows (includes openssl) or OpenSSL for Windows, then re-run."
}

if ($Step -eq "Csr") {
    if (-not $OutputDir) {
        $OutputDir = Join-Path $env:USERPROFILE "Desktop\apple_aziz_release"
    }
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
    $key = Join-Path $OutputDir "private.key"
    $csr = Join-Path $OutputDir "CertificateSigningRequest.certSigningRequest"
    $email = Read-Host "Apple ID email (for CSR)"
    if (-not $email) { $email = "dev@example.com" }
    Write-Host "Generating private key (2048-bit RSA)..."
    & $openssl genrsa -out $key 2048
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    $subj = "/emailAddress=$email/CN=Apple Distribution/O=Developer/C=US"
    Write-Host "Creating CSR (upload this file to Apple Developer → Certificates → Apple Distribution)..."
    & $openssl req -new -key $key -out $csr -subj $subj
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host ""
    Write-Host "Done. Next:"
    Write-Host "  1) Upload: $csr"
    Write-Host "  2) Download the .cer from Apple, then run -Step P12 with -CerPath and -KeyPath $key"
    Write-Host "  3) Keep private.key secret — never commit."
    return
}

if ($Step -eq "P12") {
    if (-not $CerPath -or -not (Test-Path $CerPath)) { Write-Error "Set -CerPath to the downloaded Apple Distribution .cer" }
    if (-not $KeyPath -or -not (Test-Path $KeyPath)) { Write-Error "Set -KeyPath to private.key from the CSR step" }
    if (-not $P12Path) { Write-Error "Set -P12Path for output .p12 (e.g. ...\AppleDistribution.p12)" }
    if (-not $P12Password) { Write-Error "Set -P12Password (strong password; store in GitHub secret IOS_DISTRIBUTION_CERTIFICATE_PASSWORD)" }

    $tempDir = Join-Path $env:TEMP ("apple_p12_" + [Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    try {
        $pem = Join-Path $tempDir "distribution.pem"
        Write-Host "Converting .cer to PEM..."
        & $openssl x509 -inform DER -in $CerPath -out $pem
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        Write-Host "Creating PKCS#12 (.p12)..."
        $passArg = "pass:$P12Password"
        & $openssl pkcs12 -export -out $P12Path -inkey $KeyPath -in $pem -password $passArg
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    finally {
        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }
    Write-Host "Created: $P12Path"
    Write-Host "Base64 for GitHub: .\scripts\encode_file_base64.ps1 -Path `"$P12Path`" -CopyToClipboard"
}
