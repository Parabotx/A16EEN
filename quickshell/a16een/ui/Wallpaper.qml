import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    required property string currentWallpaperPath
    required property bool desktopAnimationAllowed


    readonly property string fallbackPath: Qt.resolvedUrl("../assets/wallpapers/default.png")
    readonly property string activePath: root.currentWallpaperPath.length
        ? root.currentWallpaperPath
        : root.fallbackPath
    readonly property bool isGif: root.activePath.toLowerCase().endsWith(".gif")

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

    // Keep the existing static wallpaper path untouched.
    Image {
        id: staticWallpaper
        anchors.fill: parent
        source: root.activePath
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        mipmap: true
        cache: true
        visible: !root.isGif && status === Image.Ready
    }

    // Qt 6.11 AnimatedImage already plays and loops continuously by default.
    // Do not use the Qt 6.12-only 'loops' property here.
    AnimatedImage {
        id: animatedWallpaper
        anchors.fill: parent
        source: root.isGif ? root.activePath : ""
        sourceSize.width: Math.max(1, Math.round(width))
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: false
        playing: root.isGif && root.desktopAnimationAllowed
        visible: root.isGif && status === AnimatedImage.Ready
    }

    Rectangle {
        anchors.fill: parent
        color: "#050608"
        opacity: 0.22
    }
}
