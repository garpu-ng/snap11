/*
 * Invisible layer over all screens, shown together with the window picker
 * (and just below it). A click anywhere outside the picker lands here, so
 * the picker can close even when the click hits a window that is already
 * active and KWin reports no change. A KWin script cannot see clicks on
 * other windows otherwise.
 */
import QtQuick
import org.kde.kwin
import org.kde.plasma.core as PlasmaCore

PlasmaCore.Dialog {
    id: catcher

    property rect area: Qt.rect(0, 0, 0, 0)

    // Global position of the click.
    signal clicked(point pos)

    function showAll() {
        const g = Workspace.virtualScreenGeometry;
        area = Qt.rect(g.x, g.y, g.width, g.height);
        visible = true;
        // A Dialog re-centers itself when shown, so position it afterwards.
        x = area.x;
        y = area.y;
    }

    function hide() {
        visible = false;
    }

    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    location: PlasmaCore.Types.Floating
    backgroundHints: PlasmaCore.Types.NoBackground
    type: PlasmaCore.Dialog.Normal
    visible: false

    Rectangle {
        width: catcher.area.width
        height: catcher.area.height
        // Not fully transparent, so the window surely takes input everywhere.
        color: Qt.rgba(0, 0, 0, 0.01)

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: function(mouse) {
                catcher.clicked(Qt.point(catcher.area.x + mouse.x, catcher.area.y + mouse.y));
            }
        }
    }
}
