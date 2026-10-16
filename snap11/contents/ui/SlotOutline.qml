/*
 * Translucent outline showing where the dragged window will land.
 */
import QtQuick
import org.kde.plasma.core as PlasmaCore

PlasmaCore.Dialog {
    id: outline

    // User options (Config.qml).
    required property QtObject cfg

    property rect target: Qt.rect(0, 0, 0, 0)


    function showAt(r) {
        target = r;
        visible = true;
        x = r.x;
        y = r.y;
    }

    function hide() {
        visible = false;
    }

    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus
    location: PlasmaCore.Types.Floating
    backgroundHints: PlasmaCore.Types.NoBackground
    type: PlasmaCore.Dialog.Normal
    outputOnly: true
    visible: false
    opacity: 1

    Rectangle {
        width: outline.target.width
        height: outline.target.height
        readonly property color hl: outline.cfg.highlightColor

        radius: outline.cfg.cornerRadius
        color: Qt.rgba(hl.r, hl.g, hl.b, outline.cfg.outlineFillOpacity / 100)
        border.color: Qt.rgba(hl.r, hl.g, hl.b, 0.9)
        border.width: outline.cfg.outlineBorderWidth
    }
}
