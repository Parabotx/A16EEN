import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property string currentWallpaperPath: ""

    screen: modelData
    color: "#050608"
    aboveWindows: false
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "a16een-wallpaper"

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    Process {
        id: wallpaperPathProcess
        command: ["a16een-wallpaper", "current-path"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim()
                if (path.length)
                    root.currentWallpaperPath = path
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#050608"
    }

    Image {
        anchors.fill: parent
        source: root.currentWallpaperPath.length
            ? root.currentWallpaperPath
            : Qt.resolvedUrl("../assets/wallpapers/default.png")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        mipmap: true
        cache: true
        opacity: 0.16
        visible: status === Image.Ready
    }

    // The primary artwork keeps its full aspect ratio rather than forcing a crop.
    Image {
        anchors.fill: parent
        source: root.currentWallpaperPath.length
            ? root.currentWallpaperPath
            : Qt.resolvedUrl("../assets/wallpapers/default.png")
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        mipmap: true
        cache: true
        visible: status === Image.Ready
    }

    Rectangle {
        anchors.fill: parent
        color: "#050608"
        opacity: 0.22
    }
}
