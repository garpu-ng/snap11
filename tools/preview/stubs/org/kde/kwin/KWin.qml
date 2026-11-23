// Stub of KWin's script globals: client area kinds and readConfig().
pragma Singleton
import QtQuick

QtObject {
    // Same order as KWin's ClientAreaOption.
    enum ClientAreaOption {
        PlacementArea, MovementArea, MaximizeArea, MaximizeFullArea,
        FullScreenArea, WorkArea, FullArea, ScreenArea
    }

    // Script options; Sim.setConfig() writes here.
    property var config: ({})

    function readConfig(key, fallback) {
        return config.hasOwnProperty(key) ? config[key] : fallback;
    }
}
