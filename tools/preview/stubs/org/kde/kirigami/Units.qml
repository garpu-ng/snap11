// Stub of Kirigami.Units with Plasma's default values.
pragma Singleton
import QtQuick

QtObject {
    property int gridUnit: 18
    property int smallSpacing: 4
    property int mediumSpacing: 6
    property int largeSpacing: 8
    property int cornerRadius: 5
    property int shortDuration: 100
    property int longDuration: 200
    property int veryLongDuration: 400
    property QtObject iconSizes: QtObject {
        property int small: 16
        property int smallMedium: 22
        property int medium: 32
        property int large: 48
        property int huge: 64
        property int enormous: 128
    }
}
