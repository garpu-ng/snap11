// A fake KWin window: the properties, signals and methods Snap11 uses.
import QtQuick
import org.kde.kwin

QtObject {
    property string caption
    property string icon: "application"
    property string internalId
    property string resourceClass: "demo"
    property color color: "#3b6ea5"
    property rect frameGeometry
    property var output: Workspace.screen
    property var tile: null
    property bool normalWindow: true
    property bool skipTaskbar: false
    property bool skipSwitcher: false
    property bool specialWindow: false
    property bool moveable: true
    property bool resizeable: true
    property bool minimized: false
    property bool onAllDesktops: true
    property var desktops: []
    property int pid: 1000
    // True during an interactive move (not a resize), like KWin's.
    property bool move: false
    property bool maximized: false

    signal interactiveMoveResizeStarted()
    signal interactiveMoveResizeStepped(rect geometry)
    signal interactiveMoveResizeFinished()

    function setMaximize(vertically, horizontally) {
        maximized = vertically && horizontally;
        if (maximized)
            frameGeometry = Workspace.clientArea(KWin.MaximizeArea, output, Workspace.currentDesktop);
    }

    function closeWindow() {
        Sim.removeWindow(this);
    }
}
