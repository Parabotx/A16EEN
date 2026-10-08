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

    readonly property string layoutPath: {
        const stateHome = Quickshell.env("XDG_STATE_HOME")
        const home = Quickshell.env("HOME") || ""
        const base = stateHome && stateHome.length
            ? stateHome
            : home + "/.local/state"
        return base + "/a16een/navbar-layout.json"
    }

    property string navbarPosition: "right"

    readonly property bool horizontalNavbar:
        root.navbarPosition === "top" || root.navbarPosition === "bottom"

    readonly property int dockWidth:
        Math.max(
            44,
            root.visibleWorkspaces.length * 32
                + Math.max(0, root.visibleWorkspaces.length - 1) * 4
                + 18
        )

    readonly property string stateDir: {
        const stateHome = Quickshell.env("XDG_STATE_HOME")
        const home = Quickshell.env("HOME") || ""
        return (stateHome && stateHome.length ? stateHome : home + "/.local/state") + "/a16een"
    }

    readonly property string navbarIconRoot: root.stateDir + "/navbar-icons"
    readonly property string navbarReadyPath: root.navbarIconRoot + "/ready"
    readonly property string workspaceCountPath: root.stateDir + "/workspace-count"

    property int navbarRevision: 0
    property int workspaceCount: 6
    property bool edgeRevealed: false

    readonly property var workspaceCatalog: [
        { id: "home", icon: "house.svg" },
        { id: "code", icon: "code.svg" },
        { id: "web", icon: "globe.svg" },
        { id: "comms", icon: "messages-square.svg" },
        { id: "studio", icon: "sparkles.svg" },
        { id: "music", icon: "music.svg" },
        { id: "games", icon: "gamepad-2.svg" },
        { id: "files", icon: "folder.svg" },
        { id: "lab", icon: "terminal.svg" }
    ]

    readonly property var visibleWorkspaces: root.workspaceCatalog.slice(0, root.workspaceCount)

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

    function loadWorkspaceCount(raw) {
        const value = Number(String(raw || "").trim())
        if (value >= 2 && value <= 9)
            root.workspaceCount = Math.floor(value)
    }

    function generatedIconPath(slot) {
        return "file://" + root.navbarIconRoot + "/" + slot + ".svg"
    }

    function fallbackIconPath(iconName) {
        return Qt.resolvedUrl("../assets/icons/" + iconName)
    }

    function loadNavbarLayout(raw) {
        try {
            const parsed = JSON.parse(String(raw || ""))
            if (parsed && ["left", "right", "top", "bottom"].includes(parsed.position))
                root.navbarPosition = parsed.position
        } catch (error) {
            root.navbarPosition = "right"
        }
    }

    FileView {
        id: navbarLayoutFile
        path: root.layoutPath
        watchChanges: true
        printErrors: false
        onLoaded: root.loadNavbarLayout(this.text())
        onFileChanged: root.loadNavbarLayout(this.text())
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
        id: workspaceCountFile
        path: root.workspaceCountPath
        watchChanges: true
        printErrors: false
        onLoaded: root.loadWorkspaceCount(this.text())
        onFileChanged: root.loadWorkspaceCount(this.text())
    }

    screen: modelData
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    width: root.horizontalNavbar
        ? (root.dockVisible ? root.dockWidth : root.modelData.width)
        : (root.dockVisible ? root.surfaceWidth : 8)
    height: root.horizontalNavbar
        ? (root.dockVisible ? 66 : 8)
        : root.surfaceHeight

    // The actual Wayland surface follows the selected navbar edge.
    anchors {
        left: root.horizontalNavbar || root.navbarPosition === "left"
        right: !root.horizontalNavbar && root.navbarPosition === "right"
        top: root.horizontalNavbar
            ? root.navbarPosition === "top"
            : true
        bottom: root.horizontalNavbar && root.navbarPosition === "bottom"
    }

    margins {
        left: root.horizontalNavbar && root.dockVisible
            ? Math.max(0, Math.round((root.modelData.width - root.dockWidth) / 2))
            : 0
        right: 0
        top: root.horizontalNavbar ? 0 : root.surfaceTopMargin
        bottom: 0
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

        // This is a normal QtQuick MouseArea, so use geometry instead of
        // boolean values in anchors.left/right/top/bottom. It is active only
        // while fullscreen hides the navbar, which keeps workspace clicks clean.
        x: root.horizontalNavbar
            ? 0
            : (root.navbarPosition === "right" ? parent.width - width : 0)
        y: root.horizontalNavbar
            ? (root.navbarPosition === "bottom" ? parent.height - height : 0)
            : 0
        width: root.horizontalNavbar ? parent.width : 8
        height: root.horizontalNavbar ? 8 : parent.height
        enabled: root.fullscreenActive && !root.dockVisible
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        z: 0
        onEntered: root.revealDock()
        onExited: root.scheduleHide()
    }

    Rectangle {
        id: dock
        x: root.dockVisible
            ? parent.width - width - 10
            : parent.width + 2
        anchors.verticalCenter: parent.verticalCenter

        width: root.horizontalNavbar ? root.dockWidth : 44
        height: root.horizontalNavbar ? 44 : root.dockHeight
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

        Grid {
            anchors.centerIn: parent
            columns: root.horizontalNavbar ? root.visibleWorkspaces.length : 1
            rows: root.horizontalNavbar ? 1 : root.visibleWorkspaces.length
            rowSpacing: 4
            columnSpacing: 4

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
                        anchors.right: root.horizontalNavbar ? parent.right : undefined
                        anchors.bottom: root.horizontalNavbar ? undefined : parent.bottom
                        anchors.verticalCenter: root.horizontalNavbar ? parent.verticalCenter : undefined
                        anchors.horizontalCenter: root.horizontalNavbar ? undefined : parent.horizontalCenter
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
