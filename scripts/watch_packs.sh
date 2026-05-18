#!/usr/bin/env bash
# Re-run the quiz pack validator whenever any assets/data/*.json changes.
# Useful while authoring content. Requires inotifywait (Linux) or fswatch (mac).
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

run_once() {
  echo "──── $(date +%H:%M:%S) ────"
  PYTHONIOENCODING=utf-8 python scripts/validate_quiz_packs.py || true
}

run_once

if command -v inotifywait >/dev/null 2>&1; then
  while inotifywait -qq -e modify -e create -e moved_to assets/data/*.json; do
    run_once
  done
elif command -v fswatch >/dev/null 2>&1; then
  fswatch -o assets/data | while read -r _; do
    run_once
  done
else
  # Fallback: poll mtime each 2s.
  echo "Neither inotifywait nor fswatch found — polling instead."
  last="$(stat -c %Y assets/data/*.json 2>/dev/null | sort -n | tail -1 || true)"
  while true; do
    sleep 2
    cur="$(stat -c %Y assets/data/*.json 2>/dev/null | sort -n | tail -1 || true)"
    if [[ "$cur" != "$last" ]]; then
      run_once
      last="$cur"
    fi
  done
fi
