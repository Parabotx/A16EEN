import QtQuick
import Qt.labs.lottieqt

LottieAnimation {
    id: root

    property string animationSource: ""

    anchors.fill: parent
    source: root.animationSource
    loops: LottieAnimation.Infinite
    autoPlay: false
    quality: LottieAnimation.MediumQuality

    onStatusChanged: {
        if (status === LottieAnimation.Ready) {
            // Start only after Qt has parsed the compatible shape-only animation.
            start()
            console.info("A16EEN Music: dancer animation loaded", root.source,
                "frames:", startFrame, "to", endFrame, "size:", width, "x", height)
        } else if (status === LottieAnimation.Error) {
            console.warn("A16EEN Music: failed to load dancer animation", root.source,
                "status:", status)
        }
    }
}
