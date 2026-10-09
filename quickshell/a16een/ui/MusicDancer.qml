import QtQuick
import Qt.labs.lottieqt

LottieAnimation {
    id: root

    property string animationSource: ""

    anchors.fill: parent
    source: root.animationSource
    loops: LottieAnimation.Infinite
    autoPlay: true
    quality: LottieAnimation.MediumQuality
}
