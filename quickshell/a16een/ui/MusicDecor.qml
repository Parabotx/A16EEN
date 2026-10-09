import QtQuick

Item {
    id: root

    readonly property real recordSize: Math.min(width, height) - 10

    // A quiet, monochrome vinyl-inspired mark: purely decorative and static.
    Rectangle {
        id: record
        anchors.centerIn: parent
        width: root.recordSize
        height: root.recordSize
        radius: width / 2
        color: "transparent"
        border.width: 1.2
        border.color: "#171717"

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.76
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: "#C7B8A4"
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.52
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: "#DED2C2"
        }

        Rectangle {
            anchors.centerIn: parent
            width: 13
            height: 13
            radius: width / 2
            color: "#171717"

            Rectangle {
                anchors.centerIn: parent
                width: 3
                height: 3
                radius: width / 2
                color: "#FFF5E7"
            }
        }
    }

    Rectangle {
        width: 12
        height: 2
        radius: 1
        x: root.width / 2 + root.recordSize * 0.30
        y: root.height / 2 - root.recordSize * 0.34
        rotation: 42
        color: "#171717"
    }

    Rectangle {
        width: 4
        height: 4
        radius: width / 2
        x: root.width / 2 + root.recordSize * 0.39
        y: root.height / 2 - root.recordSize * 0.40
        color: "#171717"
    }
}
