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
    property bool fillSpace: true
    property int innerEdgeWidth: 10
    property bool layoutBar: true
    property bool layoutHalves: true
    property bool layoutTwoThirdsLeft: true
    property bool layoutThirds: true
    property bool layoutHalfQuarters: true
    property bool layoutQuarters: true
    property bool layoutCenterWide: true
    property bool layoutTwoThirdsRight: false
    property bool threeColumnsWideOnly: true
    property bool assistAfterBarDrop: true
    property bool kdeTiles: true
    property bool maximizeAtTop: true
    property int topTrigger: 6
    property bool includeMinimized: true
    property bool currentScreenOnly: false

    // Look: Windows 11, light/dark and accent from the system (Fluent.qml);
    // only sizes are options.
    property int previewWidth: 80
    property int assistMaxCardWidth: 320

    function load() {
        edgeAssist = KWin.readConfig("EdgeAssist", true);
        outerEdgeSnap = KWin.readConfig("OuterEdgeSnap", true);
        innerEdgeSnap = KWin.readConfig("InnerEdgeSnap", true);
        cornerQuarters = KWin.readConfig("CornerQuarters", true);
        restoreSize = KWin.readConfig("RestoreSize", true);
        fillSpace = KWin.readConfig("FillSpace", true);
        innerEdgeWidth = KWin.readConfig("InnerEdgeWidth", 10);
        layoutBar = KWin.readConfig("LayoutBar", true);
        layoutHalves = KWin.readConfig("LayoutHalves", true);
        layoutTwoThirdsLeft = KWin.readConfig("LayoutTwoThirdsLeft", true);
        layoutThirds = KWin.readConfig("LayoutThirds", true);
        layoutHalfQuarters = KWin.readConfig("LayoutHalfQuarters", true);
        layoutQuarters = KWin.readConfig("LayoutQuarters", true);
        layoutCenterWide = KWin.readConfig("LayoutCenterWide", true);
        layoutTwoThirdsRight = KWin.readConfig("LayoutTwoThirdsRight", false);
        threeColumnsWideOnly = KWin.readConfig("ThreeColumnsWideOnly", true);
        assistAfterBarDrop = KWin.readConfig("AssistAfterBarDrop", true);
        kdeTiles = KWin.readConfig("KdeTiles", true);
        maximizeAtTop = KWin.readConfig("MaximizeAtTop", true);
        topTrigger = KWin.readConfig("TopTrigger", 6);
        includeMinimized = KWin.readConfig("IncludeMinimized", true);
        currentScreenOnly = KWin.readConfig("CurrentScreenOnly", false);

        previewWidth = KWin.readConfig("PreviewWidth", 80);
        assistMaxCardWidth = KWin.readConfig("AssistMaxCardWidth", 320);
    }
}
