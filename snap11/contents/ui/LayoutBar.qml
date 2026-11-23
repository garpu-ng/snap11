/*
 * The snap bar at the top of the screen, like Windows 11 (22H2 and later).
 *
 * As soon as a window is dragged, a small bar slides in at the top center.
 * When the cursor reaches it, it opens up and shows the layouts; the zone
 * under the cursor fills with the accent color, and dropping the window
 * there snaps it into that zone. Moving away closes it again.
 *
 * Windows' layouts in Windows' order: 50/50, 66/33, 33/33/33, 50 + 25/25,
 * quarters, 25/50/25. Like Windows, the three-column ones only show on wide
 * screens (1920 px and up).
 *
 * It only draws (outputOnly): while a window is dragged the pointer is
 * grabbed by KWin, so hover is worked out from the cursor position in
 * track() instead of with MouseAreas.
 *
 * The window always has the size of the open bar plus room for its shadow;
 * the bar's surface grows and shrinks inside it.
 */
import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

PlasmaCore.Dialog {
    id: bar

    // User options (Config.qml) and the Windows 11 look (Fluent.qml).
    required property QtObject cfg
    required property QtObject fluent

    // Work area of the screen the bar is on, and that screen.
    property rect area: Qt.rect(0, 0, 0, 0)
    property var output: null
    // Open (showing the layouts) or collapsed.
    property bool expanded: false
    // The zone under the cursor, -1 for none.
    property int hoveredLayout: -1
    property int hoveredSlot: -1

    // Layouts offered on this screen.
    readonly property var layouts: layoutsFor(area.width)

    // Layouts for a work area this wide. Each is a list of zones in
    // fractions of the work area; quickTile names the KDE quick tile used
    // for that zone (the others use KDE's custom tiles).
    function layoutsFor(width) {
        const wide = !cfg.threeColumnsWideOnly || width >= 1920;
        const list = [];
        if (cfg.layoutHalves)
            list.push([
                { "x": 0, "y": 0, "w": 1 / 2, "h": 1, "quickTile": "left" },
                { "x": 1 / 2, "y": 0, "w": 1 / 2, "h": 1, "quickTile": "right" }
            ]);
        if (cfg.layoutTwoThirdsLeft)
            list.push([
                { "x": 0, "y": 0, "w": 2 / 3, "h": 1 },
                { "x": 2 / 3, "y": 0, "w": 1 / 3, "h": 1 }
            ]);
        if (cfg.layoutThirds && wide)
            list.push([
                { "x": 0, "y": 0, "w": 1 / 3, "h": 1 },
                { "x": 1 / 3, "y": 0, "w": 1 / 3, "h": 1 },
                { "x": 2 / 3, "y": 0, "w": 1 / 3, "h": 1 }
            ]);
        if (cfg.layoutHalfQuarters)
            list.push([
                { "x": 0, "y": 0, "w": 1 / 2, "h": 1, "quickTile": "left" },
                { "x": 1 / 2, "y": 0, "w": 1 / 2, "h": 1 / 2, "quickTile": "topRight" },
                { "x": 1 / 2, "y": 1 / 2, "w": 1 / 2, "h": 1 / 2, "quickTile": "bottomRight" }
            ]);
        if (cfg.layoutQuarters)
            list.push([
                { "x": 0, "y": 0, "w": 1 / 2, "h": 1 / 2, "quickTile": "topLeft" },
                { "x": 1 / 2, "y": 0, "w": 1 / 2, "h": 1 / 2, "quickTile": "topRight" },
                { "x": 0, "y": 1 / 2, "w": 1 / 2, "h": 1 / 2, "quickTile": "bottomLeft" },
                { "x": 1 / 2, "y": 1 / 2, "w": 1 / 2, "h": 1 / 2, "quickTile": "bottomRight" }
            ]);
        if (cfg.layoutCenterWide && wide)
            list.push([
                { "x": 0, "y": 0, "w": 1 / 4, "h": 1 },
                { "x": 1 / 4, "y": 0, "w": 1 / 2, "h": 1 },
                { "x": 3 / 4, "y": 0, "w": 1 / 4, "h": 1 }
            ]);
        // Not in Windows; an extra.
        if (cfg.layoutTwoThirdsRight)
            list.push([
                { "x": 0, "y": 0, "w": 1 / 3, "h": 1 },
                { "x": 1 / 3, "y": 0, "w": 2 / 3, "h": 1 }
            ]);
        return list;
    }

    // Metrics in px, as in Windows at 100 % scale.
    readonly property int padding: 12
    readonly property int spacing: 12
    readonly property int zoneGap: 4
    readonly property int topMargin: 8
    readonly property int shadowMargin: 32
    readonly property int previewWidth: cfg.previewWidth
    // A layout has the shape of the screen.
    readonly property int previewHeight: Math.round(previewWidth * area.height / Math.max(1, area.width))
    readonly property int expandedWidth: 2 * padding + layouts.length * previewWidth
                                         + Math.max(0, layouts.length - 1) * spacing
    readonly property int expandedHeight: 2 * padding + previewHeight
    readonly property int collapsedWidth: Math.max(120, Math.round(expandedWidth * 0.3))
    readonly property int collapsedHeight: 24

    // The open bar on screen.
    function expandedRect() {
        return Qt.rect(Math.round(area.x + (area.width - expandedWidth) / 2), area.y + topMargin,
                       expandedWidth, expandedHeight);
    }

    // The collapsed bar on screen.
    function collapsedRect() {
        return Qt.rect(Math.round(area.x + (area.width - collapsedWidth) / 2), area.y + topMargin,
                       collapsedWidth, collapsedHeight);
    }

    // Layout li in the open bar, on screen.
    function previewRect(li) {
        const e = expandedRect();
        return Qt.rect(e.x + padding + li * (previewWidth + spacing), e.y + padding, previewWidth, previewHeight);
    }

    function contains(r, p, margin) {
        return p.x >= r.x - margin && p.x < r.x + r.width + margin
            && p.y >= r.y - margin && p.y < r.y + r.height + margin;
    }

    function place() {
        x = Math.round(area.x + (area.width - expandedWidth) / 2) - shadowMargin;
        y = area.y;
    }

    // Show the collapsed bar on a screen (or move it there).
    function showOn(workArea, screen) {
        area = workArea;
        output = screen;
        expanded = false;
        hoveredLayout = -1;
        hoveredSlot = -1;
        if (!visible) {
            surface.slideIn();
            visible = true;
        }
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
        expanded = false;
        hoveredLayout = -1;
        hoveredSlot = -1;
    }

    // Follow the cursor: open when it reaches the collapsed bar, close when
    // it leaves the open one, and find the zone under it.
    function track(p) {
        if (!visible)
            return;
        if (!expanded && contains(collapsedRect(), p, topMargin))
            expanded = true;
        else if (expanded && !contains(expandedRect(), p, 2 * padding))
            expanded = false;
        hitTest(p);
    }

    // Which zone is under the global point p. The bar's padding above and
    // below a layout counts as its nearest zone, the gaps between zones as
    // the zone they belong to.
    function hitTest(p) {
        hoveredLayout = -1;
        hoveredSlot = -1;
        if (!expanded)
            return;
        const e = expandedRect();
        for (let li = 0; li < layouts.length; li++) {
            const r = previewRect(li);
            if (p.x < r.x || p.x >= r.x + r.width || p.y < e.y || p.y >= e.y + e.height)
                continue;
            const fx = (p.x - r.x) / r.width;
            const fy = Math.min(0.999, Math.max(0, (p.y - r.y) / r.height));
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

    // Zone si of layout li as a screen rect inside the bar's work area.
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
    backgroundHints: PlasmaCore.Types.NoBackground
    type: PlasmaCore.Dialog.Normal
    outputOnly: true
    visible: false

    Item {
        width: bar.expandedWidth + 2 * bar.shadowMargin
        height: bar.topMargin + bar.expandedHeight + bar.shadowMargin

        Item {
            id: surface

            // Slide down from above the screen edge, like Windows.
            function slideIn() {
                slide.stop();
                y = -bar.collapsedHeight;
                slide.start();
            }

            x: Math.round((parent.width - width) / 2)
            y: bar.topMargin
            width: bar.expanded ? bar.expandedWidth : bar.collapsedWidth
            height: bar.expanded ? bar.expandedHeight : bar.collapsedHeight

            Behavior on width {
                NumberAnimation {
                    duration: bar.fluent.durNormal
                    easing.type: Easing.Bezier
                    easing.bezierCurve: bar.fluent.decelerate
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: bar.fluent.durNormal
                    easing.type: Easing.Bezier
                    easing.bezierCurve: bar.fluent.decelerate
                }
            }

            NumberAnimation {
                id: slide

                target: surface
                property: "y"
                to: bar.topMargin
                duration: bar.fluent.durFast
                easing.type: Easing.Bezier
                easing.bezierCurve: bar.fluent.decelerate
            }

            // Flyout surface: Windows' acrylic is nearly opaque, so no blur
            // is needed; the shadow is drawn here (Kirigami's, so no extra
            // Qt module is needed).
            Kirigami.ShadowedRectangle {
                anchors.fill: parent
                radius: bar.fluent.overlayRadius
                color: bar.fluent.flyoutFill
                border.width: 1
                border.color: bar.fluent.flyoutStroke
                shadow.size: 24
                shadow.yOffset: 8
                shadow.color: bar.fluent.shadowColor
            }

            // The layouts, revealed from the middle as the bar opens.
            Item {
                anchors.fill: parent
                clip: true
                opacity: bar.expanded ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation { duration: bar.fluent.durFast }
                }

                Row {
                    x: Math.round((parent.width - width) / 2)
                    y: bar.padding
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

                                // One zone: a rounded tile, filled with the
                                // accent while the cursor is on it.
                                delegate: Rectangle {
                                    required property int index
                                    readonly property var s: preview.slots[index]
                                    readonly property bool hovered: bar.hoveredLayout === preview.index
                                                                    && bar.hoveredSlot === index
                                    readonly property real half: bar.zoneGap / 2

                                    // Half a gap on each inner edge, none on the outer edges.
                                    x: Math.round(s.x * preview.width + (s.x > 0 ? half : 0))
                                    y: Math.round(s.y * preview.height + (s.y > 0 ? half : 0))
                                    width: Math.round(s.w * preview.width - (s.x > 0 ? half : 0)
                                                      - (s.x + s.w < 1 ? half : 0))
                                    height: Math.round(s.h * preview.height - (s.y > 0 ? half : 0)
                                                       - (s.y + s.h < 1 ? half : 0))
                                    radius: bar.fluent.controlRadius
                                    color: hovered ? bar.fluent.accentFill : bar.fluent.zoneFill
                                    border.width: 1
                                    border.color: hovered ? bar.fluent.accentFill : bar.fluent.zoneStroke

                                    Behavior on color {
                                        ColorAnimation { duration: bar.fluent.durFast }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
