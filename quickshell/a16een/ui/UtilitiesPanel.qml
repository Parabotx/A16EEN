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
    readonly property int popupWidth: 420
    readonly property int popupHeight: 320
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
                anchors.margins: 12
                spacing: 8
                z: 1
                layoutDirection: root.navbarPosition === "right"
                    ? Qt.RightToLeft : Qt.LeftToRight

                Item {
                    id: sidebar
                    width: 36
                    height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Rectangle {
                            id: wifiTab
                            width: 32
                            height: 32
                            radius: 10
                            color: root.selectedMode === "wifi"
                                ? "#EEF1F4"
                                : (wifiTabMouse.containsMouse ? "#F7F8FA" : "transparent")
                            border.width: root.selectedMode === "wifi" ? 1 : 0
                            border.color: "#D9DEE5"

                            Image {
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                source: Qt.resolvedUrl("../assets/icons/lucide-wifi-dark.svg")
                                sourceSize.width: 32
                                sourceSize.height: 32
                                smooth: true
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
                            width: 32
                            height: 32
                            radius: 10
                            color: root.selectedMode === "bluetooth"
                                ? "#EEF1F4"
                                : (bluetoothTabMouse.containsMouse ? "#F7F8FA" : "transparent")
                            border.width: root.selectedMode === "bluetooth" ? 1 : 0
                            border.color: "#D9DEE5"

                            Image {
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                source: Qt.resolvedUrl("../assets/icons/lucide-bluetooth-dark.svg")
                                sourceSize.width: 32
                                sourceSize.height: 32
                                smooth: true
                            }

                            MouseArea {
                                id: bluetoothTabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.modeRequested("bluetooth")
                            }
                        }
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

}
