import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower

PanelWindow {
    id: root

    required property var modelData
    property bool opened: false
    property string activeTitle: "Desktop"
    property real systemLoad: 0
    property int volumePercent: 0
    property bool volumeMuted: false

    screen: modelData
    color: "transparent"
    visible: opened
    focusable: opened

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-dashboard"
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: opened ? 0.28 : 0
    }

    Rectangle {
        width: Math.min(520, parent.width - 36)
        height: Math.min(430, parent.height - 108)
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 70
        anchors.rightMargin: 18
        radius: 26
        color: "#0B0D12F5"
        border.width: 1
        border.color: "#FFFFFF18"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 14

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: -1

                    SystemClock {
                        id: clock
                        precision: SystemClock.Seconds
                    }

                    Text {
                        text: Qt.formatDateTime(clock.date, "HH:mm:ss")
                        color: "#F5F2EA"
                        font.pixelSize: 42
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: Qt.formatDateTime(clock.date, "dddd, dd MMMM yyyy")
                        color: "#8D94A3"
                        font.pixelSize: 12
                        font.letterSpacing: 0.5
                    }
                }

                Rectangle {
                    implicitWidth: 58
                    implicitHeight: 58
                    radius: 18
                    color: "#D7B56D16"
                    border.width: 1
                    border.color: "#D7B56D44"

                    Text {
                        anchors.centerIn: parent
                        text: "A16"
                        color: "#D7B56D"
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.2
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: "#FFFFFF10"
            }

            Text {
                text: root.activeTitle.length ? root.activeTitle : "No focused window"
                color: "#F5F2EA"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                StatCard {
                    title: "SYSTEM LOAD"
                    value: root.systemLoad.toFixed(2)
                    accent: "#D7B56D"
                }

                StatCard {
                    title: "VOLUME"
                    value: root.volumeMuted ? "MUTED" : root.volumePercent + "%"
                    accent: "#7FC8FF"
                }

                StatCard {
                    title: "BATTERY"
                    value: UPower.displayDevice.ready && UPower.displayDevice.isLaptopBattery
                        ? Math.round(UPower.displayDevice.percentage) + "%"
                        : "N/A"
                    accent: UPower.onBattery ? "#D7B56D" : "#8D94A3"
                }
            }

            Text {
                text: "QUICK ACTIONS"
                color: "#8D94A3"
                font.pixelSize: 9
                font.letterSpacing: 2
            }

            GridLayout {
                columns: 2
                rowSpacing: 8
                columnSpacing: 8
                Layout.fillWidth: true

                ActionCard { label: "SUPER + D"; description: "Application launcher" }
                ActionCard { label: "SUPER + O"; description: "Workspace overview" }
                ActionCard { label: "SUPER + RETURN"; description: "Terminal" }
                ActionCard { label: "SUPER + Q"; description: "Close window" }
            }

            Item { Layout.fillHeight: true }

            Text {
                text: "A16EEN • WORKSPACE " + "SYSTEM"
                color: "#545B67"
                font.pixelSize: 9
                font.letterSpacing: 1.4
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.opened = false
    }

    component StatCard: Rectangle {
        required property string title
        required property string value
        required property color accent

        Layout.fillWidth: true
        implicitHeight: 76
        radius: 16
        color: "#FFFFFF08"
        border.width: 1
        border.color: "#FFFFFF10"

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 12
            spacing: 2

            Text {
                text: title
                color: "#626A78"
                font.pixelSize: 8
                font.letterSpacing: 1.3
            }

            Text {
                text: value
                color: accent
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }
        }
    }

    component ActionCard: Rectangle {
        required property string label
        required property string description

        Layout.fillWidth: true
        implicitHeight: 58
        radius: 14
        color: "#FFFFFF06"
        border.width: 1
        border.color: "#FFFFFF0C"

        Column {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 12
            spacing: 2

            Text {
                text: label
                color: "#D7B56D"
                font.pixelSize: 9
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
            }

            Text {
                text: description
                color: "#8D94A3"
                font.pixelSize: 10
            }
        }
    }
}
