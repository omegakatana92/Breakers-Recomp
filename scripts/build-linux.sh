#!/usr/bin/env bash
# Build the Linux x86_64 player (Release).  No packaging, no downloads.
#
# Usage: ./scripts/build-linux.sh [ROM_DIR]
# Default ROM_DIR is <repo>/roms-src.  The generated C is written into
# build-linux/generated and is never committed or distributed.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROMS="${1:-$ROOT/roms-src}"
BUILD="$ROOT/build-linux"
JOBS="${JOBS:-4}"

echo "== Breakers: Linux x86_64 build =="
echo "repo: $ROOT"
echo "roms: $ROMS"
cmake -S "$ROOT" -B "$BUILD" -DCMAKE_BUILD_TYPE=Release "-DBREAKERS_ROM_DIR=$ROMS"
cmake --build "$BUILD" --parallel "$JOBS" --target breakers
echo "built $BUILD/Breakers"
