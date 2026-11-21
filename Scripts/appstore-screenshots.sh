#!/bin/bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
BUILT="$ROOT/.artifacts/DD.noindex/Build/Products/Release/EMLViewer.app"
if [ ! -d "$BUILT" ] || find Sources Resources EMLViewer.xcodeproj -type f -newer "$BUILT/Contents/MacOS/EMLViewer" -print -quit | grep -q .; then
    ~/.claude/bin/build-slot -- xcodebuild -project EMLViewer.xcodeproj -scheme EMLViewer -configuration Release \
        -destination 'platform=macOS,arch=arm64' -derivedDataPath "$ROOT/.artifacts/DD.noindex" \
        CODE_SIGN_STYLE=- CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "$BUILT"
fi
/usr/bin/python3 Scripts/appstore/capture.py "$BUILT"
/usr/bin/swift Scripts/appstore/compose.swift
mkdir -p site/public/img
index=1
for image in AppStore/screenshots/en-US/*.png; do
    printf -v number '%02d' "$index"
    sips -Z 1440 "$image" --out "site/public/img/$number.png" >/dev/null
    index=$((index + 1))
done
