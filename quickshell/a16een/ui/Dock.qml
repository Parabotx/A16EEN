import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

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

    readonly property string navbarStatePath: {
        const stateHome = Quickshell.env("XDG_STATE_HOME")
        const home = Quickshell.env("HOME") || ""
        const base = stateHome && stateHome.length
            ? stateHome
            : home + "/.local/state"
        return base + "/a16een/navbar.json"
    }

    readonly property string navbarIconRoot: {
        const stateHome = Quickshell.env("XDG_STATE_HOME")
        const home = Quickshell.env("HOME") || ""
        const base = stateHome && stateHome.length
            ? stateHome
            : home + "/.local/state"
        return base + "/a16een/navbar-icons"
    }

    readonly property string navbarReadyPath: root.navbarIconRoot + "/ready"
    property var navbarSettings: ({})
    property int navbarRevision: 0

    function loadNavbarSettings(raw) {
        try {
            const parsed = JSON.parse(String(raw || ""))
            root.navbarSettings = parsed && typeof parsed === "object" ? parsed : ({})
        } catch (error) {
            root.navbarSettings = ({})
        }
    }

    function generatedIconPath(slot) {
        return "file://" + root.navbarIconRoot + "/" + slot + ".svg"
    }

    function fallbackIconPath(iconName) {
        return Qt.resolvedUrl("../assets/icons/" + iconName)
    }

    FileView {
        id: navbarSettingsFile
        path: root.navbarStatePath
        watchChanges: true
        printErrors: false
        onLoaded: root.loadNavbarSettings(this.text())
        onFileChanged: root.loadNavbarSettings(this.text())
    }

    FileView {
        id: navbarReadyFile
        path: root.navbarReadyPath
        watchChanges: true
        printErrors: false
        onFileChanged: root.navbarRevision++
        onLoaded: root.navbarRevision++
    }

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
                color: homeMouse.containsMouse ? root.hoverBackground : "transparent"

                NavbarImage {
                    anchors.centerIn: parent
                    width: 19
                    height: 19
                    slot: "home"
                    generatedPath: root.generatedIconPath("home")
                    fallbackPath: root.fallbackIconPath("house.svg")
                    refreshRevision: root.navbarRevision
                    active: root.workspaceIsFocused("home")
                    hovered: homeMouse.containsMouse
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

                NavbarImage {
                    anchors.centerIn: parent
                    width: 19
                    height: 19
                    slot: "code"
                    generatedPath: root.generatedIconPath("code")
                    fallbackPath: root.fallbackIconPath("code.svg")
                    refreshRevision: root.navbarRevision
                    active: root.workspaceIsFocused("code")
                    hovered: codeMouse.containsMouse
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

                NavbarImage {
                    anchors.centerIn: parent
                    width: 19
                    height: 19
                    slot: "web"
                    generatedPath: root.generatedIconPath("web")
                    fallbackPath: root.fallbackIconPath("globe.svg")
                    refreshRevision: root.navbarRevision
                    active: root.workspaceIsFocused("web")
                    hovered: webMouse.containsMouse
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

                NavbarImage {
                    anchors.centerIn: parent
                    width: 19
                    height: 19
                    slot: "comms"
                    generatedPath: root.generatedIconPath("comms")
                    fallbackPath: root.fallbackIconPath("messages-square.svg")
                    refreshRevision: root.navbarRevision
                    active: root.workspaceIsFocused("comms")
                    hovered: commsMouse.containsMouse
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

                NavbarImage {
                    anchors.centerIn: parent
                    width: 19
                    height: 19
                    slot: "studio"
                    generatedPath: root.generatedIconPath("studio")
                    fallbackPath: root.fallbackIconPath("sparkles.svg")
                    refreshRevision: root.navbarRevision
                    active: root.workspaceIsFocused("studio")
                    hovered: studioMouse.containsMouse
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

                NavbarImage {
                    anchors.centerIn: parent
                    width: 19
                    height: 19
                    slot: "music"
                    generatedPath: root.generatedIconPath("music")
                    fallbackPath: root.fallbackIconPath("music.svg")
                    refreshRevision: root.navbarRevision
                    active: root.workspaceIsFocused("music")
                    hovered: musicMouse.containsMouse
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
    component NavbarImage: Item {
        property string slot: ""
        property string generatedPath: ""
        property string fallbackPath: ""
        property int refreshRevision: 0
        property bool hovered: false
        property bool active: false

        implicitWidth: 19
        implicitHeight: 19
        scale: hovered ? 1.08 : (active ? 1.03 : 1)

        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        Image {
            id: navbarImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            sourceSize.width: width
            sourceSize.height: height
            smooth: true
            mipmap: true
            cache: false
            asynchronous: true
            source: parent.generatedPath.length
                ? parent.generatedPath
                : parent.fallbackPath

            onStatusChanged: {
                if (status === Image.Error && parent.fallbackPath.length
                    && source !== parent.fallbackPath) {
                    source = parent.fallbackPath
                }
            }
        }

        onRefreshRevisionChanged: {
            navbarImage.source = ""
            Qt.callLater(() => {
                navbarImage.source = root.generatedIconPath(slot)
            })
        }
    }

}
