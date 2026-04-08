#!/usr/bin/env bash
# macOS: create keychain, import Apple Distribution .p12, install App Store provisioning profile.
# Required env:
#   IOS_DISTRIBUTION_CERTIFICATE_BASE64, IOS_DISTRIBUTION_CERTIFICATE_PASSWORD
#   IOS_PROVISIONING_PROFILE_BASE64
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ "$(uname)" != "Darwin" ]]; then
  echo "ERROR: This script must run on macOS."
  exit 1
fi

if [[ -z "${IOS_DISTRIBUTION_CERTIFICATE_BASE64:-}" ]]; then
  echo "ERROR: IOS_DISTRIBUTION_CERTIFICATE_BASE64 is not set."
  exit 1
fi
if [[ -z "${IOS_DISTRIBUTION_CERTIFICATE_PASSWORD:-}" ]]; then
  echo "ERROR: IOS_DISTRIBUTION_CERTIFICATE_PASSWORD is not set."
  exit 1
fi
if [[ -z "${IOS_PROVISIONING_PROFILE_BASE64:-}" ]]; then
  echo "ERROR: IOS_PROVISIONING_PROFILE_BASE64 is not set."
  exit 1
fi

RUNNER_TMP="${RUNNER_TEMP:-/tmp}"
KEYCHAIN_PATH="$RUNNER_TMP/ci-build.keychain"
KEYCHAIN_PASSWORD="${KEYCHAIN_PASSWORD:-$(openssl rand -base64 32)}"

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

echo "$IOS_DISTRIBUTION_CERTIFICATE_BASE64" | base64 -d > /tmp/dist.p12
security import /tmp/dist.p12 -k "$KEYCHAIN_PATH" -P "$IOS_DISTRIBUTION_CERTIFICATE_PASSWORD" -T /usr/bin/codesign -T /usr/bin/security
rm -f /tmp/dist.p12

security list-keychain -d user -s "$KEYCHAIN_PATH"
security default-keychain -s "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

PROFILE_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
mkdir -p "$PROFILE_DIR"
echo "$IOS_PROVISIONING_PROFILE_BASE64" | base64 -d > /tmp/profile.mobileprovision
security cms -D -i /tmp/profile.mobileprovision > /tmp/profile.plist
UUID=$(/usr/libexec/PlistBuddy -c 'Print UUID' /tmp/profile.plist)
cp /tmp/profile.mobileprovision "$PROFILE_DIR/$UUID.mobileprovision"
rm -f /tmp/profile.mobileprovision /tmp/profile.plist

echo "iOS signing: keychain + provisioning profile installed (UUID=$UUID)."
