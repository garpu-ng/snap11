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
    readonly property rect virtualScreenGeometry: {
        let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
        for (let i = 0; i < screens.length; i++) {
            const g = screens[i].geometry;
            x0 = Math.min(x0, g.x); y0 = Math.min(y0, g.y);
            x1 = Math.max(x1, g.x + g.width); y1 = Math.max(y1, g.y + g.height);
        }
        return Qt.rect(x0, y0, x1 - x0, y1 - y0);
    }
    property Component screenComponent: Component {
        QtObject {
            property string name
            property rect geometry
        }
    }
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

    // Another screen (Sim.addScreen).
    function addScreen(name, geometry) {
        const s = screenComponent.createObject(ws, { "name": name, "geometry": geometry });
        screens = screens.concat([s]);
        return s;
    }

    // The screen a window belongs to, as in KWin: the one under the center
    // of its frame (else the first).
    function outputAt(p) {
        for (let i = 0; i < screens.length; i++) {
            const g = screens[i].geometry;
            if (p.x >= g.x && p.x < g.x + g.width && p.y >= g.y && p.y < g.y + g.height)
                return screens[i];
        }
        return screens[0];
    }

    function clientArea(kind, output, desktop) {
        const g = (output || screen).geometry;
        if (kind === 7 || kind === 6 || kind === 4) // ScreenArea, FullArea, FullScreenArea
            return Qt.rect(g.x, g.y, g.width, g.height);
        return Qt.rect(g.x, g.y, g.width, g.height - panelHeight);
    }

    // KDE's quick tile layout per screen and desktop, like KWin's
    // QuickRootTile: KDE remembers where the user dragged the split between
    // two quick tiled windows, and later quick tiles use that split. A
    // script reaches the root only through a quick tiled window
    // (window.tile.parent). Children in KWin's order: left, right, top,
    // bottom, topLeft, topRight, bottomLeft, bottomRight.
    property var quickRoots: ({})
    readonly property var quickModes: ["left", "right", "top", "bottom",
                                       "topLeft", "topRight", "bottomLeft", "bottomRight"]

    function quickRoot(output) {
        const o = output || screen;
        const key = o.name + "/" + currentDesktop;
        let root = quickRoots[key];
        if (!root) {
            root = { "output": o, "split": Qt.point(0.5, 0.5), "tiles": [] };
            for (let i = 0; i < quickModes.length; i++)
                root.tiles.push({ "parent": root, "mode": quickModes[i], "padding": 0,
                                  "resizeByPixels": function(delta, edge) {} });
            quickRoots[key] = root;
            layoutQuickRoot(root);
        }
        return root;
    }

    // Relative and absolute geometry of every child, from the split.
    function layoutQuickRoot(root) {
        const a = clientArea(2, root.output, currentDesktop);
        const fx = root.split.x, fy = root.split.y;
        const rel = {
            "left": Qt.rect(0, 0, fx, 1), "right": Qt.rect(fx, 0, 1 - fx, 1),
            "top": Qt.rect(0, 0, 1, fy), "bottom": Qt.rect(0, fy, 1, 1 - fy),
            "topLeft": Qt.rect(0, 0, fx, fy), "topRight": Qt.rect(fx, 0, 1 - fx, fy),
            "bottomLeft": Qt.rect(0, fy, fx, 1 - fy), "bottomRight": Qt.rect(fx, fy, 1 - fx, 1 - fy)
        };
        root.absoluteGeometry = a;
        for (let i = 0; i < root.tiles.length; i++) {
            const t = root.tiles[i];
            const r = rel[t.mode];
            const x0 = Math.round(a.x + r.x * a.width), x1 = Math.round(a.x + (r.x + r.width) * a.width);
            const y0 = Math.round(a.y + r.y * a.height), y1 = Math.round(a.y + (r.y + r.height) * a.height);
            t.relativeGeometry = r;
            t.absoluteGeometry = Qt.rect(x0, y0, x1 - x0, y1 - y0);
        }
    }

    // Like dragging KDE's resize handle between quick tiled windows: move
    // the split (fractions of the work area) and refit the tiled windows.
    function setQuickSplit(output, fx, fy) {
        const root = quickRoot(output);
        root.split = Qt.point(fx, fy);
        layoutQuickRoot(root);
        for (let i = 0; i < stackingOrder.length; i++) {
            const w = stackingOrder[i];
            if (w.tile && w.tile.parent === root)
                w.frameGeometry = w.tile.absoluteGeometry;
        }
    }

    // Quick tiling, as KWin does it: the active window fills that part of
    // its screen's work area (at KDE's split) and gets that quick tile.
    function quickTile(mode) {
        quickTileCalls = quickTileCalls.concat([mode]);
        const w = activeWindow;
        if (!w)
            return;
        const root = quickRoot(w.output);
        const t = root.tiles[quickModes.indexOf(mode)];
        w.frameGeometry = t.absoluteGeometry;
        w.tile = t;
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
