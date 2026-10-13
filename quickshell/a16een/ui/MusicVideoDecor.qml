import QtQuick
import QtMultimedia

Item {
    id: root

    property bool active: false
    property bool playing: false
    property url source: ""

    readonly property bool videoReady: player.hasVideo
        && player.mediaStatus !== MediaPlayer.InvalidMedia

    function syncPlayback() {
        if (root.active && root.playing && String(root.source).length > 0) {
            if (!player.playing)
                player.play()
        } else if (player.playing) {
            player.pause()
        }
    }

    onActiveChanged: root.syncPlayback()
    onPlayingChanged: root.syncPlayback()
    onSourceChanged: {
        player.stop()
        Qt.callLater(() => root.syncPlayback())
    }

    MediaPlayer {
        id: player
        source: root.active ? root.source : ""
        loops: MediaPlayer.Infinite
        audioOutput: AudioOutput {
            muted: true
            volume: 0.0
        }
        videoOutput: videoOutput

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia
                    || mediaStatus === MediaPlayer.BufferedMedia
                    || mediaStatus === MediaPlayer.BufferingMedia) {
                Qt.callLater(() => root.syncPlayback())
            } else if (mediaStatus === MediaPlayer.InvalidMedia) {
                console.warn("A16EEN music artwork: Qt Multimedia could not decode WebM:",
                    source, errorString,
                    "Check qt6-multimedia and run 'a16 music diagnose'.")
            }
        }

        onErrorOccurred: (error, errorString) => {
            console.warn("A16EEN music artwork: WebM video load failed:",
                source, "error", error, errorString)
        }
    }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        anchors.margins: 1
        visible: root.active && root.playing && root.videoReady
        fillMode: VideoOutput.PreserveAspectFit
    }
}
