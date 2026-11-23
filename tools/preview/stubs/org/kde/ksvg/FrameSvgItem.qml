// Minimal stub: a translucent frame. Only the 1.3 overlays use KSvg.
import QtQuick

Rectangle {
    enum EnabledBorder { NoBorder = 0, TopBorder = 1, BottomBorder = 2, LeftBorder = 4, RightBorder = 8, AllBorders = 15 }
    property string imagePath
    property var prefix
    property int enabledBorders: 15
    readonly property QtObject margins: QtObject {
        property int left: 6
        property int top: 6
        property int right: 6
        property int bottom: 6
    }
    color: Qt.rgba(1, 1, 1, 0.15)
    border.color: Qt.rgba(1, 1, 1, 0.3)
    radius: 4
}
