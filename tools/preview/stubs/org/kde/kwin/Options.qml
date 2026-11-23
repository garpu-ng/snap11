// Stub of KWin's Options: KDE's own edge snapping switches.
pragma Singleton
import QtQuick

QtObject {
    property bool electricBorderMaximize: false
    property bool electricBorderTiling: false
    signal configChanged()
}
