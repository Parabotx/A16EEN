import QtQuick

Item {
    id: root

    property string sourcePath: ""
    property bool desktopAnimationAllowed: false

    readonly property string lowerPath: root.sourcePath.toLowerCase()
    readonly property bool isAnimatedImage: lowerPath.endsWith(".gif")
        || lowerPath.endsWith(".webp")
    readonly property bool isVideo: lowerPath.endsWith(".mp4")
        || lowerPath.endsWith(".webm")
        || lowerPath.endsWith(".mov")
        || lowerPath.endsWith(".m4v")
        || lowerPath.endsWith(".mkv")
    readonly property bool contentReady: root.isVideo
        ? ((videoLayerLoader.item && videoLayerLoader.item.hasVideo)
            || videoLayerLoader.status === Loader.Error)
        : root.isAnimatedImage
            ? (animatedLayer.status === AnimatedImage.Ready
                || animatedLayer.status === AnimatedImage.Error)
            : (staticLayer.status === Image.Ready
                || staticLayer.status === Image.Error)

    Image {
        id: staticLayer
        anchors.fill: parent
        source: !root.isAnimatedImage
            ? (root.isVideo
                ? (videoLayerLoader.status === Loader.Error ? Qt.resolvedUrl("../assets/wallpapers/default.png") : "")
                : root.sourcePath)
            : ""
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: true
        mipmap: true
        visible: !root.isAnimatedImage
            && (!root.isVideo || videoLayerLoader.status === Loader.Error)
            && status === Image.Ready
    }

    AnimatedImage {
        id: animatedLayer
        anchors.fill: parent
        source: root.isAnimatedImage ? root.sourcePath : ""
        sourceSize.width: Math.max(1, Math.round(width))
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: false
        playing: root.desktopAnimationAllowed && root.isAnimatedImage
        visible: root.isAnimatedImage && status === AnimatedImage.Ready
    }

    Loader {
        id: videoLayerLoader
        anchors.fill: parent
        active: root.isVideo
        source: root.isVideo ? "VideoWallpaperPreview.qml" : ""
        onLoaded: {
            item.sourcePath = Qt.binding(function() {
                return root.sourcePath
            })
        }
    }
}
