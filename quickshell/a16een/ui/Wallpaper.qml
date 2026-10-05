import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    required property string currentWallpaperPath

    readonly property string fallbackPath: Qt.resolvedUrl("../assets/wallpapers/default.png")
    readonly property string activePath: root.currentWallpaperPath.length
        ? root.currentWallpaperPath
        : root.fallbackPath
    readonly property string lowerPath: root.activePath.toLowerCase()
    readonly property bool isGif: lowerPath.endsWith(".gif")
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
        anchors.fill: parent
        source: root.activePath
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        mipmap: true
        cache: true
        visible: !root.isGif && !root.isVideo && status === Image.Ready
    }

    AnimatedImage {
        anchors.fill: parent
        source: root.isGif ? root.activePath : ""
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: false
        playing: root.isGif
        loops: Animation.Infinite
        visible: root.isGif && status === AnimatedImage.Ready
    }

    MediaPlayer {
        id: videoPlayer
        source: root.isVideo ? root.activePath : ""
        loops: MediaPlayer.Infinite
        playbackRate: 1.0
        audioOutput: AudioOutput {
            muted: true
            volume: 0
        }
        onErrorOccurred: function(error, errorString) {
            console.warn("A16EEN wallpaper video error:", errorString)
        }
    }

    VideoOutput {
        anchors.fill: parent
        source: videoPlayer
        fillMode: VideoOutput.PreserveAspectCrop
        visible: root.isVideo && videoPlayer.playbackState !== MediaPlayer.StoppedState
    }

    Connections {
        target: videoPlayer

        function onMediaStatusChanged(status) {
            if (root.isVideo
                    && (status === MediaPlayer.LoadedMedia
                        || status === MediaPlayer.BufferedMedia)) {
                videoPlayer.play()
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#050608"
        opacity: 0.22
    }
}
