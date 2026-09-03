#!/usr/bin/env bash
#
# Packages Dockspace into a signed + notarized DMG ready for public
# distribution. Falls back gracefully when signing identities and
# notarization credentials are not available — the DMG is still
# produced, just unsigned.
#
# Required env vars (only when DISTRIBUTION=1):
#   DOCKSPACE_SIGN_IDENTITY   "Developer ID Application: Your Name (TEAMID)"
#   DOCKSPACE_NOTARY_PROFILE  Keychain profile created via:
#                             xcrun notarytool store-credentials <name> \
#                                 --apple-id <id> --team-id <team> \
#                                 --password <app-pw>
#
# Usage:
#   ./Scripts/release.sh                    # dev DMG (unsigned, OK for local use)
#   DOCKSPACE_SIGN_IDENTITY="..." \
#   DOCKSPACE_NOTARY_PROFILE="..." \
#       ./Scripts/release.sh                # full signed + notarized DMG
#

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="Dockspace"
# Pull the version out of the Info.plist template written by build-app.sh.
VERSION=$(grep -A1 'CFBundleShortVersionString' "$ROOT/Scripts/build-app.sh" \
    | tail -1 \
    | sed -E 's/.*<string>(.*)<\/string>.*/\1/')
VERSION=${VERSION:-0.2.0}
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
RELEASE_DIR="$ROOT/build/release"
APP_DIR="$ROOT/build/$APP_NAME.app"
DMG_PATH="$RELEASE_DIR/$DMG_NAME"

echo "▸ version: $VERSION"
echo "▸ building .app bundle"
"$ROOT/Scripts/build-app.sh" release

mkdir -p "$RELEASE_DIR"
rm -f "$DMG_PATH"

# ── Sign ─────────────────────────────────────────────────────────────
if [ -n "${DOCKSPACE_SIGN_IDENTITY:-}" ]; then
    echo "▸ signing with identity: $DOCKSPACE_SIGN_IDENTITY"
    codesign \
        --force \
        --deep \
        --options runtime \
        --sign "$DOCKSPACE_SIGN_IDENTITY" \
        --entitlements "$ROOT/Resources/Dockspace.entitlements" \
        --timestamp \
        "$APP_DIR"
else
    echo "  (DOCKSPACE_SIGN_IDENTITY not set — leaving ad-hoc signature)"
fi

# ── Notarize ─────────────────────────────────────────────────────────
if [ -n "${DOCKSPACE_NOTARY_PROFILE:-}" ] && [ -n "${DOCKSPACE_SIGN_IDENTITY:-}" ]; then
    echo "▸ notarizing (this may take a couple of minutes)"
    ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$RELEASE_DIR/$APP_NAME.zip"
    xcrun notarytool submit "$RELEASE_DIR/$APP_NAME.zip" \
        --keychain-profile "$DOCKSPACE_NOTARY_PROFILE" \
        --wait
    xcrun stapler staple "$APP_DIR"
    rm -f "$RELEASE_DIR/$APP_NAME.zip"
else
    echo "  (DOCKSPACE_NOTARY_PROFILE or DOCKSPACE_SIGN_IDENTITY not set — skipping notarization)"
fi

# ── DMG ──────────────────────────────────────────────────────────────
echo "▸ creating DMG at $DMG_PATH"
TMP_DMG="$RELEASE_DIR/tmp-$APP_NAME.dmg"
hdiutil create -volname "$APP_NAME" -srcfolder "$APP_DIR" -ov -format UDZO "$TMP_DMG"
mv "$TMP_DMG" "$DMG_PATH"

# Sign the DMG itself if we have an identity.
if [ -n "${DOCKSPACE_SIGN_IDENTITY:-}" ]; then
    codesign --force --sign "$DOCKSPACE_SIGN_IDENTITY" --timestamp "$DMG_PATH" || true
fi

# ── Verify ───────────────────────────────────────────────────────────
echo
echo "✓ release artifacts:"
ls -la "$RELEASE_DIR"
echo
echo "  inspect:  codesign -dvv '$APP_DIR'"
echo "  install:  open '$DMG_PATH'"
