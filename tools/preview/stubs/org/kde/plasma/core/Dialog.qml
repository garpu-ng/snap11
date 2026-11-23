// Stub of PlasmaCore.Dialog. In KWin every Dialog is its own window at
// global coordinates. Here it is an Item in Sim.overlayLayer, which covers
// the scene at (0, 0), so x/y are global too. It takes the size of its first
// child (the content item), and showing it stacks it on top, like a window.
// With a kwin_blur property it shows the desktop blurred behind itself, as
// KWin's blur effect does for internal windows.
import QtQuick
import QtQuick.Effects
import Snap11Sim

Item {
    id: dialog

    enum WindowType { Normal, Dock, DialogType, OnScreenDisplay }

    property int flags: 0
    property int location: 0
    property int backgroundHints: 0
    property int type: 0
    property bool outputOnly: false
    property bool active: false
    readonly property QtObject margins: QtObject {
        property int left: 0
        property int top: 0
        property int right: 0
        property int bottom: 0
    }
    default property alias content: holder.data
    readonly property bool blurBehind: dialog.kwin_blur !== undefined

    function raise() { z = Sim.nextZ(); }
    function requestActivate() { active = true; }

    visible: false
    width: holder.children.length > 0 ? holder.children[0].width : 0
    height: holder.children.length > 0 ? holder.children[0].height : 0
    onVisibleChanged: {
        if (visible)
            z = Sim.nextZ();
        else
            active = false;
    }
    Component.onCompleted: parent = Sim.overlayLayer

    Item {
        anchors.fill: parent
        clip: true
        visible: dialog.blurBehind && Sim.desktop !== null

        ShaderEffectSource {
            id: behind
            readonly property int pad: 48
            x: -pad
            y: -pad
            width: dialog.width + 2 * pad
            height: dialog.height + 2 * pad
            sourceItem: Sim.desktop
            sourceRect: Qt.rect(dialog.x - pad, dialog.y - pad, width, height)
            live: true
            visible: false
        }

        MultiEffect {
            anchors.fill: behind
            source: behind
            blurEnabled: true
            blur: 1.0
            blurMax: 48
        }
    }

    Item {
        id: holder
    }
}
