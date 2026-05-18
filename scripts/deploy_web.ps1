# Build Flutter web and deploy to Vercel (preview). Use --prod for production.
# Requires: flutter, npx vercel (logged in)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

flutter build web --release
if (-not $?) { exit 1 }

Copy-Item -Path ".\vercel.json" -Destination ".\build\web\vercel.json" -Force

$prod = $args -contains "--prod"
if ($prod) {
  npx --yes vercel@latest deploy ".\build\web" --prod --yes
} else {
  npx --yes vercel@latest deploy ".\build\web" --yes
}
