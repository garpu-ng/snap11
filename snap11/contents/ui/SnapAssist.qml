/*
 * The Snap Assist picker: covers the free slot and shows the other windows
 * as clickable thumbnails, centered in the slot.
 *
 * Built like KWin's own "Thumbnail Grid" task switcher
 * (kwin/src/tabbox/switchers/thumbnail_grid): a Plasma dialog frame (with
 * the theme's blur, contrast and shadow), the theme's "widgets/viewitem"
 * highlight on the selected window, the app icon over the bottom edge of the
 * thumbnail, the title below it, and Plasma's own close button.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kwin as KWinComponents
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3

// A PlasmaCore.Dialog (like KZones uses) shows up reliably from a KWin
// script on Plasma 6; a plain QtQuick Window did not appear at all.
PlasmaCore.Dialog {
    id: assist

    // The free slot to fill: { rect, quickTile, output }.
    property var slot: null
    // Windows offered in the picker.
    property var candidates: []
    // Losing focus closes the picker, but only once it has been open for a
    // moment: right after a drag KWin hands focus back to the dragged window.
    property double openedAt: 0
    readonly property int focusGraceMs: 600

    // User options (Config.qml).
    required property QtObject cfg

    // Space between the slot's edge and the frame, so the frame and its
    // shadow sit inside the slot like a floating Plasma popup.
    readonly property int outerGap: Kirigami.Units.largeSpacing
    // Size of the slot; the dialog sizes itself to its content item.
    property int slotWidth: 0
    property int slotHeight: 0
    readonly property int contentWidth: Math.max(0, slotWidth - 2 * outerGap - assist.margins.left - assist.margins.right)
    readonly property int contentHeight: Math.max(0, slotHeight - 2 * outerGap - assist.margins.top - assist.margins.bottom)

    // Card metrics, as in the Thumbnail Grid switcher.
    readonly property int iconSize: Kirigami.Units.iconSizes.huge
    readonly property int captionRowHeight: Kirigami.Units.gridUnit * 2
    readonly property int columnSpacing: Kirigami.Units.gridUnit
    readonly property int maxThumbWidth: cfg.assistMaxCardWidth
    // Height / width of a thumbnail: the shape of the slot's screen.
    property real thumbRatio: 9 / 16
    readonly property var grid: computeGrid(candidates.length,
                                            contentWidth - 2 * Kirigami.Units.largeSpacing,
                                            contentHeight - 2 * Kirigami.Units.largeSpacing)

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

    function place() {
        if (!slot)
            return;
        x = slot.rect.x + outerGap;
        y = slot.rect.y + outerGap;
    }

    function open(s, c) {
        slot = s;
        candidates = c;
        currentIndex = -1;
        slotWidth = s.rect.width;
        slotHeight = s.rect.height;
        const g = s.output ? s.output.geometry : null;
        thumbRatio = g && g.width > 0 ? g.height / g.width : 9 / 16;
        openedAt = Date.now();
        visible = true;
        // A Dialog re-centers itself when shown, so position it afterwards
        // (and once more in refocusTimer, after it got its final size).
        place();
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

    // Pick the column count that gives the largest thumbnails that still
    // fit. Ties (thumbnails already at their maximum width) go to the grid
    // whose shape is closest to the slot's shape, so cards spread out
    // instead of stacking.
    function computeGrid(n, availW, availH) {
        const mh = hoverItem.margins.left + hoverItem.margins.right;
        const mv = hoverItem.margins.top + hoverItem.margins.bottom;
        // Inside a card: the highlight's margins twice on each side (as in
        // the switcher), the thumbnail, the spacing and the caption row.
        const padW = 2 * mh;
        const padH = 2 * mv + columnSpacing + captionRowHeight;
        let best = { "cols": 1, "thumbWidth": 0, "cellWidth": 0, "cellHeight": 0, "shapeError": Infinity };
        const slotShape = availW / Math.max(1, availH);
        for (let cols = 1; cols <= Math.max(1, n); cols++) {
            const rows = Math.ceil(n / cols);
            const byWidth = availW / cols - padW;
            const byHeight = (availH / rows - padH) / thumbRatio;
            const tw = Math.floor(Math.min(byWidth, byHeight, maxThumbWidth));
            if (tw <= 0)
                continue;
            const cw = tw + padW;
            const ch = Math.round(tw * thumbRatio) + padH;
            const shapeError = Math.abs(Math.log((cols * cw) / Math.max(1, rows * ch) / slotShape));
            if (tw > best.thumbWidth || (tw === best.thumbWidth && shapeError < best.shapeError))
                best = { "cols": cols, "thumbWidth": tw, "cellWidth": cw, "cellHeight": ch, "shapeError": shapeError };
        }
        return best;
    }

    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    location: PlasmaCore.Types.Floating
    // The theme's own dialog frame: blur, contrast and shadow included.
    backgroundHints: PlasmaCore.Types.StandardBackground
    type: PlasmaCore.Dialog.Normal
    visible: false

    onActiveChanged: {
        if (!active && visible && Date.now() - openedAt > focusGraceMs)
            dismiss("lost focus");
    }

    // The dialog's only child is its content item.
    Item {
        width: assist.contentWidth
        height: assist.contentHeight

        Timer {
            id: refocusTimer
            interval: 150
            onTriggered: {
                assist.place();
                assist.raise();
                assist.requestActivate();
                content.forceActiveFocus();
            }
        }

        // Only here for its margins, like in the switcher.
        KSvg.FrameSvgItem {
            id: hoverItem
            imagePath: "widgets/viewitem"
            prefix: "hover"
            visible: false
        }

        // Clicking empty space closes the picker.
        MouseArea {
            anchors.fill: parent
            onClicked: assist.dismiss("clicked empty space")
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

                Repeater {
                    model: assist.candidates

                    // One window, as in the Thumbnail Grid switcher.
                    delegate: MouseArea {
                        id: card

                        required property var modelData
                        required property int index
                        readonly property bool selected: assist.currentIndex === index

                        width: assist.grid.cellWidth
                        height: assist.grid.cellHeight
                        hoverEnabled: true
                        onEntered: assist.currentIndex = card.index
                        onClicked: assist.picked(card.modelData, assist.slot)

                        Accessible.name: card.modelData.caption
                        Accessible.role: Accessible.ListItem

                        // The theme's highlight on the selected card.
                        KSvg.FrameSvgItem {
                            anchors.fill: parent
                            imagePath: "widgets/viewitem"
                            prefix: "hover"
                            visible: card.selected
                        }

                        ColumnLayout {
                            id: columnLayout

                            anchors.fill: parent
                            anchors.leftMargin: hoverItem.margins.left * 2
                            anchors.topMargin: hoverItem.margins.top * 2
                            anchors.rightMargin: hoverItem.margins.right * 2
                            anchors.bottomMargin: hoverItem.margins.bottom * 2
                            spacing: assist.columnSpacing

                            // WindowThumbnail needs a container, or it takes
                            // the size of the whole layout.
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                KWinComponents.WindowThumbnail {
                                    anchors.fill: parent
                                    wId: card.modelData.internalId
                                    visible: !card.modelData.minimized
                                }

                                // App icon over the bottom edge of the thumbnail;
                                // centered and on its own for minimized windows,
                                // which have no live content.
                                Kirigami.Icon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: card.modelData.minimized ? parent.verticalCenter : parent.bottom
                                    anchors.verticalCenterOffset: card.modelData.minimized ? 0 : Math.round(-assist.iconSize / 4)
                                    width: assist.iconSize
                                    height: assist.iconSize
                                    source: card.modelData.icon
                                }

                                PlasmaComponents3.Button {
                                    id: closeButton

                                    anchors {
                                        right: parent.right
                                        top: parent.top
                                        // Touch the inner edges of the highlight,
                                        // as in the switcher.
                                        rightMargin: -columnLayout.anchors.rightMargin
                                        topMargin: -columnLayout.anchors.topMargin
                                    }
                                    visible: card.selected || card.containsMouse || hovered
                                    icon.name: "window-close-symbolic"
                                    Accessible.name: "Close " + card.modelData.caption
                                    onClicked: assist.closeCandidate(card.modelData)
                                }
                            }

                            PlasmaComponents3.Label {
                                Layout.fillWidth: true
                                Layout.preferredHeight: assist.captionRowHeight
                                text: card.modelData.caption
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
