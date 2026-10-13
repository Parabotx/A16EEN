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
    readonly property string lowerPath: root.activePath.toLowerCase()
    readonly property bool isAnimatedImage: lowerPath.endsWith(".gif")
        || lowerPath.endsWith(".webp")
    readonly property bool isVideo: lowerPath.endsWith(".mp4")
        || lowerPath.endsWith(".webm")
        || lowerPath.endsWith(".mov")
        || lowerPath.endsWith(".m4v")
        || lowerPath.endsWith(".mkv")

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
        source: !root.isAnimatedImage
            ? (root.isVideo
                ? (videoWallpaperLoader.status === Loader.Error ? root.fallbackPath : "")
                : root.activePath)
            : ""
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        retainWhileLoading: true
        mipmap: true
        cache: true
        visible: !root.isAnimatedImage
            && (!root.isVideo || videoWallpaperLoader.status === Loader.Error)
            && status === Image.Ready
    }

    AnimatedImage {
        id: animatedWallpaper
        anchors.fill: parent
        source: root.isAnimatedImage ? root.activePath : ""
        sourceSize.width: Math.max(1, Math.round(width))
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: false
        playing: root.isAnimatedImage && root.desktopAnimationAllowed
        visible: root.isAnimatedImage && status === AnimatedImage.Ready
    }

    // Keep Qt Multimedia outside the always-loaded wallpaper component.
    // A missing or ABI-incompatible video plugin must not prevent the static
    // wallpaper, navbar, and the rest of the A16EEN shell from loading.
    Loader {
        id: videoWallpaperLoader
        anchors.fill: parent
        active: root.isVideo
        source: root.isVideo ? "VideoWallpaper.qml" : ""

        onLoaded: {
            item.sourcePath = Qt.binding(function() {
                return root.activePath
            })
            item.desktopAnimationAllowed = Qt.binding(function() {
                return root.desktopAnimationAllowed
            })
        }
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
