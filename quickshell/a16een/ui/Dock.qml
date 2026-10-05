import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    required property var workspaces

    signal launcherRequested()

    readonly property color dockBackground: "#FFFFFEF8"
    readonly property color dockBorder: "#E5E7EB"
    readonly property color iconColor: "#111827"
    readonly property color hoverBackground: "#F1F3F5"
    readonly property color activeBackground: "#E8EAED"

    readonly property var workspaceDefinitions: [
        { name: "home", label: "Home", icon: Qt.resolvedUrl("../assets/icons/house.svg") },
        { name: "code", label: "Development", icon: Qt.resolvedUrl("../assets/icons/code-2.svg") },
        { name: "web", label: "Web", icon: Qt.resolvedUrl("../assets/icons/globe.svg") },
        { name: "comms", label: "Communication", icon: Qt.resolvedUrl("../assets/icons/messages-square.svg") },
        { name: "studio", label: "Studio", icon: Qt.resolvedUrl("../assets/icons/sparkles.svg") }
    ]

    readonly property string searchIcon: Qt.resolvedUrl("../assets/icons/search.svg")

    screen: modelData
    color: "transparent"
    aboveWindows: true
    exclusiveZone: 0
    implicitWidth: 66

    anchors {
        right: true
        top: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-dock"

    function workspaceIsFocused(name) {
        const current = root.workspaces.find(workspace => workspace.name === name)
        return !!current && current.is_focused === true
    }

    function focusWorkspace(name) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", name])
    }

    Rectangle {
        id: dock
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter

        width: 44
        height: 222
        radius: 18
        color: root.dockBackground
        border.width: 1
        border.color: root.dockBorder

        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: 21
            color: "#16000000"
            z: -1
        }

        Column {
            anchors.centerIn: parent
            spacing: 4

            // Launcher
            Rectangle {
                width: 32
                height: 32
                radius: 11
                color: launcherMouse.containsMouse ? root.hoverBackground : "transparent"

                Image {
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    source: root.searchIcon
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    mipmap: true
                    smooth: true
                }

                MouseArea {
                    id: launcherMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.launcherRequested()
                }

                Rectangle {
                    visible: launcherMouse.containsMouse
                    x: -112
                    anchors.verticalCenter: parent.verticalCenter
                    width: 102
                    height: 28
                    radius: 9
                    color: "#111827"
                    z: 10

                    Text {
                        anchors.centerIn: parent
                        text: "Applications"
                        color: "#FFFFFF"
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                }
            }

            Rectangle {
                width: 20
                height: 1
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.dockBorder
            }

            Repeater {
                model: root.workspaceDefinitions

                delegate: Rectangle {
                    required property var modelData

                    width: 32
                    height: 32
                    radius: 11
                    color: root.workspaceIsFocused(modelData.name)
                        ? root.activeBackground
                        : (workspaceMouse.containsMouse ? root.hoverBackground : "transparent")

                    border.width: root.workspaceIsFocused(modelData.name) ? 1 : 0
                    border.color: "#D6D9DE"

                    Image {
                        anchors.centerIn: parent
                        width: 17
                        height: 17
                        source: modelData.icon
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        mipmap: true
                        smooth: true
                    }

                    Rectangle {
                        visible: root.workspaceIsFocused(modelData.name)
                        width: 3
                        height: 16
                        radius: 2
                        anchors.right: parent.right
                        anchors.rightMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.iconColor
                    }

                    MouseArea {
                        id: workspaceMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.focusWorkspace(modelData.name)
                    }

                    Rectangle {
                        visible: workspaceMouse.containsMouse
                        x: -114
                        anchors.verticalCenter: parent.verticalCenter
                        width: 104
                        height: 28
                        radius: 9
                        color: "#111827"
                        z: 10

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: "#FFFFFF"
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }
        }
    }
}
