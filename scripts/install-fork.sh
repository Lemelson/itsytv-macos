#!/bin/bash
# Fork only: build Release, put it in /Applications under a searchable name and start it.
# The name carries every word people search with: "remote", "apple tv", "пульт", "тв", "itsytv"
# (Spotlight matches the file name, not localized names, so the words go into the name itself).
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Apple TV Remote – Пульт ТВ (Itsytv)"
DEST="/Applications/$APP_NAME.app"
TEAM="${DEVELOPMENT_TEAM:-86PAVRA5YA}"
BUILT="build/Build/Products/Release/Itsytv.app"

xcodegen generate
xcodebuild -project itsytv.xcodeproj -scheme itsytv -configuration Release \
  -derivedDataPath build DEVELOPMENT_TEAM="$TEAM" CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="Apple Development" build -quiet
codesign --verify --deep --strict "$BUILT"

# Quit the running copy, whatever it is called.
osascript -e 'tell application id "com.itsytv.app" to quit' >/dev/null 2>&1 || true
for _ in 1 2 3 4 5; do pgrep -x Itsytv >/dev/null || break; sleep 1; done
pkill -x Itsytv 2>/dev/null || true

# Move older copies of this app (any name) to the Trash, then install.
for old in /Applications/*.app; do
  [ "$(defaults read "$old/Contents/Info" CFBundleIdentifier 2>/dev/null)" = "com.itsytv.app" ] || continue
  mv "$old" "$HOME/.Trash/$(basename "$old" .app) $(date +%Y%m%d-%H%M%S).app"
done
ditto "$BUILT" "$DEST"

/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$DEST"
mdimport "$DEST" || true
open "$DEST"
echo "Installed and started: $DEST ($(defaults read "$DEST/Contents/Info" CFBundleShortVersionString))"
