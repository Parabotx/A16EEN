import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    required property string navbarPosition
    required property bool dockVisible
    property int unreadCount: 0
    property bool notificationsOpen: false
    property bool toolsOpen: false

    signal notificationsRequested()
    signal toolsRequested()

    readonly property bool horizontalNavbar:
        root.navbarPosition === "top" || root.navbarPosition === "bottom"

    screen: root.modelData
    visible: root.dockVisible && root.modelData !== null
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    width: root.horizontalNavbar ? 52 : 28
    height: root.horizontalNavbar ? 28 : 52

    anchors {
        left: !root.horizontalNavbar && root.navbarPosition === "left"
        right: root.horizontalNavbar || root.navbarPosition === "right"
        top: root.navbarPosition === "top"
        bottom: root.navbarPosition !== "top"
    }

    // Sit directly between the main navbar and the Notes / Tasks / Presets tray.
    margins {
        left: root.horizontalNavbar ? 0 : 10
        right: root.horizontalNavbar ? 186 : 10
        top: 0
        bottom: root.horizontalNavbar ? 0 : 156
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-notifications-tools"

    Rectangle {
        anchors.fill: parent
        radius: 11
        color: "#FFFFFF"
        border.width: 1
        border.color: "#D9DEE5"

        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: 14
            color: "#10000000"
            z: -1
        }

        Row {
            visible: root.horizontalNavbar
            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: [
                    { id: "notifications", icon: "lucide-bell.svg", active: root.notificationsOpen },
                    { id: "tools", icon: "lucide-toolbox.svg", active: root.toolsOpen }
                ]

                delegate: Item {
                    id: actionItem
                    required property var modelData
                    width: 22
                    height: 22

                    Rectangle {
                        anchors.fill: parent
                        radius: 7
                        color: actionMouse.containsMouse || actionItem.modelData.active
                            ? "#F0F2F5" : "transparent"
                        border.width: actionItem.modelData.active ? 1 : 0
                        border.color: "#E2E6EB"

                        Image {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            source: Qt.resolvedUrl("../assets/icons/" + actionItem.modelData.icon)
                            sourceSize.width: 64
                            sourceSize.height: 64
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }
                    }

                    Rectangle {
                        visible: actionItem.modelData.id === "notifications" && root.unreadCount > 0
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.rightMargin: 0
                        anchors.topMargin: 0
                        width: root.unreadCount > 9 ? 13 : 10
                        height: 10
                        radius: 5
                        color: "#D94841"
                        border.width: 1
                        border.color: "#FFFFFF"

                        Text {
                            anchors.centerIn: parent
                            text: root.unreadCount > 9 ? "9+" : String(root.unreadCount)
                            color: "#FFFFFF"
                            font.pixelSize: 6
                            font.weight: Font.Bold
                            visible: root.unreadCount > 1
                        }
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activate(actionItem.modelData.id)
                    }
                }
            }
        }

        Column {
            visible: !root.horizontalNavbar
            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: [
                    { id: "notifications", icon: "lucide-bell.svg", active: root.notificationsOpen },
                    { id: "tools", icon: "lucide-toolbox.svg", active: root.toolsOpen }
                ]

                delegate: Item {
                    id: actionItem
                    required property var modelData
                    width: 22
                    height: 22

                    Rectangle {
                        anchors.fill: parent
                        radius: 7
                        color: actionMouse.containsMouse || actionItem.modelData.active
                            ? "#F0F2F5" : "transparent"
                        border.width: actionItem.modelData.active ? 1 : 0
                        border.color: "#E2E6EB"

                        Image {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            source: Qt.resolvedUrl("../assets/icons/" + actionItem.modelData.icon)
                            sourceSize.width: 64
                            sourceSize.height: 64
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }
                    }

                    Rectangle {
                        visible: actionItem.modelData.id === "notifications" && root.unreadCount > 0
                        anchors.right: parent.right
                        anchors.top: parent.top
                        width: root.unreadCount > 9 ? 13 : 10
                        height: 10
                        radius: 5
                        color: "#D94841"
                        border.width: 1
                        border.color: "#FFFFFF"

                        Text {
                            anchors.centerIn: parent
                            text: root.unreadCount > 9 ? "9+" : String(root.unreadCount)
                            color: "#FFFFFF"
                            font.pixelSize: 6
                            font.weight: Font.Bold
                            visible: root.unreadCount > 1
                        }
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activate(actionItem.modelData.id)
                    }
                }
            }
        }
    }

    function activate(actionId) {
        if (actionId === "notifications")
            root.notificationsRequested()
        else if (actionId === "tools")
            root.toolsRequested()
    }
}
