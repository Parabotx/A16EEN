import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    property bool open: false

    implicitHeight: open ? 78 : 44
    radius: 14
    color: "#FFFFFF07"
    border.width: 1
    border.color: "#FFFFFF10"

    Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 28

            Text {
                text: "SESSION"
                color: "#8D94A3"
                font.pixelSize: 9
                font.letterSpacing: 1.6
                Layout.fillWidth: true
            }

            Text {
                text: root.open ? "HIDE" : "SHOW"
                color: "#D7B56D"
                font.pixelSize: 8
                font.letterSpacing: 1.2
            }

            MouseArea {
                Layout.fillWidth: true
                Layout.fillHeight: true
                onClicked: root.open = !root.open
            }
        }

        RowLayout {
            visible: root.open
            Layout.fillWidth: true
            spacing: 6

            Button {
                label: "LOCK"
                action: ["loginctl", "lock-session"]
            }
            Button {
                label: "LOG OUT"
                action: ["niri", "msg", "action", "quit"]
            }
            Button {
                label: "REBOOT"
                action: ["systemctl", "reboot"]
            }
            Button {
                label: "POWER"
                action: ["systemctl", "poweroff"]
            }
        }
    }

    component Button: Rectangle {
        required property string label
        required property list<string> action

        Layout.fillWidth: true
        implicitHeight: 34
        radius: 10
        color: hover.containsMouse ? "#D7B56D18" : "#FFFFFF08"

        Text {
            anchors.centerIn: parent
            text: label
            color: "#B9C0CB"
            font.pixelSize: 8
            font.weight: Font.DemiBold
            font.letterSpacing: 0.7
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: Quickshell.execDetached(root.action)
        }
    }
}
