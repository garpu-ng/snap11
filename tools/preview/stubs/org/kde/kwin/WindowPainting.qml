// Draws a fake window (title bar, caption, some content lines) at any size.
// Used for the desktop and for thumbnails.
import QtQuick

Item {
    id: painting

    property var window: null
    readonly property real s: width / Math.max(1, window ? window.frameGeometry.width : 1)

    Rectangle {
        anchors.fill: parent
        radius: 8 * painting.s
        color: painting.window ? painting.window.color : "#888"
        border.color: Qt.rgba(0, 0, 0, 0.35)
        border.width: 1

        Rectangle {
            width: parent.width
            height: Math.max(2, 34 * painting.s)
            radius: parent.radius
            color: Qt.darker(painting.window ? painting.window.color : "#888", 1.25)

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12 * painting.s
                anchors.verticalCenter: parent.verticalCenter
                visible: painting.s > 0.25
                text: painting.window ? painting.window.caption : ""
                color: "white"
                font.pixelSize: Math.max(6, 14 * painting.s)
            }
        }

        Column {
            x: 24 * painting.s
            y: 60 * painting.s
            spacing: 14 * painting.s
            Repeater {
                model: 8
                Rectangle {
                    required property int index
                    width: (painting.width - 48 * painting.s) * (0.4 + 0.5 * ((index * 37) % 10) / 10)
                    height: Math.max(1, 8 * painting.s)
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.35)
                }
            }
        }
    }
}
