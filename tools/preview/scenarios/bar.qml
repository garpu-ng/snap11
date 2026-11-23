// The snap bar, like Windows 11: collapsed as soon as a window is dragged,
// expanded when the cursor reaches it, Windows' layouts in Windows' order.
import QtQuick
import Snap11Sim

QtObject {
    property var win: null
    readonly property var bar: Sim.snap ? Sim.snap.layoutBar : null

    // Center of zone si of layout li in the expanded bar, on screen.
    function zoneCenter(li, si) {
        const r = bar.previewRect(li);
        const s = bar.layouts[li][si];
        return Qt.point(Math.round(r.x + (s.x + s.w / 2) * r.width),
                        Math.round(r.y + (s.y + s.h / 2) * r.height));
    }

    property var steps: [
        [0, function() {
            Sim.addWindow({ "caption": "Notes", "geometry": Qt.rect(80, 120, 700, 500) });
            Sim.addWindow({ "caption": "Music", "geometry": Qt.rect(1100, 300, 700, 500) });
            win = Sim.addWindow({ "caption": "Browser", "geometry": Qt.rect(560, 260, 800, 560) });
        }],
        [50, function() {
            Sim.dragStart(win, Qt.point(960, 275));
            Sim.dragTo(Qt.point(940, 240));
        }],
        [300, function() {
            Sim.check(bar.visible, "bar shows as soon as a window is dragged");
            Sim.check(!bar.expanded, "bar starts collapsed");
            Sim.checkEq(bar.layouts.length, 6, "Windows' six layouts on a 1920 px screen");
            Sim.checkEq(bar.layoutsFor(1600).length, 4, "no three-column layouts below 1920 px");
            Sim.shot("bar-collapsed");
            Sim.dragTo(Qt.point(960, 18));
        }],
        [400, function() {
            Sim.check(bar.expanded, "bar expands when the cursor reaches it");
            Sim.dragTo(zoneCenter(1, 0));
        }],
        [300, function() {
            Sim.checkEq(bar.hoveredLayout, 1, "hovering layout 2 (66/33)");
            Sim.checkEq(bar.hoveredSlot, 0, "hovering its left zone");
            Sim.checkRect(bar.slotRect(1, 0), Qt.rect(0, 0, 1280, 1036), "left zone of 66/33 is two thirds");
            Sim.check(Sim.snap.dropPreview.visible, "drop preview shows for the hovered zone");
            Sim.shot("bar-expanded-dark");
            Sim.setDark(false);
        }],
        [300, function() {
            Sim.shot("bar-expanded-light");
            Sim.setDark(true);
            Sim.dragEnd();
        }],
        [300, function() {
            Sim.checkRect(win.frameGeometry, Qt.rect(0, 0, 1280, 1036), "window dropped into the two-thirds zone");
            Sim.check(!bar.visible, "bar gone after the drop");
            Sim.key(Qt.Key_Escape);
        }]
    ]
}
