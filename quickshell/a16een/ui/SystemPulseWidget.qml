import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool widgetEnabled: false
    property real systemLoad: 0
    property int volumePercent: 0
    property bool volumeMuted: false

    screen: modelData
    visible: root.widgetEnabled
    color: "transparent"
    aboveWindows: false
    exclusiveZone: 0

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "a16een-widget-pulse"

    Rectangle {
        width: 260
        height: 108
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 28
        anchors.leftMargin: 28
        radius: 18
        color: "#080808"
        border.width: 1
        border.color: "#202020"

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 10

            Row {
                width: parent.width
                height: 16

                Text {
                    text: "SYSTEM PULSE"
                    color: "#BEBEBE"
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.2
                }

                Item {
                    width: parent.width - 118
                    height: 1
                }

                Text {
                    width: 118
                    horizontalAlignment: Text.AlignRight
                    text: "A16EEN"
                    color: "#3F3F3F"
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                }
            }

            Row {
                width: parent.width
                height: 42
                spacing: 24

                Column {
                    width: 92
                    spacing: 3

                    Text {
                        text: Math.round(root.systemLoad * 100) + "%"
                        color: "#FFFFFF"
                        font.pixelSize: 25
                        font.weight: Font.Light
                    }

                    Text {
                        text: "SYSTEM LOAD"
                        color: "#4D4D4D"
                        font.pixelSize: 6
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1
                    }
                }

                Column {
                    width: 92
                    spacing: 3

                    Text {
                        text: root.volumeMuted ? "MUTE" : root.volumePercent + "%"
                        color: root.volumeMuted ? "#777777" : "#D7B56D"
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: "AUDIO"
                        color: "#4D4D4D"
                        font.pixelSize: 6
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1
                    }
                }
            }
        }
    }
}
