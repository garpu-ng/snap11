// The fake desktop: wallpaper, the fake windows and a panel; above them the
// overlay layer where Snap11's Dialogs live; main.qml; and the scenario's
// steps, played one after another.
import QtQuick
import org.kde.kwin
import Snap11Sim

Item {
    id: scene

    width: 1920
    height: 1080

    // Everything below the overlays. The blur behind overlays samples this.
    Item {
        id: desktop

        width: 1920
        height: 1080

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#16324f" }
                GradientStop { position: 0.5; color: "#2a6f97" }
                GradientStop { position: 1.0; color: "#e9a35b" }
            }
        }

        Repeater {
            model: [[260, 180, 420, "#e76f51"], [1500, 260, 520, "#8ecae6"], [900, 760, 380, "#ffb703"],
                    [1650, 900, 300, "#6a4c93"], [120, 820, 260, "#2a9d8f"]]
            Rectangle {
                required property var modelData
                x: modelData[0] - modelData[2] / 2
                y: modelData[1] - modelData[2] / 2
                width: modelData[2]
                height: width
                radius: width / 2
                color: modelData[3]
                opacity: 0.55
            }
        }

        Repeater {
            model: Workspace.stackingOrder
            WindowPainting {
                required property var modelData
                required property int index
                window: modelData
                x: modelData.frameGeometry.x
                y: modelData.frameGeometry.y
                width: modelData.frameGeometry.width
                height: modelData.frameGeometry.height
                visible: !modelData.minimized
                z: index
            }
        }

        Rectangle {
            y: 1080 - Workspace.panelHeight
            width: 1920
            height: Workspace.panelHeight
            color: "#e61b1e20"
            z: 1000
        }
    }

    Item {
        id: overlays

        anchors.fill: parent
    }

    Loader {
        id: snapLoader

        onLoaded: Sim.snap = item
    }

    Loader {
        id: scenarioLoader

        onLoaded: sequencer.begin(item.steps)
    }

    // Steps are [delay in ms before the step, function].
    Timer {
        id: sequencer

        property var steps: []
        property int i: 0

        function begin(s) {
            steps = s;
            i = 0;
            if (steps.length === 0) {
                runner.done();
                return;
            }
            interval = Math.max(1, steps[0][0]);
            start();
        }

        onTriggered: {
            try {
                steps[i][1]();
            } catch (e) {
                runner.fail("step " + i + ": " + e + (e.stack ? " at " + e.stack : ""));
            }
            i += 1;
            if (i < steps.length) {
                interval = Math.max(1, steps[i][0]);
                start();
            } else {
                runner.done();
            }
        }
    }

    Component.onCompleted: {
        Sim.desktop = desktop;
        Sim.overlayLayer = overlays;
        // Set once, not bound: the runner goes away before the scene does.
        snapLoader.source = runner.mainUrl;
        scenarioLoader.source = runner.scenarioUrl;
    }
}
