# =============================================================================
# Aziz Academy production deploy pipeline
# =============================================================================
#
# Usage:
#   .\scripts\deploy_web.ps1            # preview deploy
#   .\scripts\deploy_web.ps1 --prod     # production deploy (aziz-academy.com)
#   .\scripts\deploy_web.ps1 --prod --skip-validate  # skip post-deploy check
#
# Pipeline:
#   0. audit font coverage against bundled fonts (catches uncovered chars)
#   1. flutter build web (release, no PWA, no source maps, no tree-shake-icons)
#   2. patch flutter_bootstrap.js -> load CanvasKit from /canvaskit/ (cached)
#   3. minify all JSON pools under build/web/assets/data/
#   4. strip unused canvaskit variants (chromium/, skwasm*, wimp*)
#   5. vercel deploy
#   6. (prod only, default on) validate the live site against the
#      footgun checklist (CSP fonts, canvaskit local, no broken script tags)
#
# Native commands write deprecation warnings to stderr that PowerShell treats
# as errors and flips $? to false even on exit-code-0 success. We use
# $LASTEXITCODE explicitly to detect actual failures.
# =============================================================================

# Don't use Stop here — it makes deprecation warnings on stderr fatal.
$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot\..

function Test-LastSuccess {
  param([string]$step)
  if ($LASTEXITCODE -ne 0) {
    Write-Host "$step failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit 1
  }
}

$prod = $args -contains "--prod"
$skipValidate = $args -contains "--skip-validate"

Write-Host "==> 0a/5 audit font coverage in JSON content" -ForegroundColor Cyan
python scripts/audit_font_coverage.py
Test-LastSuccess "Font coverage audit"

Write-Host "==> 0b/5 audit sitemap routes against router" -ForegroundColor Cyan
python scripts/audit_sitemap_routes.py
Test-LastSuccess "Sitemap-router audit"

Write-Host "==> 0c/5 audit version constants vs pubspec" -ForegroundColor Cyan
python scripts/audit_version_consistency.py
Test-LastSuccess "Version consistency audit"

Write-Host "==> 1/5  flutter build web (release)" -ForegroundColor Cyan
# tree-shake-icons is the Flutter default — we leave it on. Static analysis
# (scripts/audit_font_coverage.py + a grep for `IconData(` constructions)
# confirmed every icon used resolves to a static `Icons.X` constant, so
# the tree-shaker can prune unused glyphs safely. Saves ~1.6MB on the wire.
# If any icon ever renders as a tofu box, re-add `--no-tree-shake-icons`
# and grep for the dynamic IconData call that bypassed the analyzer.
flutter build web --release `
  --pwa-strategy=none `
  --no-source-maps
Test-LastSuccess "Flutter build"

Write-Host "==> 2/5  patch CanvasKit URL -> /canvaskit/" -ForegroundColor Cyan
python scripts/patch_canvaskit_local.py
Test-LastSuccess "CanvasKit patch"

Write-Host "==> 3/5  minify JSON pools" -ForegroundColor Cyan
python scripts/minify_json_pools.py
Test-LastSuccess "JSON minify"

Write-Host "==> 4/5  strip unused canvaskit variants" -ForegroundColor Cyan
$canvaskit = ".\build\web\canvaskit"
foreach ($cruft in @("chromium", "skwasm.js", "skwasm.wasm", "skwasm.js.symbols",
                      "skwasm_heavy.js", "skwasm_heavy.wasm", "skwasm_heavy.js.symbols",
                      "wimp.js", "wimp.wasm", "wimp.js.symbols",
                      "canvaskit.js.symbols")) {
  $path = Join-Path $canvaskit $cruft
  if (Test-Path $path) { Remove-Item -Recurse -Force $path }
}

Write-Host "==> 5/5  vercel deploy" -ForegroundColor Cyan
if ($prod) {
  vercel deploy --prod --yes
} else {
  vercel deploy --yes
}
Test-LastSuccess "Vercel deploy"

if ($prod -and -not $skipValidate) {
  Write-Host ""
  Write-Host "==> validate https://aziz-academy.com" -ForegroundColor Cyan
  python scripts/validate_production_deploy.py
  if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Validation FAILED. Check the issues above." -ForegroundColor Red
    Write-Host "If they're acceptable, re-run with --skip-validate to bypass." -ForegroundColor Yellow
    exit 1
  }
}

Write-Host ""
Write-Host "Deploy complete." -ForegroundColor Green
