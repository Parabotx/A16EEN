import QtQuick

Item {
    id: root

    property bool animating: true
    property bool playing: false
    property real audioLevel: 0
    property var bandLevels: []

    // Transparent equalizer: one simple monochrome style, no beat flash or backdrop.
    Repeater {
        model: 21

        delegate: Rectangle {
            required property int index

            readonly property real bandValue: root.bandLevels
                && root.bandLevels.length > index
                ? Math.max(0, Math.min(1, Number(root.bandLevels[index]) || 0))
                : Math.max(0, Math.min(1, root.audioLevel * 0.65))
            readonly property real quietHeight: 3 + 4 * Math.abs(Math.sin(index * 0.76))

            x: 2 + index * 4.65
            y: root.height - height - 5
            width: 2.5
            height: root.playing
                ? 3.5 + Math.pow(bandValue, 0.62) * Math.min(56, root.height - 10)
                : quietHeight
            radius: 1.25
            color: "#171717"
            opacity: root.playing ? 1.0 : 0.42

            Behavior on height {
                NumberAnimation {
                    duration: 88
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: 140 }
            }
        }
    }
}
