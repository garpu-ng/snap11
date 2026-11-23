#!/bin/bash
# Run Snap11 preview scenarios without KWin: the real QML against stub KDE
# modules, on a virtual display. Screenshots land in the output directory.
#
# Usage:
#   tools/preview/run.sh <scenario> [outdir]   one scenario (tools/preview/scenarios/<name>.qml)
#   tools/preview/run.sh all [outdir]          every scenario
#
# Needs: python3 with PySide6 (pip install PySide6-Essentials), xvfb-run,
# Mesa (llvmpipe). Set SNAP11_PY to use another Python, e.g. a venv.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
PY="${SNAP11_PY:-python3}"
OUT="${2:-$ROOT/dist/preview}"
mkdir -p "$OUT"

run_one() {
    echo "== $1"
    xvfb-run -a -s "-screen 0 1920x1080x24" \
        env QT_QPA_PLATFORM=xcb QT_QUICK_CONTROLS_STYLE=Basic \
        "$PY" -I "$HERE/run.py" "$1" "$OUT"
}

if [ "${1:-}" = "all" ]; then
    failed=0
    for f in "$HERE"/scenarios/*.qml; do
        run_one "$(basename "$f" .qml)" || failed=$((failed + 1))
    done
    echo "== $failed scenario(s) failed"
    exit "$failed"
fi
run_one "$1"
