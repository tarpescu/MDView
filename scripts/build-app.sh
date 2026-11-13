#!/usr/bin/env bash
#
# Builds MDView in release mode and wraps the binary in a proper macOS
# application bundle (build/MDView.app) using Sources/MDView/Resources/Info.plist,
# so Finder "Open With", the Dock icon drop and document types all work.
#
# Usage: scripts/build-app.sh [--install]
#   --install   also copy the bundle to /Applications
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/MDView.app"

cd "$ROOT"

# SwiftUI's macros ship with Xcode, not with the Command Line Tools. If the
# active developer dir is the CLT but Xcode is installed, use Xcode.
if [[ -z "${DEVELOPER_DIR:-}" && "$(xcode-select -p 2>/dev/null)" == *CommandLineTools* \
      && -d /Applications/Xcode.app ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
    echo "Using Xcode toolchain: $DEVELOPER_DIR"
fi

swift build -c release

BIN_DIR="$(swift build -c release --show-bin-path)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/MDView" "$APP/Contents/MacOS/MDView"
cp "$ROOT/Sources/MDView/Resources/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Sources/MDView/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

# SwiftPM resource bundles of dependencies (if any) must sit next to the binary.
find "$BIN_DIR" -maxdepth 1 -name '*.bundle' -exec cp -R {} "$APP/Contents/Resources/" \;

# Ad-hoc signature so Gatekeeper lets the locally built app launch.
codesign --force --deep --sign - "$APP" >/dev/null

# Make Launch Services pick up the document types declared in Info.plist.
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP" || true

echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
    rm -rf "/Applications/MDView.app"
    cp -R "$APP" /Applications/
    echo "Installed to /Applications/MDView.app"
fi
