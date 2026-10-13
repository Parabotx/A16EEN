import QtQuick
import QtMultimedia

Item {
    id: root

    property string sourcePath: ""
    readonly property bool hasVideo: previewPlayer.hasVideo
    readonly property bool previewError: previewPlayer.error !== MediaPlayer.NoError

    MediaPlayer {
        id: previewPlayer
        source: root.sourcePath
        videoOutput: previewOutput
        audioOutput: null
        loops: MediaPlayer.Infinite

        onSourceChanged: {
            if (source.toString().length === 0)
                stop()
        }

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia
                || mediaStatus === MediaPlayer.BufferedMedia) {
                play()
            }
        }
    }

    VideoOutput {
        id: previewOutput
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        visible: previewPlayer.hasVideo
    }
}
