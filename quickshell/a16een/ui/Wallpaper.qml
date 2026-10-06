import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    required property string currentWallpaperPath
    required property bool desktopAnimationAllowed
    property bool editorialTimeWidgetEnabled: true
    property bool timeUse24Hour: true
    property bool timeShowSeconds: false

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

    EditorialTimeWidget {
        anchors.fill: parent
        widgetEnabled: root.editorialTimeWidgetEnabled
        use24Hour: root.timeUse24Hour
        showSeconds: root.timeShowSeconds
    }
}
