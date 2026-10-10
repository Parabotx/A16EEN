import QtQuick

Item {
    id: root

    property bool playing: false
    readonly property real recordSize: Math.min(width, height) - 8

    Item {
        id: spinningDisc
        anchors.centerIn: parent
        width: root.recordSize
        height: root.recordSize
        rotation: 0
        opacity: root.playing ? 1.0 : 0.68

        // CD-inspired metallic disc: a slow, uninterrupted turn without
        // a spectrum visualizer, per-frame calculations, or external processes.
        RotationAnimation on rotation {
            from: 0
            to: 360
            duration: 8200
            loops: Animation.Infinite
            running: root.playing
            easing.type: Easing.Linear
        }

        Rectangle {
            id: discFace
            anchors.fill: parent
            radius: width / 2
            border.width: 1
            border.color: "#78FFFFFF"
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#DCECF6" }
                GradientStop { position: 0.27; color: "#B6B9EE" }
                GradientStop { position: 0.62; color: "#EABDD6" }
                GradientStop { position: 1.0; color: "#8DD6CF" }
            }
        }

        // Fine, translucent grooves sit inside the filled metallic disc.
        Rectangle {
            anchors.centerIn: parent
            width: spinningDisc.width * 0.78
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: "#72FFFFFF"
        }

        Rectangle {
            anchors.centerIn: parent
            width: spinningDisc.width * 0.56
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: "#52617F98"
        }

        Rectangle {
            anchors.centerIn: parent
            width: spinningDisc.width * 0.32
            height: width
            radius: width / 2
            border.width: 1
            border.color: "#A8FFFFFF"
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#F8FBFF" }
                GradientStop { position: 0.5; color: "#C9D9F0" }
                GradientStop { position: 1.0; color: "#A8D6D7" }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 5
            height: 5
            radius: width / 2
            color: "#243349"
            border.width: 1
            border.color: "#D9FFFFFF"
        }

        Rectangle {
            width: spinningDisc.width * 0.23
            height: 2
            x: spinningDisc.width * 0.60
            y: spinningDisc.height * 0.25
            rotation: -42
            radius: 1
            color: "#58FFFFFF"
        }

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
    }
}
