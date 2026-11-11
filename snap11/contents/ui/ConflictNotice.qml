/*
 * Notice in the bottom right corner while KDE's own edge snapping is still on
 * (it would show its own outline next to Snap11's). It goes away by itself
 * once both KDE options are off; the close button hides it until the next
 * login.
 *
 * Styled like a Plasma notification popup: the theme's dialog frame, a
 * warning icon, a heading and Plasma's own close button.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents3

PlasmaCore.Dialog {
    id: notice

    // Which KDE options are still on.
    property bool maximizeOn: false
    property bool tilingOn: false
    // Hidden with the close button, for this session.
    property bool dismissed: false

    // Width of a Plasma notification popup.
    readonly property int boxWidth: Kirigami.Units.gridUnit * 18
    readonly property int margin: Kirigami.Units.largeSpacing
    property rect area: Qt.rect(0, 0, 0, 0)

    function place() {
        // Bottom right, where Plasma shows notifications, so it never
        // covers window buttons at the top.
        x = area.x + area.width - width - margin;
        y = area.y + area.height - height - margin;
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
    backgroundHints: PlasmaCore.Types.StandardBackground
    type: PlasmaCore.Dialog.Normal
    visible: false

    // The text changes height when an option is switched; keep the corner.
    onHeightChanged: if (visible) place()

    Item {
        width: notice.boxWidth
        height: layout.implicitHeight

        RowLayout {
            id: layout

            width: parent.width
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Icon {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: Kirigami.Units.iconSizes.large
                Layout.preferredHeight: Kirigami.Units.iconSizes.large
                source: "dialog-warning"
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Heading {
                        Layout.fillWidth: true
                        level: 4
                        text: "KDE's own edge snapping is on"
                        wrapMode: Text.WordWrap
                        textFormat: Text.PlainText
                    }

                    PlasmaComponents3.ToolButton {
                        Layout.alignment: Qt.AlignTop
                        icon.name: "window-close-symbolic"
                        display: QQC2.AbstractButton.IconOnly
                        text: "Hide until next login"
                        onClicked: {
                            notice.dismissed = true;
                            notice.visible = false;
                        }
                    }
                }

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    textFormat: Text.PlainText
                    text: "Snap11 and KDE would both show a drop preview. In System Settings > Screen Edges, turn off:"
                          + (notice.maximizeOn ? "\n• Maximize: Drag windows to top edge" : "")
                          + (notice.tilingOn ? "\n• Tile: Drag windows to the left or right edge" : "")
                }

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    textFormat: Text.PlainText
                    opacity: 0.7
                    font: Kirigami.Theme.smallFont
                    text: "This message goes away by itself."
                }
            }
        }
    }
}
