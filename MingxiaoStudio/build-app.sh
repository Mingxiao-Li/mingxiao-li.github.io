#!/bin/zsh
set -euo pipefail

APP_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$APP_ROOT"

swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"
APP_PATH="$APP_ROOT/dist/Mingxiao Studio.app"

rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"
cp "$BIN_DIR/MingxiaoStudio" "$APP_PATH/Contents/MacOS/MingxiaoStudio"
cp -R "$BIN_DIR/MingxiaoStudio_MingxiaoStudio.bundle" "$APP_PATH/Contents/Resources/"
cp "$APP_ROOT/Resources/AppIcon.icns" "$APP_PATH/Contents/Resources/AppIcon.icns"
cp "$APP_ROOT/Resources/Info.plist" "$APP_PATH/Contents/Info.plist"

echo "Built: $APP_PATH"
echo "Open it with: open \"$APP_PATH\""
