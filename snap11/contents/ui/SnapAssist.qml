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

    // Closing a window from a card makes KWin activate another one; that
    // must not count as "clicked elsewhere" (see main.qml windowActivated).
    property double ignoreActivationUntil: 0

    // Card selected by hover or keyboard, -1 for none.
    property int currentIndex: -1

    signal picked(var window, var slot)

    function moveSelection(step) {
        const n = candidates.length;
        if (n === 0)
            return;
        if (currentIndex < 0)
            currentIndex = step < 0 ? n - 1 : 0;
        else
            currentIndex = Math.max(0, Math.min(n - 1, currentIndex + step));
    }

    function pickSelected() {
        if (currentIndex >= 0 && currentIndex < candidates.length)
            picked(candidates[currentIndex], slot);
    }

    // Close a window from its card (the X button), like in Windows.
    function closeCandidate(w) {
        console.info("snap11: closing '" + w.caption + "' from the picker");
        ignoreActivationUntil = Date.now() + 1000;
        w.closeWindow();
        candidates = candidates.filter(function(c) { return c !== w; });
        currentIndex = Math.min(currentIndex, candidates.length - 1);
        if (candidates.length === 0)
            dismiss("no windows left");
    }

    function open(s, c) {
        slot = s;
        candidates = c;
        currentIndex = -1;
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
            Keys.onLeftPressed: assist.moveSelection(-1)
            Keys.onRightPressed: assist.moveSelection(1)
            Keys.onUpPressed: assist.moveSelection(-assist.grid.cols)
            Keys.onDownPressed: assist.moveSelection(assist.grid.cols)
            Keys.onTabPressed: assist.moveSelection(1)
            Keys.onBacktabPressed: assist.moveSelection(-1)
            Keys.onReturnPressed: assist.pickSelected()
            Keys.onEnterPressed: assist.pickSelected()

            Grid {
                anchors.centerIn: parent
                columns: assist.grid.cols
                spacing: assist.gap

                Repeater {
                    model: assist.candidates

                    // One window, Windows 11 style: icon and title on top,
                    // thumbnail below. Hover (or the keyboard) selects it; a
                    // selected card is lit and shows a close button.
                    delegate: Rectangle {
                        id: card

                        required property var modelData
                        required property int index
                        readonly property bool selected: assist.currentIndex === index
                        readonly property int thumbHeight: Math.round(width * assist.thumbRatio)
                        readonly property color hl: assist.cfg.highlightColor

                        width: assist.grid.cardWidth
                        height: thumbHeight + assist.labelHeight
                        radius: Math.round(assist.cfg.cornerRadius * 5 / 6)
                        color: selected ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.06)
                        border.color: selected ? Qt.rgba(hl.r, hl.g, hl.b, 0.9) : "transparent"
                        border.width: 2

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        // Header: icon and title.
                        Row {
                            x: 10
                            y: Math.round((assist.labelHeight - 18) / 2) + 2
                            width: parent.width - 20 - (closeButton.visible ? closeButton.width + 4 : 0)
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

                        Item {
                            x: 8
                            y: assist.labelHeight
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

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: assist.currentIndex = card.index
                            onClicked: assist.picked(card.modelData, assist.slot)
                        }

                        // Close button, top right, only on the selected card.
                        Rectangle {
                            id: closeButton

                            width: 24
                            height: 24
                            x: parent.width - width - 6
                            y: Math.round((assist.labelHeight - height) / 2) + 2
                            radius: 6
                            visible: card.selected
                            color: closeMouse.containsMouse ? "#c42b1c" : Qt.rgba(1, 1, 1, 0.12)

                            Text {
                                anchors.centerIn: parent
                                text: "\u2715"
                                color: "white"
                                font.pixelSize: 12
                            }

                            MouseArea {
                                id: closeMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: assist.closeCandidate(card.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
