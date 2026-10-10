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
    property bool screenshotCenterOpen: false
    property bool screenshotSettingsOpen: false
    property bool screenshotPreviewOpen: false
    property string screenshotPreviewPath: ""
    property string wallpaperPath: ""
    property string searchText: ""
    property string powerProfile: "balanced"
    property bool doNotDisturb: false
    property int iconThemeRevision: 0
    property string navbarPosition: "right"
    property bool quickNotesOpen: false
    property bool quickTasksOpen: false
    property bool quickPresetsOpen: false
    property bool quickUtilitiesOpen: false
    property bool utilitiesExpanded: false
    property string utilitiesMode: "wifi"
    property bool navbarRevealed: false
    property bool lockLaunchQueued: false
    property bool lockProcessRunning: false
    property bool lockSessionActive: false
    property string lockErrorMessage: ""
    // Only hide A16EEN surfaces after swaylock confirms the session is locked.
    readonly property bool secureLockActive: root.lockSessionActive

    Timer {
        id: lockLaunchTimer
        interval: 220
        repeat: false
        onTriggered: {
            // Start the locker while the UI remains visible. The locker emits
            // A16EEN_LOCK_READY only after Niri/Wayland confirms screen security.
            root.lockProcessRunning = true
            root.lockLaunchQueued = false
        }
    }

    // Run the installed Wayland locker as a tracked process so A16EEN can
    // hide its own overlay layer until the user successfully unlocks.
    Process {
        id: lockSessionProcess
        command: ["/usr/local/bin/a16een-lock"]
        running: root.lockProcessRunning

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (String(data).trim() === "A16EEN_LOCK_READY") {
                    // Retract the fullscreen navbar only after the locker
                    // confirms the session is secure.
                    root.navbarRevealed = false
                    root.lockSessionActive = true
                    root.lockLaunchQueued = false
                    console.info("A16EEN screen locker is ready.")
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(this.text || "").trim()
                if (message.length) {
                    root.lockErrorMessage = message
                    console.warn("A16EEN lock screen:", message)
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            const hadReadySignal = root.lockSessionActive
            root.lockProcessRunning = false
            root.lockSessionActive = false
            root.lockLaunchQueued = false
            if (!hadReadySignal || exitCode !== 0) {
                const reason = root.lockErrorMessage.length
                    ? root.lockErrorMessage
                    : (!hadReadySignal
                        ? "Locker exited before confirming that the screen was secured."
                        : "Locker exited with status " + exitCode)
                console.warn("A16EEN lock screen failed:", reason)
            }
        }
    }

    // Capture text-only clipboard changes into private, expiring user history.
    // Stop watching while the secure lock screen is active.
    Process {
        id: clipboardHistoryWatcher
        command: ["/usr/local/bin/a16een-clipboard", "watch"]
        running: !root.secureLockActive

        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(text || "").trim()
                if (message.length)
                    console.warn("A16EEN clipboard watcher:", message)
            }
        }
    }

    function requestLockScreen() {
        if (root.lockLaunchQueued || root.lockProcessRunning || root.lockSessionActive)
            return

        root.lockErrorMessage = ""
        root.quickNotesOpen = false
        root.quickTasksOpen = false
        root.quickPresetsOpen = false
        root.quickUtilitiesOpen = false
        root.utilitiesExpanded = false
        root.commandCenterOpen = false
        root.launcherOpen = false
        root.dashboardOpen = false
        root.wallpaperPickerOpen = false
        root.widgetsCenterOpen = false
        root.screenshotCenterOpen = false
        root.screenshotSettingsOpen = false
        root.screenshotPreviewOpen = false
        root.lockLaunchQueued = true
        lockLaunchTimer.restart()
    }

    readonly property string navbarLayoutPath: {
        const stateHome = Quickshell.env("XDG_STATE_HOME")
        const home = Quickshell.env("HOME") || ""
        const base = stateHome && stateHome.length ? stateHome : home + "/.local/state"
        return base + "/a16een/navbar-layout.json"
    }

    FileView {
        id: navbarLayoutFile
        path: root.navbarLayoutPath
        watchChanges: false
        printErrors: false
        onLoaded: {
            try {
                const parsed = JSON.parse(String(this.text || ""))
                if (parsed && ["left", "right", "top", "bottom"].includes(parsed.position))
                    root.navbarPosition = parsed.position
            } catch (error) {
                root.navbarPosition = "right"
            }
        }
    }
    property real controlIndicatorLevel: 0
    property int controlIndicatorRevision: 0

    readonly property string controlIndicatorEventPath: {
        const stateHome = Quickshell.env("XDG_STATE_HOME")
        const home = Quickshell.env("HOME") || ""
        const base = stateHome && stateHome.length
            ? stateHome
            : home + "/.local/state"
        return base + "/a16een/control-indicator"
    }

    // Widget state lives in the shell; rendering and management stay modular.
    property bool widgetsCenterOpen: false
    property bool editorialTimeWidgetEnabled: true
    property bool calendarWidgetEnabled: false
    property bool pulseWidgetEnabled: false
    property bool workspaceWidgetEnabled: false
    property bool tasksWidgetEnabled: false
    property bool musicWidgetEnabled: false
    property bool quotesWidgetEnabled: false
    property bool timeUse24Hour: true
    property bool timeShowSeconds: false
    property bool widgetSettingsLoaded: false
    property bool restoringWidgetSettings: false

    function widgetSettingsPayload() {
        return {
            editorialTimeWidgetEnabled: root.editorialTimeWidgetEnabled,
            calendarWidgetEnabled: root.calendarWidgetEnabled,
            pulseWidgetEnabled: root.pulseWidgetEnabled,
            workspaceWidgetEnabled: root.workspaceWidgetEnabled,
            tasksWidgetEnabled: root.tasksWidgetEnabled,
            musicWidgetEnabled: root.musicWidgetEnabled,
            quotesWidgetEnabled: root.quotesWidgetEnabled,
            timeUse24Hour: root.timeUse24Hour,
            timeShowSeconds: root.timeShowSeconds
        }
    }

    function requestWidgetSettingsSave() {
        if (!root.widgetSettingsLoaded || root.restoringWidgetSettings)
            return
        widgetSettingsSaveTimer.restart()
    }

    onEditorialTimeWidgetEnabledChanged: root.requestWidgetSettingsSave()
    onCalendarWidgetEnabledChanged: root.requestWidgetSettingsSave()
    onPulseWidgetEnabledChanged: root.requestWidgetSettingsSave()
    onWorkspaceWidgetEnabledChanged: root.requestWidgetSettingsSave()
    onTasksWidgetEnabledChanged: root.requestWidgetSettingsSave()
    onMusicWidgetEnabledChanged: root.requestWidgetSettingsSave()
    onQuotesWidgetEnabledChanged: root.requestWidgetSettingsSave()
    onTimeUse24HourChanged: root.requestWidgetSettingsSave()
    onTimeShowSecondsChanged: root.requestWidgetSettingsSave()

    Process {
        id: widgetSettingsLoadProcess
        command: ["a16een-widget-settings", "load"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.restoringWidgetSettings = true
                try {
                    const saved = JSON.parse(String(this.text || "{}"))
                    const keys = [
                        "editorialTimeWidgetEnabled", "calendarWidgetEnabled",
                        "pulseWidgetEnabled", "workspaceWidgetEnabled",
                        "tasksWidgetEnabled", "musicWidgetEnabled", "quotesWidgetEnabled",
                        "timeUse24Hour", "timeShowSeconds"
                    ]
                    for (let i = 0; i < keys.length; i++) {
                        const key = keys[i]
                        if (saved && typeof saved[key] === "boolean")
                            root[key] = saved[key]
                    }
                } catch (error) {
                    console.warn("A16EEN could not load saved widget preferences:", error)
                }
                root.restoringWidgetSettings = false
                root.widgetSettingsLoaded = true
            }
        }
    }

    Process {
        id: widgetSettingsSaveProcess
        command: ["a16een-widget-settings", "save", "{}"]
        running: false
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("A16EEN could not save widget preferences.")
        }
    }

    Timer {
        id: widgetSettingsSaveTimer
        interval: 300
        repeat: false
        onTriggered: {
            if (!root.widgetSettingsLoaded || root.restoringWidgetSettings)
                return
            if (widgetSettingsSaveProcess.running) {
                widgetSettingsSaveTimer.restart()
                return
            }
            widgetSettingsSaveProcess.command = [
                "a16een-widget-settings", "save",
                JSON.stringify(root.widgetSettingsPayload())
            ]
            widgetSettingsSaveProcess.running = true
        }
    }

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
        && !root.screenshotCenterOpen
        && !root.quickNotesOpen
        && !root.quickTasksOpen
        && !root.quickUtilitiesOpen
        && !root.lockLaunchQueued
        && !root.secureLockActive

    readonly property bool wallpaperAnimationAllowed: {
        switch (root.powerProfile) {
        case "performance":
            // Performance mode keeps live wallpapers running behind normal
            // and half-open/floating windows. Only a true fullscreen window pauses it.
            return !root.focusedWindowFullscreen && !root.secureLockActive
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

    FileView {
        id: controlIndicatorEvent

        path: root.controlIndicatorEventPath
        watchChanges: true

        onFileChanged: {
            controlIndicatorEvent.reload()
        }

        onLoaded: {
            root.consumeControlIndicatorEvent(this.text())
        }
    }

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
                root.screenshotCenterOpen = false
            }
        }

        function open(): void {
            root.launcherOpen = true
            root.dashboardOpen = false
            root.commandCenterOpen = false
            root.wallpaperPickerOpen = false
            root.widgetsCenterOpen = false
            root.screenshotCenterOpen = false
            root.screenshotSettingsOpen = false
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

    // Preserve the existing IPC target, but send it to the compact presets
    // popover instead of opening the legacy Command Center preset page.
    IpcHandler {
        target: "workspace-presets"

        function open(): void {
            root.openQuickPresets()
        }

        function toggle(): void {
            if (root.quickPresetsOpen)
                root.quickPresetsOpen = false
            else
                root.openQuickPresets()
        }

        function close(): void {
            root.quickPresetsOpen = false
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
                root.screenshotCenterOpen = false
            }
        }

        function open(): void {
            root.dashboardOpen = true
            root.launcherOpen = false
            root.commandCenterOpen = false
            root.wallpaperPickerOpen = false
            root.widgetsCenterOpen = false
            root.screenshotCenterOpen = false
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
            if (root.commandCenterOpen && root.widgetsCenterOpen) {
                root.widgetsCenterOpen = false
                return
            }

            root.widgetsCenterOpen = true
            root.commandCenterOpen = true
            root.launcherOpen = false
            root.dashboardOpen = false
            root.wallpaperPickerOpen = false
            root.screenshotCenterOpen = false
        }

        function open(): void {
            root.widgetsCenterOpen = true
            root.commandCenterOpen = true
            root.launcherOpen = false
            root.dashboardOpen = false
            root.wallpaperPickerOpen = false
            root.screenshotCenterOpen = false
            root.screenshotSettingsOpen = false
        }

        function close(): void {
            root.widgetsCenterOpen = false
        }
    }

    IpcHandler {
        target: "screenshot"

        function toggle(): void {
            if (root.screenshotCenterOpen || root.screenshotSettingsOpen) {
                root.screenshotCenterOpen = false
                root.screenshotSettingsOpen = false
                return
            }

            root.screenshotCenterOpen = true
            root.screenshotSettingsOpen = false
            root.launcherOpen = false
            root.dashboardOpen = false
            root.commandCenterOpen = false
            root.wallpaperPickerOpen = false
            root.widgetsCenterOpen = false
        }

        function open(): void {
            root.screenshotCenterOpen = true
            root.screenshotSettingsOpen = false
            root.launcherOpen = false
            root.dashboardOpen = false
            root.commandCenterOpen = false
            root.wallpaperPickerOpen = false
            root.widgetsCenterOpen = false
        }

        function close(): void {
            root.screenshotCenterOpen = false
            root.screenshotSettingsOpen = false
        }

        function settings(): void {
            root.screenshotCenterOpen = false
            root.screenshotSettingsOpen = true
            root.launcherOpen = false
            root.dashboardOpen = false
            root.commandCenterOpen = false
            root.wallpaperPickerOpen = false
            root.widgetsCenterOpen = false
        }

        function preview(path: string): void {
            if (path.length) {
                root.screenshotPreviewPath = path
                root.screenshotPreviewOpen = true
            }
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
                root.screenshotCenterOpen = false
                root.screenshotSettingsOpen = false
            }
        }

        function open(): void {
            root.commandCenterOpen = true
            root.launcherOpen = false
            root.dashboardOpen = false
            root.wallpaperPickerOpen = false
            root.widgetsCenterOpen = false
            root.screenshotSettingsOpen = false
        }

        function close(): void {
            root.commandCenterOpen = false
        }
    }

    function showControlIndicator(level: real): void {
        root.controlIndicatorLevel = Math.max(0, Math.min(1, level))
        root.controlIndicatorRevision++
    }

    function consumeControlIndicatorEvent(raw): void {
        const line = String(raw).trim()
        if (!line.length)
            return

        const parts = line.split("|")
        if (parts.length < 2)
            return

        const kind = parts[0]
        const value = Number(parts[1])

        if ((kind !== "volume" && kind !== "brightness") || !Number.isFinite(value))
            return

        root.showControlIndicator(value)
    }

    function setDoNotDisturb(enabled) {
        root.doNotDisturb = enabled
        dndWriter.running = false
        Qt.callLater(() => dndWriter.running = true)
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
            if (root.doNotDisturb) {
                notification.tracked = false
                return
            }

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
        id: dndReader
        command: ["a16een-control", "dnd", "get"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                root.doNotDisturb = text.trim().toLowerCase() === "on"
            }
        }
    }

    Process {
        id: dndWriter
        command: ["a16een-control", "dnd", root.doNotDisturb ? "on" : "off"]
        running: false

        onRunningChanged: {
            if (!running && root.doNotDisturb && root.latestNotification) {
                root.latestNotification.tracked = false
                root.latestNotification = null
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
            editorialTimeWidgetEnabled: root.editorialTimeWidgetEnabled
            timeUse24Hour: root.timeUse24Hour
            timeShowSeconds: root.timeShowSeconds
        }
    }

    Variants {
        model: Quickshell.screens

        CalendarWidget {
            modelData: modelData
            widgetEnabled: root.calendarWidgetEnabled && !root.secureLockActive
            use24Hour: root.timeUse24Hour
            showSeconds: root.timeShowSeconds
        }
    }

    Variants {
        model: Quickshell.screens

        SystemPulseWidget {
            modelData: modelData
            widgetEnabled: root.pulseWidgetEnabled && !root.secureLockActive
            systemLoad: root.systemLoad
            volumePercent: root.volumePercent
            volumeMuted: root.volumeMuted
        }
    }

    Variants {
        model: Quickshell.screens

        WorkspaceWidget {
            modelData: modelData
            widgetEnabled: root.workspaceWidgetEnabled && !root.secureLockActive
            workspaces: root.workspaces
            focusedWorkspaceId: root.focusedWorkspaceId
        }
    }

    Variants {
        model: Quickshell.screens

        TasksWidget {
            modelData: modelData
            widgetEnabled: root.tasksWidgetEnabled && !root.secureLockActive
        }
    }

    Variants {
        model: Quickshell.screens

        QuotesWidget {
            modelData: modelData
            widgetEnabled: root.quotesWidgetEnabled && !root.secureLockActive
            navbarPosition: root.navbarPosition
        }
    }

    Variants {
        model: Quickshell.screens

        MusicWidget {
            modelData: modelData
            widgetEnabled: root.musicWidgetEnabled && !root.secureLockActive
            navbarPosition: root.navbarPosition
        }
    }

    Variants {
        model: Quickshell.screens

        Dock {
            modelData: modelData
            workspaces: root.workspaces
            focusedWorkspaceId: root.focusedWorkspaceId
            fullscreenActive: root.focusedWindowFullscreen
            navbarPosition: root.navbarPosition
            utilitiesExpanded: root.utilitiesExpanded
            selectedUtility: root.utilitiesMode
            lockInProgress: root.secureLockActive
            onDockVisibilityChanged: {
                if (modelData === root.primaryScreen)
                    root.navbarRevealed = visible
            }

            onLauncherRequested: {
                root.launcherOpen = true
                root.dashboardOpen = false
                root.commandCenterOpen = false
                root.wallpaperPickerOpen = false
                root.widgetsCenterOpen = false
            }

            onLockRequested: root.requestLockScreen()
            onUtilitiesRequested: root.handleUtilitiesRequest(mode)
        }
    }

    function handleUtilitiesRequest(mode) {
        if (mode === "toggle" && root.quickUtilitiesOpen) {
            root.quickUtilitiesOpen = false
            root.utilitiesExpanded = false
            return
        }

        root.quickNotesOpen = false
        root.quickTasksOpen = false
        root.quickPresetsOpen = false
        root.commandCenterOpen = false
        root.launcherOpen = false
        root.dashboardOpen = false
        root.wallpaperPickerOpen = false
        root.widgetsCenterOpen = false
        root.screenshotCenterOpen = false
        root.screenshotSettingsOpen = false

        root.quickUtilitiesOpen = true
        root.utilitiesExpanded = true
        root.utilitiesMode = ["wifi", "bluetooth", "clipboard"].includes(mode) ? mode : "wifi"
    }

    function openQuickTasks() {
        root.quickTasksOpen = true
        root.quickPresetsOpen = false
        root.quickUtilitiesOpen = false
        root.utilitiesExpanded = false
        // The navbar's lightweight task list is independent of the old desktop widget.
        root.tasksWidgetEnabled = false
        root.quickNotesOpen = false
        root.commandCenterOpen = false
        root.launcherOpen = false
        root.dashboardOpen = false
        root.wallpaperPickerOpen = false
        root.widgetsCenterOpen = false
        root.screenshotCenterOpen = false
        root.screenshotSettingsOpen = false
    }

    function openQuickPresets() {
        root.quickPresetsOpen = true
        root.quickUtilitiesOpen = false
        root.utilitiesExpanded = false
        root.quickNotesOpen = false
        root.quickTasksOpen = false
        root.tasksWidgetEnabled = false
        root.commandCenterOpen = false
        root.launcherOpen = false
        root.dashboardOpen = false
        root.wallpaperPickerOpen = false
        root.widgetsCenterOpen = false
        root.screenshotCenterOpen = false
        root.screenshotSettingsOpen = false
    }

    QuickActionsTray {
        modelData: root.primaryScreen
        navbarPosition: root.navbarPosition
        dockVisible: !root.secureLockActive && (!root.focusedWindowFullscreen || root.navbarRevealed)

        onNotesRequested: {
            root.quickNotesOpen = true
            root.quickUtilitiesOpen = false
            root.utilitiesExpanded = false
            root.quickTasksOpen = false
            root.quickPresetsOpen = false
            root.commandCenterOpen = false
            root.launcherOpen = false
            root.dashboardOpen = false
            root.wallpaperPickerOpen = false
            root.widgetsCenterOpen = false
            root.screenshotCenterOpen = false
            root.screenshotSettingsOpen = false
        }

        onTasksRequested: root.openQuickTasks()

        onPresetsRequested: root.openQuickPresets()

    }

    QuickNotes {
        modelData: root.primaryScreen
        navbarPosition: root.navbarPosition
        // Once opened, keep the small popup available even if fullscreen
        // auto-hide retracts the navbar underneath it.
        dockVisible: !root.secureLockActive
        opened: root.quickNotesOpen
        onCloseRequested: root.quickNotesOpen = false
    }

    QuickTasks {
        modelData: root.primaryScreen
        navbarPosition: root.navbarPosition
        // The popup survives navbar auto-hide until the user closes it.
        dockVisible: !root.secureLockActive
        opened: root.quickTasksOpen
        onCloseRequested: root.quickTasksOpen = false
    }

    UtilitiesPanel {
        modelData: root.primaryScreen
        navbarPosition: root.navbarPosition
        dockVisible: !root.secureLockActive
        opened: root.quickUtilitiesOpen
        selectedMode: root.utilitiesMode
        onModeRequested: root.handleUtilitiesRequest(mode)
        onCloseRequested: {
            root.quickUtilitiesOpen = false
            root.utilitiesExpanded = false
        }
    }

    QuickPresets {
        modelData: root.primaryScreen
        navbarPosition: root.navbarPosition
        dockVisible: !root.secureLockActive
        opened: root.quickPresetsOpen
        onCloseRequested: root.quickPresetsOpen = false
    }

    CommandCenter {
        id: commandCenter
        modelData: root.primaryScreen
        opened: root.commandCenterOpen
        widgetViewOpen: root.widgetsCenterOpen
        editorialTimeWidgetEnabled: root.editorialTimeWidgetEnabled
        calendarWidgetEnabled: root.calendarWidgetEnabled
        pulseWidgetEnabled: root.pulseWidgetEnabled
        workspaceWidgetEnabled: root.workspaceWidgetEnabled
        tasksWidgetEnabled: root.tasksWidgetEnabled
        musicWidgetEnabled: root.musicWidgetEnabled
        quotesWidgetEnabled: root.quotesWidgetEnabled
        timeUse24Hour: root.timeUse24Hour
        timeShowSeconds: root.timeShowSeconds
        doNotDisturb: root.doNotDisturb

        onCloseRequested: root.commandCenterOpen = false
        onPresetsRequested: root.openQuickPresets()

        onNavbarPositionChanged: {
            if (["left", "right", "top", "bottom"].includes(position))
                root.navbarPosition = position
        }

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

        onScreenshotRequested: {
            root.commandCenterOpen = false
            root.screenshotCenterOpen = true
            root.screenshotSettingsOpen = false
            root.launcherOpen = false
            root.dashboardOpen = false
            root.wallpaperPickerOpen = false
            root.widgetsCenterOpen = false
        }

        onScreenshotSettingsRequested: {
            root.commandCenterOpen = false
            root.screenshotCenterOpen = false
            root.screenshotSettingsOpen = true
            root.launcherOpen = false
            root.dashboardOpen = false
            root.wallpaperPickerOpen = false
            root.widgetsCenterOpen = false
        }

        onWidgetsRequested: {
            root.widgetsCenterOpen = true
            root.commandCenterOpen = true
            root.screenshotCenterOpen = false
            root.screenshotSettingsOpen = false
            root.launcherOpen = false
            root.dashboardOpen = false
            root.wallpaperPickerOpen = false
        }

        onWidgetsCloseRequested: {
            root.widgetsCenterOpen = false
        }

        onEditorialTimeWidgetEnabledRequested: {
            root.editorialTimeWidgetEnabled = enabled
            if (enabled)
                root.calendarWidgetEnabled = false
            root.requestWidgetSettingsSave()
        }
        onCalendarWidgetEnabledRequested: {
            root.calendarWidgetEnabled = enabled
            if (enabled)
                root.editorialTimeWidgetEnabled = false
            root.requestWidgetSettingsSave()
        }
        onPulseWidgetEnabledRequested: {
            root.pulseWidgetEnabled = enabled
            root.requestWidgetSettingsSave()
        }
        onWorkspaceWidgetEnabledRequested: {
            root.workspaceWidgetEnabled = enabled
            root.requestWidgetSettingsSave()
        }
        onTasksWidgetEnabledRequested: {
            root.tasksWidgetEnabled = enabled
            root.requestWidgetSettingsSave()
        }
        onMusicWidgetEnabledRequested: {
            root.musicWidgetEnabled = enabled
            root.requestWidgetSettingsSave()
        }
        onQuotesWidgetEnabledRequested: {
            root.quotesWidgetEnabled = enabled
            root.requestWidgetSettingsSave()
        }
        onTimeUse24HourRequested: {
            root.timeUse24Hour = enabled
            root.requestWidgetSettingsSave()
        }
        onTimeShowSecondsRequested: {
            root.timeShowSeconds = enabled
            root.requestWidgetSettingsSave()
        }

        onDoNotDisturbRequested: root.setDoNotDisturb(enabled)
        onIconThemeChanged: root.iconThemeRevision++
    }

    ScreenshotCenter {
        modelData: root.primaryScreen
        opened: root.screenshotCenterOpen
        onCloseRequested: root.screenshotCenterOpen = false
    }

    ScreenshotSettings {
        modelData: root.primaryScreen
        opened: root.screenshotSettingsOpen
        onCloseRequested: root.screenshotSettingsOpen = false
    }

    Variants {
        model: Quickshell.screens

        ScreenshotPreview {
            modelData: modelData
            opened: root.screenshotPreviewOpen
            imagePath: root.screenshotPreviewPath
            onCloseRequested: root.screenshotPreviewOpen = false
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
        iconThemeRevision: root.iconThemeRevision
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

        onLockRequested: root.requestLockScreen()
    }

    Variants {
        model: Quickshell.screens

        ControlIndicator {
            modelData: modelData
            requestedLevel: root.controlIndicatorLevel
            requestRevision: root.controlIndicatorRevision
            active: modelData === root.primaryScreen && !root.secureLockActive
        }
    }

    NotificationToast {
        modelData: root.primaryScreen
        notification: root.secureLockActive ? null : root.latestNotification
    }
}
