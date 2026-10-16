/*
 * All user options in one place. load() reads them from the script's
 * config (System Settings > Window Management > KWin Scripts > Snap11).
 *
 * The defaults here must match contents/config/main.xml. A value the user
 * never changed is not stored, so the defaults below are what applies.
 */
import QtQuick
import org.kde.kwin

QtObject {
    // Behavior
    property bool edgeAssist: true
    property bool innerEdgeSnap: true
    property int innerEdgeWidth: 10
    property bool layoutBar: true
    property bool layoutHalves: true
    property bool layoutThirds: true
    property bool layoutTwoThirdsLeft: false
    property bool layoutTwoThirdsRight: false
    property bool layoutQuarters: false
    property bool assistAfterBarDrop: true
    property bool maximizeAtTop: true
    property int topTrigger: 6
    property bool includeMinimized: true
    property bool currentScreenOnly: false

    // Look
    property color highlightColor: Qt.rgba(1, 1, 1, 1)
    property color barColor: Qt.rgba(0.11, 0.11, 0.13, 1)
    property int barOpacity: 100
    property int previewWidth: 120
    property int previewHeight: 64
    property int cornerRadius: 12
    property int outlineFillOpacity: 20
    property int outlineBorderWidth: 3
    property bool outlineBlur: true
    property int assistDim: 40
    property bool assistBlur: true
    property int assistMaxCardWidth: 340

    // KConfig stores colors as "r,g,b" (or "r,g,b,a"); also accept "#rrggbb".
    function readColor(key, fallback) {
        const v = KWin.readConfig(key, "");
        const s = v === undefined || v === null ? "" : v.toString().trim();
        if (s.length === 0)
            return fallback;
        if (s.charAt(0) === "#")
            return s;
        const parts = s.split(",").map(function(p) { return parseInt(p, 10); });
        if (parts.length < 3 || parts.some(isNaN))
            return fallback;
        const a = parts.length > 3 ? parts[3] / 255 : 1;
        return Qt.rgba(parts[0] / 255, parts[1] / 255, parts[2] / 255, a);
    }

    function load() {
        edgeAssist = KWin.readConfig("EdgeAssist", true);
        innerEdgeSnap = KWin.readConfig("InnerEdgeSnap", true);
        innerEdgeWidth = KWin.readConfig("InnerEdgeWidth", 10);
        layoutBar = KWin.readConfig("LayoutBar", true);
        layoutHalves = KWin.readConfig("LayoutHalves", true);
        layoutThirds = KWin.readConfig("LayoutThirds", true);
        layoutTwoThirdsLeft = KWin.readConfig("LayoutTwoThirdsLeft", false);
        layoutTwoThirdsRight = KWin.readConfig("LayoutTwoThirdsRight", false);
        layoutQuarters = KWin.readConfig("LayoutQuarters", false);
        assistAfterBarDrop = KWin.readConfig("AssistAfterBarDrop", true);
        maximizeAtTop = KWin.readConfig("MaximizeAtTop", true);
        topTrigger = KWin.readConfig("TopTrigger", 6);
        includeMinimized = KWin.readConfig("IncludeMinimized", true);
        currentScreenOnly = KWin.readConfig("CurrentScreenOnly", false);

        highlightColor = readColor("HighlightColor", Qt.rgba(1, 1, 1, 1));
        barColor = readColor("BarColor", Qt.rgba(0.11, 0.11, 0.13, 1));
        barOpacity = KWin.readConfig("BarOpacity", 100);
        previewWidth = KWin.readConfig("PreviewWidth", 120);
        previewHeight = KWin.readConfig("PreviewHeight", 64);
        cornerRadius = KWin.readConfig("CornerRadius", 12);
        outlineFillOpacity = KWin.readConfig("OutlineFillOpacity", 20);
        outlineBorderWidth = KWin.readConfig("OutlineBorderWidth", 3);
        outlineBlur = KWin.readConfig("OutlineBlur", true);
        assistDim = KWin.readConfig("AssistDim", 40);
        assistBlur = KWin.readConfig("AssistBlur", true);
        assistMaxCardWidth = KWin.readConfig("AssistMaxCardWidth", 340);
    }
}
