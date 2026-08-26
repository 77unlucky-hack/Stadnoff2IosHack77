#!/bin/bash
set -euo pipefail

echo "🔨 Building Lucky77.dylib for iOS..."

SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
CLANG="$(xcrun --find clang)"
ARCH="arm64"
MIN_VERSION="15.0"

mkdir -p build

"$CLANG" \
  -fobjc-arc \
  -isysroot "$SDK" \
  -miphoneos-version-min=$MIN_VERSION \
  -arch $ARCH \
  -dynamiclib \
  -framework UIKit \
  -framework AudioToolbox \
  -framework QuartzCore \
  -framework Foundation \
  -framework CoreGraphics \
  Tweak.xm \
  -o build/Lucky77.dylib

if [ -f "build/Lucky77.dylib" ]; then
    echo "✅ Built: build/Lucky77.dylib"
    file build/Lucky77.dylib
    ls -la build/
else
    echo "❌ Build failed!"
    exit 1
fi
