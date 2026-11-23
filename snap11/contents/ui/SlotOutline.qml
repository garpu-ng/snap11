/*
 * The drop preview: shows where the dragged window will land, like Windows
 * 11's snap preview. A frosted glass rectangle with rounded corners that
 * floats a little inside the work area, with the app's icon in the middle.
 * It grows out of the dragged window when it appears and glides from one
 * target to the next.
 *
 * KWin's blur effect blurs a script's window when the window has a
 * "kwin_blur" property, and only as a whole rectangle. So the window is
 * exactly the preview, and it is the window's geometry that animates. It
 * takes no input (outputOnly).
 */
import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

PlasmaCore.Dialog {
    id: outline

    // User options (Config.qml) and the Windows 11 look (Fluent.qml).
    required property QtObject cfg
    required property QtObject fluent

    // Ask KWin's blur effect to blur behind the whole window.
    property rect kwin_blur: Qt.rect(0, 0, 0, 0)

    // Where the preview is going (inset, on screen), and the app's icon.
    property rect target: Qt.rect(0, 0, 0, 0)
    property var icon: ""

    // The geometry being shown; animated towards target.
    property real gx: 0
    property real gy: 0
    property real gw: 0
    property real gh: 0

    function sameRect(a, b) {
        return a.x === b.x && a.y === b.y && a.width === b.width && a.height === b.height;
    }

    // r: the zone the window will fill; workArea: usable area of r's
    // screen; from: the dragged window's geometry, where the preview grows
    // from when it appears (null: appear in place); windowIcon: shown in
    // the middle.
    function showAt(r, workArea, from, windowIcon) {
        const t = fluent.zoneRect(r, workArea);
        icon = windowIcon || "";
        const firstShow = !visible;
        if (!firstShow && sameRect(t, target))
            return;
        target = t;
        glide.stop();
        if (firstShow) {
            const f = from && from.width > 0 && from.height > 0 ? clipped(from, workArea) : t;
            setGeometry(f.x, f.y, f.width, f.height);
            visible = true;
            // A Dialog re-centers itself when shown, so position it afterwards.
            x = Math.round(gx);
            y = Math.round(gy);
        }
        if (fluent.durNormal <= 0) {
            setGeometry(t.x, t.y, t.width, t.height);
            return;
        }
        glide.start();
    }

    function hide() {
        glide.stop();
        visible = false;
    }

    function setGeometry(px, py, pw, ph) {
        gx = px;
        gy = py;
        gw = pw;
        gh = ph;
    }

    // The window's rect, cut down to the work area (it may hang over).
    function clipped(r, a) {
        const x0 = Math.max(r.x, a.x);
        const y0 = Math.max(r.y, a.y);
        const x1 = Math.min(r.x + r.width, a.x + a.width);
        const y1 = Math.min(r.y + r.height, a.y + a.height);
        if (x1 <= x0 || y1 <= y0)
            return target;
        return Qt.rect(x0, y0, x1 - x0, y1 - y0);
    }

    onGxChanged: x = Math.round(gx)
    onGyChanged: y = Math.round(gy)

    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus
    location: PlasmaCore.Types.Floating
    backgroundHints: PlasmaCore.Types.NoBackground
    type: PlasmaCore.Dialog.Normal
    outputOnly: true
    visible: false

    ParallelAnimation {
        id: glide

        NumberAnimation {
            target: outline
            property: "gx"
            to: outline.target.x
            duration: outline.fluent.durNormal
            easing.type: Easing.Bezier
            easing.bezierCurve: outline.fluent.pointToPoint
        }
        NumberAnimation {
            target: outline
            property: "gy"
            to: outline.target.y
            duration: outline.fluent.durNormal
            easing.type: Easing.Bezier
            easing.bezierCurve: outline.fluent.pointToPoint
        }
        NumberAnimation {
            target: outline
            property: "gw"
            to: outline.target.width
            duration: outline.fluent.durNormal
            easing.type: Easing.Bezier
            easing.bezierCurve: outline.fluent.pointToPoint
        }
        NumberAnimation {
            target: outline
            property: "gh"
            to: outline.target.height
            duration: outline.fluent.durNormal
            easing.type: Easing.Bezier
            easing.bezierCurve: outline.fluent.pointToPoint
        }
    }

    Rectangle {
        width: Math.round(outline.gw)
        height: Math.round(outline.gh)
        radius: outline.fluent.overlayRadius
        color: outline.fluent.glassFill
        border.width: 1
        border.color: outline.fluent.glassStroke

        Kirigami.Icon {
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.huge
            height: width
            source: outline.icon
            visible: !!outline.icon && parent.width > 2 * width && parent.height > 2 * height
        }
    }
}
