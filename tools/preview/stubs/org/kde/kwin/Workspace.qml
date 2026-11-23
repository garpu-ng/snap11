// Stub of KWin's Workspace: one 1920x1080 screen with a 44 px panel at the
// bottom, a stacking order of fake windows (Snap11Sim/FakeWindow.qml), the
// cursor, and quick tiling that records which slot was asked for.
pragma Singleton
import QtQuick

QtObject {
    id: ws

    readonly property int panelHeight: 44
    property QtObject screen: QtObject {
        property string name: "DP-1"
        property rect geometry: Qt.rect(0, 0, 1920, 1080)
    }
    property var screens: [screen]
    property rect virtualScreenGeometry: Qt.rect(0, 0, 1920, 1080)
    property string currentDesktop: "desktop-1"
    // Bottom to top, like KWin.
    property var stackingOrder: []
    property var activeWindow: null
    property point cursorPos: Qt.point(0, 0)
    // Quick tile slots asked for, in order ("left", "topRight", ...).
    property var quickTileCalls: []

    signal windowAdded(var window)
    signal windowRemoved(var window)
    signal windowActivated(var window)

    onActiveWindowChanged: {
        const w = activeWindow;
        if (w && stackingOrder.indexOf(w) >= 0)
            stackingOrder = stackingOrder.filter(function(x) { return x !== w; }).concat([w]);
        windowActivated(w);
    }

    function clientArea(kind, output, desktop) {
        const g = (output || screen).geometry;
        if (kind === 7 || kind === 6 || kind === 4) // ScreenArea, FullArea, FullScreenArea
            return Qt.rect(g.x, g.y, g.width, g.height);
        return Qt.rect(g.x, g.y, g.width, g.height - panelHeight);
    }

    // Quick tiling, as KWin does it: the active window fills that part of
    // its screen's work area and gets a (quick) tile.
    function quickTile(mode) {
        quickTileCalls = quickTileCalls.concat([mode]);
        const w = activeWindow;
        if (!w)
            return;
        const a = clientArea(2, w.output, currentDesktop);
        const lw = Math.round(a.width / 2), th = Math.round(a.height / 2);
        const r = {
            "left": Qt.rect(a.x, a.y, lw, a.height),
            "right": Qt.rect(a.x + lw, a.y, a.width - lw, a.height),
            "topLeft": Qt.rect(a.x, a.y, lw, th),
            "topRight": Qt.rect(a.x + lw, a.y, a.width - lw, th),
            "bottomLeft": Qt.rect(a.x, a.y + th, lw, a.height - th),
            "bottomRight": Qt.rect(a.x + lw, a.y + th, a.width - lw, a.height - th)
        }[mode];
        w.frameGeometry = r;
        w.tile = { "absoluteGeometry": r, "padding": 0, "quickTileMode": mode,
                   "resizeByPixels": function(delta, edge) {} };
    }

    function slotWindowQuickTileLeft() { quickTile("left"); }
    function slotWindowQuickTileRight() { quickTile("right"); }
    function slotWindowQuickTileTopLeft() { quickTile("topLeft"); }
    function slotWindowQuickTileTopRight() { quickTile("topRight"); }
    function slotWindowQuickTileBottomLeft() { quickTile("bottomLeft"); }
    function slotWindowQuickTileBottomRight() { quickTile("bottomRight"); }

    // No custom tiles (tile editor) in the stub: bar layouts that need them
    // are placed by geometry, which main.qml supports.
    function rootTile(output, desktop) { return null; }
}
