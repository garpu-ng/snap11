/*
 * The snap layout bar at the top of the screen.
 *
 * Looks like KWin's own popups (the virtual desktop switch OSD): a Plasma
 * dialog frame with the theme's blur, contrast and shadow, and each layout
 * drawn with the theme's pager tiles ("widgets/pager"), the same ones the
 * Pager widget and the desktop OSD use. The slot under the cursor uses the
 * pager's hover look plus the system accent color.
 *
 * It only draws (outputOnly): while a window is being dragged the pointer
 * is grabbed by KWin, so hover is worked out from the cursor position in
 * hitTest() instead of with MouseAreas.
 */
import QtQuick
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

PlasmaCore.Dialog {
    id: bar

    // User options (Config.qml).
    required property QtObject cfg

    // Layouts offered, each a list of slots in screen fractions.
    // quickTile: use KDE's native quick tiling for that slot.
    readonly property var layouts: buildLayouts()

    function buildLayouts() {
        const list = [];
        if (cfg.layoutHalves)
            list.push([
                { "x": 0, "y": 0, "w": 1 / 2, "h": 1, "quickTile": "left" },
                { "x": 1 / 2, "y": 0, "w": 1 / 2, "h": 1, "quickTile": "right" }
            ]);
        if (cfg.layoutThirds)
            list.push([
                { "x": 0, "y": 0, "w": 1 / 3, "h": 1 },
                { "x": 1 / 3, "y": 0, "w": 1 / 3, "h": 1 },
                { "x": 2 / 3, "y": 0, "w": 1 / 3, "h": 1 }
            ]);
        if (cfg.layoutTwoThirdsLeft)
            list.push([
                { "x": 0, "y": 0, "w": 2 / 3, "h": 1 },
                { "x": 2 / 3, "y": 0, "w": 1 / 3, "h": 1 }
            ]);
        if (cfg.layoutTwoThirdsRight)
            list.push([
                { "x": 0, "y": 0, "w": 1 / 3, "h": 1 },
                { "x": 1 / 3, "y": 0, "w": 2 / 3, "h": 1 }
            ]);
        if (cfg.layoutQuarters)
            list.push([
                { "x": 0, "y": 0, "w": 1 / 2, "h": 1 / 2 },
                { "x": 1 / 2, "y": 0, "w": 1 / 2, "h": 1 / 2 },
                { "x": 0, "y": 1 / 2, "w": 1 / 2, "h": 1 / 2 },
                { "x": 1 / 2, "y": 1 / 2, "w": 1 / 2, "h": 1 / 2 }
            ]);
        return list;
    }

    // Sizes follow Plasma's spacing units, so they scale with the font.
    readonly property int previewWidth: cfg.previewWidth
    readonly property int previewHeight: cfg.previewHeight
    readonly property int spacing: Kirigami.Units.largeSpacing
    readonly property int slotGap: Kirigami.Units.smallSpacing
    readonly property int topMargin: Kirigami.Units.largeSpacing
    // Content size, and the whole window with the theme's frame around it.
    readonly property int contentWidth: layouts.length * previewWidth + Math.max(0, layouts.length - 1) * spacing
    readonly property int contentHeight: previewHeight
    readonly property int barWidth: bar.margins.left + contentWidth + bar.margins.right
    readonly property int barHeight: bar.margins.top + contentHeight + bar.margins.bottom

    // Screen area the bar belongs to, and the slot under the cursor.
    property rect area: Qt.rect(0, 0, 0, 0)
    property var output: null
    property int hoveredLayout: -1
    property int hoveredSlot: -1

    function barX() {
        return Math.round(area.x + (area.width - barWidth) / 2);
    }

    function place() {
        x = barX();
        y = area.y + topMargin;
    }

    function showOn(workArea, screen) {
        area = workArea;
        output = screen;
        hoveredLayout = -1;
        hoveredSlot = -1;
        visible = true;
        // Position after showing; a Dialog re-centers itself when shown.
        place();
    }

    // Put the bar back on top of other overlays. raise() does nothing for
    // KWin's own windows, but showing a window again stacks it on top.
    function bringToFront() {
        if (!visible)
            return;
        visible = false;
        visible = true;
        place();
    }

    function hide() {
        visible = false;
        hoveredLayout = -1;
        hoveredSlot = -1;
    }

    // Is the cursor close enough to the bar to keep it open?
    function isNear(p) {
        const bx = barX();
        return p.y <= area.y + topMargin + barHeight + 60
            && p.x >= bx - 120 && p.x <= bx + barWidth + 120;
    }

    // Update which slot is under the global point p.
    function hitTest(p) {
        const bx = barX() + bar.margins.left;
        const top = area.y + topMargin;
        const py = top + bar.margins.top;
        hoveredLayout = -1;
        hoveredSlot = -1;
        for (let li = 0; li < layouts.length; li++) {
            const px = bx + li * (previewWidth + spacing);
            // The frame above and below counts as the nearest slot row.
            if (p.x < px || p.x >= px + previewWidth || p.y < top || p.y >= top + barHeight)
                continue;
            const fx = (p.x - px) / previewWidth;
            const fy = Math.min(0.999, Math.max(0, (p.y - py) / previewHeight));
            const slots = layouts[li];
            for (let si = 0; si < slots.length; si++) {
                const s = slots[si];
                if (fx >= s.x && fx < s.x + s.w && fy >= s.y && fy < s.y + s.h) {
                    hoveredLayout = li;
                    hoveredSlot = si;
                    return;
                }
            }
        }
    }

    // Slot li/si as a screen rect inside the bar's work area.
    function slotRect(li, si) {
        const s = layouts[li][si];
        const x0 = Math.round(area.x + s.x * area.width);
        const x1 = Math.round(area.x + (s.x + s.w) * area.width);
        const y0 = Math.round(area.y + s.y * area.height);
        const y1 = Math.round(area.y + (s.y + s.h) * area.height);
        return Qt.rect(x0, y0, x1 - x0, y1 - y0);
    }

    function slot(li, si) {
        return { "rect": slotRect(li, si), "quickTile": layouts[li][si].quickTile || "", "output": output };
    }

    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus
    location: PlasmaCore.Types.Floating
    // The theme's own dialog frame: blur, contrast and shadow included.
    backgroundHints: PlasmaCore.Types.StandardBackground
    type: PlasmaCore.Dialog.Normal
    outputOnly: true
    visible: false

    Item {
        width: bar.contentWidth
        height: bar.contentHeight

        Row {
            spacing: bar.spacing

            Repeater {
                model: bar.layouts.length

                delegate: Item {
                    id: preview

                    required property int index
                    readonly property var slots: bar.layouts[index]

                    width: bar.previewWidth
                    height: bar.previewHeight

                    Repeater {
                        model: preview.slots.length

                        delegate: Item {
                            id: tile

                            required property int index
                            readonly property var s: preview.slots[index]
                            readonly property bool hovered: bar.hoveredLayout === preview.index
                                                            && bar.hoveredSlot === index

                            // Half a gap on each inner edge, none on the outer edges.
                            x: Math.round(s.x * preview.width) + (s.x > 0 ? bar.slotGap / 2 : 0)
                            y: Math.round(s.y * preview.height) + (s.y > 0 ? bar.slotGap / 2 : 0)
                            width: Math.round(s.w * preview.width) - (s.x > 0 ? bar.slotGap / 2 : 0)
                                   - (s.x + s.w < 1 ? bar.slotGap / 2 : 0)
                            height: Math.round(s.h * preview.height) - (s.y > 0 ? bar.slotGap / 2 : 0)
                                    - (s.y + s.h < 1 ? bar.slotGap / 2 : 0)

                            // Accent fill under the hovered tile, shaped like
                            // the theme's tile (inset by its frame margins).
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: Kirigami.Units.cornerRadius / 2
                                color: Kirigami.Theme.highlightColor
                                opacity: tile.hovered ? 0.6 : 0

                                Behavior on opacity {
                                    NumberAnimation { duration: Kirigami.Units.shortDuration }
                                }
                            }

                            KSvg.FrameSvgItem {
                                anchors.fill: parent
                                imagePath: "widgets/pager"
                                // A list: the first prefix the theme has wins.
                                prefix: tile.hovered ? ["hover", "active", "normal"] : "normal"
                            }
                        }
                    }
                }
            }
        }
    }
}
