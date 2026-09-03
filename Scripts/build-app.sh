#!/usr/bin/env bash
#
# Builds a real .app bundle from `swift build` output.
# Required because SPM alone doesn't generate Info.plist / LSUIElement / entitlements.
#
# Usage: ./Scripts/build-app.sh [debug|release]
# Output: ./build/Dockspace.app
#

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIG="${1:-release}"
APP_NAME="Dockspace"
BUNDLE_ID="app.dockspace.Dockspace"
BUILD_DIR="$ROOT/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
ENTITLEMENTS="$ROOT/Resources/Dockspace.entitlements"

if [ ! -f "$ENTITLEMENTS" ]; then
    echo "✗ entitlements file not found at $ENTITLEMENTS" >&2
    exit 1
fi

echo "▸ swift build -c $CONFIG"
swift build -c "$CONFIG"

BIN_PATH="$(swift build -c "$CONFIG" --show-bin-path)/$APP_NAME"
if [ ! -f "$BIN_PATH" ]; then
    echo "✗ binary not found at $BIN_PATH" >&2
    exit 1
fi

echo "▸ assembling $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$APP_NAME"
chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ENTITLEMENTS" "$APP_DIR/Contents/Resources/Dockspace.entitlements"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>Dockspace</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>0.2.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
    <key>NSFocusStatusUsageDescription</key>
    <string>Dockspace can switch your Dock to a saved profile when a macOS Focus turns on or off.</string>
    <key>NSHumanReadableCopyright</key>
    <string>MIT License, © Luciano dii Souza</string>
</dict>
</plist>
PLIST

# Apply entitlements via codesign so the binary can be re-signed later
# without re-running the script. We do an ad-hoc signature here; for
# distribution, ./Scripts/release.sh does the real signature.
echo "▸ ad-hoc codesign with entitlements"
codesign \
    --force \
    --sign - \
    --entitlements "$ENTITLEMENTS" \
    --timestamp=none \
    "$APP_DIR" 2>/dev/null || echo "  (codesign failed; bundle is unsigned — fine for dev run)"

echo "✓ built $APP_DIR"
echo "  run:    open $APP_DIR"
echo "  deploy: ./Scripts/release.sh"
