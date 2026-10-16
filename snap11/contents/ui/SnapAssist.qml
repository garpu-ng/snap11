/*
 * The Snap Assist picker: a window covering the free slot, showing the
 * other windows as clickable thumbnails, centered in the slot.
 */
import QtQuick
import org.kde.kwin as KWinComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

// A PlasmaCore.Dialog (like KZones uses) shows up reliably from a KWin
// script on Plasma 6; a plain QtQuick Window did not appear at all.
PlasmaCore.Dialog {
    id: assist

    // The free slot to fill: { rect, quickTile }.
    property var slot: null
    // Windows offered in the picker.
    property var candidates: []
    // Losing focus closes the picker, but only once it has been open for a
    // moment: right after a drag KWin hands focus back to the dragged window.
    property double openedAt: 0
    readonly property int focusGraceMs: 600

    // User options (Config.qml).
    required property QtObject cfg


    // No margin: the blur covers the whole window, so the backdrop has to
    // fill it too, or the blur would show around its edges.
    readonly property int outerMargin: 0
    readonly property int gap: 16
    readonly property int labelHeight: 30
    readonly property real thumbRatio: 0.6
    readonly property int maxCardWidth: cfg.assistMaxCardWidth
    // Size of the slot; the dialog sizes itself to its content item.
    property int slotWidth: 0
    property int slotHeight: 0
    readonly property var grid: computeGrid(candidates.length,
                                            slotWidth - 2 * outerMargin - 2 * gap,
                                            slotHeight - 2 * outerMargin - 2 * gap)

    signal picked(var window, var slot)

    function open(s, c) {
        slot = s;
        candidates = c;
        slotWidth = s.rect.width;
        slotHeight = s.rect.height;
        openedAt = Date.now();
        visible = true;
        // A Dialog re-centers itself when shown, so position it afterwards
        // (and once more in refocusTimer, after it got its final size).
        x = s.rect.x;
        y = s.rect.y;
        raise();
        requestActivate();
        content.forceActiveFocus();
        // Ask again once KWin has settled the end of the drag.
        refocusTimer.restart();
        console.info("snap11: assist open at " + x + "," + y + " " + width + "x" + height);
    }

    function dismiss(reason) {
        if (!visible)
            return;
        console.info("snap11: assist closed (" + (reason || "picked") + ")");
        visible = false;
        candidates = [];
    }

    // Pick the column count that gives the largest cards that still fit.
    // Ties (cards already at maxCardWidth) go to the grid whose shape is
    // closest to the slot's shape, so cards spread out instead of stacking.
    function computeGrid(n, availW, availH) {
        let best = { "cols": 1, "cardWidth": 0, "shapeError": Infinity };
        const slotShape = availW / Math.max(1, availH);
        for (let cols = 1; cols <= Math.max(1, n); cols++) {
            const rows = Math.ceil(n / cols);
            const byWidth = (availW - (cols - 1) * gap) / cols;
            const byHeight = ((availH - (rows - 1) * gap) / rows - labelHeight) / thumbRatio;
            const w = Math.floor(Math.min(byWidth, byHeight, maxCardWidth));
            const gridShape = (cols * w) / Math.max(1, rows * (w * thumbRatio + labelHeight));
            const shapeError = Math.abs(Math.log(gridShape / slotShape));
            if (w > best.cardWidth || (w === best.cardWidth && shapeError < best.shapeError))
                best = { "cols": cols, "cardWidth": w, "shapeError": shapeError };
        }
        return best;
    }

    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    location: PlasmaCore.Types.Floating
    backgroundHints: PlasmaCore.Types.NoBackground
    type: PlasmaCore.Dialog.Normal
    visible: false

    onActiveChanged: {
        if (!active && visible && Date.now() - openedAt > focusGraceMs)
            dismiss("lost focus");
    }

    // The dialog's only child is its content item.
    Item {
        width: assist.slotWidth
        height: assist.slotHeight

        Timer {
            id: refocusTimer
            interval: 150
            onTriggered: {
                assist.raise();
                assist.requestActivate();
                content.forceActiveFocus();
            }
        }

        // Dimmed backdrop of the free slot. Clicking it closes the picker.
        Rectangle {
            anchors.fill: parent
            anchors.margins: assist.outerMargin
            radius: assist.cfg.cornerRadius
            color: Qt.rgba(0.08, 0.08, 0.1, assist.cfg.assistDim / 100)
            border.color: Qt.rgba(1, 1, 1, 0.12)
            border.width: 1

            MouseArea {
                anchors.fill: parent
                onClicked: assist.dismiss("clicked empty space")
            }
        }

        Item {
            id: content

            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: assist.dismiss("escape")

            Grid {
                anchors.centerIn: parent
                columns: assist.grid.cols
                spacing: assist.gap

                Repeater {
                    model: assist.candidates

                    delegate: Rectangle {
                        id: card

                        required property var modelData
                        readonly property int thumbHeight: Math.round(width * assist.thumbRatio)

                        width: assist.grid.cardWidth
                        height: thumbHeight + assist.labelHeight
                        radius: Math.round(assist.cfg.cornerRadius * 5 / 6)
                        color: mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.06)
                        border.color: mouse.containsMouse ? Kirigami.Theme.highlightColor : "transparent"
                        border.width: 2

                        Item {
                            x: 8
                            y: 8
                            width: parent.width - 16
                            height: card.thumbHeight - 8

                            KWinComponents.WindowThumbnail {
                                anchors.fill: parent
                                wId: card.modelData.internalId
                                visible: !card.modelData.minimized
                            }

                            // Minimized windows have no live content; show the icon.
                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: 64
                                height: 64
                                source: card.modelData.icon
                                visible: card.modelData.minimized
                            }
                        }

                        Row {
                            x: 10
                            y: card.thumbHeight + 4
                            width: parent.width - 20
                            spacing: 6

                            Kirigami.Icon {
                                width: 18
                                height: 18
                                source: card.modelData.icon
                            }

                            Text {
                                width: parent.width - 24
                                text: card.modelData.caption
                                color: "white"
                                elide: Text.ElideRight
                                font.pixelSize: 13
                            }
                        }

                        MouseArea {
                            id: mouse

                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: assist.picked(card.modelData, assist.slot)
                        }
                    }
                }
            }
        }
    }
}
