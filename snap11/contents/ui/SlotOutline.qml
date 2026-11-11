/*
 * The drop preview: shows where the dragged window will land.
 *
 * Drawn exactly like KWin's own quick tiling outline
 * (kwin/src/qml/outline/plasma/outline.qml): the Plasma theme's
 * "widgets/translucentbackground" frame, without borders along the edges of
 * the work area, sliding out of the dragged window when it first appears.
 * It follows the Plasma theme, so it matches whatever theme is in use.
 *
 * The window covers the whole work area of the screen and only draws the
 * frame inside it, so the frame can move from the window's spot to the
 * target. It takes no input (outputOnly).
 */
import QtQuick
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

PlasmaCore.Dialog {
    id: outline

    // User options (Config.qml). Not used for the look any more (that comes
    // from the Plasma theme), kept so all overlays are set up the same way.
    required property QtObject cfg

    // Work area the outline lives in (the window covers it), and the target.
    property rect area: Qt.rect(0, 0, 0, 0)
    property rect target: Qt.rect(0, 0, 0, 0)

    readonly property int animationDuration: Kirigami.Units.longDuration
    property bool animationEnabled: false

    function sameRect(a, b) {
        return a.x === b.x && a.y === b.y && a.width === b.width && a.height === b.height;
    }

    // r: target rect; workArea: usable area of r's screen; from: the
    // dragged window's geometry, where the frame starts when it appears
    // (like KWin, which slides it out of the window). Later target changes
    // jump, also like KWin.
    function showAt(r, workArea, from) {
        const firstShow = !visible;
        if (!firstShow && sameRect(r, target) && sameRect(workArea, area))
            return;
        const areaChanged = !sameRect(workArea, area);
        area = workArea;
        target = r;
        if (firstShow)
            visible = true;
        if (firstShow || areaChanged) {
            // A Dialog re-centers itself when shown, so position it afterwards.
            x = area.x;
            y = area.y;
        }
        animationEnabled = false;
        if (firstShow && from && from.width > 0 && from.height > 0) {
            frame.setGeometry(clipped(from));
            animationEnabled = true;
        }
        frame.setGeometry(target);
        animationEnabled = true;
    }

    function hide() {
        visible = false;
    }

    // The window's rect, cut down to the work area (it may hang over).
    function clipped(r) {
        const x0 = Math.max(r.x, area.x);
        const y0 = Math.max(r.y, area.y);
        const x1 = Math.min(r.x + r.width, area.x + area.width);
        const y1 = Math.min(r.y + r.height, area.y + area.height);
        if (x1 <= x0 || y1 <= y0)
            return target;
        return Qt.rect(x0, y0, x1 - x0, y1 - y0);
    }

    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus
    location: PlasmaCore.Types.Floating
    backgroundHints: PlasmaCore.Types.NoBackground
    type: PlasmaCore.Dialog.Normal
    outputOnly: true
    visible: false

    Item {
        width: outline.area.width
        height: outline.area.height

        KSvg.FrameSvgItem {
            id: frame

            function setGeometry(g) {
                x = g.x - outline.area.x;
                y = g.y - outline.area.y;
                width = g.width;
                height = g.height;
            }

            imagePath: "widgets/translucentbackground"

            // Like KWin: no border where the target touches the work area's
            // edge, all borders when it fills the whole area (maximize).
            enabledBorders: {
                const t = outline.target;
                const a = outline.area;
                const left = t.x === a.x;
                const right = t.x + t.width === a.x + a.width;
                const top = t.y === a.y;
                const bottom = t.y + t.height === a.y + a.height;
                if (left && right && top && bottom)
                    return KSvg.FrameSvgItem.AllBorders;
                let borders = KSvg.FrameSvgItem.AllBorders;
                if (left)
                    borders &= ~KSvg.FrameSvgItem.LeftBorder;
                if (right)
                    borders &= ~KSvg.FrameSvgItem.RightBorder;
                if (top)
                    borders &= ~KSvg.FrameSvgItem.TopBorder;
                if (bottom)
                    borders &= ~KSvg.FrameSvgItem.BottomBorder;
                return borders;
            }

            Behavior on x {
                enabled: outline.animationEnabled
                NumberAnimation { duration: outline.animationDuration; easing.type: Easing.InOutCubic }
            }
            Behavior on y {
                enabled: outline.animationEnabled
                NumberAnimation { duration: outline.animationDuration; easing.type: Easing.InOutCubic }
            }
            Behavior on width {
                enabled: outline.animationEnabled
                NumberAnimation { duration: outline.animationDuration; easing.type: Easing.InOutCubic }
            }
            Behavior on height {
                enabled: outline.animationEnabled
                NumberAnimation { duration: outline.animationDuration; easing.type: Easing.InOutCubic }
            }
        }
    }
}
