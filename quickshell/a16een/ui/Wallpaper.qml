import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData

    screen: modelData
    color: "transparent"
    aboveWindows: false
    exclusiveZone: 0
    updatesEnabled: false
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
        source: Qt.resolvedUrl("../assets/wallpapers/default.webp")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        mipmap: true
        cache: true

        Rectangle {
            anchors.fill: parent
            color: "#050608"
            opacity: parent.status === Image.Ready ? 0.06 : 1.0
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#050608"
        opacity: 0.22
    }
}
