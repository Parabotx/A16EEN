import QtQuick
import Quickshell

ShellRoot {
    PanelWindow {
        id: panel

        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: 42
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            anchors.margins: 8
            radius: 14
            color: "#101218"
            border.width: 1
            border.color: "#2A2F3A"

            Row {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 18

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "A16EEN"
                    color: "#E8D7A8"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "DESKTOP"
                    color: "#7F8795"
                    font.pixelSize: 10
                    font.letterSpacing: 1.5
                }

                Item {
                    width: 1
                    height: 1
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "FOUNDATION"
                    color: "#545B67"
                    font.pixelSize: 9
                    font.letterSpacing: 2
                }
            }
        }
    }
}
