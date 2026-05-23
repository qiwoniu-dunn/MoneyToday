#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/.build/app/MoneyToday.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/module-cache" swift build --disable-sandbox --package-path "$ROOT_DIR"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$ROOT_DIR/.build/debug/MoneyToday" "$MACOS_DIR/MoneyToday"
CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/module-cache" swift "$ROOT_DIR/scripts/generate_app_icon.swift" "$RESOURCES_DIR/MoneyToday.icns"

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
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>100</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "Created $APP_DIR"
