// Stub of KWin's live window thumbnail: paints the fake window, keeping its
// aspect ratio inside the item like KWin does.
import QtQuick

Item {
    id: thumb

    property var wId
    readonly property var window: {
        const s = Workspace.stackingOrder;
        for (let i = 0; i < s.length; i++) {
            if (s[i].internalId === wId)
                return s[i];
        }
        return null;
    }
    readonly property real scaleToFit: window
        ? Math.min(width / window.frameGeometry.width, height / window.frameGeometry.height) : 1

    WindowPainting {
        window: thumb.window
        visible: thumb.window !== null
        width: thumb.window ? thumb.window.frameGeometry.width * thumb.scaleToFit : 0
        height: thumb.window ? thumb.window.frameGeometry.height * thumb.scaleToFit : 0
        anchors.centerIn: parent
    }
}
