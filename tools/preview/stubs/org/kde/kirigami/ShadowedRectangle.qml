// Stub of Kirigami.ShadowedRectangle: a rounded rectangle with border and
// a soft drop shadow.
import QtQuick
import QtQuick.Effects

Item {
    id: root

    component BorderGroup: QtObject {
        property real width: 0
        property color color: "transparent"
    }
    component ShadowGroup: QtObject {
        property real size: 0
        property real xOffset: 0
        property real yOffset: 0
        property color color: "black"
    }

    property real radius: 0
    property color color: "white"
    readonly property BorderGroup border: BorderGroup {}
    readonly property ShadowGroup shadow: ShadowGroup {}

    Rectangle {
        id: shape
        anchors.fill: parent
        radius: root.radius
        color: root.color
        border.width: root.border.width
        border.color: root.border.color
        visible: false
        layer.enabled: true
    }

    MultiEffect {
        anchors.fill: shape
        source: shape
        autoPaddingEnabled: true
        shadowEnabled: root.shadow.size > 0
        shadowColor: root.shadow.color
        shadowBlur: 1.0
        blurMax: Math.max(1, root.shadow.size)
        shadowHorizontalOffset: root.shadow.xOffset
        shadowVerticalOffset: root.shadow.yOffset
    }
}
