#!/bin/bash
# Build the release file dist/snap11-<version>.kwinscript.
#
# A .kwinscript is a zip with metadata.json and contents/ at its top level.
# Install it with:  kpackagetool6 --type KWin/Script --install <file>
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/snap11"

# Settings schema and page are generated; make sure they are current.
python3 -I "$ROOT/tools/gen_config.py" >/dev/null

VERSION="$(python3 -I -c 'import json,sys; print(json.load(open(sys.argv[1]))["KPlugin"]["Version"])' "$SRC/metadata.json")"
OUT="$ROOT/dist/snap11-$VERSION.kwinscript"

# The self test must never ship switched on.
if grep -q 'readonly property bool selfTest: true' "$SRC/contents/ui/main.qml"; then
    echo "error: selfTest is on in main.qml" >&2
    exit 1
fi

mkdir -p "$ROOT/dist"
rm -f "$OUT"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
cp -r "$SRC"/. "$STAGE"
cp "$ROOT/LICENSE" "$STAGE/LICENSE"
(cd "$STAGE" && zip -qr -X "$OUT" metadata.json contents LICENSE)
echo "$OUT"
