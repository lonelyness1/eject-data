#!/bin/bash
set -euo pipefail

APP_NAME="EjectData"
BUILD_DIR="build"
APP="$BUILD_DIR/$APP_NAME.app"
ROOT="$(cd "$(dirname "$0")" && pwd)"

rm -rf "$BUILD_DIR"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -o "$APP/Contents/MacOS/$APP_NAME" \
  "$ROOT/Sources/EjectData.swift" \
  -framework Cocoa

cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Resources/eject-data.sh" "$APP/Contents/Resources/eject-data.sh"
chmod +x "$APP/Contents/Resources/eject-data.sh"

codesign --force --deep --sign - "$APP"

echo "Built: $(pwd)/$APP"
echo "Install: cp -R \"$APP\" /Applications/"
