import QtQuick

Item {
    id: root

    property bool animating: true
    property bool playing: false
    property real audioLevel: 0
    property bool hotBeat: false
    property real phase: 0

    // Intentionally transparent: no rain, card, backdrop, gradient, or particle layer.
    Timer {
        interval: 42
        repeat: true
        running: root.animating && root.playing
        onTriggered: root.phase += 0.19
    }

    Repeater {
        model: 21

        delegate: Rectangle {
            id: equalizerBar
            required property int index

            readonly property real wave: 0.16 + 0.84
                * Math.abs(Math.sin(root.phase + index * 0.76))
            readonly property real quietWave: 0.18
                + 0.82 * Math.abs(Math.sin(index * 0.76))

            x: 2 + index * 4.65
            y: root.height - height - 5
            width: 2.5
            height: root.playing
                ? 3.5 + (7 + root.audioLevel * 46) * wave
                : 3 + quietWave * 4
            radius: 1.25
            color: root.hotBeat ? "#E33131" : "#161616"
            opacity: root.playing ? 1.0 : 0.42

            Behavior on height {
                NumberAnimation {
                    duration: 95
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 125
                    easing.type: Easing.InOutSine
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: 180 }
            }
        }
    }
}
