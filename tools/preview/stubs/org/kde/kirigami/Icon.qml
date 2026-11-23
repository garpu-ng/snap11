// Stub of Kirigami.Icon: a colored rounded square with the icon's first
// letter, the color picked from the icon name.
import QtQuick

Item {
    id: icon

    property var source: ""
    property bool active: false
    readonly property string name: source ? source.toString() : ""
    readonly property real hue: {
        let h = 0;
        for (let i = 0; i < name.length; i++)
            h = (h * 31 + name.charCodeAt(i)) % 360;
        return h / 360;
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: parent.width / 16
        radius: width / 5
        color: Qt.hsla(icon.hue, 0.6, 0.5, 1)

        Text {
            anchors.centerIn: parent
            text: icon.name.length ? icon.name.charAt(0).toUpperCase() : "?"
            color: "white"
            font.bold: true
            font.pixelSize: parent.height * 0.6
        }
    }
}
