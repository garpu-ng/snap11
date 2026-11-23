// The drop preview, like Windows 11: a floating frosted rectangle, inset
// from the work area's edges, that moves to wherever the window would land.
import QtQuick
import org.kde.kirigami as Kirigami
import Snap11Sim

QtObject {
    property var win: null
    readonly property rect area: Qt.rect(0, 0, 1920, 1036)
    readonly property var preview: Sim.snap ? Sim.snap.dropPreview : null

    function zone(r) {
        return Sim.snap.fluent.zoneRect(r, area);
    }

    property var steps: [
        [0, function() {
            Sim.addWindow({ "caption": "Mail", "geometry": Qt.rect(1000, 400, 800, 500) });
            win = Sim.addWindow({ "caption": "Browser", "geometry": Qt.rect(560, 260, 800, 560) });
        }],
        [50, function() {
            Sim.dragStart(win, Qt.point(960, 275));
            Sim.dragTo(Qt.point(3, 500));
        }],
        [500, function() {
            Sim.check(preview.visible, "preview shows at the left edge");
            Sim.checkRect(Sim.geometryOf(preview), zone(Qt.rect(0, 0, 960, 1036)), "preview floats in the left half");
            Sim.check(Sim.snap.layoutBar.z > preview.z, "the snap bar stays above the preview");
            Sim.shot("outline-dark");
            Sim.dragTo(Qt.point(1916, 500));
        }],
        [500, function() {
            Sim.checkRect(Sim.geometryOf(preview), zone(Qt.rect(960, 0, 960, 1036)), "preview moved to the right half");
            Sim.dragTo(Qt.point(700, 2));
        }],
        [500, function() {
            Sim.checkRect(Sim.geometryOf(preview), zone(area), "maximize preview floats in the whole work area");
            Sim.setDark(false);
            Sim.dragTo(Qt.point(3, 500));
        }],
        [500, function() {
            Sim.shot("outline-light");
            Sim.setDark(true);
            Sim.dragTo(Qt.point(960, 500));
        }],
        [100, function() {
            Sim.check(!preview.visible, "preview hides away from the edges");
            // Plasma's animation speed at "instant".
            Kirigami.Units.longDuration = 0;
            Sim.dragTo(Qt.point(3, 500));
        }],
        [30, function() {
            Sim.checkRect(Sim.geometryOf(preview), zone(Qt.rect(0, 0, 960, 1036)), "without animations the preview is there at once");
            Kirigami.Units.longDuration = 250;
            Sim.dragEnd();
        }],
        [300, function() {
            Sim.key(Qt.Key_Escape);
        }]
    ]
}
