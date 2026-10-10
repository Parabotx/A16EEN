import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    required property string navbarPosition
    property bool opened: false

    signal closeRequested()
    signal toolRequested(string toolId)

    readonly property bool horizontalNavbar:
        root.navbarPosition === "top" || root.navbarPosition === "bottom"
    readonly property real screenWidth: root.modelData ? root.modelData.width : 1920
    readonly property real screenHeight: root.modelData ? root.modelData.height : 1080
    readonly property int popupWidth: 322
    readonly property int popupHeight: 292
    readonly property var tools: [
        { id: "screenshot", label: "Screenshot", detail: "Capture your screen", icon: "lucide-crop.svg" },
        { id: "wallpapers", label: "Wallpapers", detail: "Change your background", icon: "lucide-image.svg" },
        { id: "clipboard", label: "Clipboard", detail: "Reuse copied text", icon: "lucide-clipboard.svg" },
        { id: "command-center", label: "Command center", detail: "Personalize A16EEN", icon: "lucide-sliders-horizontal.svg" }
    ]

    readonly property real popupX: root.horizontalNavbar
        ? root.screenWidth - root.popupWidth - 102
        : (root.navbarPosition === "left" ? 66 : root.screenWidth - root.popupWidth - 68)
    readonly property real popupY: root.horizontalNavbar
        ? (root.navbarPosition === "top" ? 40 : root.screenHeight - root.popupHeight - 40)
        : root.screenHeight - root.popupHeight - 72

    screen: root.modelData
    visible: root.opened && root.modelData !== null
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    focusable: root.opened
    width: root.screenWidth
    height: root.screenHeight

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-tools-panel"
    WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    MouseArea {
        id: outsideClick
        anchors.fill: parent
        z: 0
        focus: true
        acceptedButtons: Qt.AllButtons
        onClicked: root.closeRequested()
        Keys.onEscapePressed: root.closeRequested()
    }

    Item {
        id: card
        x: Math.max(8, Math.min(root.popupX, root.screenWidth - width - 8))
        y: Math.max(8, Math.min(root.popupY, root.screenHeight - height - 8))
            + (root.opened ? 0 : 6)
        width: Math.min(root.popupWidth, root.screenWidth - 16)
        height: Math.min(root.popupHeight, root.screenHeight - 16)
        z: 1
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.97

        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: "#FFFFFF"
            border.width: 1
            border.color: "#D9DEE5"

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: 20
                color: "#16000000"
                z: -1
            }

            MouseArea {
                anchors.fill: parent
                z: 0
                acceptedButtons: Qt.AllButtons
                onClicked: mouse.accepted = true
            }

            Column {
                id: content
                anchors.fill: parent
                anchors.margins: 13
                spacing: 9
                z: 1

                Row {
                    width: parent.width
                    height: 25
                    spacing: 8

                    Image {
                        width: 16
                        height: 16
                        anchors.verticalCenter: parent.verticalCenter
                        source: Qt.resolvedUrl("../assets/icons/lucide-wrench.svg")
                        sourceSize.width: 32
                        sourceSize.height: 32
                        smooth: true
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            text: "TOOLS"
                            color: "#171B21"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                        }

                        Text {
                            text: "Useful actions, one click away"
                            color: "#89929E"
                            font.pixelSize: 8
                        }
                    }
                }

                Grid {
                    id: toolsGrid
                    width: parent.width
                    columns: 2
                    spacing: 8
                    height: Math.ceil(root.tools.length / 2) * 72 + spacing

                    Repeater {
                        model: root.tools

                        delegate: Rectangle {
                            id: toolTile
                            required property var modelData
                            width: (toolsGrid.width - toolsGrid.spacing) / 2
                            height: 72
                            radius: 10
                            color: toolMouse.containsMouse ? "#EEF1F4" : "#FAFBFC"
                            border.width: 1
                            border.color: toolMouse.containsMouse ? "#DDE3E9" : "#EDF0F3"

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 9
                                anchors.rightMargin: 6
                                spacing: 8

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 8
                                    color: "#F0F3F6"
                                    anchors.verticalCenter: parent.verticalCenter

                                    Image {
                                        anchors.centerIn: parent
                                        width: 16
                                        height: 16
                                        source: Qt.resolvedUrl("../assets/icons/" + toolTile.modelData.icon)
                                        sourceSize.width: 32
                                        sourceSize.height: 32
                                        smooth: true
                                    }
                                }

                                Column {
                                    width: parent.width - 44
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4

                                    Text {
                                        width: parent.width
                                        text: toolTile.modelData.label
                                        color: "#242B34"
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: toolTile.modelData.detail
                                        color: "#8A939E"
                                        font.pixelSize: 7
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }
                                }
                            }

                            MouseArea {
                                id: toolMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toolRequested(toolTile.modelData.id)
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    height: 12
                    text: "A16EEN tools · more can be added here"
                    color: "#98A1AC"
                    font.pixelSize: 8
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible)
            Qt.callLater(() => outsideClick.forceActiveFocus())
    }
}
