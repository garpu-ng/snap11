// Windows 11 design values: light/dark and accent follow the system.
import QtQuick
import org.kde.kirigami as Kirigami
import Snap11Sim

QtObject {
    readonly property color blue: Qt.lighter("#0078d4", 1.0)

    property var steps: [
        [0, function() {
            Sim.setDark(true);
            Sim.setAccent("#0078d4");
        }],
        [50, function() {
            const f = Sim.snap.fluent;
            Sim.check(f !== undefined && f !== null, "main.qml has the Fluent tokens");
            Sim.check(f.dark, "dark system colors give the dark theme");
            Sim.check(Qt.colorEqual(f.textPrimary, "#ffffff"), "dark: primary text is white");
            Sim.check(Qt.colorEqual(f.flyoutFill, "#f52c2c2c"), "dark: flyout is #2C2C2C");
            Sim.check(f.accentFill.hslLightness > blue.hslLightness + 0.2,
                      "dark: accent fill is a lighter variant of the accent (" + f.accentFill + ")");
            Sim.checkEq(f.overlayRadius, 8, "overlay corner radius");
            Sim.checkEq(f.controlRadius, 4, "control corner radius");
            Sim.checkRect(f.zoneRect(Qt.rect(0, 0, 960, 1036), Qt.rect(0, 0, 1920, 1036)),
                          Qt.rect(8, 8, 948, 1020), "left half zone is inset 8 outside, 4 inside");
            Sim.checkRect(f.zoneRect(Qt.rect(640, 0, 640, 1036), Qt.rect(0, 0, 1920, 1036)),
                          Qt.rect(644, 8, 632, 1020), "middle third zone");
            Sim.checkEq(f.durFast, 167, "fast duration at normal animation speed");
            Sim.checkEq(f.durNormal, 250, "normal duration at normal animation speed");
            Sim.setDark(false);
        }],
        [50, function() {
            const f = Sim.snap.fluent;
            Sim.check(!f.dark, "light system colors give the light theme");
            Sim.check(Qt.colorEqual(f.textPrimary, "#e4000000"), "light: primary text is black at 89%");
            Sim.check(f.accentFill.hslLightness < blue.hslLightness,
                      "light: accent fill is a darker variant of the accent (" + f.accentFill + ")");
            Kirigami.Units.longDuration = 0;
        }],
        [50, function() {
            const f = Sim.snap.fluent;
            Sim.checkEq(f.durFast, 0, "animations off in Plasma: no animation");
            Kirigami.Units.longDuration = 250;
        }]
    ]
}
