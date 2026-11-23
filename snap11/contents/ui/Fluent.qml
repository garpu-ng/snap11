/*
 * Windows 11 design values (Fluent) for all of Snap11's overlays, so they
 * look like the Windows 11 shell: colors, corner radii, text sizes and
 * motion.
 *
 * Light or dark follows the system color scheme and the accent follows the
 * system accent color, the way Windows follows its app mode and accent
 * color. Colors are WinUI's theme resources (#AARRGGBB) where WinUI has one.
 *
 * An Item (not a QtObject) so Kirigami.Theme resolves like it does for the
 * overlays.
 */
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    visible: false

    // Dark when the system's window background is dark.
    readonly property bool dark: luminance(Kirigami.Theme.backgroundColor) < 0.5

    // The system accent, and Windows' accent fill made from it:
    // SystemAccentColorLight2 in dark mode, SystemAccentColorDark1 in light.
    // Like Windows, the shift depends on how light the accent already is
    // (#0078D4 gives #5AB7FF and #0069B9, close to Windows' own #60CDFF
    // and #005FB8).
    readonly property color accent: Kirigami.Theme.highlightColor
    readonly property color accentFill: accentVariant(accent, dark ? (0.85 - accent.hslLightness) * 0.6
                                                                 : -(accent.hslLightness - 0.15) * 0.2)

    // Text (TextFillColorPrimary / Secondary).
    readonly property color textPrimary: dark ? "#FFFFFF" : "#E4000000"
    readonly property color textSecondary: dark ? "#C5FFFFFF" : "#9E000000"

    // Flyouts (the snap bar, the toast): acrylic with Windows' high
    // luminosity opacity, so nearly opaque, plus a thin stroke.
    readonly property color flyoutFill: dark ? "#F52C2C2C" : "#F5FCFCFC"
    readonly property color flyoutStroke: dark ? "#17FFFFFF" : "#0F000000"

    // Frosted glass of the drop preview and the Snap Assist zones: more
    // translucent, over the blurred desktop.
    readonly property color glassFill: dark ? "#8C3C3C3C" : "#99F3F3F3"
    readonly property color glassStroke: dark ? "#26FFFFFF" : "#1A000000"

    // Zones of a layout in the snap bar.
    readonly property color zoneFill: dark ? "#1FFFFFFF" : "#0F000000"
    readonly property color zoneStroke: dark ? "#1AFFFFFF" : "#1F000000"

    // Hover and pressed backgrounds (SubtleFillColorSecondary / Tertiary).
    readonly property color subtleHover: dark ? "#0FFFFFFF" : "#09000000"
    readonly property color subtlePressed: dark ? "#0AFFFFFF" : "#06000000"

    // The red of a hovered / pressed close button, as on window title bars.
    readonly property color closeHover: "#C42B1C"
    readonly property color closePressed: "#E6C42B1C"

    // Keyboard focus rectangle (FocusStrokeColorOuter / Inner).
    readonly property color focusOuter: dark ? "#FFFFFF" : "#E4000000"
    readonly property color focusInner: dark ? "#B3000000" : "#B3FFFFFF"

    readonly property color shadowColor: dark ? "#66000000" : "#29000000"

    // OverlayCornerRadius, ControlCornerRadius.
    readonly property int overlayRadius: 8
    readonly property int controlRadius: 4

    // Type ramp: Caption, Body (px).
    readonly property int captionSize: 12
    readonly property int bodySize: 14
    readonly property string fontFamily: {
        const installed = Qt.fontFamilies();
        const wanted = ["Segoe UI Variable Text", "Segoe UI Variable", "Segoe UI"];
        for (let i = 0; i < wanted.length; i++) {
            if (installed.indexOf(wanted[i]) >= 0)
                return wanted[i];
        }
        return Kirigami.Theme.defaultFont.family;
    }

    // Motion: Fluent's fast and normal durations, scaled by Plasma's
    // animation speed (Kirigami's longDuration is 200 ms at normal speed,
    // 1 ms with animations off).
    readonly property real speed: Kirigami.Units.longDuration / 200
    readonly property int durFast: Math.round(167 * speed)
    readonly property int durNormal: Math.round(250 * speed)
    // Bezier curves for Easing.Bezier: decelerate (things appearing) and
    // point to point (things moving from one place to another).
    readonly property var decelerate: [0, 0, 0, 1, 1, 1]
    readonly property var pointToPoint: [0.55, 0.55, 0, 1, 1, 1]

    // Snap zones on screen float a little: 8 px from the work area's edges,
    // 4 px from a neighbouring zone (8 px between two zones).
    readonly property int zoneInsetOuter: 8
    readonly property int zoneInsetInner: 4

    function luminance(c) {
        return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
    }

    // The accent with its HSL lightness moved by dl, like Windows' Light/Dark
    // accent shades.
    function accentVariant(c, dl) {
        const l = Math.max(0.1, Math.min(0.9, c.hslLightness + dl));
        return Qt.hsla(Math.max(0, c.hslHue), c.hslSaturation, l, c.a);
    }

    // The rect a snap zone r is drawn at inside work area a.
    function zoneRect(r, a) {
        const t = 2;
        const left = Math.abs(r.x - a.x) <= t ? zoneInsetOuter : zoneInsetInner;
        const top = Math.abs(r.y - a.y) <= t ? zoneInsetOuter : zoneInsetInner;
        const right = Math.abs(r.x + r.width - (a.x + a.width)) <= t ? zoneInsetOuter : zoneInsetInner;
        const bottom = Math.abs(r.y + r.height - (a.y + a.height)) <= t ? zoneInsetOuter : zoneInsetInner;
        return Qt.rect(r.x + left, r.y + top, r.width - left - right, r.height - top - bottom);
    }
}
