// The notice about KDE's own edge snapping, as a Windows 11 toast in the
// bottom right corner.
import QtQuick
import org.kde.kwin
import Snap11Sim

QtObject {
    readonly property var notice: Sim.snap ? Sim.snap.notice : null

    property var steps: [
        [0, function() {
            Sim.addWindow({ "caption": "Files", "geometry": Qt.rect(200, 150, 900, 600) });
            Sim.check(!notice.visible, "no notice while KDE's edge snapping is off");
            Options.electricBorderTiling = true;
            Options.configChanged();
        }],
        [300, function() {
            Sim.check(notice.visible, "notice shows while KDE's edge tiling is on");
            const r = notice.surfaceRect();
            Sim.checkEq(r.x + r.width, 1920 - 12, "toast is 12 px from the right edge");
            Sim.checkEq(r.y + r.height, 1036 - 12, "toast is 12 px above the panel");
            Sim.checkEq(r.width, 364, "toast is as wide as a Windows toast");
            Sim.shot("notice-dark");
            Sim.setDark(false);
        }],
        [200, function() {
            Sim.shot("notice-light");
            Sim.setDark(true);
            Options.electricBorderTiling = false;
            Options.configChanged();
        }],
        [200, function() {
            Sim.check(!notice.visible, "notice goes away once KDE's edge tiling is off");
        }]
    ]
}
