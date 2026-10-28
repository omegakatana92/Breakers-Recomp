#!/usr/bin/env bash
# Build the Linux x86_64 player and package it as a Steam Deck AppImage.
#
# Prerequisites: gcc, g++, cmake 3.21+, make, libsdl2-dev, wget, strip.
# The user's ROMs are never bundled.  The AppImage contains the recompiled
# player and its licenses only.
#
# Usage: ./packaging/appimage/build-appimage.sh [ROM_DIR]
# Default ROM_DIR=<repo>/roms-src.  Output:
#   dist/steamdeck/Breakers-SteamDeck-x86_64.AppImage
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ROMS="${1:-$ROOT/roms-src}"
BUILD="${BREAKERS_BUILD_DIR:-$ROOT/build-linux}"
JOBS="${JOBS:-4}"
APPDIR="$BUILD/AppDir"
OUT_NAME="${BREAKERS_APPIMAGE_NAME:-Breakers-SteamDeck-x86_64.AppImage}"
OUT="$ROOT/dist/steamdeck/$OUT_NAME"

echo "== Breakers: Steam Deck AppImage =="
echo "repo: $ROOT"
echo "roms: $ROMS"

echo "== configure/build (Release) =="
cmake -S "$ROOT" -B "$BUILD" -DCMAKE_BUILD_TYPE=Release "-DBREAKERS_ROM_DIR=$ROMS"
cmake --build "$BUILD" --parallel "$JOBS" --target breakers

echo "== assemble AppDir =="
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" \
         "$APPDIR/usr/share/applications" \
         "$APPDIR/usr/share/icons/hicolor/256x256/apps" \
         "$APPDIR/usr/share/doc/breakers/LICENSES"
cp "$BUILD/Breakers" "$APPDIR/usr/bin/Breakers"
strip --strip-unneeded "$APPDIR/usr/bin/Breakers" 2>/dev/null || true

# Bundle the SDL2 the build linked against; SteamOS may have a different
# build, and this keeps the AppImage self-contained.
SDL=$(ldd "$BUILD/Breakers" | awk '/libSDL2-2\.0\.so\.0/{print $3; exit}')
if [ -n "${SDL:-}" ]; then cp "$SDL" "$APPDIR/usr/lib/"; fi

cp "$ROOT/packaging/appimage/breakers.png" "$APPDIR/breakers.png"
cp "$ROOT/packaging/appimage/breakers.png" \
   "$APPDIR/usr/share/icons/hicolor/256x256/apps/breakers.png"
cp "$ROOT/packaging/appimage/breakers.desktop" "$APPDIR/breakers.desktop"
cp "$ROOT/packaging/appimage/breakers.desktop" \
   "$APPDIR/usr/share/applications/breakers.desktop"
cp "$ROOT/packaging/appimage/README.txt" "$APPDIR/usr/share/doc/breakers/README.txt"
cp "$ROOT/LICENSE" "$APPDIR/usr/share/doc/breakers/LICENSE.txt"
cp "$ROOT/LICENSE-STATUS.md" "$APPDIR/usr/share/doc/breakers/LICENSE-STATUS.txt"
cp "$ROOT/THIRD_PARTY_NOTICES.md" "$APPDIR/usr/share/doc/breakers/THIRD_PARTY_NOTICES.txt"
cp "$ROOT/neogeorecomp/LICENSE" "$APPDIR/usr/share/doc/breakers/LICENSES/neogeorecomp.txt"
cp "$ROOT/neogeorecomp/NOTICE" "$APPDIR/usr/share/doc/breakers/LICENSES/neogeorecomp-NOTICE.txt"
cp "$ROOT/neogeorecomp/LICENSES/"*.txt "$APPDIR/usr/share/doc/breakers/LICENSES/"
cp "$ROOT/packaging/appimage/AppRun" "$APPDIR/AppRun"
chmod +x "$APPDIR/AppRun"

echo "== appimagetool =="
mkdir -p "$ROOT/dist/steamdeck"
TOOL="${APPIMAGETOOL:-$BUILD/appimagetool.AppImage}"
if [ ! -x "$TOOL" ]; then
    wget -q -O "$TOOL" \
      https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x "$TOOL"
fi
ARCH=x86_64 "$TOOL" --appimage-extract-and-run --no-appstream "$APPDIR" "$OUT"
chmod +x "$OUT"
echo "wrote $OUT"
