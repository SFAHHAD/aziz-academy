#!/usr/bin/env bash
# Lighthouse audit on the live deployment. Requires `npx` + Chromium.
# Usage:  bash scripts/lighthouse_audit.sh [url]
set -euo pipefail

URL="${1:-https://aziz-academy.vercel.app/}"
OUT="lighthouse-report.html"

echo "Auditing $URL ..."
npx --yes lighthouse "$URL" \
  --output html \
  --output-path "$OUT" \
  --quiet \
  --chrome-flags="--headless=new --no-sandbox"

echo "Report saved to $OUT"
