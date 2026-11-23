// Snap Assist like Windows 11: after dropping a window into a zone of a
// three-zone layout, the next zone offers the other windows as cards and
// the zone after it shows as an empty placeholder.
import QtQuick
import Snap11Sim

QtObject {
    property var win: null
    property var music: null
    readonly property rect area: Qt.rect(0, 0, 1920, 1036)
    readonly property var bar: Sim.snap ? Sim.snap.layoutBar : null
    readonly property var assist: Sim.snap ? Sim.snap.snapAssist : null

    function zone(r) {
        return Sim.snap.fluent.zoneRect(r, area);
    }

    function placeholder(i) {
        return Sim.snap.placeholders.objectAt(i);
    }

    function zoneCenter(li, si) {
        const r = bar.previewRect(li);
        const s = bar.layouts[li][si];
        return Qt.point(Math.round(r.x + (s.x + s.w / 2) * r.width),
                        Math.round(r.y + (s.y + s.h / 2) * r.height));
    }

    function center(r) {
        return Qt.point(Math.round(r.x + r.width / 2), Math.round(r.y + r.height / 2));
    }

    property var steps: [
        [0, function() {
            Sim.addWindow({ "caption": "Notes - meeting.txt", "geometry": Qt.rect(80, 120, 700, 500) });
            music = Sim.addWindow({ "caption": "Music", "geometry": Qt.rect(1100, 300, 700, 500) });
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
            Sim.checkRect(win.frameGeometry, Qt.rect(0, 0, 640, 1036), "window dropped into the left third");
            Sim.check(assist.visible, "Snap Assist opens for the next zone");
            Sim.checkRect(Sim.geometryOf(assist), zone(Qt.rect(640, 0, 640, 1036)), "Snap Assist fills the middle third");
            Sim.checkEq(assist.candidates.length, 2, "the two other windows are offered");
            Sim.check(placeholder(0).visible, "the right third shows as a placeholder");
            Sim.checkRect(Sim.geometryOf(placeholder(0)), zone(Qt.rect(1280, 0, 640, 1036)), "placeholder in the right third");
            Sim.check(!placeholder(1).visible, "no second placeholder");
            Sim.key(Qt.Key_Right);
        }],
        [300, function() {
            Sim.checkEq(assist.currentIndex, 0, "arrow key selects the first card");
            Sim.check(assist.keyboardNav, "keyboard selection shows the focus rectangle");
            Sim.shot("assist-keyboard-dark");
            Sim.mouseMove(center(assist.cardRect(1)).x, center(assist.cardRect(1)).y);
        }],
        [300, function() {
            Sim.checkEq(assist.currentIndex, 1, "hovering selects the second card");
            Sim.check(!assist.keyboardNav, "mouse hover shows no focus rectangle");
            Sim.shot("assist-dark");
            Sim.setDark(false);
        }],
        [300, function() {
            Sim.shot("assist-light");
            Sim.setDark(true);
            Sim.key(Qt.Key_Left);
            Sim.key(Qt.Key_Return);
        }],
        [600, function() {
            Sim.checkRect(assist.candidates.length > 0 ? Sim.geometryOf(assist) : Qt.rect(0, 0, 0, 0),
                          zone(Qt.rect(1280, 0, 640, 1036)), "Snap Assist moves on to the right third");
            Sim.check(!placeholder(0).visible, "no placeholder left");
            Sim.checkEq(assist.candidates.length, 1, "one window left to offer");
            Sim.key(Qt.Key_Escape);
        }],
        [300, function() {
            Sim.check(!assist.visible, "Escape closes Snap Assist");
            Sim.check(!placeholder(0).visible && !placeholder(1).visible, "no placeholders after closing");
        }]
    ]
}
