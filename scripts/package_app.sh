#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/.build/app/MoneyToday.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
DIST_DIR="$ROOT_DIR/dist"
STAGE_DIR="$ROOT_DIR/.build/release-stage"
PKG_FIX_DIR="$ROOT_DIR/.build/pkg-fix"
PKG_BOM_ROOT="$ROOT_DIR/.build/pkg-bom-root"
VERSION="1.2.0"
BUILD="120"

CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/module-cache" swift build --disable-sandbox --package-path "$ROOT_DIR"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$ROOT_DIR/.build/debug/MoneyToday" "$MACOS_DIR/MoneyToday"
cp "$ROOT_DIR/Sources/MoneyTodayApp/Resources/AppIcon/MoneyToday.icns" "$RESOURCES_DIR/MoneyToday.icns"
cp -R "$ROOT_DIR/Sources/MoneyTodayApp/Resources/Rewards" "$RESOURCES_DIR/Rewards"
mkdir -p "$RESOURCES_DIR/RewardsV2/final-47"
cp "$ROOT_DIR"/Sources/MoneyTodayApp/Resources/RewardsV2/final-47/reward-*.png "$RESOURCES_DIR/RewardsV2/final-47/"
mkdir -p "$RESOURCES_DIR/Pets"
cp -R "$ROOT_DIR/Sources/MoneyTodayApp/Resources/Pets/zhima" "$RESOURCES_DIR/Pets/zhima"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MoneyToday</string>
    <key>CFBundleIdentifier</key>
    <string>local.moneytoday.app</string>
    <key>CFBundleName</key>
    <string>MoneyToday</string>
    <key>CFBundleDisplayName</key>
    <string>MoneyToday</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>MoneyToday</string>
    <key>CFBundleIconName</key>
    <string>MoneyToday</string>
    <key>CFBundleShortVersionString</key>
    <string>1.2.0</string>
    <key>CFBundleVersion</key>
    <string>120</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

find "$APP_DIR" -name ".DS_Store" -delete
find "$APP_DIR" -name "._*" -delete
xattr -cr "$APP_DIR" 2>/dev/null || true

rm -rf "$DIST_DIR/MoneyToday.app" "$DIST_DIR/MoneyToday-v$VERSION" "$STAGE_DIR"
mkdir -p "$DIST_DIR" "$STAGE_DIR/MoneyToday-v$VERSION"
ditto --norsrc --noextattr "$APP_DIR" "$DIST_DIR/MoneyToday.app"
ditto --norsrc --noextattr "$APP_DIR" "$STAGE_DIR/MoneyToday-v$VERSION/MoneyToday.app"
cp "$ROOT_DIR/README.md" "$STAGE_DIR/MoneyToday-v$VERSION/README.md"
find "$STAGE_DIR" -name ".DS_Store" -delete
find "$STAGE_DIR" -name "._*" -delete
xattr -cr "$STAGE_DIR" 2>/dev/null || true
find "$DIST_DIR/MoneyToday.app" -name ".DS_Store" -delete
find "$DIST_DIR/MoneyToday.app" -name "._*" -delete
xattr -cr "$DIST_DIR/MoneyToday.app" 2>/dev/null || true

if [[ "${APP_ONLY:-0}" == "1" ]]; then
    echo "Created $DIST_DIR/MoneyToday.app"
    exit 0
fi

rm -f "$DIST_DIR/MoneyToday-v$VERSION.zip" "$DIST_DIR/MoneyToday-v$VERSION.pkg"
(cd "$STAGE_DIR" && COPYFILE_DISABLE=1 zip -r -X "$DIST_DIR/MoneyToday-v$VERSION.zip" "MoneyToday-v$VERSION")
COPYFILE_DISABLE=1 pkgbuild --install-location /Applications --component "$DIST_DIR/MoneyToday.app" "$DIST_DIR/MoneyToday-v$VERSION.pkg"
rm -rf "$PKG_FIX_DIR" "$PKG_BOM_ROOT"
pkgutil --expand "$DIST_DIR/MoneyToday-v$VERSION.pkg" "$PKG_FIX_DIR"
(cd "$DIST_DIR" && ditto -c -z --keepParent --norsrc --noextattr --noqtn --noacl MoneyToday.app "$PKG_FIX_DIR/Payload")
mkdir -p "$PKG_BOM_ROOT"
ditto --norsrc --noextattr "$DIST_DIR/MoneyToday.app" "$PKG_BOM_ROOT/MoneyToday.app"
mkbom "$PKG_BOM_ROOT" "$PKG_FIX_DIR/Bom"
pkgutil --flatten "$PKG_FIX_DIR" "$DIST_DIR/MoneyToday-v$VERSION.pkg"
find "$DIST_DIR" -name ".DS_Store" -delete
find "$DIST_DIR" -name "._*" -delete

echo "Created $APP_DIR"
echo "Created $DIST_DIR/MoneyToday-v$VERSION.zip"
echo "Created $DIST_DIR/MoneyToday-v$VERSION.pkg"
