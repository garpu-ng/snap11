/*
 * Notice in the bottom right corner while KDE's own edge snapping is still on
 * (it would show its own outline next to Snap11's). It goes away by itself
 * once both KDE options are off; the X hides it until the next login.
 */
import QtQuick
import org.kde.plasma.core as PlasmaCore

PlasmaCore.Dialog {
    id: notice

    // Which KDE options are still on.
    property bool maximizeOn: false
    property bool tilingOn: false
    // Hidden with the X, for this session.
    property bool dismissed: false

    readonly property int boxWidth: 420
    readonly property int margin: 16
    property rect area: Qt.rect(0, 0, 0, 0)

    function update(workArea, maximize, tiling) {
        area = workArea;
        maximizeOn = maximize;
        tilingOn = tiling;
        const show = (maximize || tiling) && !dismissed;
        if (show && !visible) {
            visible = true;
            // A Dialog re-centers itself when shown, so position it afterwards.
            // Bottom right, so it never covers window buttons at the top.
            x = area.x + area.width - boxWidth - margin;
            y = area.y + area.height - height - margin;
        } else if (!show && visible) {
            visible = false;
        }
    }

    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus
    location: PlasmaCore.Types.Floating
    backgroundHints: PlasmaCore.Types.NoBackground
    type: PlasmaCore.Dialog.Normal
    visible: false

    Rectangle {
        width: notice.boxWidth
        height: body.implicitHeight + 28
        radius: 12
        color: Qt.rgba(0.11, 0.11, 0.13, 1)
        border.color: "#f67400"
        border.width: 2

        Column {
            id: body

            x: 16
            y: 14
            width: parent.width - 32 - 28
            spacing: 6

            Text {
                width: parent.width
                text: "Snap11: KDE's own edge snapping is still on"
                color: "#f67400"
                font.pixelSize: 14
                font.bold: true
                wrapMode: Text.WordWrap
            }

            Text {
                width: parent.width
                color: "white"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                text: "Both would show at the same time. In System Settings > Screen Edges, turn off:"
                      + (notice.maximizeOn ? "\n• Maximize: Drag windows to top edge" : "")
                      + (notice.tilingOn ? "\n• Tile: Drag windows to the left or right edge" : "")
                      + "\nThis notice goes away by itself."
            }
        }

        // Close: hide until the next login.
        Rectangle {
            width: 24
            height: 24
            x: parent.width - width - 10
            y: 10
            radius: 6
            color: closeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : "transparent"

            Text {
                anchors.centerIn: parent
                text: "✕"
                color: "white"
                font.pixelSize: 12
            }

            MouseArea {
                id: closeMouse

                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    notice.dismissed = true;
                    notice.visible = false;
                }
            }
        }
    }
}
