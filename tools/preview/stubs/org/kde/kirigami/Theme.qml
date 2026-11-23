// Stub of Kirigami.Theme: the system colors. Sim.setDark() switches between
// Breeze Dark and Breeze Light.
pragma Singleton
import QtQuick

QtObject {
    property color backgroundColor: "#202326"
    property color textColor: "#fcfcfc"
    property color highlightColor: "#3daee9"
    property color highlightedTextColor: "#fcfcfc"
    property font defaultFont: Qt.font({ "family": "Noto Sans", "pointSize": 10 })
    property font smallFont: Qt.font({ "family": "Noto Sans", "pointSize": 8 })
}
