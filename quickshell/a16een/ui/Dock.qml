import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    required property var workspaces
    required property int focusedWorkspaceId
    required property bool fullscreenActive

    signal launcherRequested()

    readonly property color dockBackground: "#FFFFFF"
    readonly property color dockBorder: "#E5E7EB"
    readonly property color iconColor: "#111111"
    readonly property color hoverBackground: "#F3F4F6"

    readonly property string stateDir: {
        const stateHome = Quickshell.env("XDG_STATE_HOME")
        const home = Quickshell.env("HOME") || ""
        return (stateHome && stateHome.length ? stateHome : home + "/.local/state") + "/a16een"
    }

    readonly property string navbarIconRoot: root.stateDir + "/navbar-icons"
    readonly property string navbarReadyPath: root.navbarIconRoot + "/ready"
    readonly property string workspaceRegistryPath: root.stateDir + "/workspaces.json"

    property int navbarRevision: 0
    property bool edgeRevealed: false
    property var workspaceCatalog: [
        { id: "home", name: "HOME", icon: "house.svg" },
        { id: "code", name: "CODE", icon: "code.svg" },
        { id: "web", name: "WEB", icon: "globe.svg" },
        { id: "comms", name: "COMMS", icon: "messages-square.svg" },
        { id: "studio", name: "STUDIO", icon: "sparkles.svg" },
        { id: "music", name: "MUSIC", icon: "music.svg" }
    ]

    readonly property var visibleWorkspaces: root.workspaceCatalog

    readonly property int dockHeight: Math.max(
        260,
        root.visibleWorkspaces.length * 32
            + Math.max(0, root.visibleWorkspaces.length - 1) * 4
            + 18
    )

    readonly property bool dockVisible: !root.fullscreenActive || root.edgeRevealed
    readonly property int surfaceWidth: root.dockVisible ? 66 : 8
    readonly property int surfaceHeight: root.dockVisible ? root.dockHeight : 240
    readonly property int surfaceTopMargin: Math.max(
        0,
        Math.round((root.modelData.height - root.surfaceHeight) / 2)
    )

    function loadWorkspaceRegistry(raw) {
        try {
            const parsed = JSON.parse(String(raw || ""))
            if (Array.isArray(parsed) && parsed.length)
                root.workspaceCatalog = parsed
        } catch (error) {
            // Keep the last valid registry in memory during atomic writes.
        }
    }

    function generatedIconPath(slot) {
        return "file://" + root.navbarIconRoot + "/" + slot + ".svg"
    }

    function fallbackIconPath(iconName) {
        return Qt.resolvedUrl("../assets/icons/" + iconName)
    }

    FileView {
        id: navbarReadyFile
        path: root.navbarReadyPath
        watchChanges: true
        printErrors: false
        onFileChanged: root.navbarRevision++
        onLoaded: root.navbarRevision++
    }

    FileView {
        id: workspaceRegistryFile
        path: root.workspaceRegistryPath
        watchChanges: true
        printErrors: false
        onLoaded: root.loadWorkspaceRegistry(this.text())
        onFileChanged: root.loadWorkspaceRegistry(this.text())
    }

    screen: modelData
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    width: root.surfaceWidth
    height: root.surfaceHeight

    // The actual Wayland surface is only the navbar-sized area. It never
    // covers the rest of the screen, even while the navbar is hidden.
    anchors {
        right: true
        top: true
    }

    margins {
        right: 0
        top: root.surfaceTopMargin
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-dock"

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
        root.edgeRevealed = false
        hideRevealTimer.stop()
    }

    MouseArea {
        id: edgeReveal
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 8
        height: 240
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        z: 10
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
        height: root.dockHeight
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

            Repeater {
                model: root.visibleWorkspaces

                delegate: Rectangle {
                    id: workspaceButton

                    required property var modelData
                    required property int index

                    width: 32
                    height: 32
                    radius: 11

                    readonly property bool active:
                        root.workspaceIsFocused(modelData.id)

                    color: workspaceMouse.containsMouse
                        ? root.hoverBackground
                        : "transparent"

                    Rectangle {
                        visible: workspaceButton.active
                        width: 3
                        height: 16
                        radius: 2
                        anchors.right: parent.right
                        anchors.rightMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.iconColor
                    }

                    NavbarImage {
                        anchors.centerIn: parent
                        width: 19
                        height: 19
                        slot: modelData.id
                        generatedPath: root.generatedIconPath(modelData.id)
                        fallbackPath: root.fallbackIconPath(modelData.icon)
                        refreshRevision: root.navbarRevision
                        active: workspaceButton.active
                        hovered: workspaceMouse.containsMouse
                    }

                    MouseArea {
                        id: workspaceMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.revealDock()
                        onExited: root.scheduleHide()
                        onClicked: root.focusWorkspace(modelData.id)
                    }
                }
            }
        }
    }

    component NavbarImage: Item {
        required property string slot
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
