import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool widgetEnabled: false
    property var workspaces: []
    property int focusedWorkspaceId: -1

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
    WlrLayershell.namespace: "a16een-widget-workspaces"

    Rectangle {
        width: 290
        height: 104
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 72
        anchors.rightMargin: 28
        radius: 18
        color: "#080808"
        border.width: 1
        border.color: "#202020"

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 9

            Text {
                text: "WORKSPACE MATRIX"
                color: "#BEBEBE"
                font.pixelSize: 8
                font.weight: Font.DemiBold
                font.letterSpacing: 1.2
            }

            Row {
                width: parent.width
                height: 38
                spacing: 6

                Repeater {
                    model: root.workspaces

                    delegate: Rectangle {
                        width: 28
                        height: 28
                        radius: 8
                        color: modelData.id === root.focusedWorkspaceId ? "#1B1B1B" : "#0D0D0D"
                        border.width: 1
                        border.color: modelData.id === root.focusedWorkspaceId ? "#333333" : "#181818"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.idx !== undefined ? modelData.idx : modelData.id
                            color: modelData.id === root.focusedWorkspaceId ? "#D7B56D" : "#5B5B5B"
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }
        }
    }
}
