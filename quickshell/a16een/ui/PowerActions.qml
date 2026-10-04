import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    property bool open: false
    property string confirmAction: ""

    implicitHeight: open ? 78 : 44
    radius: 14
    color: "#FFFFFF07"
    border.width: 1
    border.color: "#FFFFFF10"

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

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
                text: root.confirmAction.length ? "CLICK AGAIN TO CONFIRM" : (root.open ? "HIDE" : "SHOW")
                color: root.confirmAction.length ? "#E5A36B" : "#D7B56D"
                font.pixelSize: 8
                font.letterSpacing: 1.0
            }

            MouseArea {
                Layout.fillWidth: true
                Layout.fillHeight: true
                onClicked: {
                    root.confirmAction = ""
                    root.open = !root.open
                }
            }
        }

        RowLayout {
            visible: root.open
            Layout.fillWidth: true
            spacing: 6

            Button { label: "LOCK"; action: ["loginctl", "lock-session"]; confirm: false }
            Button { label: "LOG OUT"; action: ["niri", "msg", "action", "quit"]; confirm: false }
            Button { label: "REBOOT"; action: ["systemctl", "reboot"]; confirm: true }
            Button { label: "POWER"; action: ["systemctl", "poweroff"]; confirm: true }
        }
    }

    component Button: Rectangle {
        required property string label
        required property list<string> action
        property bool confirm: false

        Layout.fillWidth: true
        implicitHeight: 34
        radius: 10

        readonly property bool armed: root.confirmAction === label

        color: armed
            ? "#E5A36B1F"
            : (hover.containsMouse ? "#D7B56D18" : "#FFFFFF08")

        border.width: armed ? 1 : 0
        border.color: "#E5A36B66"

        Text {
            anchors.centerIn: parent
            text: parent.armed ? "CONFIRM" : label
            color: parent.armed ? "#E5A36B" : "#B9C0CB"
            font.pixelSize: 8
            font.weight: Font.DemiBold
            font.letterSpacing: 0.7
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (root.confirmAction.length && root.confirmAction !== label) {
                    root.confirmAction = ""
                }

                if (confirm && root.confirmAction !== label) {
                    root.confirmAction = label
                    return
                }

                root.confirmAction = ""
                Quickshell.execDetached(action)
            }
        }
    }
}
