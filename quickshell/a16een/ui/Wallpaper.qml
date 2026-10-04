import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData

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

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("../assets/wallpapers/default.png")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        mipmap: true
        cache: true
        opacity: 0.16
        visible: status === Image.Ready
    }

    // The primary layer never crops the supplied artwork.
    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("../assets/wallpapers/default.png")
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        mipmap: true
        cache: true
        visible: status === Image.Ready
    }

    // A16EEN remains usable even when the optional wallpaper is missing.
    Rectangle {
        anchors.fill: parent
        color: "#050608"
        z: -1
    }

    Rectangle {
        anchors.fill: parent
        color: "#050608"
        opacity: 0.22
    }
}
