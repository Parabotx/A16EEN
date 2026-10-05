import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    required property var workspaces
    required property int focusedWorkspaceId
    required property bool fullscreenActive

    signal launcherRequested()

    // Blue glass: low alpha so the blurred scene remains visible through the dock.
    readonly property color dockBackground: "#35243B8F"
    readonly property color dockBorder: "#664F8FD0"
    readonly property color iconColor: "#F4F7FF"
    readonly property color hoverBackground: "#263C6BB8"
    readonly property string searchIcon: Qt.resolvedUrl("../assets/icons/search.svg")

    property bool edgeRevealed: false
    readonly property bool dockVisible: !root.fullscreenActive || root.edgeRevealed

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

    // Request compositor-backed background blur for the glass surface.
    // Niri implements ext-background-effect-v1 natively.
    BackgroundEffect.blurRegion: Region {
        item: dock
        radius: 18
    }

    function workspaceIsFocused(name) {
        const current = root.workspaces.find(workspace => workspace.name === name)
        return !!current && current.id === root.focusedWorkspaceId
    }

    function focusWorkspace(index) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(index)])
    }

    function revealDock() {
        root.edgeRevealed = true
        hideRevealTimer.stop()
    }

    function scheduleHide() {
        if (root.fullscreenActive)
            hideRevealTimer.restart()
    }

    Timer {
        id: hideRevealTimer
        interval: 320
        repeat: false
        onTriggered: root.edgeRevealed = false
    }

    onFullscreenActiveChanged: {
        edgeRevealed = false
        hideRevealTimer.stop()
    }

    MouseArea {
        id: edgeReveal
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 240
        width: 8
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        z: 5
        onEntered: root.revealDock()
        onExited: root.scheduleHide()
    }

    Rectangle {
        id: dock
        x: root.dockVisible
            ? parent.width - width - 10
            : parent.width + 2
        anchors.verticalCenter: parent.verticalCenter

        width: 44
        height: 222
        radius: 18
        color: root.dockBackground
        border.width: 1
        border.color: root.dockBorder

        Behavior on x {
            NumberAnimation {
                duration: 85
                easing.type: Easing.OutCubic
            }
        }

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

            Rectangle {
                width: 32
                height: 32
                radius: 11
                color: "transparent"

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
                    onEntered: root.revealDock()
                    onExited: root.scheduleHide()
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.launcherRequested()
                }

            }

            Rectangle {
                width: 20
                height: 1
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.dockBorder
            }

            Rectangle {
                width: 32
                height: 32
                radius: 11
                color: homeMouse.containsMouse ? root.hoverBackground : "transparent"

                Image {
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    source: Qt.resolvedUrl("../assets/icons/house.svg")
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    mipmap: true
                    smooth: true
                }

                Rectangle {
                    visible: root.workspaceIsFocused("home")
                    width: 3
                    height: 16
                    radius: 2
                    anchors.right: parent.right
                    anchors.rightMargin: 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.iconColor
                }

                MouseArea {
                    id: homeMouse
                    anchors.fill: parent
                    onEntered: root.revealDock()
                    onExited: root.scheduleHide()
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focusWorkspace(1)
                }
            }

            Rectangle {
                width: 32
                height: 32
                radius: 11
                color: codeMouse.containsMouse ? root.hoverBackground : "transparent"

                Image {
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    source: Qt.resolvedUrl("../assets/icons/code.svg")
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    mipmap: true
                    smooth: true
                }

                Rectangle {
                    visible: root.workspaceIsFocused("code")
                    width: 3
                    height: 16
                    radius: 2
                    anchors.right: parent.right
                    anchors.rightMargin: 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.iconColor
                }

                MouseArea {
                    id: codeMouse
                    anchors.fill: parent
                    onEntered: root.revealDock()
                    onExited: root.scheduleHide()
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focusWorkspace(2)
                }
            }

            Rectangle {
                width: 32
                height: 32
                radius: 11
                color: webMouse.containsMouse ? root.hoverBackground : "transparent"

                Image {
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    source: Qt.resolvedUrl("../assets/icons/globe.svg")
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    mipmap: true
                    smooth: true
                }

                Rectangle {
                    visible: root.workspaceIsFocused("web")
                    width: 3
                    height: 16
                    radius: 2
                    anchors.right: parent.right
                    anchors.rightMargin: 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.iconColor
                }

                MouseArea {
                    id: webMouse
                    anchors.fill: parent
                    onEntered: root.revealDock()
                    onExited: root.scheduleHide()
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focusWorkspace(3)
                }
            }

            Rectangle {
                width: 32
                height: 32
                radius: 11
                color: commsMouse.containsMouse ? root.hoverBackground : "transparent"

                Image {
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    source: Qt.resolvedUrl("../assets/icons/messages-square.svg")
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    mipmap: true
                    smooth: true
                }

                Rectangle {
                    visible: root.workspaceIsFocused("comms")
                    width: 3
                    height: 16
                    radius: 2
                    anchors.right: parent.right
                    anchors.rightMargin: 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.iconColor
                }

                MouseArea {
                    id: commsMouse
                    anchors.fill: parent
                    onEntered: root.revealDock()
                    onExited: root.scheduleHide()
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focusWorkspace(4)
                }
            }

            Rectangle {
                width: 32
                height: 32
                radius: 11
                color: studioMouse.containsMouse ? root.hoverBackground : "transparent"

                Image {
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    source: Qt.resolvedUrl("../assets/icons/sparkles.svg")
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    mipmap: true
                    smooth: true
                }

                Rectangle {
                    visible: root.workspaceIsFocused("studio")
                    width: 3
                    height: 16
                    radius: 2
                    anchors.right: parent.right
                    anchors.rightMargin: 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.iconColor
                }

                MouseArea {
                    id: studioMouse
                    anchors.fill: parent
                    onEntered: root.revealDock()
                    onExited: root.scheduleHide()
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focusWorkspace(5)
                }
            }
        }
    }
}
