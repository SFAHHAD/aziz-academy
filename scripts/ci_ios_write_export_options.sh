#!/usr/bin/env bash
# Writes ios/ExportOptions-ci.plist for manual signing (CI / App Store).
# Required env: IOS_TEAM_ID, IOS_PROVISIONING_PROFILE_NAME
# Optional: IOS_BUNDLE_ID (default com.azizacademy.azizAcademy)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEAM="${IOS_TEAM_ID:?Set IOS_TEAM_ID}"
PROFILE="${IOS_PROVISIONING_PROFILE_NAME:?Set IOS_PROVISIONING_PROFILE_NAME}"
BUNDLE="${IOS_BUNDLE_ID:-com.azizacademy.azizAcademy}"

cat > "$ROOT/ios/ExportOptions-ci.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store</string>
	<key>teamID</key>
	<string>${TEAM}</string>
	<key>uploadSymbols</key>
	<true/>
	<key>signingStyle</key>
	<string>manual</string>
	<key>signingCertificate</key>
	<string>Apple Distribution</string>
	<key>provisioningProfiles</key>
	<dict>
		<key>${BUNDLE}</key>
		<string>${PROFILE}</string>
	</dict>
</dict>
</plist>
EOF

echo "Wrote ios/ExportOptions-ci.plist for bundle ${BUNDLE}."
