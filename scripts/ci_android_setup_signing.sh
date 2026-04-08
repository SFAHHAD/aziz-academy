#!/usr/bin/env bash
# Writes android/app/upload-keystore.jks and android/key.properties from env (used in CI).
# Required env: ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_PASSWORD, ANDROID_KEY_ALIAS
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -z "${ANDROID_KEYSTORE_BASE64:-}" ]]; then
  echo "ERROR: ANDROID_KEYSTORE_BASE64 is not set."
  exit 1
fi
if [[ -z "${ANDROID_KEYSTORE_PASSWORD:-}" || -z "${ANDROID_KEY_PASSWORD:-}" ]]; then
  echo "ERROR: ANDROID_KEYSTORE_PASSWORD and ANDROID_KEY_PASSWORD must be set."
  exit 1
fi
export ANDROID_KEY_ALIAS="${ANDROID_KEY_ALIAS:-upload}"

echo "$ANDROID_KEYSTORE_BASE64" | base64 -d > android/app/upload-keystore.jks
chmod 600 android/app/upload-keystore.jks

cat > android/key.properties <<EOF
storePassword=${ANDROID_KEYSTORE_PASSWORD}
keyPassword=${ANDROID_KEY_PASSWORD}
keyAlias=${ANDROID_KEY_ALIAS}
storeFile=upload-keystore.jks
EOF

echo "Android signing files written (key.properties + upload-keystore.jks)."
