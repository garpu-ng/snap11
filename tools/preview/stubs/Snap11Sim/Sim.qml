// The simulator scenarios talk to: fake windows, drags, keys, checks and
// screenshots. The Python runner (context property "runner") does the
// parts QML cannot: key events, mouse events, grabbing the window.
pragma Singleton
import QtQuick
import org.kde.kwin
import org.kde.kirigami as Kirigami

QtObject {
    id: sim

    // Set by Scene.qml.
    property Item overlayLayer: null
    property Item desktop: null
    // The loaded main.qml root item.
    property var snap: null
    // Quick tile slots asked for, in order.
    readonly property var calls: Workspace.quickTileCalls

    property int zCounter: 0
    property int idCounter: 0
    property var dragging: null
    readonly property var palette: ["#3b6ea5", "#6a4c93", "#2a9d8f", "#c06c3e", "#5c677d", "#8a5a83"]
    property Component windowComponent: Component { FakeWindow {} }

    function nextZ() {
        zCounter += 1;
        return zCounter;
    }

    // props: caption, geometry (rect), and optionally icon, color, minimized.
    function addWindow(props) {
        idCounter += 1;
        const w = windowComponent.createObject(sim, {
            "caption": props.caption || ("Window " + idCounter),
            "icon": props.icon || (props.caption || "app").toLowerCase(),
            "internalId": "{00000000-0000-0000-0000-" + ("000000000000" + idCounter).slice(-12) + "}",
            "color": props.color || palette[(idCounter - 1) % palette.length],
            "frameGeometry": props.geometry || Qt.rect(200, 150, 900, 650),
            "minimized": !!props.minimized,
            "pid": 1000 + idCounter
        });
        Workspace.stackingOrder = Workspace.stackingOrder.concat([w]);
        Workspace.windowAdded(w);
        return w;
    }

    function removeWindow(w) {
        Workspace.stackingOrder = Workspace.stackingOrder.filter(function(x) { return x !== w; });
        if (Workspace.activeWindow === w)
            Workspace.activeWindow = null;
        Workspace.windowRemoved(w);
    }

    // Interactive move, like KWin: the window follows the cursor and
    // "stepped" fires for each step on the way.
    function dragStart(w, p) {
        dragging = w;
        Workspace.cursorPos = p;
        w.move = true;
        w.interactiveMoveResizeStarted();
    }

    function dragTo(p, steps) {
        const w = dragging;
        const n = steps || 4;
        const from = Workspace.cursorPos;
        for (let i = 1; i <= n; i++) {
            const q = Qt.point(Math.round(from.x + (p.x - from.x) * i / n),
                               Math.round(from.y + (p.y - from.y) * i / n));
            const c = Workspace.cursorPos;
            const g = w.frameGeometry;
            w.frameGeometry = Qt.rect(g.x + q.x - c.x, g.y + q.y - c.y, g.width, g.height);
            Workspace.cursorPos = q;
            w.interactiveMoveResizeStepped(w.frameGeometry);
        }
    }

    // The pointer is where the window was dropped, also for the overlays.
    function dragEnd() {
        const w = dragging;
        dragging = null;
        w.move = false;
        runner.mouseMove(Workspace.cursorPos.x, Workspace.cursorPos.y);
        w.interactiveMoveResizeFinished();
    }

    function key(code) { runner.key(code); }
    function mouseMove(x, y) { runner.mouseMove(x, y); }
    function click(x, y) { runner.click(x, y); }
    function shot(name) { runner.shot(name); }

    function check(cond, msg) {
        if (cond)
            runner.passed(msg);
        else
            runner.fail(msg);
    }

    function rectText(r) {
        return r ? "(" + r.x + "," + r.y + " " + r.width + "x" + r.height + ")" : String(r);
    }

    function checkRect(actual, expected, msg) {
        const same = !!actual && !!expected && actual.x === expected.x && actual.y === expected.y
            && actual.width === expected.width && actual.height === expected.height;
        check(same, msg + ": " + rectText(actual) + (same ? "" : " expected " + rectText(expected)));
    }

    function checkEq(actual, expected, msg) {
        check(actual === expected, msg + ": " + actual + (actual === expected ? "" : " expected " + expected));
    }

    // The global rect a Dialog (an Item in the stub) covers.
    function geometryOf(dialog) {
        return Qt.rect(dialog.x, dialog.y, dialog.width, dialog.height);
    }

    // System colors: Breeze Dark or Breeze Light.
    function setDark(dark) {
        Kirigami.Theme.backgroundColor = dark ? "#202326" : "#eff0f1";
        Kirigami.Theme.textColor = dark ? "#fcfcfc" : "#232629";
    }

    function setAccent(c) {
        Kirigami.Theme.highlightColor = c;
    }

    // Change a script option, then tell the script, like System Settings.
    function setConfig(key, value) {
        const c = Object.assign({}, KWin.config);
        c[key] = value;
        KWin.config = c;
        Options.configChanged();
    }
}
