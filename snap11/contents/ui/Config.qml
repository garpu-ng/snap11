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
    property bool outerEdgeSnap: true
    property bool innerEdgeSnap: true
    property bool cornerQuarters: true
    property bool restoreSize: true
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

    // Look. Colors, frames, blur and corners come from the Plasma theme
    // and the accent color, like KWin's own popups; only sizes are options.
    property int previewWidth: 120
    property int previewHeight: 64
    property int assistMaxCardWidth: 320

    function load() {
        edgeAssist = KWin.readConfig("EdgeAssist", true);
        outerEdgeSnap = KWin.readConfig("OuterEdgeSnap", true);
        innerEdgeSnap = KWin.readConfig("InnerEdgeSnap", true);
        cornerQuarters = KWin.readConfig("CornerQuarters", true);
        restoreSize = KWin.readConfig("RestoreSize", true);
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

        previewWidth = KWin.readConfig("PreviewWidth", 120);
        previewHeight = KWin.readConfig("PreviewHeight", 64);
        assistMaxCardWidth = KWin.readConfig("AssistMaxCardWidth", 320);
    }
}
