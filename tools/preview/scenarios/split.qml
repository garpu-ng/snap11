// KDE remembers where the user dragged the split between two quick tiled
// windows, and later quick tiles use it. The drop preview (edges, corners
// and the bar's quick tile zones) must show where the window will really
// land, also after the tiled windows are gone.
import QtQuick
import Snap11Sim

QtObject {
    property var a: null
    property var b: null
    property var c: null
    readonly property rect area: Qt.rect(0, 0, 1920, 1036)
    readonly property var preview: Sim.snap ? Sim.snap.dropPreview : null
    readonly property var bar: Sim.snap ? Sim.snap.layoutBar : null

    function zone(r) {
        return Sim.snap.fluent.zoneRect(r, area);
    }

    function zoneCenter(li, si) {
        const r = bar.previewRect(li);
        const s = bar.layouts[li][si];
        return Qt.point(Math.round(r.x + (s.x + s.w / 2) * r.width),
                        Math.round(r.y + (s.y + s.h / 2) * r.height));
    }

    property var steps: [
        [0, function() {
            b = Sim.addWindow({ "caption": "Mail", "geometry": Qt.rect(1000, 400, 800, 500) });
            a = Sim.addWindow({ "caption": "Browser", "geometry": Qt.rect(560, 260, 800, 560) });
        }],
        [50, function() {
            Sim.dragStart(a, Qt.point(960, 275));
            Sim.dragTo(Qt.point(3, 500));
        }],
        [300, function() {
            Sim.checkRect(Sim.geometryOf(preview), zone(Qt.rect(0, 0, 960, 1036)), "before: preview in the left half");
            Sim.dragEnd();
        }],
        [600, function() {
            Sim.check(Sim.snap.snapAssist.visible, "Snap Assist offers the other window");
            Sim.key(Qt.Key_Right);
            Sim.key(Qt.Key_Return);
        }],
        [600, function() {
            Sim.checkRect(b.frameGeometry, Qt.rect(960, 0, 960, 1036), "second window in the right half");
            // The user drags KDE's split between the two to 60 %.
            Sim.setQuickSplit(a.output, 0.6, 0.5);
            Sim.checkRect(a.frameGeometry, Qt.rect(0, 0, 1152, 1036), "KDE moved the split to 60 %");
            // Both go away; KDE keeps the split.
            Sim.removeWindow(a);
            Sim.removeWindow(b);
            c = Sim.addWindow({ "caption": "Editor", "geometry": Qt.rect(560, 260, 800, 560) });
        }],
        [100, function() {
            Sim.dragStart(c, Qt.point(960, 275));
            Sim.dragTo(Qt.point(3, 500));
        }],
        [500, function() {
            Sim.checkRect(Sim.geometryOf(preview), zone(Qt.rect(0, 0, 1152, 1036)), "left edge: preview at KDE's split");
            Sim.dragTo(Qt.point(1916, 500));
        }],
        [500, function() {
            Sim.checkRect(Sim.geometryOf(preview), zone(Qt.rect(1152, 0, 768, 1036)), "right edge: preview at KDE's split");
            Sim.dragTo(Qt.point(3, 2), 12);
        }],
        [500, function() {
            Sim.checkRect(Sim.geometryOf(preview), zone(Qt.rect(0, 0, 1152, 518)), "top left corner: quarter at KDE's split");
            Sim.dragTo(Qt.point(960, 18));
        }],
        [400, function() {
            Sim.dragTo(zoneCenter(0, 0));
        }],
        [400, function() {
            Sim.checkRect(Sim.geometryOf(preview), zone(Qt.rect(0, 0, 1152, 1036)), "bar 50/50, left zone: at KDE's split");
            Sim.dragTo(zoneCenter(0, 1));
        }],
        [400, function() {
            Sim.checkRect(Sim.geometryOf(preview), zone(Qt.rect(1152, 0, 768, 1036)), "bar 50/50, right zone: at KDE's split");
            Sim.dragTo(Qt.point(3, 500));
        }],
        [500, function() {
            Sim.dragEnd();
        }],
        [600, function() {
            Sim.checkRect(c.frameGeometry, Qt.rect(0, 0, 1152, 1036), "window lands where the preview was");
            Sim.key(Qt.Key_Escape);
        }]
    ]
}
