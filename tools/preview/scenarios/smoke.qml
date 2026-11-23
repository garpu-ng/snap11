// The harness itself: main.qml loads against the stubs and sees windows.
import QtQuick
import Snap11Sim

QtObject {
    property var steps: [
        [0, function() {
            Sim.addWindow({ "caption": "Files", "geometry": Qt.rect(100, 100, 800, 600) });
            Sim.addWindow({ "caption": "Editor", "geometry": Qt.rect(500, 200, 900, 700) });
        }],
        [100, function() {
            Sim.check(Sim.snap !== null, "main.qml loaded");
            Sim.check(Sim.snap !== null && Sim.snap.watched.length === 2, "watching two windows");
            Sim.shot("smoke-desktop");
        }]
    ]
}
