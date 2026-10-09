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
    readonly property int popupWidth: 360
    readonly property int popupHeight: 300
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
            + (root.opened ? 0 : 8)
        width: Math.min(root.popupWidth, root.screenWidth - 16)
        height: Math.min(root.popupHeight, root.screenHeight - 16)
        z: 1
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.96
        transformOrigin: Item.Center

        Behavior on opacity {
            NumberAnimation {
                duration: 170
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 210
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: 210
                easing.type: Easing.OutCubic
            }
        }

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
                id: cardContent
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8
                z: 1

                Row {
                    id: modeTabs
                    width: parent.width
                    height: 29
                    spacing: 6

                    Repeater {
                        model: [
                            { id: "wifi", label: "Wi-Fi", icon: "wifi" },
                            { id: "bluetooth", label: "Bluetooth", icon: "bluetooth" }
                        ]

                        delegate: Rectangle {
                            id: tabButton
                            required property var modelData
                            width: (modeTabs.width - modeTabs.spacing) / 2
                            height: 29
                            radius: 9
                            color: root.selectedMode === tabButton.modelData.id
                                ? "#20262E"
                                : (tabMouse.containsMouse ? "#EEF1F4" : "#F6F7F9")
                            border.width: 1
                            border.color: root.selectedMode === tabButton.modelData.id
                                ? "#20262E" : "#E3E8ED"

                            Behavior on color {
                                ColorAnimation { duration: 120 }
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Image {
                                    width: 14
                                    height: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: Qt.resolvedUrl("../assets/icons/"
                                        + "lucide-" + tabButton.modelData.icon
                                        + (root.selectedMode === tabButton.modelData.id
                                            ? "-refined.svg" : "-refined-dark.svg"))
                                    sourceSize.width: 28
                                    sourceSize.height: 28
                                    smooth: true
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: tabButton.modelData.label
                                    color: root.selectedMode === tabButton.modelData.id
                                        ? "#FFFFFF" : "#5D6875"
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.modeRequested(tabButton.modelData.id)
                            }
                        }
                    }
                }

                Item {
                    id: detailPane
                    width: parent.width
                    height: parent.height - modeTabs.height - cardContent.spacing

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
