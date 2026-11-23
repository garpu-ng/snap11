/*
 * An empty zone still to be filled, while Snap Assist works on another
 * zone of the same layout: frosted glass like Snap Assist's, without
 * content, as in Windows 11. It takes no input (outputOnly); a click on it
 * reaches the click catcher below and closes Snap Assist.
 */
import QtQuick
import org.kde.plasma.core as PlasmaCore

PlasmaCore.Dialog {
    id: placeholder

    // The Windows 11 look (Fluent.qml).
    required property QtObject fluent

    // Ask KWin's blur effect to blur behind the whole window.
    property rect kwin_blur: Qt.rect(0, 0, 0, 0)

    // The zone on screen (inset), which is also the window's geometry.
    property rect zone: Qt.rect(0, 0, 0, 0)

    // slot: { rect, output }; workArea: usable area of its screen.
    function show(slot, workArea) {
        zone = fluent.zoneRect(slot.rect, workArea);
        visible = true;
        // A Dialog re-centers itself when shown, so position it afterwards.
        x = zone.x;
        y = zone.y;
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

    Rectangle {
        width: placeholder.zone.width
        height: placeholder.zone.height
        radius: placeholder.fluent.overlayRadius
        color: placeholder.fluent.glassFill
        border.width: 1
        border.color: placeholder.fluent.glassStroke
    }
}
