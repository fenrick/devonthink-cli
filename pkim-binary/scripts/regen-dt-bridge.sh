#!/usr/bin/env bash
# Regenerate the typed Swift bridge for DEVONthink from its current
# scripting dictionary (.sdef). Run after DEVONthink updates its
# AppleScript surface — the generated protocols in
# Sources/pkim/Bridge/Generated/ are not derivable at build time,
# only from the installed DT app.
#
# Toolchain (one-time setup):
#   git clone https://github.com/tingraldi/SwiftScripting.git /tmp/SwiftScripting
#   python3 -m venv /tmp/swiftscripting-env
#   /tmp/swiftscripting-env/bin/pip install 'clang<=16'
#
# Verified working against:
#   - DEVONthink 4.x
#   - macOS 26.x (Tahoe)
#   - Python 3.14 + clang 16.0
#   - Tony Ingraldi's SwiftScripting (commit 80c8a05, 2024-09-09)
#
# Usage:
#   pkim-binary/scripts/regen-dt-bridge.sh
#
# Then re-run the test suite to catch any surface drift:
#   cd pkim-binary && PKIM_BRIDGE_LIVE=1 swift test

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GEN_DIR="$REPO_ROOT/Sources/pkim/Bridge/Generated"
DT_APP="${DT_APP_PATH:-/Applications/DEVONthink.app}"
SWIFT_SCRIPTING_ROOT="${SWIFT_SCRIPTING_ROOT:-/tmp/SwiftScripting}"
PYTHON="${PYTHON:-/tmp/swiftscripting-env/bin/python}"

if [[ ! -d "$DT_APP" ]]; then
  echo "DEVONthink not found at $DT_APP — set DT_APP_PATH and retry." >&2
  exit 2
fi
if [[ ! -d "$SWIFT_SCRIPTING_ROOT" ]]; then
  echo "SwiftScripting not found at $SWIFT_SCRIPTING_ROOT — clone it and retry." >&2
  echo "  git clone https://github.com/tingraldi/SwiftScripting.git $SWIFT_SCRIPTING_ROOT" >&2
  exit 2
fi
if [[ ! -x "$PYTHON" ]]; then
  echo "Python with libclang bindings not found at $PYTHON — set PYTHON and retry." >&2
  exit 2
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"

echo "[1/4] sdef <- $DT_APP"
sdef "$DT_APP" > DEVONthink.sdef

echo "[2/4] sdp -fh"
# sdp emits a warning about redeclared DEVONthinkApplication; harmless.
sdp -fh --basename DEVONthink DEVONthink.sdef 2>&1 | grep -v 'redeclared' || true

echo "[3/4] sbhc.py -> Swift protocols"
"$PYTHON" "$SWIFT_SCRIPTING_ROOT/sbhc.py" DEVONthink.h

echo "[4/4] sbsc.py -> Swift enums"
"$PYTHON" "$SWIFT_SCRIPTING_ROOT/sbsc.py" DEVONthink.sdef

mkdir -p "$GEN_DIR"
cp DEVONthink.swift "$GEN_DIR/"
cp DEVONthinkScripting.swift "$GEN_DIR/"

echo
echo "Regenerated:"
ls -la "$GEN_DIR/"DEVONthink*.swift
echo
echo "Run 'swift build' from $REPO_ROOT to verify the new surface compiles."
