#!/usr/bin/env bash
# Audit the build/web bundle: print top 20 largest files + total size.
set -euo pipefail

if [[ ! -d build/web ]]; then
  echo "build/web missing — run flutter build web first." >&2
  exit 1
fi

echo "Top 20 largest files in build/web:"
find build/web -type f -printf "%s %p\n" \
  | sort -rn \
  | head -20 \
  | awk '{ printf "  %8.1f KB  %s\n", $1/1024, $2 }'

echo
echo "Total size:"
du -sh build/web
echo
echo "Asset directory breakdown:"
du -sh build/web/assets/* 2>/dev/null | sort -h
