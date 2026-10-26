import QtQuick
import QtMultimedia

Item {
    id: root

    property string sourcePath: ""
    property bool desktopAnimationAllowed: true
    readonly property bool hasVideo: previewPlayer.hasVideo
    readonly property bool previewError: previewPlayer.error !== MediaPlayer.NoError

    function syncVideoPlayback() {
        if (!root.sourcePath.length) {
            if (previewPlayer.playbackState !== MediaPlayer.StoppedState)
                previewPlayer.stop()
            return
        }

        if (root.desktopAnimationAllowed) {
            if (previewPlayer.playbackState !== MediaPlayer.PlayingState)
                previewPlayer.play()
        } else if (previewPlayer.playbackState === MediaPlayer.PlayingState) {
            previewPlayer.pause()
        }
    }

    onSourcePathChanged: Qt.callLater(root.syncVideoPlayback)
    onDesktopAnimationAllowedChanged: Qt.callLater(root.syncVideoPlayback)
    Component.onCompleted: Qt.callLater(root.syncVideoPlayback)

    MediaPlayer {
        id: previewPlayer
        source: root.sourcePath
        videoOutput: previewOutput
        audioOutput: null
        loops: MediaPlayer.Infinite

        onSourceChanged: Qt.callLater(root.syncVideoPlayback)

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia
                || mediaStatus === MediaPlayer.BufferedMedia
                || mediaStatus === MediaPlayer.BufferingMedia) {
                Qt.callLater(root.syncVideoPlayback)
            }
        }
    }

    VideoOutput {
        id: previewOutput
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectFit
        visible: previewPlayer.hasVideo
    }
}
