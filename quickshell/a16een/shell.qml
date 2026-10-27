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
    property bool commandCenterOpen: false
    property bool wallpaperPickerOpen: false
    property bool screenshotCenterOpen: false
    property bool screenshotSettingsOpen: false
    property bool screenshotPreviewOpen: false
    property string screenshotPreviewPath: ""
    property string wallpaperPath: ""
    property string wallpaperPreviewPath: ""
    property string searchText: ""
    property string powerProfile: "balanced"
    property bool doNotDisturb: false
    property int iconThemeRevision: 0
    property string navbarPosition: "right"
    property bool quickNotesOpen: false
    property bool quickTasksOpen: false
    property bool quickPresetsOpen: false
    property bool gamingPanelOpen: false
    property bool quickUtilitiesOpen: false
    property bool utilitiesExpanded: false
    property string utilitiesMode: "wifi"
    property bool navbarRevealed: false
    property bool lockLaunchQueued: false
    property bool lockProcessRunning: false
    property bool lockSessionActive: false
    property string lockErrorMessage: ""
    property bool lockSettingsLoaded: false
    property bool lockIdleEnabled: true
    property int lockIdleMinutes: 5
    property bool lockOnSleepEnabled: true
    property bool lockWatcherRunning: false
    readonly property string lockReadyStatusPath: {
        const stateHome = Quickshell.env("XDG_STATE_HOME")
        const home = Quickshell.env("HOME") || ""
        const base = stateHome && stateHome.length ? stateHome : home + "/.local/state"
        return base + "/a16een/lockscreen-ready"
    }
    readonly property var lockWatcherCommand: {
        const args = ["swayidle", "-w"]
        if (root.lockIdleEnabled)
            args.push("timeout", String(root.lockIdleMinutes * 60), "qs ipc call lock-screen request")
        if (root.lockOnSleepEnabled) {
            args.push("before-sleep", "a16een-lockscreen prepare-sleep")
            args.push("after-resume", "qs ipc call lock-screen request")
        }
        return args
    }
    // Only hide A16EEN surfaces after GTKLock/swaylock confirms the session is locked.
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

    Timer {
        id: lockWatcherRestartTimer
        interval: 250
        repeat: false
        onTriggered: {
            root.lockWatcherRunning = root.lockSettingsLoaded
                && (root.lockIdleEnabled || root.lockOnSleepEnabled)
        }
    }

    Timer {
        id: lockSettingsSaveTimer
        interval: 180
        repeat: false
        onTriggered: {
            lockSettingsWriter.running = false
            Qt.callLater(() => lockSettingsWriter.running = true)
        }
    }

    FileView {
        id: lockReadyStatusFile
        path: root.lockReadyStatusPath
        printErrors: false
        atomicWrites: true
    }

    Process {
        id: lockSettingsReader
        command: ["a16een-lockscreen", "get"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.parseLockSettings(text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(text || "").trim()
                if (message.length)
                    console.warn("A16EEN lock-screen settings:", message)
            }
        }
    }

    Process {
        id: lockSettingsWriter
        command: [
            "a16een-lockscreen", "set-all",
            root.lockIdleEnabled ? "true" : "false",
            String(root.lockIdleMinutes),
            root.lockOnSleepEnabled ? "true" : "false"
        ]
        running: false

        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(text || "").trim()
                if (message.length)
                    console.warn("A16EEN could not save lock-screen settings:", message)
            }
        }
    }

    Process {
        id: idleLockWatcher
        command: root.lockWatcherCommand
        running: root.lockWatcherRunning

        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(text || "").trim()
                if (message.length)
                    console.warn("A16EEN idle lock watcher:", message)
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (root.lockWatcherRunning) {
                root.lockWatcherRunning = false
                if (exitCode !== 0)
                    console.warn("A16EEN idle lock watcher exited with status", exitCode)
            }
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
                    lockReadyStatusFile.setText("ready\n")
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
            lockReadyStatusFile.setText("unlocked\n")
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

    function parseLockSettings(rawText) {
        const values = ({})
        for (const line of String(rawText || "").split("\n")) {
            const index = line.indexOf("=")
            if (index < 0)
                continue
            values[line.slice(0, index).trim()] = line.slice(index + 1).trim()
        }

        const idleEnabled = values.idle_enabled !== "false"
        const parsedMinutes = Number(values.idle_minutes || 5)
        const idleMinutes = [1, 3, 5, 10, 15, 30].includes(parsedMinutes) ? parsedMinutes : 5
        const sleepLockEnabled = values.sleep_lock !== "false"
        root.applyLockSettings(idleEnabled, idleMinutes, sleepLockEnabled, false)
    }

    function applyLockSettings(idleEnabled, idleMinutes, sleepLockEnabled, persist) {
        const parsedMinutes = Number(idleMinutes)
        const safeMinutes = [1, 3, 5, 10, 15, 30].includes(parsedMinutes) ? parsedMinutes : 5
        root.lockIdleEnabled = idleEnabled === true
        root.lockIdleMinutes = safeMinutes
        root.lockOnSleepEnabled = sleepLockEnabled === true
        root.lockSettingsLoaded = true

        // Restart only the idle watcher after options have settled. No periodic
        // polling is needed; settings edits trigger this small restart directly.
        root.lockWatcherRunning = false
        lockWatcherRestartTimer.restart()
        if (persist)
            lockSettingsSaveTimer.restart()
    }

    function prepareLockBeforeSleep() {
        if (root.lockSessionActive) {
            lockReadyStatusFile.setText("ready\n")
            return
        }

        lockReadyStatusFile.setText("pending\n")
        if (root.lockLaunchQueued) {
            lockLaunchTimer.stop()
            root.lockLaunchQueued = false
            root.lockProcessRunning = true
            return
        }
        root.requestLockScreen(true)
    }

    function requestLockScreen(immediate) {
        if (root.lockLaunchQueued || root.lockProcessRunning || root.lockSessionActive)
            return

        root.lockErrorMessage = ""
        lockReadyStatusFile.setText("pending\n")
        root.notificationCenterOpen = false
        root.toolsPanelOpen = false
        root.toolsPanelPage = "tools"
        root.calculatorOpen = false
        root.quickNotesOpen = false
        root.quickTasksOpen = false
        root.quickPresetsOpen = false
        root.gamingPanelOpen = false
        root.quickUtilitiesOpen = false
        root.utilitiesExpanded = false
        root.commandCenterOpen = false
        root.launcherOpen = false
        root.wallpaperPickerOpen = false
        root.widgetsCenterOpen = false
        root.screenshotCenterOpen = false
        root.screenshotSettingsOpen = false
        root.screenshotPreviewOpen = false
        root.lockLaunchQueued = true
        if (immediate === true) {
            lockLaunchTimer.stop()
            root.lockProcessRunning = true
            root.lockLaunchQueued = false
        } else {
            lockLaunchTimer.restart()
        }
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
    property bool musicWidgetEnabled: false
    property string musicWidgetBackgroundColor: "#EAF2F8"
    property int musicWidgetBackgroundOpacity: 72
    property bool quotesWidgetEnabled: false
    property bool appShelfWidgetEnabled: false
    property string appShelfShape: "capsule"
    property bool appShelfRotationEnabled: true
    property var appShelfApps: []
    property bool timeUse24Hour: true
    property bool timeShowSeconds: false
    property bool widgetSettingsLoaded: false
    property bool restoringWidgetSettings: false

    function widgetSettingsPayload() {
        return {
            editorialTimeWidgetEnabled: root.editorialTimeWidgetEnabled,
            musicWidgetEnabled: root.musicWidgetEnabled,
            musicWidgetBackgroundColor: root.musicWidgetBackgroundColor,
            musicWidgetBackgroundOpacity: root.musicWidgetBackgroundOpacity,
            quotesWidgetEnabled: root.quotesWidgetEnabled,
            appShelfWidgetEnabled: root.appShelfWidgetEnabled,
            appShelfShape: root.appShelfShape,
            appShelfRotationEnabled: root.appShelfRotationEnabled,
            appShelfApps: root.appShelfApps,
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
    onMusicWidgetEnabledChanged: root.requestWidgetSettingsSave()
    onMusicWidgetBackgroundColorChanged: root.requestWidgetSettingsSave()
    onMusicWidgetBackgroundOpacityChanged: root.requestWidgetSettingsSave()
    onQuotesWidgetEnabledChanged: root.requestWidgetSettingsSave()
    onAppShelfWidgetEnabledChanged: root.requestWidgetSettingsSave()
    onAppShelfShapeChanged: root.requestWidgetSettingsSave()
    onAppShelfRotationEnabledChanged: root.requestWidgetSettingsSave()
    onAppShelfAppsChanged: root.requestWidgetSettingsSave()
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
                        "editorialTimeWidgetEnabled",
                        "musicWidgetEnabled",
                        "quotesWidgetEnabled",
                        "appShelfWidgetEnabled",
                        "appShelfRotationEnabled",
                        "timeUse24Hour",
                        "timeShowSeconds"
                    ]
                    for (let i = 0; i < keys.length; i++) {
                        const key = keys[i]
                        if (saved && typeof saved[key] === "boolean")
                            root[key] = saved[key]
                    }
                    if (saved && typeof saved.musicWidgetBackgroundColor === "string"
                            && /^#[0-9a-fA-F]{6}$/.test(saved.musicWidgetBackgroundColor))
                        root.musicWidgetBackgroundColor = saved.musicWidgetBackgroundColor
                    if (saved && Number.isInteger(saved.musicWidgetBackgroundOpacity)
                            && saved.musicWidgetBackgroundOpacity >= 0
                            && saved.musicWidgetBackgroundOpacity <= 100)
                        root.musicWidgetBackgroundOpacity = saved.musicWidgetBackgroundOpacity
                    if (saved && ["capsule", "rounded", "compact", "circle"].includes(saved.appShelfShape))
                        root.appShelfShape = saved.appShelfShape
                    if (saved && Array.isArray(saved.appShelfApps)) {
                        root.appShelfApps = saved.appShelfApps
                            .filter(app => app && typeof app.desktopId === "string" && app.desktopId.length > 0)
                            .slice(0, 16)
                            .map(app => ({
                                desktopId: String(app.desktopId),
                                name: String(app.name || "Application"),
                                icon: String(app.icon || "")
                            }))
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

    ScreenTimeTracker {
        id: screenTimeTracker
        focusedWindowId: root.focusedWindowId
        windows: root.windows
        locked: root.lockLaunchQueued || root.secureLockActive
    }

    readonly property bool wallpaperDesktopActive:
        root.focusedWindowId < 0
        && !root.focusedWindowFullscreen
        && !root.launcherOpen
        && !root.commandCenterOpen
        && !root.wallpaperPickerOpen
        && !root.widgetsCenterOpen
        && !root.screenshotCenterOpen
        && !root.notificationCenterOpen
        && !root.toolsPanelOpen
        && !root.calculatorOpen
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


    property int volumePercent: 0
    property bool volumeMuted: false
    property var latestNotification: null
    property bool notificationCenterOpen: false
    property bool toolsPanelOpen: false
    property bool calculatorOpen: false
    property string toolsPanelPage: "tools"
    property bool quickToolWindowOpen: false
    property string quickToolWindowPage: "updates"
    property string quickToolWindowRequestedAppId: ""
    property bool dataMeterEnabled: false
    property bool dataMeterSettingsReady: false
    property bool dataMeterSnapshotReady: false
    property var dataMeterSnapshot: ({})
    property string dataMeterError: ""
    readonly property string dataMeterSettingsPath: Quickshell.stateDir + "/data-meter-settings.json"
    property int batteryWarningPercent: 20
    property int batteryCriticalPercent: 10
    property int batteryEmergencyPercent: 5
    property bool batteryWarningEnabled: true
    property bool batteryCriticalEnabled: true
    property bool batteryEmergencyEnabled: true
    property bool batteryWarningSettingsReady: false
    property var batteryAlertedLevels: []
    property int batteryLastPercent: -1
    readonly property string batteryWarningSettingsPath: Quickshell.stateDir + "/battery-warning-settings.json"
    property var notificationHistory: []
    property bool notificationHistoryReady: false
    readonly property int unreadNotificationCount:
        root.notificationHistory.filter(item => !Boolean(item.read)).length

    readonly property var primaryScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    FileView {
        id: notificationHistoryFile
        path: Quickshell.stateDir + "/notification-history.json"
        preload: true
        printErrors: false
        atomicWrites: true
        onLoaded: root.loadNotificationHistory()
        onLoadFailed: {
            root.notificationHistoryReady = true
            if (root.notificationHistory.length)
                notificationHistorySaveTimer.restart()
        }
    }

    Timer {
        id: notificationHistorySaveTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (root.notificationHistoryReady) {
                notificationHistoryFile.setText(JSON.stringify({
                    version: 1,
                    notifications: root.notificationHistory
                }))
            }
        }
    }

    FileView {
        id: dataMeterSettingsFile
        path: root.dataMeterSettingsPath
        preload: true
        printErrors: false
        atomicWrites: true
        onLoaded: root.loadDataMeterSettings()
        onLoadFailed: root.dataMeterSettingsReady = true
    }

    Timer {
        id: dataMeterSettingsSaveTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (root.dataMeterSettingsReady) {
                dataMeterSettingsFile.setText(JSON.stringify({
                    version: 1,
                    showSpeed: root.dataMeterEnabled
                }))
            }
        }
    }

    FileView {
        id: batteryWarningSettingsFile
        path: root.batteryWarningSettingsPath
        preload: true
        printErrors: false
        atomicWrites: true
        onLoaded: root.loadBatteryWarningSettings(batteryWarningSettingsFile.text())
        onLoadFailed: {
            root.batteryWarningSettingsReady = true
            Qt.callLater(() => root.checkBatteryWarnings())
        }
    }

    Timer {
        id: batteryWarningSettingsSaveTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (root.batteryWarningSettingsReady) {
                batteryWarningSettingsFile.setText(JSON.stringify({
                    version: 1,
                    warningPercent: root.batteryWarningPercent,
                    criticalPercent: root.batteryCriticalPercent,
                    emergencyPercent: root.batteryEmergencyPercent,
                    warningEnabled: root.batteryWarningEnabled,
                    criticalEnabled: root.batteryCriticalEnabled,
                    emergencyEnabled: root.batteryEmergencyEnabled
                }))
            }
        }
    }

    Timer {
        id: batteryWarningMonitorTimer
        interval: 8000
        repeat: true
        running: true
        onTriggered: root.checkBatteryWarnings()
    }

    Process {
        id: dataMeterProcess
        command: ["a16een-data-meter", "snapshot"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(String(text || "{}"))
                    if (!parsed || typeof parsed !== "object")
                        throw new Error("No data snapshot was returned")
                    root.dataMeterSnapshot = parsed
                    root.dataMeterSnapshotReady = true
                    root.dataMeterError = ""
                } catch (error) {
                    root.dataMeterError = "Network data is unavailable."
                    console.warn("A16EEN Data Meter could not parse the snapshot:", error)
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(text || "").trim()
                if (message.length) {
                    root.dataMeterError = "Network data is unavailable."
                    console.warn("A16EEN Data Meter:", message)
                }
            }
        }
    }

    // One startup snapshot seeds today's counters; this timer stops by itself.
    // Continuous sampling only begins while the Data Meter page or speed pill is enabled.
    Timer {
        id: dataMeterBootstrapTimer
        interval: 250
        repeat: false
        running: true
        onTriggered: {
            if (!dataMeterProcess.running)
                dataMeterProcess.running = true
        }
    }

    Timer {
        id: dataMeterTimer
        interval: 1000
        repeat: true
        running: root.dataMeterEnabled || (root.toolsPanelOpen && root.toolsPanelPage === "data-meter")
        onTriggered: root.requestDataMeterSnapshot()
    }

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

    // A low-frequency check handles wallpaper rotation and time-of-day schedules.
    // The helper exits immediately when automation is disabled; no shell restart is needed.
    Timer {
        id: wallpaperAutomationTimer
        interval: 30000
        repeat: true
        running: true
        onTriggered: {
            wallpaperAutomationProcess.running = false
            wallpaperAutomationProcess.running = true
        }
    }

    Process {
        id: wallpaperAutomationProcess
        command: ["a16een-wallpaper", "auto-check"]
        running: false
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

            // Niri reports tile positions/sizes separately as windows are
            // resized, moved, or the scrolling workspace view changes. Keep
            // the shared state fresh so ScreenshotCenter hover targets match
            // the actual on-screen windows.
            if (event.WindowLayoutsChanged) {
                const changes = event.WindowLayoutsChanged.changes || []
                if (changes.length) {
                    const updatedWindows = root.windows.slice()
                    for (let i = 0; i < changes.length; i++) {
                        const change = changes[i]
                        const id = Array.isArray(change) ? change[0] : change.id
                        const layout = Array.isArray(change) ? change[1] : change.layout
                        if (!layout)
                            continue
                        for (let j = 0; j < updatedWindows.length; j++) {
                            if (Number(updatedWindows[j].id) === Number(id)) {
                                updatedWindows[j].layout = layout
                                break
                            }
                        }
                    }
                    root.windows = updatedWindows
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

    IpcHandler {
        target: "lock-screen"

        function request(): void {
            root.requestLockScreen(false)
        }

        function prepare(): void {
            root.prepareLockBeforeSleep()
        }
    }

    IpcHandler {
        target: "screen-time"

        function idle(): void {
            screenTimeTracker.setIdleState(true)
        }

        function resume(): void {
            screenTimeTracker.setIdleState(false)
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.launcherOpen = !root.launcherOpen
            if (root.launcherOpen) {
                root.toolsPanelOpen = false
                root.toolsPanelPage = "tools"
                root.calculatorOpen = false
                root.commandCenterOpen = false
                root.wallpaperPickerOpen = false
                root.widgetsCenterOpen = false
                root.screenshotCenterOpen = false
            }
        }

        function open(): void {
            root.launcherOpen = true
            root.toolsPanelOpen = false
            root.toolsPanelPage = "tools"
            root.calculatorOpen = false
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
        target: "app-stash"

        function hide(): void {
            Quickshell.execDetached(["a16een-app-stash", "hide"])
        }

        function toggle(): void {
            if (root.toolsPanelOpen && root.toolsPanelPage === "stash") {
                root.toolsPanelOpen = false
                root.toolsPanelPage = "tools"
                return
            }
            root.openToolsPage("stash")
        }

        function open(): void {
            root.openToolsPage("stash")
        }

        function close(): void {
            root.toolsPanelOpen = false
            root.toolsPanelPage = "tools"
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
        target: "wallpaper"

        function preview(path: string): void {
            if (path.length)
                root.wallpaperPreviewPath = path
        }

        function clearPreview(): void {
            root.wallpaperPreviewPath = ""
        }

        function apply(path: string): void {
            if (path.length) {
                // Commit first, then clear the temporary preview. If both
                // paths match this avoids a duplicate wallpaper reload.
                root.wallpaperPath = path
                root.wallpaperPreviewPath = ""
            }
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
            root.toolsPanelOpen = false
            root.toolsPanelPage = "tools"
            root.calculatorOpen = false
            root.commandCenterOpen = true
            root.launcherOpen = false
            root.wallpaperPickerOpen = false
            root.screenshotCenterOpen = false
        }

        function open(): void {
            root.widgetsCenterOpen = true
            root.toolsPanelOpen = false
            root.toolsPanelPage = "tools"
            root.calculatorOpen = false
            root.commandCenterOpen = true
            root.launcherOpen = false
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
            root.toolsPanelOpen = false
            root.toolsPanelPage = "tools"
            root.calculatorOpen = false
            root.screenshotSettingsOpen = false
            root.launcherOpen = false
            root.commandCenterOpen = false
            root.wallpaperPickerOpen = false
            root.widgetsCenterOpen = false
        }

        function open(): void {
            root.screenshotCenterOpen = true
            root.toolsPanelOpen = false
            root.toolsPanelPage = "tools"
            root.calculatorOpen = false
            root.screenshotSettingsOpen = false
            root.launcherOpen = false
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
            root.toolsPanelOpen = false
            root.toolsPanelPage = "tools"
            root.calculatorOpen = false
            root.launcherOpen = false
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
            const shouldOpen = !root.commandCenterOpen
            // Clear nested manager state before changing the PanelWindow's
            // visibility, preventing a stale WidgetSection from stealing focus.
            root.widgetsCenterOpen = false
            root.toolsPanelOpen = false
            root.toolsPanelPage = "tools"
            root.calculatorOpen = false
            root.launcherOpen = false
            root.wallpaperPickerOpen = false
            root.screenshotCenterOpen = false
            root.screenshotSettingsOpen = false
            root.commandCenterOpen = shouldOpen
        }

        function open(): void {
            root.widgetsCenterOpen = false
            root.toolsPanelOpen = false
            root.toolsPanelPage = "tools"
            root.calculatorOpen = false
            root.launcherOpen = false
            root.wallpaperPickerOpen = false
            root.screenshotSettingsOpen = false
            root.commandCenterOpen = true
        }

        function close(): void {
            root.widgetsCenterOpen = false
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

    function loadNotificationHistory() {
        if (root.notificationHistoryReady)
            return

        let diskEntries = []
        try {
            const parsed = JSON.parse(String(notificationHistoryFile.text() || "{}"))
            if (parsed && Array.isArray(parsed.notifications)) {
                diskEntries = parsed.notifications
                    .filter(item => item && String(item.id || "").length)
                    .map(item => ({
                        id: String(item.id),
                        appName: String(item.appName || "Notification"),
                        summary: String(item.summary || "Notification"),
                        body: String(item.body || ""),
                        appIcon: String(item.appIcon || ""),
                        timestamp: Number(item.timestamp) || Date.now(),
                        read: Boolean(item.read)
                    }))
            }
        } catch (error) {
            diskEntries = []
            console.warn("A16EEN notification history could not be read:", error)
        }

        const alreadyInMemory = root.notificationHistory.slice()
        const combined = alreadyInMemory.concat(diskEntries)
        combined.sort((a, b) => Number(b.timestamp || 0) - Number(a.timestamp || 0))
        const seen = ({})
        root.notificationHistory = combined.filter(item => {
            const key = String(item.id || "")
            if (!key.length || seen[key])
                return false
            seen[key] = true
            return true
        }).slice(0, 60)

        root.notificationHistoryReady = true
        if (alreadyInMemory.length)
            notificationHistorySaveTimer.restart()
    }

    function rememberNotification(notification) {
        const entry = {
            id: String(Date.now()) + "-" + String(root.notificationHistory.length),
            appName: String(notification.appName || "Notification"),
            summary: String(notification.summary || "Notification"),
            body: String(notification.body || ""),
            appIcon: String(notification.appIcon || ""),
            timestamp: Date.now(),
            read: false
        }
        root.notificationHistory = [entry, ...root.notificationHistory].slice(0, 60)
        if (root.notificationHistoryReady)
            notificationHistorySaveTimer.restart()
    }

    function markNotificationHistoryRead() {
        if (!root.notificationHistory.some(item => !Boolean(item.read)))
            return
        root.notificationHistory = root.notificationHistory.map(item => ({
            id: String(item.id),
            appName: String(item.appName || "Notification"),
            summary: String(item.summary || "Notification"),
            body: String(item.body || ""),
            appIcon: String(item.appIcon || ""),
            timestamp: Number(item.timestamp) || Date.now(),
            read: true
        }))
        if (root.notificationHistoryReady)
            notificationHistorySaveTimer.restart()
    }

    function removeNotificationHistory(id) {
        root.notificationHistory = root.notificationHistory.filter(item => String(item.id) !== String(id))
        if (root.notificationHistoryReady)
            notificationHistorySaveTimer.restart()
    }

    function clearNotificationHistory() {
        root.notificationHistory = []
        if (root.notificationHistoryReady)
            notificationHistorySaveTimer.restart()
    }

    function loadBatteryWarningSettings(rawText) {
        try {
            const saved = JSON.parse(String(rawText || "{}"))
            const warning = Number(saved.warningPercent)
            const critical = Number(saved.criticalPercent)
            const emergency = Number(saved.emergencyPercent)

            if (Number.isInteger(warning) && warning >= 2 && warning <= 95
                    && Number.isInteger(critical) && critical >= 2 && critical < warning
                    && Number.isInteger(emergency) && emergency >= 1 && emergency < critical) {
                root.batteryWarningPercent = warning
                root.batteryCriticalPercent = critical
                root.batteryEmergencyPercent = emergency
            }

            if (typeof saved.warningEnabled === "boolean")
                root.batteryWarningEnabled = saved.warningEnabled
            if (typeof saved.criticalEnabled === "boolean")
                root.batteryCriticalEnabled = saved.criticalEnabled
            if (typeof saved.emergencyEnabled === "boolean")
                root.batteryEmergencyEnabled = saved.emergencyEnabled
        } catch (error) {
            console.warn("A16EEN battery warning settings could not be read:", error)
        }

        root.batteryWarningSettingsReady = true
        Qt.callLater(() => root.checkBatteryWarnings())
    }

    function updateBatteryWarningSettings(settings) {
        if (!settings || typeof settings !== "object")
            return

        const warning = Number(settings.warningPercent)
        const critical = Number(settings.criticalPercent)
        const emergency = Number(settings.emergencyPercent)
        if (!Number.isInteger(warning) || warning < 2 || warning > 95
                || !Number.isInteger(critical) || critical < 2 || critical >= warning
                || !Number.isInteger(emergency) || emergency < 1 || emergency >= critical)
            return

        root.batteryWarningPercent = warning
        root.batteryCriticalPercent = critical
        root.batteryEmergencyPercent = emergency
        root.batteryWarningEnabled = settings.warningEnabled === true
        root.batteryCriticalEnabled = settings.criticalEnabled === true
        root.batteryEmergencyEnabled = settings.emergencyEnabled === true
        root.batteryLastPercent = -1
        if (root.batteryWarningSettingsReady)
            batteryWarningSettingsSaveTimer.restart()
        Qt.callLater(() => root.checkBatteryWarnings())
    }

    function configuredBatteryWarnings() {
        return [
            { id: "warning", percent: root.batteryWarningPercent, enabled: root.batteryWarningEnabled, summary: "Battery low" },
            { id: "critical", percent: root.batteryCriticalPercent, enabled: root.batteryCriticalEnabled, summary: "Battery very low" },
            { id: "emergency", percent: root.batteryEmergencyPercent, enabled: root.batteryEmergencyEnabled, summary: "Battery critical" }
        ]
    }

    function batteryWarningKey(level) {
        return level.id + ":" + level.percent
    }

    function showBatteryWarning(level, percent) {
        const notification = {
            appName: "A16EEN Battery",
            summary: level.summary,
            body: "Battery is at " + percent + "%. Connect your charger to avoid interruption.",
            appIcon: "",
            tracked: true
        }
        root.rememberNotification(notification)

        if (root.doNotDisturb)
            return

        if (root.latestNotification)
            root.latestNotification.tracked = false
        root.latestNotification = notification
        notificationTimer.restart()
    }

    function checkBatteryWarnings() {
        if (!root.batteryWarningSettingsReady)
            return

        const device = UPower.displayDevice
        if (!device.ready || !device.isPresent) {
            root.batteryLastPercent = -1
            return
        }

        const raw = Number(device.percentage)
        if (!Number.isFinite(raw))
            return
        const normalized = raw > 0 && raw <= 1 ? raw * 100 : raw
        const percent = Math.max(0, Math.min(100, Math.round(normalized)))
        const state = device.state
        const onBattery = UPower.onBattery
            && state !== UPowerDeviceState.Charging
            && state !== UPowerDeviceState.PendingCharge

        if (!onBattery) {
            root.batteryAlertedLevels = []
            root.batteryLastPercent = -1
            return
        }

        const levels = root.configuredBatteryWarnings()
        if (root.batteryLastPercent < 0) {
            root.batteryLastPercent = percent
            const reached = levels.filter(level =>
                level.enabled
                && percent <= level.percent
                && !root.batteryAlertedLevels.includes(root.batteryWarningKey(level))
            ).sort((a, b) => a.percent - b.percent)

            if (!reached.length)
                return

            // If the shell starts while already low, show just the most urgent
            // applicable warning and mark the other reached thresholds as passed.
            root.batteryAlertedLevels = root.batteryAlertedLevels.concat(
                reached.map(level => root.batteryWarningKey(level))
            )
            root.showBatteryWarning(reached[0], percent)
            return
        }

        const previousPercent = root.batteryLastPercent
        root.batteryLastPercent = percent
        if (percent >= previousPercent)
            return

        const crossed = levels.filter(level =>
            level.enabled
            && previousPercent > level.percent
            && percent <= level.percent
            && !root.batteryAlertedLevels.includes(root.batteryWarningKey(level))
        )
        if (!crossed.length)
            return

        root.batteryAlertedLevels = root.batteryAlertedLevels.concat(
            crossed.map(level => root.batteryWarningKey(level))
        )
        // Avoid stacking multiple toasts if the battery crosses several levels
        // between samples; present only the most urgent reached threshold.
        crossed.sort((a, b) => a.percent - b.percent)
        root.showBatteryWarning(crossed[0], percent)
    }

    function loadDataMeterSettings() {
        try {
            const parsed = JSON.parse(String(dataMeterSettingsFile.text() || "{}"))
            root.dataMeterEnabled = Boolean(parsed && parsed.showSpeed)
        } catch (error) {
            root.dataMeterEnabled = false
            console.warn("A16EEN Data Meter settings could not be read:", error)
        }
        root.dataMeterSettingsReady = true
        if (root.dataMeterEnabled)
            Qt.callLater(() => root.requestDataMeterSnapshot())
    }

    function saveDataMeterSettings() {
        if (root.dataMeterSettingsReady)
            dataMeterSettingsSaveTimer.restart()
    }

    function setDataMeterEnabled(value) {
        root.dataMeterEnabled = Boolean(value)
        root.saveDataMeterSettings()
        if (root.dataMeterEnabled)
            root.requestDataMeterSnapshot()
        else if (!(root.toolsPanelOpen && root.toolsPanelPage === "data-meter"))
            dataMeterTimer.stop()
    }

    function requestDataMeterSnapshot() {
        if (!root.dataMeterEnabled
            && !(root.toolsPanelOpen && root.toolsPanelPage === "data-meter"))
            return
        if (!dataMeterProcess.running)
            dataMeterProcess.running = true
    }

    function openGamingPanel() {
        if (root.gamingPanelOpen) {
            root.gamingPanelOpen = false
            return
        }
        root.closeTransientPanels()
        root.gamingPanelOpen = true
    }

    function openQuickToolWindow(pageName, requestedAppId) {
        root.closeTransientPanels()
        root.quickToolWindowPage = String(pageName || "updates")
        root.quickToolWindowRequestedAppId = String(requestedAppId || "")
        root.quickToolWindowOpen = true
    }

    function returnToQuickTools() {
        root.quickToolWindowOpen = false
        root.quickToolWindowRequestedAppId = ""
        root.openToolsPage("tools")
    }

    function openToolsPage(pageName) {
        // Reuse the existing layer-shell surface to avoid overlay handoff/blink.
        root.gamingPanelOpen = false
        root.quickNotesOpen = false
        root.quickTasksOpen = false
        root.quickPresetsOpen = false
        root.quickUtilitiesOpen = false
        root.utilitiesExpanded = false
        root.notificationCenterOpen = false
        root.commandCenterOpen = false
        root.launcherOpen = false
        root.wallpaperPickerOpen = false
        root.widgetsCenterOpen = false
        root.screenshotCenterOpen = false
        root.screenshotSettingsOpen = false
        root.screenshotPreviewOpen = false
        root.calculatorOpen = false
        root.toolsPanelPage = String(pageName || "tools")
        root.toolsPanelOpen = true
        if (root.toolsPanelPage === "data-meter")
            Qt.callLater(() => root.requestDataMeterSnapshot())
    }

    function closeTransientPanels() {
        root.quickToolWindowOpen = false
        root.quickToolWindowRequestedAppId = ""
        root.gamingPanelOpen = false
        root.quickNotesOpen = false
        root.quickTasksOpen = false
        root.quickPresetsOpen = false
        root.quickUtilitiesOpen = false
        root.utilitiesExpanded = false
        root.notificationCenterOpen = false
        root.toolsPanelOpen = false
        root.toolsPanelPage = "tools"
        root.calculatorOpen = false
        root.commandCenterOpen = false
        root.launcherOpen = false
        root.wallpaperPickerOpen = false
        root.widgetsCenterOpen = false
        root.screenshotCenterOpen = false
        root.screenshotSettingsOpen = false
        root.screenshotPreviewOpen = false
    }

    function openNotificationCenter() {
        if (root.notificationCenterOpen) {
            root.notificationCenterOpen = false
            return
        }
        root.closeTransientPanels()
        root.notificationCenterOpen = true
        root.markNotificationHistoryRead()
    }

    function openToolsPanel() {
        if (root.toolsPanelOpen) {
            root.toolsPanelOpen = false
            root.toolsPanelPage = "tools"
            return
        }
        root.openToolsPage("tools")
    }

    function activateHubTool(toolId) {
        const id = String(toolId || "")
        if (["updates", "app-locker", "sessions"].includes(id)) {
            root.openQuickToolWindow(id, "")
            return
        }
        if (["calculator", "monitor", "stash", "data-meter", "screen-time", "ai"].includes(id)) {
            root.openToolsPage(id)
            return
        }
        root.closeTransientPanels()
        switch (id) {
        case "screenshot":
            root.screenshotCenterOpen = true
            break
        case "wallpapers":
            root.wallpaperPickerOpen = true
            break
        case "clipboard":
            root.quickUtilitiesOpen = true
            root.utilitiesExpanded = true
            root.utilitiesMode = "clipboard"
            break
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
            // Keep every received notification in the local inbox, even when
            // DND suppresses the transient toast.
            root.rememberNotification(notification)

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
            volumeProcess.running = false
            volumeProcess.running = true
        }
    }

    Variants {
        model: Quickshell.screens

        Wallpaper {
            modelData: modelData
            currentWallpaperPath: root.wallpaperPath
            previewWallpaperPath: root.wallpaperPreviewPath
            desktopAnimationAllowed: root.wallpaperAnimationAllowed
            editorialTimeWidgetEnabled: root.editorialTimeWidgetEnabled
            timeUse24Hour: root.timeUse24Hour
            timeShowSeconds: root.timeShowSeconds
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
            backgroundColor: root.musicWidgetBackgroundColor
            backgroundOpacity: root.musicWidgetBackgroundOpacity
        }
    }

    Variants {
        model: Quickshell.screens

        AppShelfWidget {
            modelData: modelData
            widgetEnabled: root.appShelfWidgetEnabled && !root.secureLockActive
            apps: root.appShelfApps
            shape: root.appShelfShape
            rotationEnabled: root.appShelfRotationEnabled
            navbarPosition: root.navbarPosition
            windowItems: root.windows
            workspaceItems: root.workspaces
            focusedWorkspaceId: root.focusedWorkspaceId
            focusedWindowId: root.focusedWindowId
            onProtectedAppRequested: (desktopId, appName) => {
                root.openQuickToolWindow("app-locker", desktopId)
            }
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
                root.closeTransientPanels()
                root.launcherOpen = true
                root.commandCenterOpen = false
                root.wallpaperPickerOpen = false
                root.widgetsCenterOpen = false
            }

            onLockRequested: root.requestLockScreen()
            onUtilitiesRequested: root.handleUtilitiesRequest(mode)
            onAiRequested: {
                if (root.toolsPanelOpen && root.toolsPanelPage === "ai") {
                    root.toolsPanelOpen = false
                    root.toolsPanelPage = "tools"
                } else {
                    root.openToolsPage("ai")
                }
            }
            onGamingRequested: root.openGamingPanel()
        }
    }

    function handleUtilitiesRequest(mode) {
        root.gamingPanelOpen = false
        root.notificationCenterOpen = false
        root.toolsPanelOpen = false
        root.toolsPanelPage = "tools"
        root.calculatorOpen = false
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
        root.wallpaperPickerOpen = false
        root.widgetsCenterOpen = false
        root.screenshotCenterOpen = false
        root.screenshotSettingsOpen = false

        root.quickUtilitiesOpen = true
        root.utilitiesExpanded = true
        root.utilitiesMode = ["wifi", "bluetooth", "clipboard"].includes(mode) ? mode : "wifi"
    }

    function openQuickTasks() {
        root.gamingPanelOpen = false
        root.notificationCenterOpen = false
        root.toolsPanelOpen = false
        root.toolsPanelPage = "tools"
        root.calculatorOpen = false
        root.quickTasksOpen = true
        root.quickPresetsOpen = false
        root.quickUtilitiesOpen = false
        root.utilitiesExpanded = false
        root.quickNotesOpen = false
        root.commandCenterOpen = false
        root.launcherOpen = false
        root.wallpaperPickerOpen = false
        root.widgetsCenterOpen = false
        root.screenshotCenterOpen = false
        root.screenshotSettingsOpen = false
    }

    function openQuickPresets() {
        root.gamingPanelOpen = false
        root.notificationCenterOpen = false
        root.toolsPanelOpen = false
        root.toolsPanelPage = "tools"
        root.calculatorOpen = false
        root.quickPresetsOpen = true
        root.quickUtilitiesOpen = false
        root.utilitiesExpanded = false
        root.quickNotesOpen = false
        root.quickTasksOpen = false
        root.commandCenterOpen = false
        root.launcherOpen = false
        root.wallpaperPickerOpen = false
        root.widgetsCenterOpen = false
        root.screenshotCenterOpen = false
        root.screenshotSettingsOpen = false
    }

    QuickHubTray {
        modelData: root.primaryScreen
        navbarPosition: root.navbarPosition
        dockVisible: !root.secureLockActive && (!root.focusedWindowFullscreen || root.navbarRevealed)
        unreadCount: root.unreadNotificationCount
        notificationsOpen: root.notificationCenterOpen
        toolsOpen: root.toolsPanelOpen
        onNotificationsRequested: root.openNotificationCenter()
        onToolsRequested: root.openToolsPanel()
    }

    DataMeterIndicator {
        modelData: root.primaryScreen
        navbarPosition: root.navbarPosition
        dockVisible: !root.secureLockActive && (!root.focusedWindowFullscreen || root.navbarRevealed)
        enabled: root.dataMeterEnabled
        snapshot: root.dataMeterSnapshot
        onOpenRequested: root.openToolsPage("data-meter")
    }

    QuickActionsTray {
        modelData: root.primaryScreen
        navbarPosition: root.navbarPosition
        dockVisible: !root.secureLockActive && (!root.focusedWindowFullscreen || root.navbarRevealed)

        onNotesRequested: {
            root.gamingPanelOpen = false
            root.quickNotesOpen = true
            root.quickUtilitiesOpen = false
            root.utilitiesExpanded = false
            root.quickTasksOpen = false
            root.quickPresetsOpen = false
            root.commandCenterOpen = false
            root.launcherOpen = false
            root.wallpaperPickerOpen = false
            root.widgetsCenterOpen = false
            root.screenshotCenterOpen = false
            root.screenshotSettingsOpen = false
            root.notificationCenterOpen = false
            root.toolsPanelOpen = false
        }

        onTasksRequested: root.openQuickTasks()

        onPresetsRequested: root.openQuickPresets()

    }

    NotificationCenter {
        modelData: root.primaryScreen
        navbarPosition: root.navbarPosition
        opened: root.notificationCenterOpen
        history: root.notificationHistory
        onCloseRequested: root.notificationCenterOpen = false
        onClearRequested: root.clearNotificationHistory()
        onRemoveRequested: id => root.removeNotificationHistory(id)
    }

    QuickToolsWindow {
        modelData: root.primaryScreen
        opened: root.quickToolWindowOpen
        page: root.quickToolWindowPage
        requestedAppId: root.quickToolWindowRequestedAppId
        onBackRequested: root.returnToQuickTools()
        onCloseRequested: root.quickToolWindowOpen = false
    }

    ToolsPanel {
        modelData: root.primaryScreen
        navbarPosition: root.navbarPosition
        opened: root.toolsPanelOpen
        page: root.toolsPanelPage
        onCloseRequested: {
            root.toolsPanelOpen = false
            root.toolsPanelPage = "tools"
        }
        onToolRequested: toolId => root.activateHubTool(toolId)
        dataMeterEnabled: root.dataMeterEnabled
        dataMeterSnapshot: root.dataMeterSnapshot
        dataMeterSnapshotReady: root.dataMeterSnapshotReady
        dataMeterError: root.dataMeterError
        screenTimeTodaySeconds: screenTimeTracker.todaySeconds
        screenTimeWeekSeconds: screenTimeTracker.weekSeconds
        screenTimeMonthSeconds: screenTimeTracker.monthSeconds
        screenTimeTopApps: screenTimeTracker.topApps
        screenTimeWeekApps: screenTimeTracker.weekApps
        screenTimeMonthApps: screenTimeTracker.monthApps
        screenTimeTrackingActive: screenTimeTracker.trackingActive
        screenTimeStatus: screenTimeTracker.statusText
        screenTimeCurrentApp: screenTimeTracker.currentAppName
        onDataMeterToggleRequested: enabled => root.setDataMeterEnabled(enabled)
        onAppStashRequested: root.openToolsPage("stash")
        onBackRequested: root.toolsPanelPage = "tools"
        onRestoreRequested: windowId => {
            Quickshell.execDetached(["a16een-app-stash", "restore", String(windowId)])
            root.toolsPanelOpen = false
            root.toolsPanelPage = "tools"
        }
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

    GamingPanel {
        modelData: root.primaryScreen
        navbarPosition: root.navbarPosition
        dockVisible: !root.secureLockActive
        opened: root.gamingPanelOpen
        onCloseRequested: root.gamingPanelOpen = false
    }

    CommandCenter {
        id: commandCenter
        modelData: root.primaryScreen
        dataMeterEnabled: root.dataMeterEnabled
        opened: root.commandCenterOpen
        lockIdleEnabled: root.lockIdleEnabled
        lockIdleMinutes: root.lockIdleMinutes
        lockOnSleepEnabled: root.lockOnSleepEnabled
        widgetViewOpen: root.widgetsCenterOpen
        editorialTimeWidgetEnabled: root.editorialTimeWidgetEnabled
        musicWidgetEnabled: root.musicWidgetEnabled
        musicWidgetBackgroundColor: root.musicWidgetBackgroundColor
        musicWidgetBackgroundOpacity: root.musicWidgetBackgroundOpacity
        quotesWidgetEnabled: root.quotesWidgetEnabled
        appShelfWidgetEnabled: root.appShelfWidgetEnabled
        appShelfShape: root.appShelfShape
        appShelfRotationEnabled: root.appShelfRotationEnabled
        appShelfApps: root.appShelfApps
        timeUse24Hour: root.timeUse24Hour
        timeShowSeconds: root.timeShowSeconds
        doNotDisturb: root.doNotDisturb
        batteryWarningPercent: root.batteryWarningPercent
        batteryCriticalPercent: root.batteryCriticalPercent
        batteryEmergencyPercent: root.batteryEmergencyPercent
        batteryWarningEnabled: root.batteryWarningEnabled
        batteryCriticalEnabled: root.batteryCriticalEnabled
        batteryEmergencyEnabled: root.batteryEmergencyEnabled

        onCloseRequested: {
            // Close nested views with the command surface so the next
            // Super + / open always starts from a clean command palette.
            root.widgetsCenterOpen = false
            root.commandCenterOpen = false
        }
        onPresetsRequested: root.openQuickPresets()
        onLockScreenSettingsChanged: root.applyLockSettings(idleEnabled, idleMinutes, lockOnSleepEnabled, true)
        onLockNowRequested: root.requestLockScreen(false)

        onNavbarPositionChanged: {
            if (["left", "right", "top", "bottom"].includes(position))
                root.navbarPosition = position
        }

        onLauncherRequested: {
            root.commandCenterOpen = false
            root.wallpaperPickerOpen = false
            root.launcherOpen = true
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
            root.wallpaperPickerOpen = false
            root.widgetsCenterOpen = false
        }

        onScreenshotSettingsRequested: {
            root.commandCenterOpen = false
            root.screenshotCenterOpen = false
            root.screenshotSettingsOpen = true
            root.launcherOpen = false
            root.wallpaperPickerOpen = false
            root.widgetsCenterOpen = false
        }

        onWidgetsRequested: {
            root.widgetsCenterOpen = true
            root.commandCenterOpen = true
            root.screenshotCenterOpen = false
            root.screenshotSettingsOpen = false
            root.launcherOpen = false
            root.wallpaperPickerOpen = false
        }

        onWidgetsCloseRequested: {
            root.widgetsCenterOpen = false
        }

        onEditorialTimeWidgetEnabledRequested: {
            root.editorialTimeWidgetEnabled = enabled
            root.requestWidgetSettingsSave()
        }
        onMusicWidgetEnabledRequested: {
            root.musicWidgetEnabled = enabled
            root.requestWidgetSettingsSave()
        }
        onMusicWidgetBackgroundColorRequested: {
            if (typeof color === "string" && /^#[0-9a-fA-F]{6}$/.test(color)) {
                root.musicWidgetBackgroundColor = color
                root.requestWidgetSettingsSave()
            }
        }
        onMusicWidgetBackgroundOpacityRequested: {
            root.musicWidgetBackgroundOpacity = Math.max(0, Math.min(100, Number(opacity) || 0))
            root.requestWidgetSettingsSave()
        }
        onQuotesWidgetEnabledRequested: {
            root.quotesWidgetEnabled = enabled
            root.requestWidgetSettingsSave()
        }
        onAppShelfWidgetEnabledRequested: {
            root.appShelfWidgetEnabled = enabled
            root.requestWidgetSettingsSave()
        }
        onAppShelfRotationEnabledRequested: {
            root.appShelfRotationEnabled = enabled
            root.requestWidgetSettingsSave()
        }
        onAppShelfShapeRequested: {
            if (["capsule", "rounded", "compact", "circle"].includes(shape)) {
                root.appShelfShape = shape
                root.requestWidgetSettingsSave()
            }
        }
        onAppShelfAppsRequested: function(apps) {
            // QML may expose a signal's list payload as an array-like sequence
            // after it crosses component boundaries. Do not discard valid apps
            // solely because Array.isArray() rejects that converted value.
            if (!apps || typeof apps.length !== "number") {
                console.warn("A16EEN App Shelf ignored an invalid application selection payload.")
                return
            }

            const nextApps = []
            const count = Math.min(16, Math.max(0, Math.floor(apps.length)))
            for (let i = 0; i < count; i++) {
                const app = apps[i]
                if (!app || typeof app.desktopId !== "string" || !app.desktopId.length)
                    continue
                if (nextApps.some(saved => saved.desktopId === app.desktopId))
                    continue

                nextApps.push({
                    desktopId: app.desktopId,
                    name: String(app.name || "Application"),
                    icon: String(app.icon || "")
                })
            }

            root.appShelfApps = nextApps
            root.requestWidgetSettingsSave()
        }
        onBatteryWarningSettingsRequested: settings => root.updateBatteryWarningSettings(settings)
        onTimeUse24HourRequested: {
            root.timeUse24Hour = enabled
            root.requestWidgetSettingsSave()
        }
        onTimeShowSecondsRequested: {
            root.timeShowSeconds = enabled
            root.requestWidgetSettingsSave()
        }

        onDoNotDisturbRequested: root.setDoNotDisturb(enabled)
        onDataMeterToggleRequested: root.setDataMeterEnabled(enabled)
        onIconThemeChanged: root.iconThemeRevision++
    }

    ScreenshotCenter {
        modelData: root.primaryScreen
        opened: root.screenshotCenterOpen
        windowItems: root.windows
        workspaceItems: root.workspaces
        focusedWorkspaceId: root.focusedWorkspaceId
        focusedWindowId: root.focusedWindowId
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
        onOpenRequested: root.wallpaperPickerOpen = true
    }

    Launcher {
        modelData: root.primaryScreen
        opened: root.launcherOpen
        searchText: root.searchText
        iconThemeRevision: root.iconThemeRevision
        onSearchTextChanged: root.searchText = searchText
        onCloseRequested: root.launcherOpen = false
        onProtectedAppRequested: (desktopId, appName) => {
            root.openQuickToolWindow("app-locker", desktopId)
        }
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
