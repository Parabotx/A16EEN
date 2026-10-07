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

    // Clean white A16EEN dock with a monochrome workspace language.
    readonly property color dockBackground: "#FFFFFF"
    readonly property color dockBorder: "#E5E7EB"
    readonly property color iconColor: "#111111"
    readonly property color hoverBackground: "#F3F4F6"
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

    // The dock PanelWindow spans the full screen height and 66px of width.
    // Without an input mask, transparent pixels still block clicks on the
    // application underneath. Only the visible dock and the 8px reveal strip
    // should ever participate in pointer hit-testing.
    mask: Region {
        x: root.width - 8
        y: (root.height - 240) / 2
        width: 8
        height: 240

        Region {
            x: root.dock.x - (root.width - 8)
            y: root.dock.y - ((root.height - 240) / 2)
            width: root.dock.width
            height: root.dock.height
            intersection: Intersection.Combine
        }
    }

    function workspaceIsFocused(name) {
        const current = root.workspaces.find(workspace => workspace.name === name)
        return !!current && current.id === root.focusedWorkspaceId
    }

    function focusWorkspace(name) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", name])
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
        height: 260
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
                    onClicked: root.focusWorkspace("home")
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
                    onClicked: root.focusWorkspace("code")
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
                    onClicked: root.focusWorkspace("web")
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
                    onClicked: root.focusWorkspace("comms")
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
                    onClicked: root.focusWorkspace("studio")
                }
            }

            Rectangle {
                width: 32
                height: 32
                radius: 11
                color: musicMouse.containsMouse ? root.hoverBackground : "transparent"

                Image {
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    source: Qt.resolvedUrl("../assets/icons/music.svg")
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    mipmap: true
                    smooth: true
                }

                Rectangle {
                    visible: root.workspaceIsFocused("music")
                    width: 3
                    height: 16
                    radius: 2
                    anchors.right: parent.right
                    anchors.rightMargin: 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.iconColor
                }

                MouseArea {
                    id: musicMouse
                    anchors.fill: parent
                    onEntered: root.revealDock()
                    onExited: root.scheduleHide()
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focusWorkspace("music")
                }
            }
        }
    }
}
