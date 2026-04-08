# Build once, then deploy to all configured targets you choose.
# Usage:
#   .\scripts\deploy_all.ps1                    # Vercel preview only
#   .\scripts\deploy_all.ps1 -VercelProd        # Vercel production
#   .\scripts\deploy_all.ps1 -Firebase        # Firebase Hosting (needs .firebaserc)
#   .\scripts\deploy_all.ps1 -VercelProd -Firebase
param(
  [switch] $VercelProd,
  [switch] $Firebase
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

Write-Host "Building Flutter web (release)..." -ForegroundColor Cyan
flutter build web --release
if (-not $?) { exit 1 }

Copy-Item -Path ".\vercel.json" -Destination ".\build\web\vercel.json" -Force

if ($VercelProd) {
  Write-Host "Deploying to Vercel (production)..." -ForegroundColor Cyan
  npx --yes vercel@latest deploy ".\build\web" --prod --yes
} else {
  Write-Host "Deploying to Vercel (preview)..." -ForegroundColor Cyan
  npx --yes vercel@latest deploy ".\build\web" --yes
}

if ($Firebase) {
  if (-not (Test-Path ".\.firebaserc")) {
    Write-Error "Firebase requested but .firebaserc is missing. Copy .firebaserc.example to .firebaserc."
  }
  Write-Host "Deploying to Firebase Hosting..." -ForegroundColor Cyan
  firebase deploy --only hosting
}

Write-Host ""
Write-Host "Done. GitHub Pages deploys automatically on push to main/master when enabled in repo Settings → Pages." -ForegroundColor Green
