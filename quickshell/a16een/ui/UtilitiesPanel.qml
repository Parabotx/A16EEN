import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.ui

PanelWindow {
    id: root

    required property var modelData
    required property string navbarPosition
    property bool opened: false
    property bool dockVisible: true
    property string selectedMode: "wifi"

    signal closeRequested()
    signal modeRequested(string mode)

    readonly property bool horizontalNavbar:
        root.navbarPosition === "top" || root.navbarPosition === "bottom"
    readonly property real screenWidth: root.modelData ? root.modelData.width : 1920
    readonly property real screenHeight: root.modelData ? root.modelData.height : 1080
    readonly property int popupWidth: 580
    readonly property int popupHeight: 418
    readonly property real popupX: root.horizontalNavbar
        ? 100
        : (root.navbarPosition === "left"
            ? 66
            : Math.max(8, root.screenWidth - root.popupWidth - 66))
    readonly property real popupY: root.horizontalNavbar
        ? (root.navbarPosition === "top"
            ? 42
            : Math.max(8, root.screenHeight - root.popupHeight - 42))
        : 118

    screen: root.modelData
    visible: root.opened && root.dockVisible && root.modelData !== null
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
    WlrLayershell.namespace: "a16een-utilities"
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
        width: Math.min(root.popupWidth, root.screenWidth - 16)
        height: Math.min(root.popupHeight, root.screenHeight - 16)
        z: 1

        Rectangle {
            anchors.fill: parent
            radius: 19
            color: "#FFFFFF"
            border.width: 1
            border.color: "#D9DEE5"

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: 23
                color: "#16000000"
                z: -1
            }

            MouseArea {
                anchors.fill: parent
                z: 0
                acceptedButtons: Qt.AllButtons
                onClicked: mouse.accepted = true
            }

            Row {
                id: cardContent
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12
                z: 1

                Column {
                    id: sidebar
                    width: 118
                    height: parent.height
                    spacing: 8

                    Item {
                        width: parent.width
                        height: 42

                        Column {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Text {
                                text: "UTILITIES"
                                color: "#111318"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.1
                            }

                            Text {
                                text: "CONNECTIONS"
                                color: "#8A939E"
                                font.pixelSize: 7
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.0
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#E7EAEE"
                    }

                    Rectangle {
                        id: wifiTab
                        width: parent.width
                        height: 58
                        radius: 12
                        color: root.selectedMode === "wifi" ? "#F1F3F5" : (wifiTabMouse.containsMouse ? "#F8F9FA" : "transparent")
                        border.width: root.selectedMode === "wifi" ? 1 : 0
                        border.color: "#D9DEE5"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            anchors.rightMargin: 6
                            spacing: 8

                            Item {
                                width: 22
                                height: 22
                                anchors.verticalCenter: parent.verticalCenter

                                Image {
                                    anchors.centerIn: parent
                                    width: 17
                                    height: 17
                                    source: Qt.resolvedUrl("../assets/icons/lucide-wifi.svg")
                                    sourceSize.width: 34
                                    sourceSize.height: 34
                                    smooth: true
                                    opacity: 0.9
                                }

                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    color: details.wifiState === "on" && details.wifiName !== "Not connected" ? "#3FA779"
                                        : (details.wifiState === "off" ? "#B8C0C9" : "#D5A94F")
                                    border.width: 1
                                    border.color: "#FFFFFF"
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 30
                                spacing: 4

                                Text {
                                    text: "Wi-Fi"
                                    color: "#171B21"
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    width: parent.width
                                    text: root.wifiStatusText
                                    color: "#7A8490"
                                    font.pixelSize: 7
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            id: wifiTabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.modeRequested("wifi")
                        }
                    }

                    Rectangle {
                        id: bluetoothTab
                        width: parent.width
                        height: 58
                        radius: 12
                        color: root.selectedMode === "bluetooth" ? "#F1F3F5" : (bluetoothTabMouse.containsMouse ? "#F8F9FA" : "transparent")
                        border.width: root.selectedMode === "bluetooth" ? 1 : 0
                        border.color: "#D9DEE5"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            anchors.rightMargin: 6
                            spacing: 8

                            Item {
                                width: 22
                                height: 22
                                anchors.verticalCenter: parent.verticalCenter

                                Image {
                                    anchors.centerIn: parent
                                    width: 17
                                    height: 17
                                    source: Qt.resolvedUrl("../assets/icons/lucide-bluetooth.svg")
                                    sourceSize.width: 34
                                    sourceSize.height: 34
                                    smooth: true
                                    opacity: 0.9
                                }

                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    color: details.bluetoothState === "on" ? "#3FA779"
                                        : (details.bluetoothState === "off" ? "#B8C0C9" : "#D5A94F")
                                    border.width: 1
                                    border.color: "#FFFFFF"
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 30
                                spacing: 4

                                Text {
                                    text: "Bluetooth"
                                    color: "#171B21"
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    width: parent.width
                                    text: root.bluetoothStatusText
                                    color: "#7A8490"
                                    font.pixelSize: 7
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            id: bluetoothTabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.modeRequested("bluetooth")
                        }
                    }

                    Item { width: 1; height: 1 }

                    Text {
                        width: parent.width
                        text: "LIVE STATUS"
                        color: "#A0A8B2"
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.0
                    }
                }

                Rectangle {
                    width: 1
                    height: parent.height
                    color: "#E7EAEE"
                }

                Item {
                    id: detailPane
                    width: cardContent.width - sidebar.width - 1 - cardContent.spacing * 2
                    height: parent.height

                    ControlDetailSection {
                        id: details
                        anchors.fill: parent
                        mode: root.selectedMode
                        active: root.opened
                        embedded: true
                        doNotDisturb: false
                        onBackRequested: root.closeRequested()
                    }
                }
            }
        }
    }

    readonly property string wifiStatusText: {
        if (details.wifiState === "unavailable")
            return "Unavailable"
        if (details.wifiState === "off")
            return "Turned off"
        return details.wifiName !== "Not connected" ? "Connected" : "Enabled"
    }

    readonly property string bluetoothStatusText: {
        if (details.bluetoothState === "unavailable")
            return "Unavailable"
        if (details.bluetoothState === "off")
            return "Turned off"
        return details.bluetoothDevices.some(device => device.connected)
            ? "Connected"
            : "Enabled"
    }
}
