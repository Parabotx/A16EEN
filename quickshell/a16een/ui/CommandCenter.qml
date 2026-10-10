import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool opened: false
    property bool powerViewOpen: false
    property bool widgetViewOpen: false
    property bool controlViewOpen: false
    property string controlDetail: ""
    property bool iconThemeViewOpen: false
    property bool navbarViewOpen: false
    property bool workspacePresetViewOpen: false
    property bool doNotDisturb: false
    property string commandText: "/"
    property int selectedCommandIndex: 0
    property var commandUsage: ({})
    property var pendingCommandUsage: ({})
    property bool commandUsageLoaded: false
    readonly property string commandUsagePath: Quickshell.stateDir + "/command-center-usage.json"

    property bool editorialTimeWidgetEnabled: true
    property bool calendarWidgetEnabled: false
    property bool pulseWidgetEnabled: false
    property bool workspaceWidgetEnabled: false
    property bool tasksWidgetEnabled: false
    property bool musicWidgetEnabled: false
    property bool quotesWidgetEnabled: false
    property bool timeUse24Hour: true
    property bool timeShowSeconds: false

    property string currentPowerProfile: ""
    property string pendingPowerProfile: ""
    property string powerStatus: "READY"

    property int batteryPercent: 0
    property bool batteryPresent: false
    property string batteryState: "unknown"
    property string batteryTime: "—"
    property string batteryRate: "—"
    property string batteryCapacity: "—"

    signal closeRequested()
    signal launcherRequested()
    signal wallpaperRequested()
    signal screenshotRequested()
    signal screenshotSettingsRequested()
    signal widgetsRequested()
    signal widgetsCloseRequested()
    signal presetsRequested()
    signal doNotDisturbRequested(bool enabled)
    signal editorialTimeWidgetEnabledRequested(bool enabled)
    signal calendarWidgetEnabledRequested(bool enabled)
    signal pulseWidgetEnabledRequested(bool enabled)
    signal workspaceWidgetEnabledRequested(bool enabled)
    signal tasksWidgetEnabledRequested(bool enabled)
    signal musicWidgetEnabledRequested(bool enabled)
    signal quotesWidgetEnabledRequested(bool enabled)
    signal timeUse24HourRequested(bool enabled)
    signal timeShowSecondsRequested(bool enabled)
    signal iconThemeChanged(string themeId)
    signal navbarPositionChanged(string position)

    // The expanded command-center card becomes a light card for navbar mode.
    // The card itself is bounded; this does not create a screen-wide cover.
    readonly property color surface: root.widgetViewOpen || root.controlViewOpen || root.iconThemeViewOpen || root.workspacePresetViewOpen || root.navbarViewOpen ? "#FFFFFF" : "#000000"
    readonly property color borderColor: "#1A1A1A"
    readonly property color fieldBackground: "#0A0A0A"
    readonly property color fieldBorder: "#1C1C1C"
    readonly property color fieldFocusBorder: "#333333"
    readonly property color primaryText: "#FFFFFF"
    readonly property color secondaryText: "#6F6F6F"
    readonly property color mutedText: "#3F3F3F"
    readonly property color selectedBackground: "#111111"
    readonly property bool plainCommandView:
        !root.powerViewOpen
        && !root.widgetViewOpen
        && !root.controlViewOpen
        && !root.iconThemeViewOpen
        && !root.workspacePresetViewOpen
        && !root.navbarViewOpen

    readonly property var commands: [
        // First-run suggestions are common, useful actions; usage history
        // gradually promotes the commands each user actually runs most.
        { id: "launcher", name: "launcher", keywords: ["launcher", "applications", "apps"] },
        { id: "controls", name: "controls", keywords: ["controls", "control center", "settings", "system settings"] },
        { id: "wallpaper", name: "wallpaper", keywords: ["wallpaper", "background", "image"] },
        { id: "screenshot", name: "screenshot", keywords: ["screenshot", "screen", "capture", "snapshot", "area", "window"] },
        { id: "power", name: "power", keywords: ["power", "performance", "balanced", "energy", "eco", "power-saving", "power-saver"] },
        { id: "screenshot-settings", name: "screenshot settings", keywords: ["screenshot settings", "capture settings", "save", "clipboard", "pointer", "location"] },
        { id: "overview", name: "overview", keywords: ["overview", "workspaces", "windows"] },
        { id: "widgets", name: "widgets", keywords: ["widgets", "widget", "clock", "time", "day", "date", "desktop", "modules"] },
        { id: "presets", name: "workspace presets", keywords: ["workspace presets", "preset", "workspace setup", "app sets", "app group", "session setup", "launch setup"] },
        { id: "icons", name: "icons", keywords: ["icons", "icon theme", "icon themes", "app icons", "folder icons", "appearance"] },
        { id: "navbar", name: "navbar", keywords: ["navbar", "navigation", "dock"] },
        { id: "wifi", name: "wifi", keywords: ["wifi", "wi-fi", "network", "networks", "internet", "connection"] },
        { id: "bluetooth", name: "bluetooth", keywords: ["bluetooth", "devices", "pair", "wireless"] },
        { id: "audio", name: "audio", keywords: ["audio", "volume", "sound", "mute", "speaker"] },
        { id: "brightness", name: "brightness", keywords: ["brightness", "display", "screen"] },
        { id: "night-light", name: "night light", keywords: ["night light", "nightlight", "warm", "temperature"] },
        { id: "battery", name: "battery", keywords: ["battery", "charge", "charging"] },
        { id: "dnd", name: "do not disturb", keywords: ["do not disturb", "dnd", "focus", "notifications"] },
        { id: "restart-shell", name: "restart-shell", keywords: ["restart", "shell", "reload", "quickshell"] },
        { id: "doctor", name: "doctor", keywords: ["doctor", "diagnostics", "health"] }
    ]

    readonly property string query: {
        const value = root.commandText
        return value.startsWith("/")
            ? value.slice(1).trim().toLowerCase()
            : value.trim().toLowerCase()
    }

    readonly property var filteredCommands: {
        const query = root.query
        const rankedCommands = root.commands.map((command, index) => ({
            command: command,
            index: index,
            usage: Math.max(0, Number(root.commandUsage[command.id] || 0))
        })).sort((a, b) => b.usage - a.usage || a.index - b.index)

        const matches = !query
            ? rankedCommands
            : rankedCommands.filter(entry => {
                const command = entry.command
                const haystack = [command.name, ...(command.keywords || [])]
                    .join(" ")
                    .toLowerCase()
                return haystack.includes(query)
            })

        return matches.slice(0, 5).map(entry => entry.command)
    }

    FileView {
        id: commandUsageFile
        path: root.commandUsagePath
        preload: true
        printErrors: false
        atomicWrites: true
        onLoaded: root.loadCommandUsage(commandUsageFile.text())
        onLoadFailed: root.loadCommandUsage("{}")
    }

    Timer {
        id: commandUsageSaveTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (root.commandUsageLoaded) {
                commandUsageFile.setText(JSON.stringify({
                    version: 1,
                    usage: root.commandUsage
                }))
            }
        }
    }

    function loadCommandUsage(rawText) {
        const savedUsage = ({})
        try {
            const parsed = JSON.parse(String(rawText || "{}"))
            const stored = parsed && parsed.usage && typeof parsed.usage === "object"
                ? parsed.usage
                : {}

            for (const command of root.commands) {
                const count = Math.floor(Number(stored[command.id] || 0))
                if (isFinite(count) && count > 0)
                    savedUsage[command.id] = count
            }
        } catch (error) {
            console.warn("A16EEN command usage history could not be read:", error)
        }

        const pending = root.pendingCommandUsage
        for (const command of root.commands) {
            const count = Math.floor(Number(pending[command.id] || 0))
            if (isFinite(count) && count > 0)
                savedUsage[command.id] = Number(savedUsage[command.id] || 0) + count
        }

        root.commandUsage = savedUsage
        root.pendingCommandUsage = ({})
        root.commandUsageLoaded = true
        if (Object.keys(pending).length > 0)
            commandUsageSaveTimer.restart()
    }

    function recordCommandUsage(commandId) {
        if (!root.commands.some(command => command.id === commandId))
            return

        if (!root.commandUsageLoaded) {
            const pending = ({})
            for (const key in root.pendingCommandUsage)
                pending[key] = root.pendingCommandUsage[key]
            pending[commandId] = Number(pending[commandId] || 0) + 1
            root.pendingCommandUsage = pending
            return
        }

        const nextUsage = ({})
        for (const key in root.commandUsage)
            nextUsage[key] = root.commandUsage[key]
        nextUsage[commandId] = Number(nextUsage[commandId] || 0) + 1
        root.commandUsage = nextUsage
        commandUsageSaveTimer.restart()
    }

    readonly property string activeProfileLabel: {
        switch (root.currentPowerProfile) {
        case "performance":
            return "PERFORMANCE"
        case "power-saver":
            return "ECO"
        case "balanced":
            return "BALANCED"
        default:
            return "—"
        }
    }

    readonly property string batteryStateLabel: {
        switch (root.batteryState) {
        case "charging":
            return "CHARGING"
        case "discharging":
            return "ON BATTERY"
        case "fully-charged":
            return "FULLY CHARGED"
        case "pending-charge":
            return "PENDING CHARGE"
        case "pending-discharge":
            return "PENDING DISCHARGE"
        default:
            return root.batteryPresent ? "BATTERY" : "AC POWER"
        }
    }

    readonly property string wallpaperModeLabel: {
        switch (root.currentPowerProfile) {
        case "performance":
            return "LIVE • RUNNING"
        case "power-saver":
            return "STATIC • PAUSED"
        case "balanced":
            return "ADAPTIVE • DESKTOP ONLY"
        default:
            return "ADAPTIVE"
        }
    }

    readonly property string monitorModeLabel: {
        switch (root.currentPowerProfile) {
        case "performance":
            return "1 SECOND"
        case "power-saver":
            return "7 SECONDS"
        case "balanced":
        default:
            return "3 SECONDS"
        }
    }

    function normalizePowerProfile(value) {
        const profile = String(value || "").trim().toLowerCase()

        if (profile === "power-saver" || profile === "powersave" || profile === "powersaver")
            return "power-saver"

        if (profile === "performance")
            return "performance"

        if (profile === "balanced")
            return "balanced"

        return profile
    }

    function refreshPowerProfile() {
        if (!root.powerViewOpen || profileReader.running)
            return

        profileReader.running = true
    }

    function refreshBattery() {
        if (!root.powerViewOpen || batteryReader.running)
            return

        batteryReader.running = true
    }

    function parseBatteryInfo(output) {
        root.batteryPresent = false
        root.batteryPercent = 0
        root.batteryState = "unknown"
        root.batteryTime = "—"
        root.batteryRate = "—"
        root.batteryCapacity = "—"

        const lines = String(output || "").split("\n")

        for (const rawLine of lines) {
            const line = rawLine.trim()
            const parts = line.split(":")
            if (parts.length < 2)
                continue

            const key = parts[0].trim().toLowerCase()
            const value = parts.slice(1).join(":").trim()

            if (key === "percentage") {
                const match = value.match(/([0-9]+(?:\.[0-9]+)?)\s*%/)
                if (match) {
                    root.batteryPercent = Math.max(0, Math.min(100, Math.round(Number(match[1]))))
                    root.batteryPresent = true
                }
            } else if (key === "state") {
                root.batteryState = value.toLowerCase()
            } else if (key === "time to empty" || key === "time to full") {
                if (value.length)
                    root.batteryTime = value
            } else if (key === "energy-rate") {
                root.batteryRate = value
            } else if (key === "capacity") {
                root.batteryCapacity = value
            }
        }

        if (!root.batteryPresent) {
            root.batteryState = "unknown"
            root.batteryTime = "—"
            root.batteryRate = "—"
            root.batteryCapacity = "—"
        }
    }

    function selectPowerProfile(profile) {
        if (!profile)
            return

        root.pendingPowerProfile = profile
        root.powerStatus = "APPLYING " + (
            profile === "power-saver" ? "ECO" : profile.toUpperCase()
        )

        profileWriter.running = false
        Qt.callLater(() => profileWriter.running = true)
    }

    function powerProfileIsActive(profile) {
        return root.currentPowerProfile === profile
    }

    function openPowerView() {
        root.widgetsCloseRequested()
        root.workspacePresetViewOpen = false
        root.controlViewOpen = false
        root.powerViewOpen = true
        root.iconThemeViewOpen = false
        root.navbarViewOpen = false
        root.commandText = "/power"
        root.selectedCommandIndex = 0
        root.currentPowerProfile = ""
        root.pendingPowerProfile = ""
        root.powerStatus = "READING SYSTEM PROFILE"
        root.batteryPresent = false
        root.batteryPercent = 0
        root.batteryState = "unknown"
        root.batteryTime = "—"
        root.batteryRate = "—"
        root.batteryCapacity = "—"

        Qt.callLater(() => {
            root.refreshPowerProfile()
            root.refreshBattery()
        })
    }

    function closePowerView() {
        root.powerViewOpen = false
        root.commandText = "/"
        root.selectedCommandIndex = 0
        root.powerStatus = "READY"
        Qt.callLater(() => search.forceActiveFocus())
    }

    function openControlView() {
        root.powerViewOpen = false
        root.workspacePresetViewOpen = false
        root.widgetViewOpen = false
        root.iconThemeViewOpen = false
        root.controlViewOpen = true
        root.navbarViewOpen = false
        root.controlDetail = ""
        root.commandText = "/controls"
        root.selectedCommandIndex = 0
        Qt.callLater(() => {
            if (root.controlViewOpen)
                controlSection.forceActiveFocus()
        })
    }

    function closeControlView() {
        root.controlViewOpen = false
        root.controlDetail = ""
        root.commandText = "/"
        root.selectedCommandIndex = 0
        Qt.callLater(() => search.forceActiveFocus())
    }

    function openControlDetail(key) {
        root.powerViewOpen = false
        root.widgetViewOpen = false
        root.controlViewOpen = true
        root.iconThemeViewOpen = false
        root.controlDetail = key
        root.commandText = "/" + key
        root.selectedCommandIndex = 0
        Qt.callLater(() => {
            if (root.controlDetail.length)
                controlDetailSection.forceActiveFocus()
        })
    }

    function openIconThemeView() {
        root.powerViewOpen = false
        root.workspacePresetViewOpen = false
        root.widgetViewOpen = false
        root.controlViewOpen = false
        root.controlDetail = ""
        root.iconThemeViewOpen = true
        root.navbarViewOpen = false
        root.commandText = "/icons"
        root.selectedCommandIndex = 0
        Qt.callLater(() => {
            if (root.iconThemeViewOpen)
                iconThemeSection.forceActiveFocus()
        })
    }

    function openNavbarView() {
        root.powerViewOpen = false
        root.workspacePresetViewOpen = false
        root.widgetViewOpen = false
        root.controlViewOpen = false
        root.controlDetail = ""
        root.iconThemeViewOpen = false
        root.navbarViewOpen = true
        root.commandText = "/navbar"
        root.selectedCommandIndex = 0
        Qt.callLater(() => {
            if (root.navbarViewOpen && navbarLoader.item)
                navbarLoader.item.forceActiveFocus()
        })
    }

    function closeNavbarView() {
        root.navbarViewOpen = false
        root.commandText = "/"
        root.selectedCommandIndex = 0
        Qt.callLater(() => search.forceActiveFocus())
    }

    function closeIconThemeView() {
        root.iconThemeViewOpen = false
        root.workspacePresetViewOpen = false
        root.commandText = "/"
        root.selectedCommandIndex = 0
        Qt.callLater(() => search.forceActiveFocus())
    }

    // Presets now belong to the compact navbar popover. Route every entry
    // point here to that panel instead of opening the legacy large view.
    function openWorkspacePresetView() {
        root.workspacePresetViewOpen = false
        root.closeRequested()
        root.presetsRequested()
    }

    function closeWorkspacePresetView() {
        root.workspacePresetViewOpen = false
        root.commandText = "/"
        root.selectedCommandIndex = 0
        Qt.callLater(() => search.forceActiveFocus())
    }

    function openWidgetView() {
        root.powerViewOpen = false
        root.workspacePresetViewOpen = false
        root.controlViewOpen = false
        root.iconThemeViewOpen = false
        root.navbarViewOpen = false
        root.commandText = "/widgets"
        root.selectedCommandIndex = 0
        root.widgetsRequested()
        Qt.callLater(() => {
            if (root.widgetViewOpen)
                widgetSection.forceActiveFocus()
        })
    }

    function closeWidgetView() {
        root.widgetsCloseRequested()
        root.commandText = "/"
        root.selectedCommandIndex = 0
        Qt.callLater(() => search.forceActiveFocus())
    }

    screen: modelData
    color: "transparent"
    visible: root.opened
    focusable: root.opened

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-command-center"
    WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    // Match the rounded command surface so blur remains local and efficient.
    BackgroundEffect.blurRegion: Region {
        item: commandPaletteBackdrop
        radius: 14
    }

    Process {
        id: profileReader
        command: ["powerprofilesctl", "get"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const profile = root.normalizePowerProfile(text)
                if (profile.length) {
                    root.currentPowerProfile = profile
                    root.powerStatus = "SYSTEM PROFILE ACTIVE"
                } else {
                    root.powerStatus = "PROFILE UNAVAILABLE"
                }
            }
        }

        onRunningChanged: {
            if (!running && root.powerViewOpen && !root.currentPowerProfile.length)
                root.powerStatus = "PROFILE UNAVAILABLE"
        }
    }

    Process {
        id: profileWriter
        command: ["powerprofilesctl", "set", root.pendingPowerProfile]
        running: false

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length)
                    root.powerStatus = "FAILED TO APPLY PROFILE"
            }
        }

        onRunningChanged: {
            if (!running && root.pendingPowerProfile.length) {
                root.currentPowerProfile = root.pendingPowerProfile
                root.powerStatus = "VERIFYING SYSTEM PROFILE"
                powerRefreshTimer.restart()
            }
        }
    }

    Process {
        id: batteryReader
        command: [
            "bash",
            "-lc",
            "upower -i /org/freedesktop/UPower/devices/DisplayDevice 2>/dev/null || true"
        ]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.parseBatteryInfo(text)
        }
    }

    Timer {
        id: powerRefreshTimer
        interval: 450
        repeat: false
        onTriggered: root.refreshPowerProfile()
    }

    Timer {
        id: powerDataTimer
        interval: 4000
        repeat: true
        running: root.powerViewOpen

        onTriggered: {
            root.refreshPowerProfile()
            root.refreshBattery()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.opened ? 0.12 : 0
    }

    Rectangle {
        id: card
        width: root.powerViewOpen || root.widgetViewOpen || root.controlViewOpen || root.iconThemeViewOpen || root.workspacePresetViewOpen || root.navbarViewOpen
            ? Math.min(940, parent.width - 72)
            : Math.min(500, parent.width - 48)
        height: root.plainCommandView
            ? 210
            : root.powerViewOpen || root.widgetViewOpen || root.controlViewOpen || root.iconThemeViewOpen || root.workspacePresetViewOpen || root.navbarViewOpen
                ? Math.min(640, parent.height - 80)
                : 280
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.plainCommandView
            ? Math.min(36, parent.width * 0.03)
            : 0
        anchors.verticalCenterOffset: root.plainCommandView
            ? Math.min(215, Math.max(190, parent.height * 0.27))
            : root.powerViewOpen || root.controlViewOpen || root.iconThemeViewOpen || root.workspacePresetViewOpen || root.navbarViewOpen ? 0 : 185
        radius: root.plainCommandView ? 0 : root.powerViewOpen || root.controlViewOpen || root.iconThemeViewOpen || root.workspacePresetViewOpen || root.navbarViewOpen ? 26 : 18
        color: root.plainCommandView ? "transparent" : root.surface
        border.width: root.plainCommandView ? 0 : 1
        border.color: root.widgetViewOpen || root.controlViewOpen || root.iconThemeViewOpen || root.workspacePresetViewOpen || root.navbarViewOpen ? "#E1E6EC" : "#202020"
        clip: !root.plainCommandView

        Behavior on width {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Behavior on height {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Behavior on anchors.horizontalCenterOffset {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Behavior on anchors.verticalCenterOffset {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        // The command palette stays visually anchored without adding nested UI chrome.
        // The compositor blurs only this bounded region, not the full-screen layer.
        Rectangle {
            id: commandPaletteBackdrop
            anchors.fill: parent
            visible: root.plainCommandView
            radius: 14
            color: "#D90A0A0A"
            border.width: 1
            border.color: "#303030"
            z: 0
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -5
            radius: root.powerViewOpen || root.controlViewOpen || root.iconThemeViewOpen || root.workspacePresetViewOpen || root.navbarViewOpen ? 31 : 23
            color: "#16000000"
            z: -1
            visible: !root.plainCommandView
        }

        WorkspacePresetsSection {
            id: workspacePresetSection
            anchors.fill: parent
            visible: root.workspacePresetViewOpen
            active: root.workspacePresetViewOpen
            onBackRequested: root.closeWorkspacePresetView()
        }
        IconThemeSection {
            id: iconThemeSection
            anchors.fill: parent
            visible: root.iconThemeViewOpen
            active: root.iconThemeViewOpen
            onBackRequested: root.closeIconThemeView()
            onThemeChangeRequested: root.iconThemeChanged(themeId)
        }
        Loader {
            id: navbarLoader
            anchors.fill: parent
            active: root.navbarViewOpen
            visible: root.navbarViewOpen
            focus: root.navbarViewOpen
            z: 30
            source: Qt.resolvedUrl("NavbarManager.qml")

            onLoaded: {
                if (!item)
                    return

                // Explicitly own the loader geometry and stacking so the
                // manager cannot disappear behind the command-center layers.
                item.anchors.fill = navbarLoader
                item.visible = true
                item.active = true
                item.backRequested.connect(root.closeNavbarView)
                item.navbarPositionChanged.connect(root.navbarPositionChanged)

                Qt.callLater(() => {
                    if (root.navbarViewOpen && navbarLoader.item) {
                        navbarLoader.item.anchors.fill = navbarLoader
                        navbarLoader.item.visible = true
                        navbarLoader.item.active = true
                        navbarLoader.item.forceActiveFocus()
                    }
                })
            }
        }

        // Fail safely if NavbarManager cannot be loaded. The panel must never
        // become an empty white rectangle: show a readable recovery message.
        Rectangle {
            id: navbarLoadFallback
            anchors.fill: parent
            z: 40
            visible: root.navbarViewOpen
                && (!navbarLoader.item || navbarLoader.status !== Loader.Ready)
            color: "#F3F5F7"
            radius: 26
            border.width: 1
            border.color: "#D5DCE4"

            Column {
                anchors.centerIn: parent
                width: Math.min(parent.width - 56, 420)
                spacing: 12

                Text {
                    width: parent.width
                    text: navbarLoader.status === Loader.Error
                        ? "NAVBAR MANAGER COULD NOT LOAD"
                        : "LOADING NAVBAR MANAGER"
                    color: "#111318"
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                Text {
                    width: parent.width
                    text: navbarLoader.status === Loader.Error
                        ? "A16EEN kept this panel readable instead of showing a blank white screen. Close this view and check the Quickshell log for the loading error."
                        : "Preparing your navbar controls…"
                    color: "#4B5563"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    x: (parent.width - width) / 2
                    width: 148
                    height: 38
                    radius: 10
                    color: fallbackMouse.containsMouse ? "#E5E7EB" : "#FFFFFF"
                    border.width: 1
                    border.color: "#B8C1CC"

                    Text {
                        anchors.centerIn: parent
                        text: "CLOSE NAVBAR"
                        color: "#111318"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: fallbackMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeNavbarView()
                    }
                }
            }
        }

        ControlCenterSection {
            id: controlSection
            anchors.fill: parent
            visible: root.controlViewOpen && root.controlDetail.length === 0 && !root.iconThemeViewOpen
            active: root.controlViewOpen && root.controlDetail.length === 0 && !root.iconThemeViewOpen
            doNotDisturb: root.doNotDisturb

            onBackRequested: root.closeControlView()
            onControlRequested: root.openControlDetail(key)
            onDoNotDisturbRequested: root.doNotDisturbRequested(enabled)
            onBatteryRequested: root.openPowerView()
        }

        ControlDetailSection {
            id: controlDetailSection
            anchors.fill: parent
            visible: root.controlViewOpen && root.controlDetail.length > 0
            active: root.controlViewOpen && root.controlDetail.length > 0
            mode: root.controlDetail
            doNotDisturb: root.doNotDisturb

            onBackRequested: root.openControlView()
            onDoNotDisturbRequested: root.doNotDisturbRequested(enabled)
        }

        WidgetSection {
            id: widgetSection
            anchors.fill: parent
            visible: root.widgetViewOpen

            editorialTimeEnabled: root.editorialTimeWidgetEnabled
            calendarEnabled: root.calendarWidgetEnabled
            pulseEnabled: root.pulseWidgetEnabled
            workspaceEnabled: root.workspaceWidgetEnabled
            tasksEnabled: root.tasksWidgetEnabled
            musicEnabled: root.musicWidgetEnabled
            quotesEnabled: root.quotesWidgetEnabled
            timeUse24Hour: root.timeUse24Hour
            timeShowSeconds: root.timeShowSeconds

            onBackRequested: root.closeWidgetView()
            onEditorialTimeWidgetEnabledRequested: root.editorialTimeWidgetEnabledRequested(enabled)
            onCalendarWidgetEnabledRequested: root.calendarWidgetEnabledRequested(enabled)
            onPulseWidgetEnabledRequested: root.pulseWidgetEnabledRequested(enabled)
            onWorkspaceWidgetEnabledRequested: root.workspaceWidgetEnabledRequested(enabled)
            onTasksWidgetEnabledRequested: root.tasksWidgetEnabledRequested(enabled)
            onMusicWidgetEnabledRequested: root.musicWidgetEnabledRequested(enabled)
            onQuotesWidgetEnabledRequested: root.quotesWidgetEnabledRequested(enabled)
            onTimeUse24HourRequested: root.timeUse24HourRequested(enabled)
            onTimeShowSecondsRequested: root.timeShowSecondsRequested(enabled)
        }

        // Plain terminal-style command palette: no nested cards or button chrome.
        Item {
            anchors.fill: parent
            visible: root.plainCommandView

            TextInput {
                id: search
                x: 2
                y: 6
                width: parent.width - 4
                height: 30
                color: "#F2F2F2"
                selectionColor: "#FFFFFF35"
                selectedTextColor: "#FFFFFF"
                font.family: "monospace"
                font.pixelSize: 14
                clip: true
                focus: root.opened && root.plainCommandView
                activeFocusOnPress: true
                verticalAlignment: Text.AlignVCenter
                selectByMouse: true
                text: "/"
                cursorVisible: activeFocus

                onTextChanged: {
                    if (!text.startsWith("/")) {
                        text = "/" + text
                        return
                    }

                    root.commandText = text
                    root.selectedCommandIndex = 0
                }

                Keys.onEscapePressed: root.closeRequested()

                Keys.onReturnPressed: {
                    if (root.filteredCommands.length > 0)
                        root.executeCommand(
                            root.filteredCommands[
                                Math.min(
                                    root.selectedCommandIndex,
                                    root.filteredCommands.length - 1
                                )
                            ]
                        )
                }

                Keys.onDownPressed: {
                    if (root.filteredCommands.length > 0)
                        root.selectedCommandIndex = Math.min(
                            root.filteredCommands.length - 1,
                            root.selectedCommandIndex + 1
                        )
                }

                Keys.onUpPressed: {
                    if (root.filteredCommands.length > 0)
                        root.selectedCommandIndex = Math.max(
                            0,
                            root.selectedCommandIndex - 1
                        )
                }
            }

            Column {
                id: commandColumn
                x: 2
                y: 40
                width: parent.width - 4
                spacing: 0

                Repeater {
                    model: root.filteredCommands

                    delegate: Item {
                        width: commandColumn.width
                        height: 27

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 2
                            verticalAlignment: Text.AlignVCenter
                            text: "/" + modelData.name
                            color: root.selectedCommandIndex === index ? "#FFFFFF" : "#858585"
                            font.family: "monospace"
                            font.pixelSize: 12
                            font.weight: root.selectedCommandIndex === index
                                ? Font.DemiBold
                                : Font.Normal
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.selectedCommandIndex = index
                            onClicked: root.executeCommand(modelData)
                        }
                    }
                }
            }

            Text {
                x: 4
                y: 40
                width: parent.width - 8
                height: 27
                visible: root.filteredCommands.length === 0
                text: "no matching command"
                color: "#777777"
                font.family: "monospace"
                font.pixelSize: 12
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Redesigned power center.
        Item {
            id: powerView
            anchors.fill: parent
            visible: root.powerViewOpen

            Column {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 14

                // Header: profile status is now inside the main container.
                Rectangle {
                    width: parent.width
                    height: 68
                    radius: 16
                    color: "#090909"
                    border.width: 1
                    border.color: "#181818"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Text {
                                text: "POWER CENTER"
                                color: root.primaryText
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.5
                            }

                            Text {
                                text: "SYSTEM PERFORMANCE • BATTERY • ENERGY"
                                color: "#505050"
                                font.pixelSize: 8
                                font.letterSpacing: 1.1
                            }
                        }

                        Item {
                            width: parent.width - 390
                            height: 1
                        }

                        Rectangle {
                            width: 180
                            height: 44
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 13
                            color: "#101010"
                            border.width: 1
                            border.color: "#282828"

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    width: 150
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "ACTIVE PROFILE"
                                    color: "#4C4C4C"
                                    font.pixelSize: 7
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 1.1
                                }

                                Text {
                                    width: 150
                                    horizontalAlignment: Text.AlignHCenter
                                    text: root.activeProfileLabel
                                    color: "#D7B56D"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.8
                                }
                            }
                        }
                    }
                }

                // Main content.
                Row {
                    width: parent.width
                    height: 340
                    spacing: 14

                    Rectangle {
                        id: batteryPanel
                        width: Math.min(350, parent.width * 0.39)
                        height: parent.height
                        radius: 18
                        color: "#080808"
                        border.width: 1
                        border.color: "#171717"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 22
                            spacing: 12

                            Row {
                                width: parent.width
                                height: 24

                                Text {
                                    text: "BATTERY"
                                    color: "#B0B0B0"
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 1.4
                                }

                                Item { width: parent.width - 125; height: 1 }

                                Text {
                                    width: 125
                                    horizontalAlignment: Text.AlignRight
                                    text: root.batteryPresent ? root.batteryStateLabel : "AC POWER"
                                    color: "#555555"
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.9
                                }
                            }

                            Item {
                                width: parent.width
                                height: 120

                                Rectangle {
                                    id: batteryBody
                                    width: 188
                                    height: 78
                                    anchors.centerIn: parent
                                    radius: 15
                                    color: "#0E0E0E"
                                    border.width: 1
                                    border.color: "#2A2A2A"

                                    Rectangle {
                                        width: 5
                                        height: 26
                                        anchors.right: parent.right
                                        anchors.rightMargin: -6
                                        anchors.verticalCenter: parent.verticalCenter
                                        radius: 2
                                        color: "#2A2A2A"
                                    }

                                    Rectangle {
                                        x: 9
                                        y: 9
                                        width: Math.max(0, Math.min(parent.width - 18, (parent.width - 18) * root.batteryPercent / 100))
                                        height: parent.height - 18
                                        radius: 9
                                        color: root.batteryPresent
                                            ? (root.batteryState === "charging" ? "#C8A85E" : "#6E6E6E")
                                            : "#202020"

                                        Behavior on width {
                                            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.batteryPresent
                                            ? root.batteryPercent + "%"
                                            : "AC"
                                        color: "#FFFFFF"
                                        font.pixelSize: 27
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }

                            Column {
                                width: parent.width
                                spacing: 2

                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: root.batteryPresent
                                        ? root.batteryStateLabel
                                        : "CONNECTED TO AC POWER"
                                    color: "#D2D2D2"
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.8
                                }

                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: root.batteryPresent
                                        ? (root.batteryState === "charging" ? "Power is flowing into the battery" : "Battery telemetry from the system")
                                        : "Battery telemetry will appear when a battery is detected"
                                    color: "#525252"
                                    font.pixelSize: 8
                                }
                            }

                            Row {
                                width: parent.width
                                height: 64
                                spacing: 8

                                MetricTile {
                                    label: "TIME"
                                    value: root.batteryTime
                                }

                                MetricTile {
                                    label: "POWER"
                                    value: root.batteryRate
                                }

                                MetricTile {
                                    label: "HEALTH"
                                    value: root.batteryCapacity
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width - batteryPanel.width - 14
                        height: parent.height
                        radius: 18
                        color: "#080808"
                        border.width: 1
                        border.color: "#171717"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 9

                            Row {
                                width: parent.width
                                height: 28

                                Column {
                                    spacing: 2

                                    Text {
                                        text: "POWER MODES"
                                        color: "#B0B0B0"
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 1.4
                                    }

                                    Text {
                                        text: "Choose how A16EEN prioritizes speed and battery"
                                        color: "#454545"
                                        font.pixelSize: 7
                                    }
                                }

                                Item { width: 1; height: 1 }
                            }

                            PowerModeRow {
                                title: "PERFORMANCE"
                                subtitle: "Maximum responsiveness"
                                detail: "Live wallpaper runs • system checks every 1s"
                                profile: "performance"
                                active: root.powerProfileIsActive("performance")
                            }

                            PowerModeRow {
                                title: "BALANCED"
                                subtitle: "Adaptive everyday mode"
                                detail: "Wallpaper pauses while using apps • checks every 3s"
                                profile: "balanced"
                                active: root.powerProfileIsActive("balanced")
                            }

                            PowerModeRow {
                                title: "ECO"
                                subtitle: "Maximum battery saving"
                                detail: "Wallpaper stays static • system checks every 7s"
                                profile: "power-saver"
                                active: root.powerProfileIsActive("power-saver")
                            }
                        }
                    }
                }

                // A16EEN effects summary.
                Rectangle {
                    width: parent.width
                    height: 58
                    radius: 15
                    color: "#090909"
                    border.width: 1
                    border.color: "#171717"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        spacing: 12

                        EffectChip {
                            title: "LIVE WALLPAPER"
                            value: root.wallpaperModeLabel
                        }

                        EffectChip {
                            title: "A16EEN MONITOR"
                            value: root.monitorModeLabel
                        }

                        Item {
                            width: Math.max(1, parent.width - 476)
                            height: 1
                        }

                        Text {
                            width: 190
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignRight
                            text: root.powerStatus
                            color: "#4D4D4D"
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                            elide: Text.ElideRight
                        }
                    }
                }

                // Clean footer with no overlap.
                Row {
                    width: parent.width
                    height: 40
                    spacing: 10

                    Rectangle {
                        width: 40
                        height: 40
                        radius: 12
                        color: "#0A0A0A"
                        border.width: 1
                        border.color: "#1D1D1D"

                        Text {
                            anchors.centerIn: parent
                            text: "←"
                            color: "#9A9A9A"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closePowerView()
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: "COMMAND SEARCH"
                            color: "#666666"
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.0
                        }

                        Text {
                            text: "Return to / commands"
                            color: "#3F3F3F"
                            font.pixelSize: 8
                        }
                    }

                    Item { width: parent.width - 180; height: 1 }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "POWERPROFILES"
                        color: "#2F2F2F"
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.0
                    }
                }
            }
        }
    }

    MouseArea {
        z: -1
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    Keys.onEscapePressed: {
        if (root.powerViewOpen)
            root.closePowerView()
        else if (root.widgetViewOpen)
            root.closeWidgetView()
        else if (root.navbarViewOpen)
            root.closeNavbarView()
        else
            root.closeRequested()
    }

    component MetricTile: Rectangle {
        required property string label
        required property string value

        width: (parent.width - 16) / 3
        height: 64
        radius: 11
        color: "#0C0C0C"
        border.width: 1
        border.color: "#151515"

        Column {
            anchors.fill: parent
            anchors.margins: 9
            spacing: 5

            Text {
                text: parent.parent.label
                color: "#414141"
                font.pixelSize: 7
                font.weight: Font.DemiBold
                font.letterSpacing: 0.9
            }

            Text {
                width: parent.width
                text: parent.parent.value
                color: "#C8C8C8"
                font.pixelSize: 9
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }
    }

    component EffectChip: Rectangle {
        required property string title
        required property string value

        width: 125
        height: 38
        anchors.verticalCenter: parent.verticalCenter
        radius: 10
        color: "#0C0C0C"
        border.width: 1
        border.color: "#151515"

        Column {
            anchors.centerIn: parent
            spacing: 2

            Text {
                width: 110
                horizontalAlignment: Text.AlignHCenter
                text: parent.parent.title
                color: "#414141"
                font.pixelSize: 6
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
            }

            Text {
                width: 110
                horizontalAlignment: Text.AlignHCenter
                text: parent.parent.value
                color: "#BBBBBB"
                font.pixelSize: 7
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }
    }

    component PowerModeRow: Rectangle {
        required property string title
        required property string subtitle
        required property string detail
        required property string profile
        required property bool active

        width: parent.width
        height: 82
        radius: 15
        color: active ? "#111111" : "#090909"
        border.width: 1
        border.color: active ? "#303030" : "#151515"

        Behavior on color {
            ColorAnimation { duration: 140 }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 13

            Rectangle {
                width: 42
                height: 42
                anchors.verticalCenter: parent.verticalCenter
                radius: 12
                color: active ? "#222222" : "#0E0E0E"
                border.width: 1
                border.color: active ? "#373737" : "#191919"

                Text {
                    anchors.centerIn: parent
                    text: title.charAt(0)
                    color: "#FFFFFF"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }

            Column {
                width: parent.width - 170
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Text {
                    text: parent.parent.parent.title
                    color: "#FFFFFF"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.8
                }

                Text {
                    text: parent.parent.parent.subtitle
                    color: "#727272"
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width
                    text: parent.parent.parent.detail
                    color: "#454545"
                    font.pixelSize: 7
                    elide: Text.ElideRight
                }
            }

            Column {
                width: 90
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5

                Rectangle {
                    width: 90
                    height: 24
                    radius: 8
                    color: active ? "#1A1A1A" : "#0B0B0B"
                    border.width: 1
                    border.color: active ? "#333333" : "#171717"

                    Text {
                        anchors.centerIn: parent
                        text: active ? "ACTIVE" : "SELECT"
                        color: active ? "#D7B56D" : "#555555"
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.0
                    }
                }

                Text {
                    width: 90
                    horizontalAlignment: Text.AlignRight
                    text: profile === "power-saver" ? "ECO" : profile.toUpperCase()
                    color: "#353535"
                    font.pixelSize: 6
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.7
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.selectPowerProfile(parent.profile)
        }
    }

    function executeCommand(command) {
        if (!command)
            return

        root.recordCommandUsage(command.id)

        switch (command.id) {
        case "wallpaper":
            root.closeRequested()
            root.wallpaperRequested()
            break
        case "screenshot":
            root.closeRequested()
            root.screenshotRequested()
            break
        case "screenshot-settings":
            root.closeRequested()
            root.screenshotSettingsRequested()
            break
        case "launcher":
            root.closeRequested()
            root.launcherRequested()
            break
        case "overview":
            root.closeRequested()
            Quickshell.execDetached(["niri", "msg", "action", "toggle-overview"])
            break
        case "power":
            root.openPowerView()
            break
        case "controls":
            root.openControlView()
            break
        case "icons":
            root.openIconThemeView()
            break
        case "presets":
            root.openWorkspacePresetView()
            break
        case "navbar":
            root.openNavbarView()
            break
        case "wifi":
        case "bluetooth":
        case "audio":
        case "brightness":
        case "night-light":
        case "battery":
        case "dnd":
            root.openControlDetail(command.id)
            break
        case "widgets":
            root.openWidgetView()
            break
        case "restart-shell":
            root.closeRequested()
            Quickshell.execDetached(["a16", "-r"])
            break
        case "doctor":
            root.closeRequested()
            Quickshell.execDetached(["a16", "-d"])
            break
        }
    }

    onWidgetViewOpenChanged: {
        if (root.widgetViewOpen) {
            root.controlViewOpen = false
            root.controlDetail = ""
            Qt.callLater(() => widgetSection.forceActiveFocus())
        } else if (root.opened && !root.powerViewOpen && !root.controlViewOpen && !root.iconThemeViewOpen && !root.workspacePresetViewOpen && !root.navbarViewOpen) {
            Qt.callLater(() => search.forceActiveFocus())
        }
    }

    onOpenedChanged: {
        if (!opened) {
            root.powerViewOpen = false
            root.controlViewOpen = false
            root.controlDetail = ""
            root.iconThemeViewOpen = false
            root.workspacePresetViewOpen = false
            root.navbarViewOpen = false
            root.commandText = "/"
            root.selectedCommandIndex = 0
            return
        }

        root.powerViewOpen = false
        root.controlViewOpen = false
        root.iconThemeViewOpen = false
        root.navbarViewOpen = false
        root.commandText = "/"
        root.selectedCommandIndex = 0
        search.text = "/"

        Qt.callLater(() => {
            if (root.opened && !root.widgetViewOpen && !root.powerViewOpen && !root.controlViewOpen && !root.iconThemeViewOpen && !root.workspacePresetViewOpen && !root.navbarViewOpen)
                search.forceActiveFocus()
        })
    }
}
