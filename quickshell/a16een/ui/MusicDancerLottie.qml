import QtQuick
import Qt.labs.lottieqt

Item {
    id: root

    property string animationSource: ""
    property bool ready: false

    anchors.fill: parent

    LottieAnimation {
        id: lottie
        anchors.fill: parent
        source: root.animationSource
        loops: LottieAnimation.Infinite
        autoPlay: false
        quality: LottieAnimation.HighQuality
        visible: status === LottieAnimation.Ready

        onStatusChanged: {
            root.ready = status === LottieAnimation.Ready
            if (status === LottieAnimation.Ready) {
                start()
                console.info("A16EEN Music: dancer animation loaded", root.animationSource,
                    "frames:", startFrame, "to", endFrame, "canvas:", root.width, "x", root.height)
            } else if (status === LottieAnimation.Error) {
                console.warn("A16EEN Music: failed to load dancer animation",
                    root.animationSource, "status:", status)
            } else if (status === LottieAnimation.Loading) {
                console.info("A16EEN Music: loading dancer animation", root.animationSource)
            }
        }
    }
}
