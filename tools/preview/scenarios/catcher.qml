// The invisible click catcher over all screens must only be up while Snap
// Assist is. In 1.4.0 Snap Assist failed to open in KWin (a TypeError in
// SnapAssist.open), but the catcher was already shown and nothing hid it
// again: every click on the desktop was swallowed until KWin restarted.
import QtQuick
import Snap11Sim

QtObject {
    property var win: null
    readonly property var assist: Sim.snap ? Sim.snap.snapAssist : null
    readonly property var catcher: Sim.snap ? Sim.snap.clickCatcher : null

    property var steps: [
        [0, function() {
            Sim.addWindow({ "caption": "Notes", "geometry": Qt.rect(1100, 300, 700, 500) });
            win = Sim.addWindow({ "caption": "Browser", "geometry": Qt.rect(560, 260, 800, 560) });
        }],
        [50, function() {
            Sim.check(!catcher.visible, "no click catcher before any snap");
            // Snap to the left half with KDE's quick tiling; Snap Assist
            // opens for the right half.
            Sim.dragStart(win, Qt.point(960, 275));
            Sim.dragTo(Qt.point(0, 540));
        }],
        [300, function() {
            Sim.dragEnd();
        }],
        [600, function() {
            Sim.check(assist.visible, "Snap Assist opens for the free half");
            Sim.check(catcher.visible, "the click catcher is up together with Snap Assist");
            Sim.key(Qt.Key_Escape);
        }],
        [300, function() {
            Sim.check(!assist.visible, "Escape closes Snap Assist");
            Sim.check(!catcher.visible, "the click catcher goes away with Snap Assist");
            // Opening fails (no slot): the catcher must not stay behind.
            Sim.snap.openAssist(null, [win], []);
        }],
        [300, function() {
            Sim.check(!assist.visible, "Snap Assist did not open");
            Sim.check(!catcher.visible, "no click catcher left when Snap Assist fails to open");
        }]
    ]
}
