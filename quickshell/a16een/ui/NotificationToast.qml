import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

PanelWindow {
    id: root

    required property var modelData
    property var notification: null

    screen: modelData
    color: "transparent"
    visible: notification !== null

    anchors {
        top: true
        right: true
    }

    margins {
        top: 72
        right: 14
    }

    implicitWidth: 322
    implicitHeight: 78

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: "#FFFFFF"
        border.width: 1
        border.color: "#D9DEE5"

        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: 18
            color: "#16000000"
            z: -1
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 9

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                Layout.alignment: Qt.AlignTop
                radius: 8
                color: "#F1F3F6"

                IconImage {
                    anchors.centerIn: parent
                    implicitWidth: 18
                    implicitHeight: 18
                    source: root.notification && root.notification.appIcon
                        ? root.notification.appIcon
                        : Quickshell.iconPath("dialog-information", "dialog-information")
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: root.notification ? (root.notification.appName || "Notification") : ""
                    color: "#7C8794"
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: root.notification ? (root.notification.summary || "Notification") : ""
                    color: "#20262E"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: root.notification ? (root.notification.body || "") : ""
                    color: "#7D8793"
                    font.pixelSize: 9
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    Layout.fillWidth: true
                }
            }
        }
    }
}
