import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower

PanelWindow {
    id: root

    required property var modelData
    property var workspaces: []
    property int focusedWorkspaceId: -1
    property string activeTitle: "A16EEN"
    property real systemLoad: 0
    property int volumePercent: 0
    property bool volumeMuted: false

    property color panelColor: "#0B0D12E8"
    property color panelBorder: "#FFFFFF16"
    property color textPrimary: "#F5F2EA"
    property color textSecondary: "#8D94A3"
    property color accent: "#D7B56D"

    screen: modelData
    color: "transparent"
    aboveWindows: true
    exclusiveZone: 64

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: 12
        left: 14
        right: 14
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        radius: 16
        color: root.panelColor
        border.width: 1
        border.color: root.panelBorder

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: "A16EEN"
                color: root.accent
                font.pixelSize: 15
                font.weight: Font.DemiBold
                font.letterSpacing: 1.4
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 1
                implicitHeight: 20
                color: root.panelBorder
            }

            Row {
                Layout.alignment: Qt.AlignVCenter
                spacing: 5

                Repeater {
                    model: root.workspaces

                    delegate: Rectangle {
                        required property var modelData

                        width: modelData.name ? 74 : 42
                        height: 28
                        radius: 10
                        color: modelData.id === root.focusedWorkspaceId ? "#D7B56D20" : "#FFFFFF08"
                        border.width: modelData.id === root.focusedWorkspaceId ? 1 : 0
                        border.color: "#D7B56D80"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.name || String(modelData.idx || 1)
                            color: modelData.id === root.focusedWorkspaceId ? root.accent : root.textSecondary
                            font.pixelSize: 11
                            font.weight: modelData.id === root.focusedWorkspaceId ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            visible: modelData.is_urgent === true
                            width: 5
                            height: 5
                            radius: 2.5
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 5
                            color: "#E56B6F"
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 8

                Text {
                    Layout.maximumWidth: 330
                    text: root.activeTitle
                    color: root.textSecondary
                    font.pixelSize: 11
                    elide: Text.ElideMiddle
                    visible: root.activeTitle.length > 0
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 1
                implicitHeight: 20
                color: root.panelBorder
            }

            Row {
                Layout.alignment: Qt.AlignVCenter
                spacing: 10

                Text {
                    text: "LOAD " + root.systemLoad.toFixed(2)
                    color: root.textSecondary
                    font.pixelSize: 10
                    font.letterSpacing: 0.8
                }

                Text {
                    text: root.volumeMuted ? "VOL MUTE" : "VOL " + root.volumePercent + "%"
                    color: root.textSecondary
                    font.pixelSize: 10
                    font.letterSpacing: 0.8
                }

                Text {
                    visible: UPower.displayDevice.ready && UPower.displayDevice.isLaptopBattery
                    text: "BAT " + Math.round(UPower.displayDevice.percentage) + "%"
                    color: UPower.onBattery ? root.accent : root.textSecondary
                    font.pixelSize: 10
                    font.letterSpacing: 0.8
                }
            }

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            Column {
                Layout.alignment: Qt.AlignVCenter
                spacing: -1

                Text {
                    anchors.right: parent.right
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: root.textPrimary
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    anchors.right: parent.right
                    text: Qt.formatDateTime(clock.date, "ddd, dd MMM")
                    color: root.textSecondary
                    font.pixelSize: 9
                    font.letterSpacing: 0.6
                }
            }
        }
    }
}
