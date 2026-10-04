import QtQuick
import Quickshell

Rectangle {
    id: root

    property string label: ""
    property string value: ""
    property string iconText: "•"
    property color accent: "#D7B56D"

    implicitWidth: content.implicitWidth + 22
    implicitHeight: 30
    radius: 10
    color: "#FFFFFF08"
    border.width: 1
    border.color: "#FFFFFF0D"

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: root.iconText
            color: root.accent
            font.pixelSize: 10
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.label.length ? root.label + (root.value.length ? "  " : "") + root.value : root.value
            color: "#A5ACB8"
            font.pixelSize: 9
            font.letterSpacing: 0.7
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
