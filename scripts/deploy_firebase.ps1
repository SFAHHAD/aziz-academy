# Build Flutter web and deploy to Firebase Hosting.
# Requires: flutter, Firebase CLI (`npm i -g firebase-tools`), `firebase login`, and `.firebaserc` with your project id.
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

if (-not (Test-Path ".\.firebaserc")) {
  Write-Error "Missing .firebaserc — copy .firebaserc.example to .firebaserc and set your Firebase project id."
}

flutter build web --release
if (-not $?) { exit 1 }

Copy-Item -Path ".\vercel.json" -Destination ".\build\web\vercel.json" -Force -ErrorAction SilentlyContinue

firebase deploy --only hosting
