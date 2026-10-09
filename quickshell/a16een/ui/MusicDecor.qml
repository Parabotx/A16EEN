import QtQuick

Item {
    id: root

    property bool animating: true
    property bool playing: false

    clip: true

    Rectangle {
        anchors.fill: parent
        radius: 15
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#FCF4EA" }
            GradientStop { position: 0.55; color: "#F6EBDD" }
            GradientStop { position: 1.0; color: "#F0E8F1" }
        }
        border.width: 1
        border.color: "#E5D5C3"
    }

    // Soft watercolor-like halos keep the rain from feeling like a flat overlay.
    Rectangle {
        width: 58
        height: 58
        x: -20
        y: 35
        radius: 29
        color: "#E8C7B6"
        opacity: 0.27
    }

    Rectangle {
        width: 54
        height: 54
        x: 65
        y: -20
        radius: 27
        color: "#D6CBEA"
        opacity: 0.34
    }

    Rectangle {
        width: 126
        height: 18
        x: -18
        y: 28
        rotation: -24
        radius: 9
        color: "#FFFFFF"
        opacity: 0.26
    }

    Rectangle {
        width: 112
        height: 1
        x: -4
        y: 39
        rotation: -24
        color: "#D8BCA6"
        opacity: 0.28
    }

    // Diagonal rain: droplets fall toward the lower-right at several staggered speeds.
    Repeater {
        model: 24

        delegate: Item {
            id: rainParticle
            required property int index

            property real seedX: ((index * 29 + 13) % (root.width + 14)) - 7
            property real seedY: ((index * 17 + 9) % (root.height + 18)) - 9
            property real driftX: 13 + ((index * 5) % 13)
            property int fallDuration: (root.playing ? 1050 : 1500) + ((index * 97) % 820)
            property real seedOpacity: 0.24 + ((index * 7) % 5) * 0.105

            width: index % 5 === 0 ? 2.5 : index % 3 === 0 ? 2 : 1.5
            height: index % 5 === 0 ? 7 : index % 3 === 0 ? 4 : 2
            x: seedX
            y: seedY
            rotation: index % 5 === 0 ? 22 : 14
            opacity: seedOpacity

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: rainParticle.index % 4 === 0 ? "#C99B63"
                    : rainParticle.index % 4 === 1 ? "#D58C83"
                    : rainParticle.index % 4 === 2 ? "#A99ACB" : "#C6A38F"
            }

            SequentialAnimation {
                running: root.animating
                loops: Animation.Infinite

                PauseAnimation { duration: (rainParticle.index * 83) % 960 }

                ParallelAnimation {
                    NumberAnimation {
                        target: rainParticle
                        property: "x"
                        from: rainParticle.seedX
                        to: rainParticle.seedX + rainParticle.driftX
                        duration: rainParticle.fallDuration
                        easing.type: Easing.Linear
                    }

                    NumberAnimation {
                        target: rainParticle
                        property: "y"
                        from: rainParticle.seedY
                        to: root.height + 9
                        duration: rainParticle.fallDuration
                        easing.type: Easing.Linear
                    }

                    NumberAnimation {
                        target: rainParticle
                        property: "opacity"
                        from: rainParticle.seedOpacity
                        to: 0.035
                        duration: rainParticle.fallDuration
                        easing.type: Easing.Linear
                    }
                }
            }
        }
    }

    // Quiet glints add depth without competing with the artwork or track title.
    Rectangle {
        width: 4
        height: 4
        x: 13
        y: 14
        radius: 1
        rotation: 45
        color: "#D2A46D"
        opacity: 0.45

        SequentialAnimation on opacity {
            running: root.animating
            loops: Animation.Infinite
            NumberAnimation { to: 0.92; duration: 660; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.28; duration: 820; easing.type: Easing.InOutSine }
        }
    }

    Rectangle {
        width: 3
        height: 3
        x: 80
        y: 22
        radius: 0.8
        rotation: 45
        color: "#D58C83"
        opacity: 0.4

        SequentialAnimation on opacity {
            running: root.animating
            loops: Animation.Infinite
            PauseAnimation { duration: 240 }
            NumberAnimation { to: 0.9; duration: 740; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.26; duration: 840; easing.type: Easing.InOutSine }
        }
    }

    // A tiny five-bar equalizer ties the rain motif to the current audio state.
    Repeater {
        model: 5

        delegate: Rectangle {
            id: equalizerBar
            required property int index
            property real restingHeight: 3 + (index % 3) * 2

            x: root.width - 31 + index * 4.5
            y: root.height - height - 6
            width: 2.5
            height: restingHeight
            radius: 1.25
            color: index % 2 === 0 ? "#C98765" : "#A99ACB"
            opacity: root.playing ? 0.74 : 0.38

            Behavior on opacity { NumberAnimation { duration: 200 } }

            SequentialAnimation on height {
                running: root.animating && root.playing
                loops: Animation.Infinite
                NumberAnimation {
                    to: equalizerBar.restingHeight + 3
                    duration: 240 + equalizerBar.index * 47
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: equalizerBar.restingHeight
                    duration: 280 + equalizerBar.index * 53
                    easing.type: Easing.InOutSine
                }
            }
        }
    }
}
