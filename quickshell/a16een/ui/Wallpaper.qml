import QtQuick
import QtMultimedia
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

    function syncVideoPlayback() {
        if (!root.isVideo) {
            if (videoPlayer.playbackState !== MediaPlayer.StoppedState)
                videoPlayer.stop()
            return
        }

        if (root.desktopAnimationAllowed) {
            if (videoPlayer.playbackState !== MediaPlayer.PlayingState)
                videoPlayer.play()
        } else if (videoPlayer.playbackState === MediaPlayer.PlayingState) {
            videoPlayer.pause()
        }
    }

    onActivePathChanged: Qt.callLater(root.syncVideoPlayback)
    onDesktopAnimationAllowedChanged: Qt.callLater(root.syncVideoPlayback)
    Component.onCompleted: Qt.callLater(root.syncVideoPlayback)

    Rectangle {
        anchors.fill: parent
        color: "#050608"
    }

    Image {
        id: staticWallpaper
        anchors.fill: parent
        source: !root.isAnimatedImage && !root.isVideo ? root.activePath : ""
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        retainWhileLoading: true
        mipmap: true
        cache: true
        visible: !root.isAnimatedImage && !root.isVideo && status === Image.Ready
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

    MediaPlayer {
        id: videoPlayer
        source: root.isVideo ? root.activePath : ""
        videoOutput: wallpaperVideoOutput
        audioOutput: null
        loops: MediaPlayer.Infinite

        onSourceChanged: Qt.callLater(root.syncVideoPlayback)
        onMediaStatusChanged: {
            if (root.isVideo && root.desktopAnimationAllowed
                && (mediaStatus === MediaPlayer.LoadedMedia
                    || mediaStatus === MediaPlayer.BufferedMedia
                    || mediaStatus === MediaPlayer.BufferingMedia)) {
                Qt.callLater(root.syncVideoPlayback)
            }
        }
        onErrorOccurred: function(error, errorString) {
            console.warn("A16EEN could not play the selected video wallpaper:", errorString)
        }
    }

    VideoOutput {
        id: wallpaperVideoOutput
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        visible: root.isVideo && videoPlayer.hasVideo
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
