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
        top: 78
        right: 18
    }

    implicitWidth: 390
    implicitHeight: 104

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 18
        color: "#0B0D12F3"
        border.width: 1
        border.color: "#FFFFFF18"

        RowLayout {
            anchors.fill: parent
            anchors.margins: 13
            spacing: 12

            IconImage {
                Layout.alignment: Qt.AlignTop
                implicitWidth: 32
                implicitHeight: 32
                source: notification && notification.appIcon
                    ? notification.appIcon
                    : Quickshell.iconPath("dialog-information", "dialog-information")
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    text: notification ? (notification.appName || "Notification") : ""
                    color: "#D7B56D"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }

                Text {
                    text: notification ? notification.summary : ""
                    color: "#F5F2EA"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: notification ? notification.body : ""
                    color: "#8D94A3"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
