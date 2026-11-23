pragma Singleton
import QtQuick

QtObject {
    enum Location { Floating, Desktop, FullScreen, TopEdge, BottomEdge, LeftEdge, RightEdge }
    enum BackgroundHints { NoBackground, StandardBackground, TranslucentBackground }
}
