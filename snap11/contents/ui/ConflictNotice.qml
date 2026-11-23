/*
 * Notice in the bottom right corner while KDE's own edge snapping is still on
 * (it would show its own outline next to Snap11's). It goes away by itself
 * once both KDE options are off; the close button hides it until the next
 * login.
 *
 * Styled like a Windows 11 notification toast: the app's icon and name on
 * top, a close button that shows on hover, a semibold title and the text.
 */
import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

PlasmaCore.Dialog {
    id: notice

    // The Windows 11 look (Fluent.qml).
    required property QtObject fluent

    // Which KDE options are still on.
    property bool maximizeOn: false
    property bool tilingOn: false
    // Hidden with the close button, for this session.
    property bool dismissed: false
    property rect area: Qt.rect(0, 0, 0, 0)

    // A Windows toast: 364 px wide, 16 px padding, 12 px from the corner.
    readonly property int toastWidth: 364
    readonly property int padding: 16
    readonly property int margin: 12
    readonly property int shadowMargin: 32

    // The toast on screen (the window is larger, for the shadow).
    function surfaceRect() {
        return Qt.rect(x + shadowMargin, y + shadowMargin, toastWidth, toast.height);
    }

    function place() {
        // Bottom right, where notifications show, so it never covers
        // window buttons at the top.
        x = area.x + area.width - margin - toastWidth - shadowMargin;
        y = area.y + area.height - margin - toast.height - shadowMargin;
    }

    function update(workArea, maximize, tiling) {
        area = workArea;
        maximizeOn = maximize;
        tilingOn = tiling;
        const show = (maximize || tiling) && !dismissed;
        if (show && !visible) {
            visible = true;
            // A Dialog re-centers itself when shown, so position it afterwards.
            place();
        } else if (show) {
            place();
        } else if (!show && visible) {
            visible = false;
        }
    }

    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus
    location: PlasmaCore.Types.Floating
    backgroundHints: PlasmaCore.Types.NoBackground
    type: PlasmaCore.Dialog.Normal
    visible: false

    // The text changes height when an option is switched; keep the corner.
    onHeightChanged: if (visible) place()

    Item {
        width: notice.toastWidth + 2 * notice.shadowMargin
        height: toast.height + 2 * notice.shadowMargin

        Rectangle {
            id: background

            x: notice.shadowMargin
            y: notice.shadowMargin
            width: notice.toastWidth
            height: toast.height
            radius: notice.fluent.overlayRadius
            color: notice.fluent.flyoutFill
            border.width: 1
            border.color: notice.fluent.flyoutStroke
            visible: false
            layer.enabled: true
        }

        MultiEffect {
            anchors.fill: background
            source: background
            autoPaddingEnabled: true
            shadowEnabled: true
            shadowColor: notice.fluent.shadowColor
            shadowBlur: 1.0
            shadowVerticalOffset: 8
            blurMax: 32
        }

        Item {
            id: toast

            x: notice.shadowMargin
            y: notice.shadowMargin
            width: notice.toastWidth
            height: column.implicitHeight + 2 * notice.padding

            // Hover shows the close button, like a Windows toast.
            MouseArea {
                id: toastMouse

                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }

            Column {
                id: column

                x: notice.padding
                y: notice.padding
                width: notice.toastWidth - 2 * notice.padding
                spacing: 4

                // App icon and name.
                Item {
                    width: parent.width
                    height: 24

                    Kirigami.Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        source: "preferences-system-windows-effect"
                    }

                    Text {
                        x: 24
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Snap11"
                        color: notice.fluent.textSecondary
                        font.family: notice.fluent.fontFamily
                        font.pixelSize: notice.fluent.captionSize
                    }

                    Rectangle {
                        id: closeButton

                        width: 32
                        height: 24
                        x: parent.width - width + 8
                        radius: notice.fluent.controlRadius
                        visible: toastMouse.containsMouse || closeMouse.containsMouse
                        color: closeMouse.pressed ? notice.fluent.subtlePressed
                             : closeMouse.containsMouse ? notice.fluent.subtleHover : "transparent"

                        Accessible.name: "Hide until next login"
                        Accessible.role: Accessible.Button

                        // The thin X of Windows' close glyph.
                        Repeater {
                            model: [45, -45]
                            Rectangle {
                                required property var modelData
                                anchors.centerIn: parent
                                width: 12
                                height: 1
                                antialiasing: true
                                rotation: modelData
                                color: notice.fluent.textSecondary
                            }
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

                Item {
                    width: 1
                    height: 4
                }

                Text {
                    width: parent.width
                    text: "KDE's own edge snapping is on"
                    textFormat: Text.PlainText
                    wrapMode: Text.WordWrap
                    color: notice.fluent.textPrimary
                    font.family: notice.fluent.fontFamily
                    font.pixelSize: notice.fluent.bodySize
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width
                    textFormat: Text.PlainText
                    wrapMode: Text.WordWrap
                    color: notice.fluent.textPrimary
                    font.family: notice.fluent.fontFamily
                    font.pixelSize: notice.fluent.bodySize
                    lineHeight: 1.1
                    text: "Snap11 and KDE would both show a drop preview. In System Settings > Screen Edges, turn off:"
                          + (notice.maximizeOn ? "\n• Maximize: Drag windows to top edge" : "")
                          + (notice.tilingOn ? "\n• Tile: Drag windows to the left or right edge" : "")
                }

                Text {
                    width: parent.width
                    textFormat: Text.PlainText
                    wrapMode: Text.WordWrap
                    color: notice.fluent.textSecondary
                    font.family: notice.fluent.fontFamily
                    font.pixelSize: notice.fluent.captionSize
                    text: "This message goes away by itself."
                }
            }
        }
    }
}
