// Two screens side by side. Dropping at the top edge maximizes on the
// screen the preview showed (the cursor's), even when most of the window
// is still on the other screen.
import QtQuick
import Snap11Sim

QtObject {
    property var win: null
    property var right: null
    readonly property rect rightArea: Qt.rect(1920, 0, 1920, 1036)

    property var steps: [
        [0, function() {
            right = Sim.addScreen("DP-2", Qt.rect(1920, 0, 1920, 1080));
            win = Sim.addWindow({ "caption": "Wide", "geometry": Qt.rect(500, 300, 1400, 600) });
        }],
        [50, function() {
            // Grab the title bar near its right end, cursor to the other
            // screen's top edge; the window's center stays on the left.
            Sim.dragStart(win, Qt.point(1880, 315));
            Sim.dragTo(Qt.point(1930, 2));
        }],
        [400, function() {
            Sim.check(win.output !== right, "most of the window is still on the left screen");
            Sim.check(Sim.snap.layoutBar.output === right, "the bar follows the cursor to the right screen");
            Sim.check(Sim.snap.maximizeArmed, "top edge of the right screen arms maximize");
            Sim.checkRect(Sim.geometryOf(Sim.snap.dropPreview), Sim.snap.fluent.zoneRect(rightArea, rightArea),
                          "maximize preview on the right screen");
            Sim.dragEnd();
        }],
        [300, function() {
            Sim.checkRect(win.frameGeometry, rightArea, "window maximized on the screen the preview showed");
        }]
    ]
}
