#!/bin/bash
# Reload the Snap11 KWin script without logging out.
#
# KWin caches QML files by path, so reloading the same path keeps running
# old code. For development we copy the script to a fresh directory each
# time and load it from there.
#
# Usage:
#   ./reload.sh            load a fresh dev copy (until next login)
#   ./reload.sh test       same, and open the picker by itself (self test)
#   ./reload.sh demo       self test on the smaller screen with demo apps only
#   ./reload.sh install    build the package and install it for real
# Logs: journalctl --user -f | grep snap11
set -e
SRC="$(cd "$(dirname "$0")" && pwd)/snap11"
KS="qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting"

$KS.unloadScript snap11 >/dev/null || true

if [ "$1" = "install" ]; then
    # Build the release file and install or upgrade it like a user would.
    # Note: an upgrade in a running session can keep using KWin's cached
    # old QML until the next login.
    PKG="$("$(dirname "$SRC")/tools/package.sh")"
    kpackagetool6 --type KWin/Script --upgrade "$PKG" 2>/dev/null \
        || kpackagetool6 --type KWin/Script --install "$PKG"
    kwriteconfig6 --file kwinrc --group Plugins --key snap11Enabled true
    qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure
    $KS.start
else
    BASE="${XDG_RUNTIME_DIR:-/tmp}/snap11-dev"
    rm -rf "$BASE"
    DEV="$BASE/$(date +%s%N)"
    mkdir -p "$DEV"
    cp -r "$SRC"/. "$DEV"
    if [ "$1" = "test" ] || [ "$1" = "demo" ]; then
        sed -i 's/readonly property bool selfTest: false/readonly property bool selfTest: true/' "$DEV/contents/ui/main.qml"
    fi
    if [ "$1" = "demo" ]; then
        # Window classes used for screenshots; see demoClasses in main.qml.
        CLASSES='"org.kde.gwenview", "org.kde.dolphin", "org.kde.kate", "org.kde.kcalc", "kcm_kwin4_genericscripted"'
        sed -i "s/readonly property var demoClasses: \[\]/readonly property var demoClasses: [$CLASSES]/" "$DEV/contents/ui/main.qml"
    fi
    $KS.loadDeclarativeScript "$DEV/contents/ui/main.qml" snap11 >/dev/null
    $KS.start
fi
echo "loaded: $($KS.isScriptLoaded snap11)"
