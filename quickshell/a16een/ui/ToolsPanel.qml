import QtQuick
import qs.ui
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: root

    PopupCardStyle {
        id: popupCardStyle
        containerId: "quick-hub"
    }

    PopupCardStyle {
        id: aiPopupCardStyle
        containerId: "ai-assistant"
        isolateAppearance: true
    }

    readonly property var activePopupCardStyle: root.page === "ai" ? aiPopupCardStyle : popupCardStyle

    required property var modelData
    required property string navbarPosition
    property bool opened: false
    property string page: "tools"
    property var stashedApps: []
    property bool dataMeterEnabled: false
    property var dataMeterSnapshot: ({})
    property bool dataMeterSnapshotReady: false
    property string dataMeterError: ""
    property string dataMeterPeriod: "today"
    property int screenTimeTodaySeconds: 0
    property int screenTimeWeekSeconds: 0
    property int screenTimeMonthSeconds: 0
    property string screenTimePeriod: "today"
    property var screenTimeTopApps: []
    property var screenTimeWeekApps: []
    property var screenTimeMonthApps: []
    readonly property int screenTimeSelectedSeconds: root.screenTimePeriod === "week"
        ? root.screenTimeWeekSeconds
        : (root.screenTimePeriod === "month" ? root.screenTimeMonthSeconds : root.screenTimeTodaySeconds)
    readonly property var screenTimeSelectedApps: root.screenTimePeriod === "week"
        ? root.screenTimeWeekApps
        : (root.screenTimePeriod === "month" ? root.screenTimeMonthApps : root.screenTimeTopApps)
    property bool screenTimeTrackingActive: false
    property string screenTimeStatus: "Waiting for an active window"
    property string screenTimeCurrentApp: "No active application"
    property string expression: "0"
    property string calculatorError: ""
    property bool justEvaluated: false

    signal closeRequested()
    signal toolRequested(string toolId)
    signal appStashRequested()
    signal backRequested()
    signal restoreRequested(string windowId)
    signal dataMeterToggleRequested(bool enabled)

    readonly property bool horizontalNavbar: root.navbarPosition === "top" || root.navbarPosition === "bottom"
    readonly property real screenWidth: root.modelData ? root.modelData.width : 1920
    readonly property real screenHeight: root.modelData ? root.modelData.height : 1080
    readonly property string navbarStateDir: {
        const stateHome = Quickshell.env("XDG_STATE_HOME")
        const home = Quickshell.env("HOME") || ""
        return (stateHome && stateHome.length ? stateHome : home + "/.local/state") + "/a16een"
    }
    property int navbarWorkspaceCount: 6
    property var navbarAppearanceState: ({})
    readonly property bool navbarAiTileVisible: root.navbarContainerVisible("ai")
    readonly property bool navbarGamingTileVisible: root.navbarContainerVisible("gaming")
    readonly property int navbarDockHeight: Math.max(
        260,
        root.navbarWorkspaceCount * 32 + Math.max(0, root.navbarWorkspaceCount - 1) * 4 + 18
    )
    readonly property int navbarShortcutCount: (root.navbarAiTileVisible ? 1 : 0)
        + (root.navbarGamingTileVisible ? 1 : 0)
    readonly property int navbarShortcutStackHeight: navbarShortcutCount > 0 ? 2 + 26 + 24 : 0
    readonly property int navbarAiTileX: root.navbarPosition === "right"
        ? root.screenWidth - 34
        : (root.navbarGamingTileVisible ? 34 : 8)
    readonly property int navbarAiTileY: Math.max(
        0,
        Math.round((root.screenHeight - (root.navbarDockHeight + root.navbarShortcutStackHeight)) / 2) + 2
    )
    readonly property int popupWidth: root.page === "ai" ? Math.min(430, root.screenWidth - 16)
        : (["updates", "app-locker", "sessions"].includes(root.page) ? Math.min(430, root.screenWidth - 16)
        : ((root.page === "data-meter" || root.page === "screen-time") ? 360 : 322))
    readonly property int popupHeight: root.page === "ai" ? 590
        : (root.page === "tools" ? 460
        : (["updates", "app-locker", "sessions"].includes(root.page) ? 510
        : (root.page === "stash" ? 388
        : (root.page === "monitor" ? 310
        : (root.page === "calculator" ? 420
        : (root.page === "screen-time" ? 420
        : (root.page === "data-meter" ? 390 : 316)))))))
    property var monitorStats: null
    property string monitorError: ""
    readonly property var monitorMetrics: [
        {
            label: "CPU",
            value: root.monitorStats ? Number(root.monitorStats.cpu_percent).toFixed(1) + "%" : "—",
            detail: root.monitorStats ? "Current processor use" : "Collecting a sample…",
            ratio: root.monitorStats ? Math.max(0, Math.min(1, Number(root.monitorStats.cpu_percent) / 100)) : 0
        },
        {
            label: "RAM",
            value: root.monitorStats
                ? (Number(root.monitorStats.ram_used_bytes) / 1073741824).toFixed(1) + " / "
                    + (Number(root.monitorStats.ram_total_bytes) / 1073741824).toFixed(1) + " GB"
                : "—",
            detail: root.monitorStats
                ? Number(root.monitorStats.ram_percent).toFixed(0) + "% of memory used"
                : "Reading memory…",
            ratio: root.monitorStats ? Math.max(0, Math.min(1, Number(root.monitorStats.ram_percent) / 100)) : 0
        },
        {
            label: "STORAGE",
            value: root.monitorStats
                ? (Number(root.monitorStats.storage_used_bytes) / 1000000000).toFixed(0) + " / "
                    + (Number(root.monitorStats.storage_total_bytes) / 1000000000).toFixed(0) + " GB"
                : "—",
            detail: root.monitorStats
                ? Number(root.monitorStats.storage_percent).toFixed(0) + "% of home disk used"
                : "Reading storage…",
            ratio: root.monitorStats ? Math.max(0, Math.min(1, Number(root.monitorStats.storage_percent) / 100)) : 0
        }
    ]
    readonly property var tools: [
        { id: "screenshot", label: "Screenshot", detail: "Capture your screen", icon: "lucide-crop.svg" },
        { id: "calculator", label: "Calculator", detail: "Quick calculations", icon: "lucide-calculator.svg" },
        { id: "monitor", label: "System Monitor", detail: "CPU, memory & disk", icon: "lucide-activity.svg" },
        { id: "stash", label: "Nest", detail: "Keep windows out of the way", icon: "lucide-archive.svg" },
        { id: "screen-time", label: "Screen Time", detail: "Daily active time by app", icon: "lucide-activity.svg" },
        { id: "data-meter", label: "Data Meter", detail: "Daily internet usage and speed", icon: "lucide-activity.svg" },
        { id: "updates", label: "Updates", detail: "A16EEN + system updates", icon: "download.svg" },
        { id: "app-locker", label: "App Locker", detail: "Password-gated app launches", icon: "lock.svg" },
        { id: "sessions", label: "Session Snapshots", detail: "Restore your open apps", icon: "layers.svg" },
        { id: "ai", label: "A16EEN AI", detail: "Tell your desktop what to do", icon: "bot.svg" }
    ]

    readonly property real popupX: root.horizontalNavbar
        ? root.screenWidth - root.popupWidth - 102
        : (root.navbarPosition === "left" ? 66 : root.screenWidth - root.popupWidth - 68)
    readonly property real popupY: root.horizontalNavbar
        ? (root.navbarPosition === "top" ? 40 : root.screenHeight - root.popupHeight - 40)
        : root.screenHeight - root.popupHeight - 72

    function navbarContainerVisible(id) {
        const settings = root.navbarAppearanceState || ({})
        const all = settings.all || ({})
        const containers = settings.containers || ({})
        if (all.visibilityControl === true)
            return all.visible !== false
        const item = containers[id] || ({})
        return item.visible !== false
    }

    function isNavbarAiShortcutClick(x, y) {
        if (root.horizontalNavbar || !root.navbarAiTileVisible)
            return false
        return Number(x) >= root.navbarAiTileX
            && Number(x) <= root.navbarAiTileX + 26
            && Number(y) >= root.navbarAiTileY
            && Number(y) <= root.navbarAiTileY + 26
    }

    function parseNavbarWorkspaceCount(raw) {
        const value = Number(String(raw || "").trim())
        if (value >= 2 && value <= 9)
            root.navbarWorkspaceCount = Math.floor(value)
    }

    function formatBytes(value) {
        const bytes = Math.max(0, Number(value) || 0)
        if (bytes < 1024) return Math.round(bytes) + " B"
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(0) + " KB"
        if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + " MB"
        return (bytes / (1024 * 1024 * 1024)).toFixed(2) + " GB"
    }

    function formatRate(value) {
        const rate = Math.max(0, Number(value) || 0)
        if (rate < 1024) return Math.round(rate) + " B/s"
        if (rate < 1024 * 1024) return (rate / 1024).toFixed(rate < 10240 ? 1 : 0) + " KB/s"
        return (rate / (1024 * 1024)).toFixed(1) + " MB/s"
    }

    function formatDuration(value) {
        const seconds = Math.max(0, Math.floor(Number(value) || 0))
        const hours = Math.floor(seconds / 3600)
        const minutes = Math.floor((seconds % 3600) / 60)
        if (hours > 0)
            return hours + "h " + minutes + "m"
        if (minutes > 0)
            return minutes + "m"
        return seconds > 0 ? seconds + "s" : "0m"
    }

    function calculate(sourceText) {
        const source = String(sourceText || "").replace(/\s+/g, "")
        if (!source.length) throw new Error("Enter an expression")
        let position = 0
        function parsePrimary() {
            if (source[position] === "+") { position++; return parsePrimary() }
            if (source[position] === "-") { position++; return -parsePrimary() }
            if (source[position] === "(") {
                position++
                const nested = parseAddSub()
                if (source[position] !== ")") throw new Error("Missing closing parenthesis")
                position++
                let value = nested
                while (source[position] === "%") { value /= 100; position++ }
                return value
            }
            const match = source.slice(position).match(/^(?:\d+(?:\.\d*)?|\.\d+)/)
            if (!match) throw new Error("Invalid number")
            position += match[0].length
            let value = Number(match[0])
            while (source[position] === "%") { value /= 100; position++ }
            return value
        }
        function parseMultiply() {
            let value = parsePrimary()
            while (source[position] === "*" || source[position] === "/") {
                const operator = source[position++]
                const next = parsePrimary()
                if (operator === "/" && next === 0) throw new Error("Cannot divide by zero")
                value = operator === "*" ? value * next : value / next
            }
            return value
        }
        function parseAddSub() {
            let value = parseMultiply()
            while (source[position] === "+" || source[position] === "-") {
                const operator = source[position++]
                const next = parseMultiply()
                value = operator === "+" ? value + next : value - next
            }
            return value
        }
        const result = parseAddSub()
        if (position !== source.length || !Number.isFinite(result)) throw new Error("Invalid expression")
        return String(Number(result.toPrecision(12)))
    }

    function pressCalculator(value) {
        root.calculatorError = ""
        if (value === "clear") {
            root.expression = "0"
            root.justEvaluated = false
            return
        }
        if (value === "backspace") {
            root.expression = root.justEvaluated || root.expression.length <= 1 ? "0" : root.expression.slice(0, -1)
            root.justEvaluated = false
            return
        }
        if (value === "equals") {
            try {
                root.expression = root.calculate(root.expression)
                root.justEvaluated = true
            } catch (error) {
                root.calculatorError = String(error.message || "Invalid expression")
                root.justEvaluated = false
            }
            return
        }
        if (value === "sign") {
            const match = root.expression.match(/(-?\d*\.?\d+)$/)
            if (match) {
                const start = root.expression.length - match[0].length
                const number = match[0]
                root.expression = root.expression.slice(0, start) + (number.startsWith("-") ? number.slice(1) : "-" + number)
            } else if (root.expression === "0") root.expression = "-0"
            else if (/[+\-*/(]$/.test(root.expression)) root.expression += "-"
            root.justEvaluated = false
            return
        }
        if (root.justEvaluated && /^[0-9.]$/.test(value)) root.expression = "0"
        if (/^[+*/%]$/.test(value) || value === "-") {
            if (root.expression === "0" && value !== "-") return
            if (root.expression === "0" && value === "-") {
                root.expression = "-"
                root.justEvaluated = false
                return
            }
            if (/[+\-*/%]$/.test(root.expression) && value !== "-") root.expression = root.expression.slice(0, -1)
        }
        if (value === "." && String(root.expression.split(/[+\-*/()%]/).pop()).includes(".")) return
        if (root.expression === "0" && /^[0-9]$/.test(value)) root.expression = value
        else root.expression += value
        root.justEvaluated = false
    }

    function iconSource(appId) {
        const id = String(appId || "").trim()
        if (id.length) {
            const entry = DesktopEntries.heuristicLookup(id)
            if (entry && String(entry.icon || "").length)
                return Quickshell.iconPath(entry.icon, "application-x-executable")
            return Quickshell.iconPath(id, "application-x-executable")
        }
        return Quickshell.iconPath("application-x-executable", "application-x-executable")
    }

    function refreshStash() {
        if (!stashListProcess.running)
            stashListProcess.running = true
    }

    function refreshMonitor() {
        if (!root.opened || root.page !== "monitor" || monitorProcess.running)
            return
        root.monitorError = ""
        monitorProcess.running = true
    }

    FileView {
        id: navbarAppearanceStateFile
        path: root.navbarStateDir + "/navbar-appearance.json"
        watchChanges: true
        printErrors: false
        onLoaded: {
            try { root.navbarAppearanceState = JSON.parse(String(this.text || "{}")) || ({}) }
            catch (error) { root.navbarAppearanceState = ({}) }
        }
        onFileChanged: {
            try { root.navbarAppearanceState = JSON.parse(String(this.text || "{}")) || ({}) }
            catch (error) { root.navbarAppearanceState = ({}) }
        }
    }

    FileView {
        id: navbarWorkspaceCountFile
        path: root.navbarStateDir + "/workspace-count"
        watchChanges: true
        printErrors: false
        onLoaded: root.parseNavbarWorkspaceCount(this.text())
        onFileChanged: root.parseNavbarWorkspaceCount(this.text())
    }

    Process {
        id: monitorProcess
        command: ["a16een-system-monitor", "snapshot"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(String(text || "{}"))
                    if (parsed && typeof parsed === "object") {
                        root.monitorStats = parsed
                        root.monitorError = ""
                    } else {
                        root.monitorError = "System data is unavailable."
                    }
                } catch (error) {
                    root.monitorError = "System data is unavailable."
                    console.warn("A16EEN System Monitor could not parse a snapshot:", error)
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(text || "").trim()
                if (message.length) {
                    root.monitorError = "System data is unavailable."
                    console.warn("A16EEN System Monitor:", message)
                }
            }
        }
    }

    Timer {
        id: monitorRefreshTimer
        interval: 2200
        repeat: true
        running: root.opened && root.page === "monitor"
        onTriggered: root.refreshMonitor()
    }

    Process {
        id: stashListProcess
        command: ["a16een-app-stash", "list"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(String(text || "[]"))
                    root.stashedApps = Array.isArray(parsed) ? parsed : []
                } catch (error) {
                    root.stashedApps = []
                    console.warn("A16EEN Nest could not read its window list:", error)
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(text || "").trim()
                if (message.length)
                    console.warn("A16EEN Nest:", message)
            }
        }
    }

    // These timers live with the shell, not the visible popup, so daily checks
    // and session snapshots continue while Quick Tools is closed.
    Process {
        id: dailyUpdateCheckProcess
        command: ["a16een-quick-tools", "updates"]
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(text || "").trim()
                if (message.length)
                    console.warn("A16EEN daily update check:", message)
            }
        }
    }

    Timer {
        interval: 1000
        repeat: false
        running: true
        onTriggered: if (!dailyUpdateCheckProcess.running) dailyUpdateCheckProcess.running = true
    }

    Timer {
        interval: 24 * 60 * 60 * 1000
        repeat: true
        running: true
        onTriggered: if (!dailyUpdateCheckProcess.running) dailyUpdateCheckProcess.running = true
    }

    Process {
        id: automaticSnapshotProcess
        command: ["a16een-quick-tools", "snapshot", "auto"]
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(text || "").trim()
                if (message.length)
                    console.warn("A16EEN automatic session snapshot:", message)
            }
        }
    }

    Timer {
        // Start the first automatic capture after 30 minutes. Do not overwrite
        // the previous session snapshot immediately on login.
        interval: 30 * 60 * 1000
        repeat: true
        running: true
        onTriggered: if (!automaticSnapshotProcess.running) automaticSnapshotProcess.running = true
    }

    Timer {
        id: stashRefreshTimer
        interval: 1600
        repeat: true
        running: root.opened && root.page === "stash"
        onTriggered: root.refreshStash()
    }

    onOpenedChanged: {
        if (!root.opened) {
            monitorProcess.running = false
            stashListProcess.running = false
        } else if (root.page === "stash") {
            Qt.callLater(() => root.refreshStash())
        } else if (root.page === "monitor") {
            Qt.callLater(() => root.refreshMonitor())
        }
    }

    onPageChanged: {
        if (aiAssistantLoader.item)
            aiAssistantLoader.item.palette = root.activePopupCardStyle
        if (quickToolsFeaturesLoader.item) {
            quickToolsFeaturesLoader.item.page = root.page
            quickToolsFeaturesLoader.item.palette = root.activePopupCardStyle
        }
        if (root.page === "calculator") {
            root.expression = "0"
            root.calculatorError = ""
            root.justEvaluated = false
        }
        if (root.opened && root.page === "stash") {
            Qt.callLater(() => root.refreshStash())
        } else if (root.opened && root.page === "monitor") {
            Qt.callLater(() => root.refreshMonitor())
        } else if (root.page !== "monitor") {
            monitorProcess.running = false
        }
    }

    screen: root.modelData
    visible: root.opened && root.modelData !== null
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    focusable: root.opened
    width: root.screenWidth
    height: root.screenHeight

    anchors { left: true; right: true; top: true; bottom: true }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-tools-panel"
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    MouseArea {
        id: outsideClick
        anchors.fill: parent
        z: 0
        focus: true
        acceptedButtons: Qt.AllButtons
        onClicked: mouse => {
            if (root.isNavbarAiShortcutClick(mouse.x, mouse.y)) {
                // This full-screen overlay receives the click before the Dock.
                // Route it to the AI panel instead of swallowing the shortcut.
                if (root.page === "ai")
                    root.closeRequested()
                else
                    root.toolRequested("ai")
                return
            }
            root.closeRequested()
        }
        Keys.onEscapePressed: root.closeRequested()
    }

    Item {
        id: card
        x: Math.max(8, Math.min(root.popupX, root.screenWidth - width - 8))
        y: Math.max(8, Math.min(root.popupY, root.screenHeight - height - 8)) + (root.opened ? 0 : 6)
        width: Math.min(root.popupWidth, root.screenWidth - 16)
        height: Math.min(root.popupHeight, root.screenHeight - 16)
        z: 1
        opacity: root.opened && (root.page !== "ai" || aiPopupCardStyle.appearanceReady) ? 1 : 0
        scale: root.opened ? 1 : 0.985

        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: activePopupCardStyle.backgroundColor
            border.width: 1
            border.color: activePopupCardStyle.borderColor
            Behavior on color { ColorAnimation { duration: 135; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 135; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: 20
                color: "#14000000"
                z: -1
            }

            MouseArea {
                anchors.fill: parent
                z: 0
                acceptedButtons: Qt.AllButtons
                onClicked: mouse.accepted = true
            }

            Column {
                anchors.fill: parent
                anchors.margins: 13
                spacing: 9
                z: 1

                Row {
                    width: parent.width
                    height: 27
                    spacing: 8

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 9
                        color: activePopupCardStyle.subtleSurfaceColor
                        anchors.verticalCenter: parent.verticalCenter

                        NavbarIcon {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            visible: root.page !== "ai"
                            iconPath: Qt.resolvedUrl(root.page === "stash"
                                ? "../assets/icons/lucide-archive.svg"
                                : (root.page === "monitor"
                                    ? "../assets/icons/lucide-activity.svg"
                                    : (root.page === "calculator"
                                        ? "../assets/icons/lucide-calculator.svg"
                                        : (root.page === "updates"
                                            ? "../assets/icons/download.svg"
                                            : (root.page === "app-locker"
                                                ? "../assets/icons/lock.svg"
                                                : (root.page === "sessions"
                                                    ? "../assets/icons/layers.svg"
                                                    : ((root.page === "data-meter" || root.page === "screen-time")
                                                        ? "../assets/icons/lucide-activity.svg"
                                                        : "../assets/icons/lucide-toolbox.svg")))))))
                            iconColor: activePopupCardStyle.iconColor
                        }

                        Item {
                            visible: root.page === "ai"
                            anchors.centerIn: parent
                            width: 14
                            height: 12

                            Repeater {
                                model: 3
                                delegate: Rectangle {
                                    required property int index
                                    x: index === 1 ? 2 : 0
                                    y: index * 4.5
                                    width: index === 1 ? 10 : 14
                                    height: 1.5
                                    radius: 1
                                    color: activePopupCardStyle.iconColor
                                }
                            }
                        }

                        MouseArea {
                            id: aiHistoryMouse
                            visible: root.page === "ai"
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (aiAssistantLoader.item)
                                    aiAssistantLoader.item.toggleHistoryMenu()
                            }
                        }

                        Accessible.name: root.page === "ai" ? "Open chat history" : "Tool icon"
                    }

                    Column {
                        visible: root.page !== "ai"
                        width: root.page === "ai" ? 0 : Math.max(0, parent.width - 28 - 16 - (root.page !== "tools" ? 25 : 0))
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            width: parent.width
                            text: root.page === "stash" ? "NEST"
                                : (root.page === "monitor" ? "SYSTEM MONITOR"
                                : (root.page === "calculator" ? "CALCULATOR"
                                : (root.page === "screen-time" ? "SCREEN TIME"
                                : (root.page === "updates" ? "UPDATES"
                                : (root.page === "app-locker" ? "APP LOCKER"
                                : (root.page === "sessions" ? "SESSION SNAPSHOTS"
                                : (root.page === "ai" ? "A16EEN AI" : (root.page === "data-meter" ? "DATA METER" : "QUICK TOOLS"))))))))
                            color: activePopupCardStyle.textColor
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                        }

                        Text {
                            visible: root.page !== "data-meter"
                            width: parent.width
                            text: root.page === "stash"
                                ? "Your hidden windows, ready to return"
                                : (root.page === "monitor" ? "Live usage while this card is open"
                                : (root.page === "calculator" ? "Quick calculations, no waiting"
                                : (root.page === "screen-time" ? "Today, week and month · active window time"
                                : (root.page === "updates" ? "Daily checks for A16EEN and Arch packages"
                                : (root.page === "app-locker" ? "Password gate for selected app launches"
                                : (root.page === "sessions" ? "Restore an earlier app workspace"
                                : (root.page === "ai" ? "Gemini-powered desktop operator" : "Useful actions, one click away")))))))
                            color: activePopupCardStyle.mutedTextColor
                            font.pixelSize: 8
                            elide: Text.ElideRight
                        }
                    }

                    Item {
                        id: aiHeaderSpacer
                        visible: root.page === "ai"
                        width: visible ? Math.max(0, parent.width - 28 - 25 - 25 - 25 - parent.spacing * 4) : 0
                        height: 1
                    }

                    Rectangle {
                        id: aiNewChatButton
                        visible: root.page === "ai"
                        width: visible ? 25 : 0
                        height: 25
                        radius: 8
                        color: aiNewChatMouse.containsMouse ? activePopupCardStyle.hoverSurfaceColor : "transparent"
                        anchors.verticalCenter: parent.verticalCenter

                        Item {
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            Rectangle {
                                anchors.centerIn: parent
                                width: 12
                                height: 1.5
                                radius: 1
                                color: activePopupCardStyle.iconColor
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: 1.5
                                height: 12
                                radius: 1
                                color: activePopupCardStyle.iconColor
                            }
                        }

                        MouseArea {
                            id: aiNewChatMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: !aiAssistantLoader.item || (!aiAssistantLoader.item.busy && !aiAssistantLoader.item.awaitingApproval)
                            onClicked: {
                                if (aiAssistantLoader.item)
                                    aiAssistantLoader.item.startNewConversation(true)
                            }
                        }

                        Accessible.name: "New chat"
                    }

                    Rectangle {
                        id: aiSettingsButton
                        visible: root.page === "ai"
                        width: visible ? 25 : 0
                        height: 25
                        radius: 8
                        color: aiSettingsMouse.containsMouse ? activePopupCardStyle.hoverSurfaceColor : "transparent"
                        anchors.verticalCenter: parent.verticalCenter

                        NavbarIcon {
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            iconName: "lucide-settings.svg"
                            iconColor: activePopupCardStyle.iconColor
                        }

                        MouseArea {
                            id: aiSettingsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: !aiAssistantLoader.item || (!aiAssistantLoader.item.busy && !aiAssistantLoader.item.awaitingApproval)
                            onClicked: {
                                if (aiAssistantLoader.item) {
                                    aiAssistantLoader.item.historyMenuOpen = false
                                    aiAssistantLoader.item.pageMode = "settings"
                                }
                            }
                        }

                        Accessible.name: "AI settings"
                    }

                    Rectangle {
                        visible: root.page !== "tools"
                        width: root.page !== "tools" ? 25 : 0
                        height: 25
                        radius: 8
                        color: backMouse.containsMouse ? activePopupCardStyle.hoverSurfaceColor : "transparent"
                        anchors.verticalCenter: parent.verticalCenter

                        NavbarIcon {
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            visible: root.page !== "ai"
                            iconName: "lucide-arrow-left.svg"
                            iconColor: activePopupCardStyle.iconColor
                        }

                        Item {
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            visible: root.page === "ai"

                            Rectangle {
                                anchors.centerIn: parent
                                width: 13
                                height: 1.5
                                radius: 1
                                color: activePopupCardStyle.iconColor
                                rotation: 45
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 13
                                height: 1.5
                                radius: 1
                                color: activePopupCardStyle.iconColor
                                rotation: -45
                            }
                        }

                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.page === "ai")
                                    root.closeRequested()
                                else
                                    root.backRequested()
                            }
                        }

                        Accessible.name: root.page === "ai" ? "Close AI assistant" : "Back to tools"
                    }
                }

                Flow {
                    id: toolsGrid
                    visible: root.page === "tools"
                    width: parent.width
                    flow: Flow.LeftToRight
                    spacing: 8
                    height: Math.ceil(root.tools.length / 2) * 70 + (Math.ceil(root.tools.length / 2) - 1) * spacing

                    Repeater {
                        model: root.tools

                        delegate: Rectangle {
                            id: toolTile
                            required property var modelData
                            width: (toolsGrid.width - toolsGrid.spacing) / 2
                            height: 70
                            radius: 11
                            color: toolMouse.containsMouse ? activePopupCardStyle.hoverSurfaceColor : activePopupCardStyle.fieldColor
                            border.width: 1
                            border.color: toolMouse.containsMouse ? activePopupCardStyle.focusBorderColor : activePopupCardStyle.fieldBorderColor
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 9
                                anchors.rightMargin: 6
                                spacing: 8

                                Rectangle {
                                    width: 29
                                    height: 29
                                    radius: 9
                                    color: activePopupCardStyle.subtleSurfaceColor
                                    anchors.verticalCenter: parent.verticalCenter

                                    NavbarIcon {
                                        anchors.centerIn: parent
                                        width: 17
                                        height: 17
                                        iconName: toolTile.modelData.icon
                                        iconColor: activePopupCardStyle.iconColor
                                    }
                                }

                                Column {
                                    width: parent.width - 44
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4

                                    Text {
                                        width: parent.width
                                        text: toolTile.modelData.label
                                        color: activePopupCardStyle.textColor
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: toolTile.modelData.detail
                                        color: activePopupCardStyle.mutedTextColor
                                        font.pixelSize: 7
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }
                                }
                            }

                            MouseArea {
                                id: toolMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (toolTile.modelData.id === "monitor") {
                                        root.monitorStats = null
                                        root.monitorError = ""
                                        root.toolRequested("monitor")
                                    } else {
                                        root.toolRequested(toolTile.modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }

                Loader {
                    id: quickToolsFeaturesLoader
                    active: ["updates", "app-locker", "sessions"].includes(root.page)
                    visible: active
                    width: parent.width
                    height: visible ? Math.max(360, Math.min(424, root.screenHeight - 120)) : 0
                    source: Qt.resolvedUrl("QuickToolsPage.qml")
                    onLoaded: {
                        if (item) {
                            item.page = root.page
                            item.palette = root.activePopupCardStyle
                        }
                    }
                    onActiveChanged: {
                        if (active && item) {
                            item.page = root.page
                            item.palette = root.activePopupCardStyle
                        }
                    }
                }

                Loader {
                    id: aiAssistantLoader
                    active: true
                    visible: root.page === "ai"
                    width: parent.width
                    height: root.page === "ai" ? Math.min(520, Math.max(300, root.screenHeight - 78)) : 0
                    source: Qt.resolvedUrl("AIAssistantPage.qml")
                    onLoaded: {
                        if (item)
                            item.palette = root.activePopupCardStyle
                    }
                }

                Rectangle {
                    visible: root.page === "calculator"
                    width: parent.width
                    height: 64
                    radius: 12
                    color: activePopupCardStyle.subtleSurfaceColor
                    border.width: 1
                    border.color: activePopupCardStyle.fieldBorderColor
                    Column {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        anchors.topMargin: 7
                        anchors.bottomMargin: 7
                        spacing: 2
                        Text {
                            width: parent.width
                            height: 11
                            text: root.calculatorError.length ? root.calculatorError : " "
                            color: activePopupCardStyle.dangerColor
                            font.pixelSize: 8
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            height: 35
                            text: root.expression.replace(/\*/g, "×").replace(/\//g, "÷").replace(/-/g, "−")
                            color: activePopupCardStyle.textColor
                            font.pixelSize: Math.min(25, 284 / Math.max(1, root.expression.length) * 1.35)
                            font.weight: Font.Medium
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideLeft
                        }
                    }
                }

                Grid {
                    id: calculatorKeypad
                    visible: root.page === "calculator"
                    width: parent.width
                    columns: 4
                    spacing: 6
                    height: 5 * 42 + 4 * spacing
                    Repeater {
                        model: [
                            { label: "AC", value: "clear", kind: "utility" }, { label: "⌫", value: "backspace", kind: "utility" },
                            { label: "%", value: "%", kind: "utility" }, { label: "÷", value: "/", kind: "operator" },
                            { label: "7", value: "7", kind: "digit" }, { label: "8", value: "8", kind: "digit" },
                            { label: "9", value: "9", kind: "digit" }, { label: "×", value: "*", kind: "operator" },
                            { label: "4", value: "4", kind: "digit" }, { label: "5", value: "5", kind: "digit" },
                            { label: "6", value: "6", kind: "digit" }, { label: "−", value: "-", kind: "operator" },
                            { label: "1", value: "1", kind: "digit" }, { label: "2", value: "2", kind: "digit" },
                            { label: "3", value: "3", kind: "digit" }, { label: "+", value: "+", kind: "operator" },
                            { label: "±", value: "sign", kind: "utility" }, { label: "0", value: "0", kind: "digit" },
                            { label: ".", value: ".", kind: "digit" }, { label: "=", value: "equals", kind: "equals" }
                        ]
                        delegate: Rectangle {
                            id: calculatorTile
                            required property var modelData
                            width: (calculatorKeypad.width - calculatorKeypad.spacing * 3) / 4
                            height: 42
                            radius: 10
                            color: calculatorKeyMouse.containsMouse ? activePopupCardStyle.hoverSurfaceColor
                                : (calculatorTile.modelData.kind === "equals" ? activePopupCardStyle.actionColor
                                : (calculatorTile.modelData.kind === "digit" ? activePopupCardStyle.fieldColor : activePopupCardStyle.subtleSurfaceColor))
                            border.width: 1
                            border.color: calculatorTile.modelData.kind === "equals" ? activePopupCardStyle.actionColor : activePopupCardStyle.fieldBorderColor
                            Behavior on color { ColorAnimation { duration: 90 } }
                            Text {
                                anchors.centerIn: parent
                                text: calculatorTile.modelData.label
                                color: calculatorTile.modelData.kind === "equals" ? activePopupCardStyle.actionTextColor : activePopupCardStyle.textColor
                                font.pixelSize: calculatorTile.modelData.kind === "digit" ? 13 : 11
                                font.weight: calculatorTile.modelData.kind === "equals" ? Font.DemiBold : Font.Medium
                            }
                            MouseArea {
                                id: calculatorKeyMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.pressCalculator(calculatorTile.modelData.value)
                            }
                        }
                    }
                }

                Column {
                    id: monitorPage
                    visible: root.page === "monitor"
                    width: parent.width
                    spacing: 7

                    Repeater {
                        model: root.monitorMetrics

                        delegate: Rectangle {
                            id: metricCard
                            required property var modelData
                            width: monitorPage.width
                            height: 64
                            radius: 11
                            color: activePopupCardStyle.fieldColor
                            border.width: 1
                            border.color: activePopupCardStyle.fieldBorderColor

                            Column {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 5

                                Row {
                                    width: parent.width
                                    height: 14

                                    Text {
                                        text: metricCard.modelData.label
                                        color: activePopupCardStyle.secondaryTextColor
                                        font.pixelSize: 8
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 0.5
                                    }

                                    Item { width: Math.max(0, parent.width - 85); height: 1 }

                                    Text {
                                        text: metricCard.modelData.value
                                        color: activePopupCardStyle.textColor
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 4
                                    radius: 2
                                    color: activePopupCardStyle.selectedSurfaceColor
                                    clip: true

                                    Rectangle {
                                        width: parent.width * Math.max(0, Math.min(1, Number(metricCard.modelData.ratio || 0)))
                                        height: parent.height
                                        radius: 2
                                        color: activePopupCardStyle.iconColor
                                        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                    }
                                }

                                Text {
                                    text: root.monitorError.length ? root.monitorError : metricCard.modelData.detail
                                    color: root.monitorError.length ? activePopupCardStyle.dangerColor : activePopupCardStyle.mutedTextColor
                                    font.pixelSize: 7
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                Item {
                    id: screenTimePage
                    visible: root.page === "screen-time"
                    width: parent.width
                    height: Math.max(250, parent.height - 56)

                    // One compact switcher: these are actions, not statistic cards.
                    Rectangle {
                        id: screenTimePeriodSwitch
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: 34
                        radius: 10
                        color: activePopupCardStyle.subtleSurfaceColor
                        border.width: 1
                        border.color: activePopupCardStyle.fieldBorderColor

                        Row {
                            id: screenTimePeriodChoices
                            anchors.fill: parent
                            anchors.margins: 3
                            spacing: 3

                            Repeater {
                                model: [
                                    { id: "today", label: "Today" },
                                    { id: "week", label: "Week" },
                                    { id: "month", label: "Month" }
                                ]

                                delegate: Rectangle {
                                    id: screenTimePeriodChoice
                                    required property var modelData
                                    width: (screenTimePeriodChoices.width - screenTimePeriodChoices.spacing * 2) / 3
                                    height: screenTimePeriodChoices.height
                                    radius: 7
                                    readonly property bool selected: root.screenTimePeriod === modelData.id
                                    color: selected ? activePopupCardStyle.selectedSurfaceColor : "transparent"
                                    border.width: selected ? 1 : 0
                                    border.color: activePopupCardStyle.fieldBorderColor

                                    Text {
                                        anchors.centerIn: parent
                                        text: screenTimePeriodChoice.modelData.label
                                        color: screenTimePeriodChoice.selected
                                            ? activePopupCardStyle.textColor : activePopupCardStyle.mutedTextColor
                                        font.pixelSize: 9
                                        font.weight: screenTimePeriodChoice.selected ? Font.DemiBold : Font.Medium
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.screenTimePeriod = screenTimePeriodChoice.modelData.id
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        id: screenTimeTotalRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: screenTimePeriodSwitch.bottom
                        anchors.topMargin: 10
                        height: 44

                        Column {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Text {
                                text: root.screenTimePeriod === "today" ? "TODAY'S ACTIVE TIME"
                                    : (root.screenTimePeriod === "week" ? "LAST 7 DAYS" : "THIS MONTH")
                                color: activePopupCardStyle.mutedTextColor
                                font.pixelSize: 7
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.7
                            }

                            Text {
                                text: root.formatDuration(root.screenTimeSelectedSeconds)
                                color: activePopupCardStyle.textColor
                                font.pixelSize: 23
                                font.weight: Font.DemiBold
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.screenTimeSelectedApps.length + " APPS"
                            color: activePopupCardStyle.mutedTextColor
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                        }
                    }

                    Row {
                        id: screenTimeStatusRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: screenTimeTotalRow.bottom
                        anchors.topMargin: 6
                        height: 17
                        spacing: 6

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.screenTimeTrackingActive ? activePopupCardStyle.successColor : activePopupCardStyle.mutedTextColor
                        }

                        Text {
                            width: parent.width - 82
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.screenTimeTrackingActive
                                ? root.screenTimeCurrentApp : root.screenTimeStatus
                            color: activePopupCardStyle.secondaryTextColor
                            font.pixelSize: 8
                            elide: Text.ElideRight
                        }

                        Text {
                            width: 62
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.screenTimeTrackingActive ? "TRACKING" : "PAUSED"
                            color: root.screenTimeTrackingActive ? activePopupCardStyle.successColor : activePopupCardStyle.mutedTextColor
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    Text {
                        id: screenTimeAppsHeading
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: screenTimeStatusRow.bottom
                        anchors.topMargin: 9
                        height: 12
                        text: "APP USAGE · " + root.screenTimePeriod.toUpperCase()
                        color: activePopupCardStyle.mutedTextColor
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.65
                    }

                    Flickable {
                        id: screenTimeAppsFlick
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: screenTimeAppsHeading.bottom
                        anchors.topMargin: 7
                        anchors.bottom: parent.bottom
                        clip: true
                        contentWidth: width
                        contentHeight: screenTimeAppsList.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds
                        visible: root.screenTimeSelectedApps.length > 0

                        Column {
                            id: screenTimeAppsList
                            width: screenTimeAppsFlick.width
                            spacing: 7

                            Repeater {
                                model: root.screenTimeSelectedApps

                                delegate: Item {
                                    id: screenTimeAppRow
                                    required property var modelData
                                    width: screenTimeAppsList.width
                                    height: 29

                                    Row {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        height: 18
                                        spacing: 6

                                        Text {
                                            width: parent.width - 62
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: screenTimeAppRow.modelData.name
                                            color: activePopupCardStyle.textColor
                                            font.pixelSize: 9
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            width: 56
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: root.formatDuration(screenTimeAppRow.modelData.seconds)
                                            color: activePopupCardStyle.secondaryTextColor
                                            font.pixelSize: 8
                                            horizontalAlignment: Text.AlignRight
                                            elide: Text.ElideLeft
                                        }
                                    }

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: 3
                                        radius: 2
                                        color: activePopupCardStyle.selectedSurfaceColor
                                        clip: true

                                        Rectangle {
                                            width: parent.width * Math.max(0, Math.min(1,
                                                Number(screenTimeAppRow.modelData.seconds)
                                                / Math.max(1, Number(root.screenTimeSelectedApps.length
                                                    ? root.screenTimeSelectedApps[0].seconds : 1))))
                                            height: parent.height
                                            radius: 2
                                            color: activePopupCardStyle.iconColor
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: screenTimeAppsFlick.verticalCenter
                        visible: root.screenTimeSelectedApps.length === 0
                        text: "App usage for this period will appear here."
                        color: activePopupCardStyle.mutedTextColor
                        font.pixelSize: 9
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                Item {
                    id: dataMeterPage
                    visible: root.page === "data-meter"
                    width: parent.width
                    height: Math.max(280, parent.height - 36)

                    Rectangle {
                        id: dataMeterPeriodSwitch
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 34
                        radius: 10
                        color: activePopupCardStyle.subtleSurfaceColor

                        Row {
                            id: periodChoices
                            anchors.fill: parent
                            anchors.margins: 3
                            spacing: 3

                            Repeater {
                                model: [
                                    { id: "today", label: "Today" },
                                    { id: "month", label: "This month" }
                                ]

                                delegate: Rectangle {
                                    id: periodChoiceTile
                                    required property var modelData
                                    width: (periodChoices.width - periodChoices.spacing) / 2
                                    height: periodChoices.height
                                    radius: 7
                                    color: root.dataMeterPeriod === modelData.id ? activePopupCardStyle.actionColor : "transparent"
                                    border.width: root.dataMeterPeriod === modelData.id ? 1 : 0
                                    border.color: activePopupCardStyle.fieldBorderColor

                                    Text {
                                        anchors.centerIn: parent
                                        text: periodChoiceTile.modelData.label
                                        color: root.dataMeterPeriod === periodChoiceTile.modelData.id ? activePopupCardStyle.actionTextColor : activePopupCardStyle.secondaryTextColor
                                        font.pixelSize: 10
                                        font.weight: root.dataMeterPeriod === periodChoiceTile.modelData.id
                                            ? Font.DemiBold : Font.Medium
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.dataMeterPeriod = periodChoiceTile.modelData.id
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        id: dataMeterTotals
                        anchors.left: parent.left
                        anchors.right: parent.right
                        y: 42
                        height: 79
                        spacing: 8

                        Repeater {
                            model: [
                                {
                                    label: "DOWNLOADED",
                                    value: root.dataMeterSnapshotReady
                                        ? root.formatBytes(root.dataMeterPeriod === "month"
                                            ? root.dataMeterSnapshot.month_download_bytes
                                            : root.dataMeterSnapshot.today_download_bytes) : "—"
                                },
                                {
                                    label: "UPLOADED",
                                    value: root.dataMeterSnapshotReady
                                        ? root.formatBytes(root.dataMeterPeriod === "month"
                                            ? root.dataMeterSnapshot.month_upload_bytes
                                            : root.dataMeterSnapshot.today_upload_bytes) : "—"
                                }
                            ]

                            delegate: Rectangle {
                                id: trafficTile
                                required property var modelData
                                width: (dataMeterTotals.width - dataMeterTotals.spacing) / 2
                                height: dataMeterTotals.height
                                radius: 12
                                color: activePopupCardStyle.fieldColor
                                border.width: 1
                                border.color: activePopupCardStyle.fieldBorderColor

                                Column {
                                    anchors.fill: parent
                                    anchors.leftMargin: 11
                                    anchors.rightMargin: 8
                                    anchors.topMargin: 10
                                    anchors.bottomMargin: 8
                                    spacing: 7

                                    Text {
                                        width: parent.width
                                        text: trafficTile.modelData.label
                                        color: activePopupCardStyle.mutedTextColor
                                        font.pixelSize: 8
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 0.45
                                    }

                                    Text {
                                        width: parent.width
                                        text: trafficTile.modelData.value
                                        color: activePopupCardStyle.textColor
                                        font.pixelSize: 18
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        id: dataMeterNetworkHeading
                        anchors.left: parent.left
                        anchors.right: parent.right
                        y: 132
                        height: 12
                        text: "BY NETWORK"
                        color: activePopupCardStyle.mutedTextColor
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.65
                    }

                    Item {
                        id: dataMeterNetworkArea
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: dataMeterNetworkHeading.bottom
                        anchors.topMargin: 6
                        anchors.bottom: dataMeterToggleRow.top
                        anchors.bottomMargin: 7
                        clip: true

                        Column {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            spacing: 3

                            Repeater {
                                model: root.dataMeterSnapshot && Array.isArray(root.dataMeterSnapshot.interfaces)
                                    ? root.dataMeterSnapshot.interfaces.slice(0, 3) : []

                                delegate: Rectangle {
                                    id: networkRow
                                    required property var modelData
                                    width: dataMeterNetworkArea.width
                                    height: 24
                                    radius: 7
                                    color: networkRow.modelData.is_default ? activePopupCardStyle.selectedSurfaceColor : "transparent"

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 5

                                        Text {
                                            width: parent.width * 0.40
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: String(networkRow.modelData.connection || networkRow.modelData.name || "Network")
                                                + (networkRow.modelData.is_default ? "  •" : "")
                                            color: networkRow.modelData.is_default ? activePopupCardStyle.textColor : activePopupCardStyle.secondaryTextColor
                                            font.pixelSize: 9
                                            font.weight: networkRow.modelData.is_default ? Font.DemiBold : Font.Normal
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            width: parent.width * 0.60 - parent.spacing
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "↓ " + root.formatBytes(root.dataMeterPeriod === "month"
                                                ? networkRow.modelData.rx_month_bytes : networkRow.modelData.rx_today_bytes)
                                                + "   ↑ " + root.formatBytes(root.dataMeterPeriod === "month"
                                                ? networkRow.modelData.tx_month_bytes : networkRow.modelData.tx_today_bytes)
                                            color: activePopupCardStyle.secondaryTextColor
                                            font.pixelSize: 8
                                            horizontalAlignment: Text.AlignRight
                                            elide: Text.ElideLeft
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 8
                            visible: !root.dataMeterSnapshotReady || !root.dataMeterSnapshot.interfaces
                                || root.dataMeterSnapshot.interfaces.length === 0
                            text: root.dataMeterError.length ? root.dataMeterError : "No network traffic detected yet"
                            color: root.dataMeterError.length ? activePopupCardStyle.dangerColor : activePopupCardStyle.mutedTextColor
                            font.pixelSize: 9
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        id: dataMeterToggleRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 40
                        radius: 10
                        color: toggleMeterMouse.containsMouse ? activePopupCardStyle.subtleSurfaceColor : activePopupCardStyle.fieldColor
                        border.width: 1
                        border.color: activePopupCardStyle.fieldBorderColor

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 11
                            anchors.right: meterToggle.left
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Data speed meter on the navbar"
                            color: activePopupCardStyle.textColor
                            font.pixelSize: 9
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            id: meterToggle
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32
                            height: 19
                            radius: 10
                            color: root.dataMeterEnabled ? activePopupCardStyle.actionColor : activePopupCardStyle.fieldBorderColor
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Rectangle {
                                width: 13
                                height: 13
                                y: 3
                                x: root.dataMeterEnabled ? 16 : 3
                                radius: 7
                                color: "#FFFFFF"
                                Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                            }
                        }

                        MouseArea {
                            id: toggleMeterMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.dataMeterToggleRequested(!root.dataMeterEnabled)
                        }
                    }
                }

                GridView {
                    id: stashGrid
                    visible: root.page === "stash" && root.stashedApps.length > 0
                    width: parent.width
                    height: 282
                    clip: true
                    cellWidth: 73
                    cellHeight: 78
                    model: root.stashedApps
                    interactive: contentHeight > height

                    delegate: Item {
                        id: stashTile
                        required property var modelData
                        width: stashGrid.cellWidth
                        height: stashGrid.cellHeight

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 1
                            width: 44
                            height: 44
                            radius: 13
                            color: stashIconMouse.containsMouse ? activePopupCardStyle.hoverSurfaceColor : activePopupCardStyle.subtleSurfaceColor
                            border.width: 1
                            border.color: activePopupCardStyle.fieldBorderColor

                            Image {
                                anchors.centerIn: parent
                                width: 27
                                height: 27
                                source: root.iconSource(stashTile.modelData.app_id)
                                sourceSize.width: 96
                                sourceSize.height: 96
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                                asynchronous: true
                            }

                            MouseArea {
                                id: stashIconMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.restoreRequested(String(stashTile.modelData.window_id))
                            }
                        }

                        Text {
                            anchors.top: parent.top
                            anchors.topMargin: 49
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width - 4
                            text: String(stashTile.modelData.title || "Application")
                            color: activePopupCardStyle.secondaryTextColor
                            font.pixelSize: 8
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }
                }

                Item {
                    visible: root.page === "stash" && root.stashedApps.length === 0
                    width: parent.width
                    height: 282

                    Column {
                        anchors.centerIn: parent
                        spacing: 10

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 50
                            height: 50
                            radius: 15
                            color: activePopupCardStyle.subtleSurfaceColor
                            border.width: 1
                            border.color: activePopupCardStyle.fieldBorderColor

                            NavbarIcon {
                                anchors.centerIn: parent
                                width: 23
                                height: 23
                                iconName: "lucide-archive.svg"
                                iconColor: activePopupCardStyle.iconColor
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Nest is empty"
                            color: activePopupCardStyle.textColor
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Press Super + H to tuck away a window."
                            color: activePopupCardStyle.mutedTextColor
                            font.pixelSize: 9
                        }
                    }
                }

                Text {
                    visible: ["stash", "monitor", "calculator", "screen-time"].includes(root.page)
                    width: parent.width
                    height: 11
                    text: root.page === "stash"
                        ? "Choose an icon to restore its window"
                        : (root.page === "monitor" ? "Refreshes only while open"
                        : (root.page === "calculator" ? "Basic arithmetic · percentage included"
                        : "Tracks focused apps; pauses after 60 seconds idle or screen lock"))
                    color: activePopupCardStyle.mutedTextColor
                    font.pixelSize: 8
                    elide: Text.ElideRight
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible)
            Qt.callLater(() => outsideClick.forceActiveFocus())
    }
}
