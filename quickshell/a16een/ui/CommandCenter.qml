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
    property string commandText: "/"
    property int selectedCommandIndex: 0

    property bool editorialTimeWidgetEnabled: true
    property bool calendarWidgetEnabled: false
    property bool pulseWidgetEnabled: false
    property bool workspaceWidgetEnabled: false
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
    signal dashboardRequested()
    signal wallpaperRequested()
    signal widgetsRequested()
    signal widgetsCloseRequested()
    signal editorialTimeWidgetEnabledRequested(bool enabled)
    signal calendarWidgetEnabledRequested(bool enabled)
    signal pulseWidgetEnabledRequested(bool enabled)
    signal workspaceWidgetEnabledRequested(bool enabled)
    signal timeUse24HourRequested(bool enabled)
    signal timeShowSecondsRequested(bool enabled)

    readonly property color surface: "#000000"
    readonly property color borderColor: "#1A1A1A"
    readonly property color fieldBackground: "#0A0A0A"
    readonly property color fieldBorder: "#1C1C1C"
    readonly property color fieldFocusBorder: "#333333"
    readonly property color primaryText: "#FFFFFF"
    readonly property color secondaryText: "#6F6F6F"
    readonly property color mutedText: "#3F3F3F"
    readonly property color selectedBackground: "#111111"

    readonly property var commands: [
        { id: "wallpaper", name: "wallpaper", keywords: ["wallpaper", "background", "image"] },
        { id: "launcher", name: "launcher", keywords: ["launcher", "applications", "apps"] },
        { id: "dashboard", name: "dashboard", keywords: ["dashboard", "system"] },
        { id: "overview", name: "overview", keywords: ["overview", "workspaces", "windows"] },
        { id: "power", name: "power", keywords: ["power", "performance", "balanced", "battery", "energy", "eco", "power-saving", "power-saver"] },
        { id: "widgets", name: "widgets", keywords: ["widgets", "widget", "clock", "time", "day", "date", "desktop", "modules"] },
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

        if (!query)
            return root.commands

        return root.commands.filter(command => {
            const haystack = [command.name, ...(command.keywords || [])]
                .join(" ")
                .toLowerCase()

            return haystack.includes(query)
        })
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
        root.powerViewOpen = true
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
        root.widgetViewOpen = false
        root.commandText = "/"
        root.selectedCommandIndex = 0
        root.powerStatus = "READY"
        Qt.callLater(() => search.forceActiveFocus())
    }

    function openWidgetView() {
        root.widgetViewOpen = true
        root.powerViewOpen = false
        root.commandText = "/widgets"
        root.selectedCommandIndex = 0
        Qt.callLater(() => widgetSection.forceActiveFocus())
    }

    function closeWidgetView() {
        root.widgetViewOpen = false
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
        opacity: root.opened ? 0.34 : 0
    }

    Rectangle {
        id: card
        width: root.powerViewOpen || root.widgetViewOpen
            ? Math.min(940, parent.width - 72)
            : Math.min(500, parent.width - 48)
        height: root.powerViewOpen || root.widgetViewOpen
            ? Math.min(640, parent.height - 80)
            : 326
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.powerViewOpen ? 0 : 185
        radius: root.powerViewOpen ? 26 : 18
        color: root.surface
        border.width: 1
        border.color: "#202020"
        clip: true

        Behavior on width {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Behavior on height {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Behavior on anchors.verticalCenterOffset {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -5
            radius: root.powerViewOpen ? 31 : 23
            color: "#16000000"
            z: -1
        }

        Connections {
            target: root

            function onTimeWidgetEnabledChanged() {
                if (widgetSectionLoader.item)
                    widgetSectionLoader.item.timeEnabled = root.timeWidgetEnabled
            }

            function onPulseWidgetEnabledChanged() {
                if (widgetSectionLoader.item)
                    widgetSectionLoader.item.pulseEnabled = root.pulseWidgetEnabled
            }

            function onWorkspaceWidgetEnabledChanged() {
                if (widgetSectionLoader.item)
                    widgetSectionLoader.item.workspaceEnabled = root.workspaceWidgetEnabled
            }

            function onTimeUse24HourChanged() {
                if (widgetSectionLoader.item)
                    widgetSectionLoader.item.timeUse24Hour = root.timeUse24Hour
            }

            function onTimeShowSecondsChanged() {
                if (widgetSectionLoader.item)
                    widgetSectionLoader.item.timeShowSeconds = root.timeShowSeconds
            }
        }

        // Normal command search.
        Item {
            anchors.fill: parent
            visible: !root.powerViewOpen && !root.widgetViewOpen

            Rectangle {
                id: searchBox
                x: 12
                y: 12
                width: parent.width - 24
                height: 48
                radius: 12
                color: search.activeFocus ? "#0D0D0D" : root.fieldBackground
                border.width: 1
                border.color: search.activeFocus
                    ? root.fieldFocusBorder
                    : root.fieldBorder

                TextInput {
                    id: search
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 12
                    color: root.primaryText
                    selectionColor: "#FFFFFF20"
                    selectedTextColor: root.primaryText
                    font.pixelSize: 12
                    clip: true
                    focus: root.opened && !root.powerViewOpen
                    activeFocusOnPress: true
                    verticalAlignment: Text.AlignVCenter
                    selectByMouse: true
                    text: "/"

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

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 28
                    anchors.verticalCenter: parent.verticalCenter
                    text: "search commands"
                    color: root.secondaryText
                    font.pixelSize: 12
                    visible: search.text === "/"
                }
            }

            Rectangle {
                id: commandSurface
                x: 12
                y: 68
                width: parent.width - 24
                height: 246
                radius: 12
                color: "#000000"
                border.width: 1
                border.color: "#111111"
                clip: true

                Column {
                    id: commandColumn
                    x: 5
                    y: 5
                    width: parent.width - 10
                    spacing: 2

                    Repeater {
                        model: root.filteredCommands

                        delegate: Rectangle {
                            width: commandColumn.width
                            height: 36
                            radius: 9
                            color: root.selectedCommandIndex === index
                                ? root.selectedBackground
                                : "#000000"

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                text: "/" + modelData.name
                                color: root.primaryText
                                font.pixelSize: 12
                                font.weight: root.selectedCommandIndex === index
                                    ? Font.DemiBold
                                    : Font.Normal
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

                    Text {
                        width: parent.width
                        visible: root.filteredCommands.length === 0
                        text: "No command"
                        color: root.secondaryText
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }

        // Redesigned power center.
        Item {
            id: powerView
            anchors.fill: parent
            visible: root.powerViewOpen

        WidgetSection {
            id: widgetSection
            anchors.fill: parent
            visible: root.widgetViewOpen

            editorialTimeEnabled: root.editorialTimeWidgetEnabled
            calendarEnabled: root.calendarWidgetEnabled
            pulseEnabled: root.pulseWidgetEnabled
            workspaceEnabled: root.workspaceWidgetEnabled
            timeUse24Hour: root.timeUse24Hour
            timeShowSeconds: root.timeShowSeconds

            onBackRequested: root.closeWidgetView()
            onEditorialTimeWidgetEnabledRequested: root.editorialTimeWidgetEnabledRequested(enabled)
            onCalendarWidgetEnabledRequested: root.calendarWidgetEnabledRequested(enabled)
            onPulseWidgetEnabledRequested: root.pulseWidgetEnabledRequested(enabled)
            onWorkspaceWidgetEnabledRequested: root.workspaceWidgetEnabledRequested(enabled)
            onTimeUse24HourRequested: root.timeUse24HourRequested(enabled)
            onTimeShowSecondsRequested: root.timeShowSecondsRequested(enabled)
        }

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

        switch (command.id) {
        case "wallpaper":
            root.closeRequested()
            root.wallpaperRequested()
            break
        case "launcher":
            root.closeRequested()
            root.launcherRequested()
            break
        case "dashboard":
            root.closeRequested()
            root.dashboardRequested()
            break
        case "overview":
            root.closeRequested()
            Quickshell.execDetached(["niri", "msg", "action", "toggle-overview"])
            break
        case "power":
            root.openPowerView()
            break
        case "widgets":
            root.openWidgetView()
            break
        case "restart-shell":
            root.closeRequested()
            Quickshell.execDetached(["a16een", "restart-shell"])
            break
        case "doctor":
            root.closeRequested()
            Quickshell.execDetached(["a16een-doctor"])
            break
        }
    }

    onOpenedChanged: {
        if (!opened) {
            root.powerViewOpen = false
            root.widgetViewOpen = false
            root.commandText = "/"
            root.selectedCommandIndex = 0
            return
        }

        root.powerViewOpen = false
        root.commandText = "/"
        root.selectedCommandIndex = 0
        search.text = "/"

        Qt.callLater(() => search.forceActiveFocus())
    }
}
