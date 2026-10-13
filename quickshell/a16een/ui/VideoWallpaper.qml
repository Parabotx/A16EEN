import QtQuick
import QtMultimedia

Item {
    id: root

    property string sourcePath: ""
    property bool desktopAnimationAllowed: true

    anchors.fill: parent

    function syncVideoPlayback() {
        if (!root.sourcePath.length) {
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

    onSourcePathChanged: Qt.callLater(root.syncVideoPlayback)
    onDesktopAnimationAllowedChanged: Qt.callLater(root.syncVideoPlayback)
    Component.onCompleted: Qt.callLater(root.syncVideoPlayback)

    MediaPlayer {
        id: videoPlayer
        source: root.sourcePath.length ? Qt.resolvedUrl(root.sourcePath) : ""
        videoOutput: wallpaperVideoOutput
        audioOutput: null
        loops: MediaPlayer.Infinite

        onSourceChanged: Qt.callLater(root.syncVideoPlayback)
        onMediaStatusChanged: {
            if (root.sourcePath.length && root.desktopAnimationAllowed
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
        visible: videoPlayer.hasVideo
    }
}
