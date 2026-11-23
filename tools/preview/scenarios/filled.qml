// A zone that gets filled while Snap Assist works on another one is
// skipped, and its placeholder goes away.
import QtQuick
import Snap11Sim

QtObject {
    property var win: null
    property var notes: null
    readonly property rect area: Qt.rect(0, 0, 1920, 1036)
    readonly property var bar: Sim.snap ? Sim.snap.layoutBar : null
    readonly property var assist: Sim.snap ? Sim.snap.snapAssist : null

    function zoneCenter(li, si) {
        const r = bar.previewRect(li);
        const s = bar.layouts[li][si];
        return Qt.point(Math.round(r.x + (s.x + s.w / 2) * r.width),
                        Math.round(r.y + (s.y + s.h / 2) * r.height));
    }

    property var steps: [
        [0, function() {
            notes = Sim.addWindow({ "caption": "Notes", "geometry": Qt.rect(80, 120, 700, 500) });
            Sim.addWindow({ "caption": "Music", "geometry": Qt.rect(1100, 300, 700, 500) });
            Sim.addWindow({ "caption": "Mail", "geometry": Qt.rect(400, 500, 700, 400) });
            win = Sim.addWindow({ "caption": "Browser", "geometry": Qt.rect(560, 260, 800, 560) });
        }],
        [50, function() {
            Sim.dragStart(win, Qt.point(960, 275));
            Sim.dragTo(Qt.point(960, 18));
        }],
        [400, function() {
            Sim.dragTo(zoneCenter(2, 0));
        }],
        [300, function() {
            Sim.dragEnd();
        }],
        [600, function() {
            Sim.check(assist.visible && Sim.snap.placeholders.objectAt(0).visible,
                      "Snap Assist in the middle third, placeholder in the right third");
            // Something else fills the right third meanwhile.
            notes.frameGeometry = Qt.rect(1280, 0, 640, 1036);
            Sim.key(Qt.Key_Right);
            Sim.key(Qt.Key_Return);
        }],
        [600, function() {
            Sim.check(!assist.visible, "no Snap Assist over the zone that is now filled");
            Sim.check(!Sim.snap.placeholders.objectAt(0).visible, "its placeholder is gone too");
        }]
    ]
}
