/*
 * Snap Assist, like Windows 11: the free zone fills with frosted glass and
 * offers the other windows as cards. Each card has the app's icon and the
 * window's title on top and its thumbnail below. Hovering a card lights it
 * up and shows a close button (red under the cursor); arrow keys move a
 * Windows focus rectangle; Enter or a click picks the window; Escape or a
 * click anywhere else closes Snap Assist. Cards fade and grow in.
 *
 * The window is exactly the zone (inset like the drop preview), so KWin's
 * blur effect can blur the whole window (kwin_blur, see SlotOutline.qml).
 */
import QtQuick
import org.kde.kwin as KWinComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

// A PlasmaCore.Dialog (like KZones uses) shows up reliably from a KWin
// script on Plasma 6; a plain QtQuick Window did not appear at all.
PlasmaCore.Dialog {
    id: assist

    // User options (Config.qml) and the Windows 11 look (Fluent.qml).
    required property QtObject cfg
    required property QtObject fluent

    // Ask KWin's blur effect to blur behind the whole window.
    property rect kwin_blur: Qt.rect(0, 0, 0, 0)

    // The free zone to fill: { rect, quickTile, output }.
    property var slot: null
    // Windows offered.
    property var candidates: []
    // The zone on screen (inset), which is also the window's geometry.
    property rect zone: Qt.rect(0, 0, 0, 0)
    // Losing focus closes Snap Assist, but only once it has been open for a
    // moment: right after a drag KWin hands focus back to the dragged window.
    property double openedAt: 0
    readonly property int focusGraceMs: 600
    // Closing a window from a card makes KWin activate another one; that
    // must not count as "clicked elsewhere" (see main.qml windowActivated).
    property double ignoreActivationUntil: 0

    // Card selected by hover or keyboard, -1 for none. Like Windows, the
    // focus rectangle only shows when the keyboard selected it.
    property int currentIndex: -1
    property bool keyboardNav: false

    // Card metrics (px, as in Windows at 100 %).
    readonly property int cardPadding: 8
    readonly property int headerHeight: 32
    readonly property int iconSize: 16
    readonly property int cardSpacing: 16
    readonly property int edgeMargin: 24
    readonly property int maxThumbWidth: cfg.assistMaxCardWidth
    // Height / width of a thumbnail box: the shape of the zone's screen.
    property real thumbRatio: 9 / 16
    readonly property var grid: computeGrid(candidates.length, zone.width - 2 * edgeMargin,
                                            zone.height - 2 * edgeMargin)

    signal picked(var window, var slot)

    function moveSelection(step) {
        const n = candidates.length;
        if (n === 0)
            return;
        keyboardNav = true;
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
        x = zone.x;
        y = zone.y;
    }

    function open(s, c) {
        const area = KWinComponents.Workspace.clientArea(KWinComponents.KWin.MaximizeArea, s.output,
                                                         KWinComponents.Workspace.currentDesktop);
        slot = s;
        zone = fluent.zoneRect(s.rect, area);
        currentIndex = -1;
        keyboardNav = false;
        const g = s.output ? s.output.geometry : null;
        thumbRatio = g && g.width > 0 ? g.height / g.width : 9 / 16;
        candidates = c;
        openedAt = Date.now();
        visible = true;
        // A Dialog re-centers itself when shown, so position it afterwards
        // (and once more in refocusTimer, after it got its final size).
        place();
        raise();
        requestActivate();
        content.forceActiveFocus();
        backdropFade.restart();
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
    // whose shape is closest to the zone's, so cards spread out instead of
    // stacking.
    function computeGrid(n, availW, availH) {
        const padW = 2 * cardPadding;
        const padH = headerHeight + cardPadding;
        let best = { "cols": 1, "thumbWidth": 0, "cellWidth": 0, "cellHeight": 0, "shapeError": Infinity };
        const zoneShape = availW / Math.max(1, availH);
        for (let cols = 1; cols <= Math.max(1, n); cols++) {
            const rows = Math.ceil(n / cols);
            const byWidth = (availW - (cols - 1) * cardSpacing) / cols - padW;
            const byHeight = ((availH - (rows - 1) * cardSpacing) / rows - padH) / thumbRatio;
            const tw = Math.floor(Math.min(byWidth, byHeight, maxThumbWidth));
            if (tw <= 0)
                continue;
            const cw = tw + padW;
            const ch = Math.round(tw * thumbRatio) + padH;
            const shapeError = Math.abs(Math.log((cols * cw) / Math.max(1, rows * ch) / zoneShape));
            if (tw > best.thumbWidth || (tw === best.thumbWidth && shapeError < best.shapeError))
                best = { "cols": cols, "thumbWidth": tw, "cellWidth": cw, "cellHeight": ch, "shapeError": shapeError };
        }
        return best;
    }

    // Card i on screen.
    function cardRect(i) {
        const cols = grid.cols;
        const rows = Math.ceil(candidates.length / cols);
        const gw = cols * grid.cellWidth + (cols - 1) * cardSpacing;
        const gh = rows * grid.cellHeight + (rows - 1) * cardSpacing;
        const x0 = zone.x + Math.round((zone.width - gw) / 2);
        const y0 = zone.y + Math.round((zone.height - gh) / 2);
        return Qt.rect(x0 + (i % cols) * (grid.cellWidth + cardSpacing),
                       y0 + Math.floor(i / cols) * (grid.cellHeight + cardSpacing),
                       grid.cellWidth, grid.cellHeight);
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
        width: assist.zone.width
        height: assist.zone.height

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

        // The zone's frosted glass. Clicking it (not a card) closes.
        Rectangle {
            id: backdrop

            anchors.fill: parent
            radius: assist.fluent.overlayRadius
            color: assist.fluent.glassFill
            border.width: 1
            border.color: assist.fluent.glassStroke

            NumberAnimation {
                id: backdropFade

                target: backdrop
                property: "opacity"
                from: assist.fluent.durFast > 0 ? 0 : 1
                to: 1
                duration: assist.fluent.durFast
                easing.type: Easing.Bezier
                easing.bezierCurve: assist.fluent.decelerate
            }

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
                spacing: assist.cardSpacing

                Repeater {
                    model: assist.candidates

                    // One window, as in Windows 11: icon and title on top,
                    // the thumbnail below.
                    delegate: Item {
                        id: card

                        required property var modelData
                        required property int index
                        readonly property bool selected: assist.currentIndex === index

                        width: assist.grid.cellWidth
                        height: assist.grid.cellHeight
                        opacity: assist.fluent.durFast > 0 ? 0 : 1
                        scale: assist.fluent.durFast > 0 ? 0.9 : 1

                        Accessible.name: card.modelData.caption
                        Accessible.role: Accessible.ListItem

                        // Fade and grow in.
                        ParallelAnimation {
                            running: assist.fluent.durFast > 0
                            NumberAnimation {
                                target: card
                                property: "opacity"
                                to: 1
                                duration: assist.fluent.durFast
                                easing.type: Easing.Bezier
                                easing.bezierCurve: assist.fluent.decelerate
                            }
                            NumberAnimation {
                                target: card
                                property: "scale"
                                to: 1
                                duration: assist.fluent.durFast
                                easing.type: Easing.Bezier
                                easing.bezierCurve: assist.fluent.decelerate
                            }
                        }

                        // Hover / selection background.
                        Rectangle {
                            anchors.fill: parent
                            radius: assist.fluent.overlayRadius
                            color: cardMouse.pressed ? assist.fluent.subtlePressed
                                 : card.selected ? assist.fluent.subtleHover : "transparent"
                        }

                        // Windows' focus rectangle: 2 px outer, 1 px inner,
                        // just outside the card.
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -3
                            radius: assist.fluent.overlayRadius + 3
                            color: "transparent"
                            border.width: 2
                            border.color: assist.fluent.focusOuter
                            visible: card.selected && assist.keyboardNav

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 2
                                radius: assist.fluent.overlayRadius + 1
                                color: "transparent"
                                border.width: 1
                                border.color: assist.fluent.focusInner
                            }
                        }

                        MouseArea {
                            id: cardMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            // Like Windows, using the mouse hides the
                            // focus rectangle.
                            onEntered: {
                                assist.keyboardNav = false;
                                assist.currentIndex = card.index;
                            }
                            onPositionChanged: {
                                assist.keyboardNav = false;
                                assist.currentIndex = card.index;
                            }
                            // The highlight follows the pointer off the card
                            // (a keyboard selection stays).
                            onExited: {
                                if (!assist.keyboardNav && assist.currentIndex === card.index
                                        && !closeMouse.containsMouse)
                                    assist.currentIndex = -1;
                            }
                            onClicked: assist.picked(card.modelData, assist.slot)
                        }

                        Kirigami.Icon {
                            x: assist.cardPadding
                            y: Math.round((assist.headerHeight - height) / 2)
                            width: assist.iconSize
                            height: assist.iconSize
                            source: card.modelData.icon
                        }

                        Text {
                            x: assist.cardPadding + assist.iconSize + 8
                            width: (closeButton.visible ? closeButton.x - 4 : card.width - assist.cardPadding) - x
                            height: assist.headerHeight
                            verticalAlignment: Text.AlignVCenter
                            text: card.modelData.caption
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            color: assist.fluent.textPrimary
                            font.family: assist.fluent.fontFamily
                            font.pixelSize: assist.fluent.captionSize
                        }

                        // The window's thumbnail; minimized windows have no
                        // live content, so they show their icon.
                        Item {
                            x: assist.cardPadding
                            y: assist.headerHeight
                            width: card.width - 2 * assist.cardPadding
                            height: card.height - assist.headerHeight - assist.cardPadding

                            KWinComponents.WindowThumbnail {
                                anchors.fill: parent
                                wId: card.modelData.internalId
                                visible: !card.modelData.minimized
                            }

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: Kirigami.Units.iconSizes.huge
                                height: width
                                source: card.modelData.icon
                                visible: card.modelData.minimized
                            }
                        }

                        // Close button: top right, on the selected card. Red
                        // under the cursor, like a window's close button.
                        Rectangle {
                            id: closeButton

                            width: 32
                            height: 24
                            x: card.width - width - 4
                            y: Math.round((assist.headerHeight - height) / 2)
                            radius: assist.fluent.controlRadius
                            visible: card.selected || cardMouse.containsMouse || closeMouse.containsMouse
                            color: closeMouse.pressed ? assist.fluent.closePressed
                                 : closeMouse.containsMouse ? assist.fluent.closeHover : "transparent"

                            Accessible.name: "Close " + card.modelData.caption
                            Accessible.role: Accessible.Button

                            // The thin X of Windows' close glyph.
                            Repeater {
                                model: [45, -45]
                                Rectangle {
                                    required property var modelData
                                    anchors.centerIn: parent
                                    width: 14
                                    height: 1
                                    antialiasing: true
                                    rotation: modelData
                                    color: closeMouse.containsMouse ? "#FFFFFF" : assist.fluent.textPrimary
                                }
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
