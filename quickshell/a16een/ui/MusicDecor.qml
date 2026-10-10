import QtQuick
import QtQuick.Effects

Item {
    id: root

    property bool playing: false
    property string coverSource: ""
    property bool woodTone: false

    readonly property real recordSize: Math.min(width, height) - 8
    readonly property bool hasCover: root.coverSource.length > 0
        && coverImage.status === Image.Ready

    // Alternate between brushed silver-glass and warm, restrained wood only
    // when no cover art is available. This is a single, inexpensive timer.
    Timer {
        interval: 10000
        repeat: true
        running: root.playing && !root.hasCover
        onTriggered: root.woodTone = !root.woodTone
    }

    Item {
        id: spinningDisc
        anchors.centerIn: parent
        width: root.recordSize
        height: root.recordSize
        rotation: 0
        opacity: root.playing ? 1.0 : 0.72

        // CD-inspired metallic disc with understated fallback materials and smooth motion.
    // One rotation only; no visualizer or external polling.
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
            visible: !root.hasCover
            border.width: 1
            border.color: root.woodTone ? "#A88D67" : "#B8C8D4"
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.woodTone ? "#D5BE9A" : "#E5EBF0" }
                GradientStop { position: 0.25; color: root.woodTone ? "#B99B70" : "#C9D4DE" }
                GradientStop { position: 0.52; color: root.woodTone ? "#E1CDA9" : "#F5F8FA" }
                GradientStop { position: 0.78; color: root.woodTone ? "#AD8D62" : "#B9C8D4" }
                GradientStop { position: 1.0; color: root.woodTone ? "#D6BD96" : "#DCE5EB" }
            }
        }

        // Subtle grain/reflection lines add texture without crowding the disc.
        Rectangle {
            visible: !root.hasCover
            width: spinningDisc.width * 0.43
            height: 1
            x: spinningDisc.width * 0.25
            y: spinningDisc.height * 0.28
            rotation: -34
            radius: 1
            color: root.woodTone ? "#60FFF4DE" : "#9FFFFFFF"
        }

        Rectangle {
            visible: !root.hasCover
            width: spinningDisc.width * 0.28
            height: 1
            x: spinningDisc.width * 0.44
            y: spinningDisc.height * 0.69
            rotation: -34
            radius: 1
            color: root.woodTone ? "#55846A49" : "#7B8797A5"
        }

        Rectangle {
            anchors.centerIn: parent
            width: spinningDisc.width * 0.77
            height: width
            radius: width / 2
            visible: !root.hasCover
            color: "transparent"
            border.width: 1
            border.color: root.woodTone ? "#46F5E3BD" : "#67FFFFFF"
        }

        Rectangle {
            anchors.centerIn: parent
            width: spinningDisc.width * 0.56
            height: width
            radius: width / 2
            visible: !root.hasCover
            color: "transparent"
            border.width: 1
            border.color: root.woodTone ? "#3891744F" : "#526C8396"
        }

        // The cover art is masked into a true circle, then rotates with the disc.
        Image {
            id: coverImage
            anchors.fill: parent
            source: root.coverSource
            visible: false
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            sourceSize.width: 256
            sourceSize.height: 256
        }

        MultiEffect {
            anchors.fill: parent
            source: coverImage
            visible: root.hasCover
            maskEnabled: true
            maskSource: Item {
                visible: false
                width: spinningDisc.width
                height: spinningDisc.height
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "#FFFFFF"
                    antialiasing: true
                }
            }
        }

        // A tiny center pin completes the CD silhouette without hiding artwork.
        Rectangle {
            anchors.centerIn: parent
            width: 5
            height: 5
            radius: width / 2
            color: root.hasCover ? "#E9FFFFFF" : (root.woodTone ? "#6C5236" : "#536575")
            border.width: 1
            border.color: "#B8FFFFFF"
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: root.hasCover ? "#76FFFFFF"
                : (root.woodTone ? "#67F1DEB9" : "#8BA7B8C8")
        }

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
    }
}
