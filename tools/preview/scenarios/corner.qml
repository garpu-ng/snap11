// Dragging along the top edge into a corner snaps to that quarter, like
// Windows, instead of maximizing.
import QtQuick
import Snap11Sim

QtObject {
    property var win: null

    property var steps: [
        [0, function() {
            win = Sim.addWindow({ "caption": "Editor", "geometry": Qt.rect(560, 280, 800, 600) });
        }],
        [50, function() {
            Sim.dragStart(win, Qt.point(960, 295));
            Sim.dragTo(Qt.point(960, 2));
        }],
        [200, function() {
            Sim.dragTo(Qt.point(3, 2), 12);
        }],
        [300, function() {
            Sim.check(Sim.snap.dropPreview.visible, "drop preview shows in the corner");
            Sim.check(!Sim.snap.maximizeArmed, "corner does not maximize");
            Sim.dragEnd();
        }],
        [300, function() {
            Sim.checkEq(Sim.calls[Sim.calls.length - 1], "topLeft", "window quick tiled to the top left quarter");
            Sim.key(Qt.Key_Escape);
        }]
    ]
}
