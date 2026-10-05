import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    required property string currentWallpaperPath

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

    Rectangle {
        anchors.fill: parent
        color: "#050608"
    }

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
