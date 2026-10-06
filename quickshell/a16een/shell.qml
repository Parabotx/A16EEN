//@ pragma AppId a16een

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import Quickshell.Services.UPower
import qs.ui

ShellRoot {
    id: root

    property bool launcherOpen: false
    property bool dashboardOpen: false
    property bool commandCenterOpen: false
    property bool wallpaperPickerOpen: false
    property string wallpaperPath: ""
    property string searchText: ""
    property string powerProfile: "balanced"

    // Widget state lives in the shell; rendering and management stay modular.
    property bool widgetsCenterOpen: false
    property bool timeWidgetEnabled: true
    property bool pulseWidgetEnabled: false
    property bool workspaceWidgetEnabled: false
    property bool timeUse24Hour: true
    property bool timeShowSeconds: false

    property var workspaces: []
    property var windows: []
    property int focusedWorkspaceId: -1
    property int focusedWindowId: -1
    readonly property bool focusedWindowFullscreen: ToplevelManager.activeToplevel
        ? ToplevelManager.activeToplevel.fullscreen
        : false
    readonly property bool wallpaperDesktopActive:
        root.focusedWindowId < 0
        && !root.focusedWindowFullscreen
        && !root.launcherOpen
        && !root.dashboardOpen
        && !root.commandCenterOpen
        && !root.wallpaperPickerOpen
        && !root.widgetsCenterOpen

    readonly property bool wallpaperAnimationAllowed: {
        switch (root.powerProfile) {
        case "performance":
            // Performance mode keeps live wallpapers running behind normal
            // and half-open/floating windows. Only a true fullscreen window pauses it.
            return !root.focusedWindowFullscreen
        case "power-saver":
            // Eco mode always freezes animated wallpapers.
            return false
        case "balanced":
        default:
            // Balanced mode pauses animation while the user is actively using
            // an app or any A16EEN overlay.
            return root.wallpaperDesktopActive
        }
    }

    readonly property int systemMonitorInterval: {
        switch (root.powerProfile) {
        case "performance":
            return 1000
        case "power-saver":
            return 7000
        case "balanced":
        default:
            return 3000
        }
    }

    property string activeTitle: "A16EEN"

    property real systemLoad: 0
    property int volumePercent: 0
    property bool volumeMuted: false
    property var latestNotification: null

    readonly property var primaryScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    Process {
        id: wallpaperPathProcess
        command: ["a16een-wallpaper", "current-path"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim()
                if (path.length)
                    root.wallpaperPath = path
            }
        }
    }

    Process {
        id: powerProfileProcess
        command: ["powerprofilesctl", "get"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const profile = String(text).trim().toLowerCase()

                if (profile === "performance"
                    || profile === "balanced"
                    || profile === "power-saver") {
                    root.powerProfile = profile
                }
            }
        }
    }

    Timer {
        id: powerProfileTimer
        interval: 2000
        repeat: true
        running: true

        onTriggered: {
            powerProfileProcess.running = false
            powerProfileProcess.running = true
        }
    }

    function consumeNiriEvent(raw) {
        const line = String(raw).trim()
        if (!line.length) return

        try {
            const event = JSON.parse(line)

            if (event.WorkspacesChanged) {
                root.workspaces = event.WorkspacesChanged.workspaces || []

                const focused = root.workspaces.find(workspace =>
                    workspace.is_focused === true
                )
                if (focused)
                    root.focusedWorkspaceId = focused.id

                return
            }

            if (event.WindowsChanged) {
                root.windows = event.WindowsChanged.windows || []
                const focused = root.windows.find(window => window.is_focused === true)
                if (focused)
                    root.focusedWindowId = focused.id
                return
            }

            if (event.WindowOpenedOrChanged) {
                const incoming = event.WindowOpenedOrChanged.window
                const next = [...root.windows].filter(window => window.id !== incoming.id)
                next.push(incoming)
                root.windows = next
                if (incoming.is_focused)
                    root.focusedWindowId = incoming.id
                return
            }

            if (event.WindowClosed) {
                root.windows = root.windows.filter(window => window.id !== event.WindowClosed.id)
                if (root.focusedWindowId === event.WindowClosed.id) {
                    root.focusedWindowId = -1
                }
                return
            }

            if (event.WindowFocusChanged) {
                root.focusedWindowId = event.WindowFocusChanged.id === null
                    ? -1
                    : event.WindowFocusChanged.id

                return
            }

            if (event.WorkspaceActivated) {
                if (event.WorkspaceActivated.focused === true) {
                    root.focusedWorkspaceId = event.WorkspaceActivated.id
                }
                return
            }
        } catch (error) {
            // Ignore malformed or version-incompatible event lines.
        }
    }

    readonly property string computedActiveTitle: {
        const focused = root.windows.find(window => window.id === root.focusedWindowId)
        return focused ? (focused.title || focused.app_id || "Desktop") : "A16EEN"
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.launcherOpen = !root.launcherOpen
            if (root.launcherOpen) {
                root.dashboardOpen = false
                root.commandCenterOpen = false
                root.wallpaperPickerOpen = false
                root.widgetsCenterOpen = false
            }
        }

        function open(): void {
            root.launcherOpen = true
            root.dashboardOpen = false
            root.commandCenterOpen = false
            root.wallpaperPickerOpen = false
            root.widgetsCenterOpen = false
        }

        function close(): void {
            root.launcherOpen = false
        }
    }

    IpcHandler {
        target: "fullscreen"

        function exit(): void {
            const active = ToplevelManager.activeToplevel
            if (active && active.fullscreen)
                Quickshell.execDetached(["niri", "msg", "action", "fullscreen-window"])
        }
    }

    IpcHandler {
        target: "dashboard"

        function toggle(): void {
            root.dashboardOpen = !root.dashboardOpen
            if (root.dashboardOpen) {
                root.launcherOpen = false
                root.commandCenterOpen = false
                root.wallpaperPickerOpen = false
                root.widgetsCenterOpen = false
            }
        }

        function open(): void {
            root.dashboardOpen = true
            root.launcherOpen = false
            root.commandCenterOpen = false
            root.wallpaperPickerOpen = false
            root.widgetsCenterOpen = false
        }

        function close(): void {
            root.dashboardOpen = false
        }
    }

    IpcHandler {
        target: "wallpaper"

        function apply(path: string): void {
            if (path.length)
                root.wallpaperPath = path
        }
    }

    IpcHandler {
        target: "widgets"

        function toggle(): void {
            root.widgetsCenterOpen = !root.widgetsCenterOpen
            if (root.widgetsCenterOpen) {
                root.launcherOpen = false
                root.dashboardOpen = false
                root.commandCenterOpen = false
                root.wallpaperPickerOpen = false
            }
        }

        function open(): void {
            root.widgetsCenterOpen = true
            root.launcherOpen = false
            root.dashboardOpen = false
            root.commandCenterOpen = false
            root.wallpaperPickerOpen = false
        }

        function close(): void {
            root.widgetsCenterOpen = false
        }
    }

    IpcHandler {
        target: "command-center"

        function toggle(): void {
            root.commandCenterOpen = !root.commandCenterOpen
            if (root.commandCenterOpen) {
                root.launcherOpen = false
                root.dashboardOpen = false
                root.wallpaperPickerOpen = false
                root.widgetsCenterOpen = false
            }
        }

        function open(): void {
            root.commandCenterOpen = true
            root.launcherOpen = false
            root.dashboardOpen = false
            root.wallpaperPickerOpen = false
            root.widgetsCenterOpen = false
        }

        function close(): void {
            root.commandCenterOpen = false
        }
    }

    NotificationServer {
        id: notificationServer

        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        imageSupported: true
        actionsSupported: false
        persistenceSupported: false

        onNotification: notification => {
            if (root.latestNotification) root.latestNotification.tracked = false
            notification.tracked = true
            root.latestNotification = notification
            notificationTimer.restart()
        }
    }

    Timer {
        id: notificationTimer
        interval: 5500
        repeat: false

        onTriggered: {
            if (root.latestNotification) {
                root.latestNotification.tracked = false
            }
            root.latestNotification = null
        }
    }

    Process {
        id: niriEvents

        command: ["niri", "msg", "--json", "event-stream"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.consumeNiriEvent(data)
        }

        onRunningChanged: {
            if (!running) reconnectTimer.start()
        }
    }

    Timer {
        id: reconnectTimer
        interval: 1500
        repeat: false
        onTriggered: niriEvents.running = true
    }

    Process {
        id: loadProcess

        command: ["cat", "/proc/loadavg"]

        stdout: StdioCollector {
            onStreamFinished: {
                const pieces = text.trim().split(/\s+/)
                if (pieces.length > 0) root.systemLoad = Number(pieces[0]) || 0
            }
        }
    }

    Process {
        id: volumeProcess

        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]

        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim()
                const match = output.match(/Volume:\s*([0-9.]+)/)
                if (match) root.volumePercent = Math.round(Number(match[1]) * 100)
                root.volumeMuted = /\[MUTED\]/.test(output)
            }
        }
    }

    Timer {
        id: systemMonitorTimer
        interval: root.systemMonitorInterval
        repeat: true
        running: true

        onTriggered: {
            loadProcess.running = false
            loadProcess.running = true

            volumeProcess.running = false
            volumeProcess.running = true
        }
    }

    Variants {
        model: Quickshell.screens

        Wallpaper {
            modelData: modelData
            currentWallpaperPath: root.wallpaperPath
            desktopAnimationAllowed: root.wallpaperAnimationAllowed
        }
    }

    Loader {
        id: widgetHostLoader
        active: true
        source: Qt.resolvedUrl("ui/WidgetHost.qml")

        onLoaded: {
            item.modelData = root.primaryScreen
            item.timeEnabled = root.timeWidgetEnabled
            item.pulseEnabled = root.pulseWidgetEnabled
            item.workspaceEnabled = root.workspaceWidgetEnabled
            item.timeUse24Hour = root.timeUse24Hour
            item.timeShowSeconds = root.timeShowSeconds
            item.systemLoad = root.systemLoad
            item.volumePercent = root.volumePercent
            item.volumeMuted = root.volumeMuted
            item.workspaces = root.workspaces
            item.focusedWorkspaceId = root.focusedWorkspaceId
        }
    }

    Connections {
        target: root

        function onTimeWidgetEnabledChanged() {
            if (widgetHostLoader.item) widgetHostLoader.item.timeEnabled = root.timeWidgetEnabled
        }
        function onPulseWidgetEnabledChanged() {
            if (widgetHostLoader.item) widgetHostLoader.item.pulseEnabled = root.pulseWidgetEnabled
        }
        function onWorkspaceWidgetEnabledChanged() {
            if (widgetHostLoader.item) widgetHostLoader.item.workspaceEnabled = root.workspaceWidgetEnabled
        }
        function onTimeUse24HourChanged() {
            if (widgetHostLoader.item) widgetHostLoader.item.timeUse24Hour = root.timeUse24Hour
        }
        function onTimeShowSecondsChanged() {
            if (widgetHostLoader.item) widgetHostLoader.item.timeShowSeconds = root.timeShowSeconds
        }
        function onSystemLoadChanged() {
            if (widgetHostLoader.item) widgetHostLoader.item.systemLoad = root.systemLoad
        }
        function onVolumePercentChanged() {
            if (widgetHostLoader.item) widgetHostLoader.item.volumePercent = root.volumePercent
        }
        function onVolumeMutedChanged() {
            if (widgetHostLoader.item) widgetHostLoader.item.volumeMuted = root.volumeMuted
        }
        function onWorkspacesChanged() {
            if (widgetHostLoader.item) widgetHostLoader.item.workspaces = root.workspaces
        }
        function onFocusedWorkspaceIdChanged() {
            if (widgetHostLoader.item) widgetHostLoader.item.focusedWorkspaceId = root.focusedWorkspaceId
        }
    }

    Variants {
        model: Quickshell.screens

        Dock {
            modelData: modelData
            workspaces: root.workspaces
            focusedWorkspaceId: root.focusedWorkspaceId
            fullscreenActive: root.focusedWindowFullscreen

            onLauncherRequested: {
                root.launcherOpen = true
                root.dashboardOpen = false
                root.commandCenterOpen = false
                root.wallpaperPickerOpen = false
                root.widgetsCenterOpen = false
            }
        }
    }

    CommandCenter {
        modelData: root.primaryScreen
        opened: root.commandCenterOpen
        onCloseRequested: root.commandCenterOpen = false
        onLauncherRequested: {
            root.commandCenterOpen = false
            root.wallpaperPickerOpen = false
            root.launcherOpen = true
        }
        onDashboardRequested: {
            root.commandCenterOpen = false
            root.wallpaperPickerOpen = false
            root.dashboardOpen = true
        }
        onWallpaperRequested: {
            root.commandCenterOpen = false
            root.wallpaperPickerOpen = true
        }
    }

    Loader {
        id: widgetManagerLoader
        active: root.widgetsCenterOpen
        source: Qt.resolvedUrl("ui/WidgetManager.qml")

        onLoaded: {
            item.modelData = root.primaryScreen
            item.opened = root.widgetsCenterOpen
            item.timeEnabled = root.timeWidgetEnabled
            item.pulseEnabled = root.pulseWidgetEnabled
            item.workspaceEnabled = root.workspaceWidgetEnabled
            item.timeUse24Hour = root.timeUse24Hour
            item.timeShowSeconds = root.timeShowSeconds
        }
    }

    Connections {
        target: widgetManagerLoader.item

        function onCloseRequested() {
            root.widgetsCenterOpen = false
        }
        function onWidgetEnabledRequested(widgetId, enabled) {
            if (widgetId === "time")
                root.timeWidgetEnabled = enabled
            else if (widgetId === "pulse")
                root.pulseWidgetEnabled = enabled
            else if (widgetId === "workspaces")
                root.workspaceWidgetEnabled = enabled
        }
        function onTimeUse24HourRequested(enabled) {
            root.timeUse24Hour = enabled
        }
        function onTimeShowSecondsRequested(enabled) {
            root.timeShowSeconds = enabled
        }
    }

    WallpaperPicker {
        modelData: root.primaryScreen
        opened: root.wallpaperPickerOpen
        onCloseRequested: root.wallpaperPickerOpen = false
    }

    Launcher {
        modelData: root.primaryScreen
        opened: root.launcherOpen
        searchText: root.searchText
        onSearchTextChanged: root.searchText = searchText
        onCloseRequested: root.launcherOpen = false
    }

    Dashboard {
        modelData: root.primaryScreen
        opened: root.dashboardOpen
        activeTitle: root.computedActiveTitle
        systemLoad: root.systemLoad
        volumePercent: root.volumePercent
        volumeMuted: root.volumeMuted
    }

    NotificationToast {
        modelData: root.primaryScreen
        notification: root.latestNotification
    }
}
