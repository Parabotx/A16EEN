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

    property var navbarSettings: ({})
    function isWhiteColor(value) {
        const color = String(value || "").toUpperCase()
        return color === "#FFFFFF" || color === "#FFFFFFFF"
    }

    function isAllWhiteNavbarStyle(value) {
        const style = String(value || "").toUpperCase()

        if (isWhiteColor(style))
            return true

        if (style.indexOf("SOLID:") === 0)
            return isWhiteColor(style.substring(6))

        const parts = style.split(":")
        if (parts.length === 3 && (
                parts[0] === "SPLIT-X" ||
                parts[0] === "SPLIT-Y" ||
                parts[0] === "GRADIENT-X" ||
                parts[0] === "GRADIENT-Y" ||
                parts[0] === "GRADIENT-DIAG"))
            return isWhiteColor(parts[1]) && isWhiteColor(parts[2])

        return false
    }

    readonly property bool allWhiteNavbarStyles: {
        if (!root.visibleWorkspaces.length)
            return false

        for (const workspace of root.visibleWorkspaces) {
            const setting = root.navbarSettings[workspace.id]
            const style = setting && setting.color ? String(setting.color) : ""
            if (!root.isAllWhiteNavbarStyle(style))
                return false
        }

        return true
    }
    readonly property color dockBackground:
        root.allWhiteNavbarStyles ? "#111318" : "#FFFFFF"
    readonly property color dockBorder:
        root.allWhiteNavbarStyles ? "#2A2E35" : "#E5E7EB"
    readonly property color iconColor:
        root.allWhiteNavbarStyles ? "#FFFFFF" : "#111111"
    readonly property color hoverBackground:
        root.allWhiteNavbarStyles ? "#252A33" : "#F3F4F6"

    readonly property string stateDir: {
        const stateHome = Quickshell.env("XDG_STATE_HOME")
        const home = Quickshell.env("HOME") || ""
        return (stateHome && stateHome.length ? stateHome : home + "/.local/state") + "/a16een"
    }

    readonly property string navbarIconRoot: root.stateDir + "/navbar-icons"
    readonly property string navbarReadyPath: root.navbarIconRoot + "/ready"
    readonly property string navbarSettingsPath: root.stateDir + "/navbar.json"
    readonly property string workspaceRegistryPath: root.stateDir + "/workspaces.json"
    readonly property string navbarLayoutPath: root.stateDir + "/navbar-layout.json"
    readonly property string navbarContentPath: root.stateDir + "/navbar-content.json"

    property int navbarRevision: 0
    property int liveRevision: 0
    property bool edgeRevealed: false
    property string navbarPosition: "right"
    property var workspaceCatalog: [
        { id: "home", name: "HOME", icon: "house.svg" },
        { id: "code", name: "CODE", icon: "code.svg" },
        { id: "web", name: "WEB", icon: "globe.svg" },
        { id: "comms", name: "COMMS", icon: "messages-square.svg" },
        { id: "studio", name: "STUDIO", icon: "sparkles.svg" },
        { id: "music", name: "MUSIC", icon: "music.svg" }
    ]
    property var contentState: ({
        workspaces: true,
        time: false,
        date: false,
        battery: false,
        volume: false,
        network: false
    })
    property int batteryPercent: -1
    property bool networkConnected: false
    property int volumePercent: 0
    property bool volumeMuted: false

    readonly property bool horizontalNavbar:
        root.navbarPosition === "top" || root.navbarPosition === "bottom"

    readonly property var visibleWorkspaces: root.workspaceCatalog

    readonly property int workspaceExtent: root.contentState.workspaces !== false
        ? Math.max(
            44,
            root.visibleWorkspaces.length * 36
                + Math.max(0, root.visibleWorkspaces.length - 1) * 4
        )
        : 0

    readonly property int contentCount: {
        let count = 0
        if (root.contentState.time === true) count++
        if (root.contentState.date === true) count++
        if (root.contentState.battery === true) count++
        if (root.contentState.volume === true) count++
        if (root.contentState.network === true) count++
        return count
    }

    readonly property int contentExtent: root.contentCount > 0
        ? 12 + root.contentCount * 52
            + Math.max(0, root.contentCount - 1) * 4
        : 0

    readonly property int actualDockWidth: root.horizontalNavbar
        ? Math.max(48, root.workspaceExtent + root.contentExtent + (root.contentCount > 0 ? 8 : 0))
        : (root.contentCount > 0 ? 66 : 44)

    readonly property int actualDockHeight: root.horizontalNavbar
        ? (root.contentCount > 0 ? 58 : 44)
        : Math.max(44, root.workspaceExtent + root.contentExtent)

    readonly property bool dockVisible:
        root.displayItems.length > 0
        && (!root.fullscreenActive || root.edgeRevealed)

    readonly property int surfaceWidth:
        root.horizontalNavbar
            ? (root.dockVisible ? root.actualDockWidth : root.modelData.width)
            : (root.dockVisible ? root.actualDockWidth : 8)

    readonly property int surfaceHeight:
        root.horizontalNavbar
            ? (root.dockVisible ? root.actualDockHeight : 8)
            : (root.dockVisible ? root.actualDockHeight : Math.max(240, root.modelData.height / 3))

    readonly property int horizontalCenterMargin:
        Math.max(0, Math.round((root.modelData.width - root.surfaceWidth) / 2))

    readonly property int verticalCenterMargin:
        Math.max(0, Math.round((root.modelData.height - root.surfaceHeight) / 2))

    readonly property var displayItems: {
        const items = []
        if (root.contentState.workspaces !== false) {
            for (const workspace of root.visibleWorkspaces)
                items.push({ kind: "workspace", data: workspace })
        }
        if (root.contentState.time === true)
            items.push({ kind: "content", id: "time" })
        if (root.contentState.date === true)
            items.push({ kind: "content", id: "date" })
        if (root.contentState.battery === true)
            items.push({ kind: "content", id: "battery" })
        if (root.contentState.volume === true)
            items.push({ kind: "content", id: "volume" })
        if (root.contentState.network === true)
            items.push({ kind: "content", id: "network" })
        return items
    }

    function navbarIcon(slot, fallbackIcon) {
        const setting = root.navbarSettings && root.navbarSettings[slot]
            ? root.navbarSettings[slot] : null
        return setting && setting.icon ? setting.icon : fallbackIcon
    }

    function navbarColor(slot, fallbackIcon) {
        const setting = root.navbarSettings && root.navbarSettings[slot]
            ? root.navbarSettings[slot] : null
        const spec = String(setting && setting.color ? setting.color : "#111318")
        let selected = "#111318"

        if (spec.indexOf("solid:") === 0) {
            selected = spec.substring(6)
        } else if (spec.charAt(0) === "#") {
            selected = spec
        } else {
            const parts = spec.split(":")
            if (parts.length >= 3) {
                const first = parts[1]
                const second = parts[2]
                selected = root.isWhiteColor(first) && !root.isWhiteColor(second)
                    ? second : first
            }
        }

        // A single white workspace icon would disappear on the normal white
        // surface. Reserve true white for the all-white design, where Dock
        // itself switches to the dark surface.
        if (!root.allWhiteNavbarStyles && root.isWhiteColor(selected))
            return "#111318"

        return selected
    }

    function loadNavbarSettings(raw) {
        try {
            const parsed = JSON.parse(String(raw || ""))
            if (parsed && typeof parsed === "object")
                root.navbarSettings = parsed
        } catch (error) {}
    }

    function loadWorkspaceRegistry(raw) {
        try {
            const parsed = JSON.parse(String(raw || ""))
            if (Array.isArray(parsed) && parsed.length)
                root.workspaceCatalog = parsed
        } catch (error) {}
    }

    function loadLayout(raw) {
        try {
            const parsed = JSON.parse(String(raw || ""))
            if (parsed && parsed.position
                && ["left", "right", "top", "bottom"].includes(parsed.position)) {
                root.navbarPosition = parsed.position
            }
        } catch (error) {}
    }

    function loadContent(raw) {
        try {
            const parsed = JSON.parse(String(raw || ""))
            if (parsed && typeof parsed === "object")
                root.contentState = parsed
        } catch (error) {}
    }

    function generatedIconPath(slot) {
        return "file://" + root.navbarIconRoot + "/" + slot + ".svg"
    }

    function fallbackIconPath(iconName) {
        return Qt.resolvedUrl("../assets/icons/" + iconName)
    }

    function workspaceIsFocused(name) {
        const current = root.workspaces.find(workspace => workspace.name === name)
        return !!current && current.id === root.focusedWorkspaceId
    }

    function focusWorkspace(name) {
        Quickshell.execDetached(["a16een-focus-workspace", name])
    }

    function contentValue(id) {
        root.liveRevision
        switch (id) {
        case "time":
            return Qt.formatTime(new Date(), "HH:mm")
        case "date":
            return Qt.formatDate(new Date(), "ddd d")
        case "battery":
            return root.batteryPercent >= 0 ? root.batteryPercent + "%" : "AC"
        case "volume":
            return root.volumeMuted ? "MUTE" : root.volumePercent + "%"
        case "network":
            return root.networkConnected ? "ONLINE" : "OFFLINE"
        default:
            return ""
        }
    }

    function contentIcon(id) {
        switch (id) {
        case "time": return "clock.svg"
        case "date": return "calendar.svg"
        case "battery": return "zap.svg"
        case "volume": return "volume-2.svg"
        case "network": return "wifi.svg"
        default: return "circle.svg"
        }
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

    Timer {
        id: liveRefresh
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.liveRevision++
    }

    Timer {
        id: systemRefresh
        interval: 5000
        repeat: true
        running: true
        onTriggered: {
            batteryProcess.running = false
            batteryProcess.running = true
            volumeProcess.running = false
            volumeProcess.running = true
            networkProcess.running = false
            networkProcess.running = true
        }
    }

    Process {
        id: batteryProcess
        command: [
            "/bin/sh",
            "-c",
            "for f in /sys/class/power_supply/BAT*/capacity; do [ -r \"$f\" ] && cat \"$f\" && exit; done; echo -1"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const value = Number(String(text).trim())
                if (Number.isFinite(value))
                    root.batteryPercent = Math.round(value)
            }
        }
    }

    Process {
        id: volumeProcess
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const output = String(text).trim()
                const match = output.match(/Volume:\s*([0-9.]+)/)
                if (match)
                    root.volumePercent = Math.round(Number(match[1]) * 100)
                root.volumeMuted = /\[MUTED\]/.test(output)
            }
        }
    }

    Process {
        id: networkProcess
        command: [
            "/bin/sh",
            "-c",
            "nmcli -t -f STATE g 2>/dev/null | grep -q '^connected' && printf connected || printf disconnected"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.networkConnected = String(text).trim() === "connected"
            }
        }
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
        id: navbarSettingsFile
        path: root.navbarSettingsPath
        watchChanges: true
        printErrors: false
        onLoaded: root.loadNavbarSettings(this.text())
        onFileChanged: root.loadNavbarSettings(this.text())
    }

    FileView {
        id: workspaceRegistryFile
        path: root.workspaceRegistryPath
        watchChanges: true
        printErrors: false
        onLoaded: root.loadWorkspaceRegistry(this.text())
        onFileChanged: root.loadWorkspaceRegistry(this.text())
    }

    FileView {
        id: navbarLayoutFile
        path: root.navbarLayoutPath
        watchChanges: true
        printErrors: false
        onLoaded: root.loadLayout(this.text())
        onFileChanged: root.loadLayout(this.text())
    }

    FileView {
        id: navbarContentFile
        path: root.navbarContentPath
        watchChanges: true
        printErrors: false
        onLoaded: root.loadContent(this.text())
        onFileChanged: {
            root.loadContent(this.text())
            root.liveRevision++
        }
    }

    screen: modelData
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    width: root.surfaceWidth
    height: root.surfaceHeight

    // PanelWindow anchors the small Wayland surface to the requested screen edge.
    // For top/bottom we center it mathematically with a left margin; for
    // left/right we center it vertically with a top margin.
    anchors {
        left: root.horizontalNavbar || root.navbarPosition === "left"
        right: !root.horizontalNavbar && root.navbarPosition === "right"
        top: root.horizontalNavbar ? root.navbarPosition === "top" : true
        bottom: root.horizontalNavbar && root.navbarPosition === "bottom"
    }

    margins {
        left: root.horizontalNavbar ? root.horizontalCenterMargin : 0
        right: 0
        top: root.horizontalNavbar ? 0 : root.verticalCenterMargin
        bottom: 0
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-dock"

    MouseArea {
        id: edgeReveal
        anchors.left: root.horizontalNavbar || root.navbarPosition === "left"
        anchors.right: !root.horizontalNavbar && root.navbarPosition === "right"
        anchors.top: !root.horizontalNavbar || root.navbarPosition === "top"
        anchors.bottom: root.horizontalNavbar && root.navbarPosition === "bottom"
        width: root.horizontalNavbar ? parent.width : 8
        height: root.horizontalNavbar ? 8 : parent.height
        // Only the physical screen edge is a reveal trigger. Never let this
        // invisible hover surface cover the vertical navbar buttons.
        x: root.navbarPosition === "right" && !root.horizontalNavbar
            ? parent.width - 8
            : 0
        y: root.navbarPosition === "bottom" && root.horizontalNavbar
            ? parent.height - 8
            : 0
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        // This invisible edge trigger must never sit above workspace buttons.
        z: -1
        onEntered: root.revealDock()
        onExited: root.scheduleHide()
    }

    Rectangle {
        id: dock
        visible: root.dockVisible
        anchors.centerIn: parent

        width: root.actualDockWidth
        height: root.actualDockHeight
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

        Row {
            visible: root.horizontalNavbar
                && root.contentState.workspaces !== false
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 10
            spacing: 4

            Repeater {
                model: root.visibleWorkspaces
                delegate: WorkspaceButton {
                    workspace: modelData
                }
            }
        }

        Column {
            visible: !root.horizontalNavbar
                && root.contentState.workspaces !== false
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 9
            spacing: 4

            Repeater {
                model: root.visibleWorkspaces
                delegate: WorkspaceButton {
                    workspace: modelData
                }
            }
        }

        Grid {
            visible: root.contentCount > 0
            columns: root.horizontalNavbar ? root.contentCount : 1
            rows: root.horizontalNavbar ? 1 : root.contentCount
            rowSpacing: 4
            columnSpacing: 4
            width: root.horizontalNavbar ? root.contentExtent : 56
            height: root.horizontalNavbar ? 40 : root.contentExtent
            anchors.right: root.horizontalNavbar ? parent.right : undefined
            anchors.bottom: !root.horizontalNavbar ? parent.bottom : undefined
            anchors.rightMargin: root.horizontalNavbar ? 6 : 0
            anchors.bottomMargin: !root.horizontalNavbar ? 6 : 0

            Repeater {
                model: [
                    "time",
                    "date",
                    "battery",
                    "volume",
                    "network"
                ].filter(id => root.contentState[id] === true)

                delegate: Rectangle {
                    width: root.horizontalNavbar ? 52 : 52
                    height: 34
                    radius: 9
                    color: contentMouse.containsMouse ? root.hoverBackground : "#F7F8FA"
                    border.width: 1
                    border.color: "#E5E7EB"

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        Image {
                            width: 13
                            height: 13
                            sourceSize.width: width
                            sourceSize.height: height
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            source: Qt.resolvedUrl("../assets/icons/" + root.contentIcon(modelData))
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.contentValue(modelData)
                            color: root.text
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                        }
                    }

                    MouseArea {
                        id: contentMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.revealDock()
                        onExited: root.scheduleHide()
                    }
                }
            }
        }
    }

    component WorkspaceButton: Rectangle {
        required property var workspace

        width: 32
        height: 32
        radius: 11
        color: workspaceMouse.containsMouse ? root.hoverBackground : "transparent"

        Rectangle {
            visible: root.workspaceIsFocused(workspace.id)
            width: 3
            height: 16
            radius: 2
            anchors.right: root.horizontalNavbar ? parent.right : undefined
            anchors.left: !root.horizontalNavbar ? undefined : undefined
            anchors.bottom: root.horizontalNavbar ? undefined : parent.bottom
            anchors.verticalCenter: root.horizontalNavbar ? parent.verticalCenter : undefined
            anchors.horizontalCenter: !root.horizontalNavbar ? parent.horizontalCenter : undefined
            color: root.iconColor
        }

        NavbarIcon {
            anchors.centerIn: parent
            width: 19
            height: 19
            iconName: root.navbarIcon(workspace.id, workspace.icon)
            iconColor: root.navbarColor(workspace.id, workspace.icon)
            active: root.workspaceIsFocused(workspace.id)
            hovered: workspaceMouse.containsMouse
        }

        MouseArea {
            id: workspaceMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.revealDock()
            onExited: root.scheduleHide()
            onClicked: root.focusWorkspace(workspace.id)
        }
    }

    onFullscreenActiveChanged: {
        root.edgeRevealed = false
        hideRevealTimer.stop()
    }
}
