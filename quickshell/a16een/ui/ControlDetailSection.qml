import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io

Item {
    id: root

    required property string mode
    property bool active: false
    // When embedded in another card, the parent owns navigation/header layout.
    property bool embedded: false
    property bool doNotDisturb: false

    signal backRequested()
    signal doNotDisturbRequested(bool enabled)
    signal batteryWarningSettingsRequested(var settings)

    property string statusMessage: "READING SYSTEM"
    property string wifiState: "unavailable"
    property string wifiRadioState: "unavailable"
    property string wifiName: "Not connected"
    property string wifiDevice: "—"
    property var wifiNetworks: []
    property bool wifiRefreshing: false
    property string wifiSelectedSsid: ""
    property string wifiSelectedSecurity: ""
    property string wifiPassword: ""
    property bool wifiPasswordVisible: false
    property bool wifiConnecting: false
    property bool wifiSelectedSaved: false
    property string wifiActionMenuSsid: ""
    property bool wifiTogglePending: false

    property string bluetoothState: "unavailable"
    property var bluetoothDevices: []
    property bool bluetoothScanning: false
    property string bluetoothActionMac: ""
    property string bluetoothActionVerb: ""

    property int audioPercent: 0
    property bool audioMuted: false
    property string audioSink: "Default output"

    property int brightnessPercent: 0

    property bool nightLightEnabled: false
    property string nightLightTemperature: "4000K"
    property string nightLightSchedule: "06:30 → 18:30"

    property int batteryPercent: 0
    property string batteryState: "unknown"
    property string batteryTime: "—"
    property string batteryRate: "—"
    property string batteryCapacity: "—"
    property int batteryWarningPercent: 20
    property int batteryCriticalPercent: 10
    property int batteryEmergencyPercent: 5
    property bool batteryWarningEnabled: true
    property bool batteryCriticalEnabled: true
    property bool batteryEmergencyEnabled: true

    property bool dndEnabled: false

    readonly property color page: "#FFFFFF"
    readonly property color tile: "#F7F8FA"
    readonly property color tileHover: "#EEF1F4"
    readonly property color tileActive: "#F1F3F5"
    readonly property color border: "#E1E5EA"
    readonly property color borderStrong: "#CDD3DA"
    readonly property color textPrimary: "#111318"
    readonly property color textSecondary: "#66707C"
    readonly property color textMuted: "#8A939E"
    readonly property color accent: "#B18B3F"

    // Live palette passed by UtilitiesPanel so this view follows user-selected
    // popup colors and stays neutral when no custom color is enabled.
    property color themeSurface: "#F7F8FA"
    property color themeSubtle: "#F7F8FA"
    property color themeHover: "#EEF1F4"
    property color themeSelected: "#E9EDF1"
    property color themeBorder: "#E1E5EA"
    property color themeText: "#111318"
    property color themeSecondaryText: "#66707C"
    property color themeMutedText: "#8A939E"
    property color themeAction: "#242A32"
    property color themeActionText: "#F3F5F8"
    property color themeIcon: "#111318"
    property color themeSuccess: "#438562"
    readonly property string title: {
        switch (root.mode) {
        case "wifi": return "WI-FI"
        case "bluetooth": return "BLUETOOTH"
        case "audio": return "AUDIO"
        case "brightness": return "BRIGHTNESS"
        case "night-light": return "NIGHT LIGHT"
        case "battery": return "BATTERY"
        case "dnd": return "DO NOT DISTURB"
        default: return "SYSTEM CONTROL"
        }
    }

    readonly property string subtitle: {
        switch (root.mode) {
        case "wifi": return "NETWORKS • CONNECTIONS • ADAPTER"
        case "bluetooth": return "DEVICES • PAIRING • CONNECTIONS"
        case "audio": return "OUTPUT • VOLUME • MUTE"
        case "brightness": return "DISPLAY • LEVEL"
        case "night-light": return "COLOR TEMPERATURE • SCHEDULE"
        case "battery": return "POWER • HEALTH • STATUS"
        case "dnd": return "NOTIFICATIONS • FOCUS"
        default: return "A16EEN SYSTEM CONTROL"
        }
    }

    function iconSource(name) {
        return Qt.resolvedUrl("../assets/icons/lucide-" + name + "-dark.svg")
    }

    function run(args) {
        if (!args || !args.length || actionProcess.running)
            return
        actionArgs = args
        root.statusMessage = "APPLYING"
        actionProcess.running = true
    }

    function loadDetails() {
        if (!root.active || detailReader.running)
            return
        detailReader.running = true
        if (root.mode === "wifi" && !wifiReader.running)
            wifiReader.running = true
        if (root.mode === "bluetooth" && !bluetoothReader.running)
            bluetoothReader.running = true
    }

    function refreshVisibleMode() {
        root.loadDetails()
        if (root.mode === "wifi")
            root.refreshWifiNetworks(true)
    }

    function refreshWifiNetworks(forceScan) {
        if (!root.active || root.mode !== "wifi" || wifiNetworksReader.running)
            return

        root.wifiRefreshing = true
        wifiNetworksReader.command = forceScan
            ? ["a16een-control", "wifi", "networks", "--scan"]
            : ["a16een-control", "wifi", "networks"]
        wifiNetworksReader.running = true
    }

    onActiveChanged: {
        if (!root.active)
            return

        root.statusMessage = "READING SYSTEM"
        Qt.callLater(() => root.refreshVisibleMode())
    }

    onModeChanged: {
        root.wifiSelectedSsid = ""
        root.wifiSelectedSecurity = ""
        root.wifiPassword = ""
        if (root.active)
            Qt.callLater(() => root.refreshVisibleMode())
    }

    function parseKeyValue(text, key) {
        const lines = String(text || "").split("\n")
        for (const raw of lines) {
            const index = raw.indexOf("=")
            if (index < 0)
                continue
            if (raw.slice(0, index).trim() === key)
                return raw.slice(index + 1).trim()
        }
        return ""
    }

    function parseDetails(output) {
        const data = String(output || "")
        switch (root.mode) {
        case "wifi":
            root.wifiState = root.normalizeState(root.parseKeyValue(data, "state"))
            root.wifiRadioState = root.normalizeState(root.parseKeyValue(data, "radio"))
            root.wifiName = root.parseKeyValue(data, "connection") || "Not connected"
            root.wifiDevice = root.parseKeyValue(data, "device") || "—"
            break
        case "audio":
            root.audioPercent = Number(root.parseKeyValue(data, "volume")) || 0
            root.audioMuted = root.parseKeyValue(data, "muted") === "1"
            root.audioSink = root.parseKeyValue(data, "sink") || "Default output"
            break
        case "brightness":
            root.brightnessPercent = Number(root.parseKeyValue(data, "percent")) || 0
            break
        case "night-light":
            root.nightLightEnabled = root.normalizeState(root.parseKeyValue(data, "state")) === "on"
            root.nightLightTemperature = root.parseKeyValue(data, "temperature") || "4000K"
            root.nightLightSchedule = root.parseKeyValue(data, "schedule") || "06:30 → 18:30"
            break
        case "battery":
            root.batteryPercent = Number(root.parseKeyValue(data, "percent")) || 0
            root.batteryState = root.parseKeyValue(data, "state") || "unknown"
            root.batteryTime = root.parseKeyValue(data, "time") || "—"
            root.batteryRate = root.parseKeyValue(data, "rate") || "—"
            root.batteryCapacity = root.parseKeyValue(data, "capacity") || "—"
            break
        case "dnd":
            root.dndEnabled = root.parseKeyValue(data, "state") === "on"
            break
        }
        root.statusMessage = "SYSTEM READY"
    }

    function normalizeState(value) {
        const state = String(value || "").trim().toLowerCase()
        if (state === "enabled" || state === "on" || state === "connected")
            return "on"
        if (state === "disabled" || state === "off" || state === "disconnected")
            return "off"
        return "unavailable"
    }

    function splitWifiNetworkFields(raw) {
        const fields = []
        let field = ""
        let escaped = false

        for (const character of String(raw || "")) {
            if (escaped) {
                field += character
                escaped = false
            } else if (character === "\\") {
                escaped = true
            } else if (character === "|") {
                fields.push(field)
                field = ""
            } else {
                field += character
            }
        }

        if (escaped)
            field += "\\"
        fields.push(field)
        return fields
    }

    function parseWifiNetworks(output) {
        const result = []
        const lines = String(output || "").split("\n")
        for (const raw of lines) {
            if (!raw.trim())
                continue
            const parts = root.splitWifiNetworkFields(raw)
            if (parts.length < 3)
                continue
            result.push({
                ssid: parts[0],
                signal: Number(parts[1]) || 0,
                security: parts[2] || "--",
                inUse: parts.length > 3 && parts[3] === "*",
                saved: parts.length > 4 && parts[4] === "yes"
            })
        }
        root.wifiNetworks = result
    }

    function splitBluetoothDeviceFields(raw) {
        const fields = []
        let field = ""
        let escaped = false

        for (const character of String(raw || "")) {
            if (escaped) {
                field += character
                escaped = false
            } else if (character === "\\") {
                escaped = true
            } else if (character === "|") {
                fields.push(field)
                field = ""
            } else {
                field += character
            }
        }

        if (escaped)
            field += "\\"
        fields.push(field)
        return fields
    }

    function parseBluetoothDevices(output) {
        const result = []
        const state = root.parseKeyValue(output, "state")
        if (state.length)
            root.bluetoothState = root.normalizeState(state)

        const lines = String(output || "").split("\n")
        for (const raw of lines) {
            if (!raw.trim() || raw.indexOf("|") < 0)
                continue
            const parts = root.splitBluetoothDeviceFields(raw)
            if (parts.length < 2 || !/^[0-9a-f]{2}(:[0-9a-f]{2}){5}$/i.test(parts[0].trim()))
                continue

            result.push({
                mac: parts[0].trim(),
                name: parts[1] || "Unknown device",
                connected: parts[2] === "yes",
                trusted: parts[3] === "yes",
                paired: parts[4] === "yes"
            })
        }

        // Keep devices discovered during this panel session visible after the
        // short BlueZ discovery cache expires. Starting a fresh scan clears
        // stale unpaired entries while preserving known paired connections.
        const seen = {}
        for (const device of result)
            seen[device.mac.toLowerCase()] = true
        for (const previous of root.bluetoothDevices) {
            const key = String(previous.mac || "").toLowerCase()
            if (key && !seen[key]) {
                result.push(previous)
                seen[key] = true
            }
        }

        result.sort((a, b) =>
            Number(b.connected) - Number(a.connected)
            || Number(b.paired) - Number(a.paired)
            || a.name.localeCompare(b.name))
        root.bluetoothDevices = result
    }

    function startBluetoothScan() {
        if (!root.active || root.mode !== "bluetooth"
            || root.bluetoothState !== "on" || root.bluetoothScanning
            || actionProcess.running)
            return

        root.bluetoothDevices = root.bluetoothDevices.filter(
            device => device.paired || device.connected || device.trusted)
        root.bluetoothScanning = true
        root.run(["bluetooth", "scan"])
        bluetoothScanRefresh.restart()
    }

    function stopBluetoothScan() {
        if (!root.bluetoothScanning)
            return

        root.bluetoothScanning = false
        bluetoothScanRefresh.stop()
        root.run(["bluetooth", "scan-stop"])
        if (!bluetoothReader.running)
            bluetoothReader.running = true
    }

    function runBluetoothDeviceAction(action, mac) {
        if (actionProcess.running || !mac
            || !["pair", "connect", "disconnect"].includes(action))
            return

        root.bluetoothActionMac = mac
        root.bluetoothActionVerb = action
        root.run(["bluetooth", action, mac])
    }

    function connectWifi() {
        const requiresPassword = root.wifiSelectedSecurity !== "--" && root.wifiSelectedSecurity !== ""
        if (actionProcess.running || !root.wifiSelectedSsid.length
            || (requiresPassword && !root.wifiPassword.length && !root.wifiSelectedSaved))
            return

        root.wifiConnecting = true
        root.wifiActionMenuSsid = ""
        const password = root.wifiSelectedSaved || !requiresPassword ? "" : root.wifiPassword
        root.run(["wifi", "connect", root.wifiSelectedSsid, password])
    }

    function clearWifiSelection() {
        root.wifiSelectedSsid = ""
        root.wifiSelectedSecurity = ""
        root.wifiPassword = ""
        root.wifiPasswordVisible = false
        root.wifiSelectedSaved = false
    }

    function selectWifiNetwork(network) {
        root.wifiActionMenuSsid = ""
        if (network.inUse) {
            root.clearWifiSelection()
            return
        }

        root.wifiSelectedSsid = network.ssid
        root.wifiSelectedSecurity = network.security
        root.wifiSelectedSaved = !!network.saved
        root.wifiPassword = ""
        root.wifiPasswordVisible = false
        if (network.saved || network.security === "--" || network.security === "")
            root.connectWifi()
        else
            Qt.callLater(() => wifiPasswordInput.forceActiveFocus())
    }

    function toggleWifiRadio() {
        if (actionProcess.running || root.wifiTogglePending)
            return

        const wasOn = root.wifiRadioState === "on"
        root.wifiTogglePending = true
        root.wifiRadioState = wasOn ? "off" : "on"
        if (wasOn)
            root.wifiName = "Not connected"
        root.run(["wifi", "toggle"])
    }

    function setAudio(value) {
        root.run(["audio", "set", String(Math.round(Math.max(0, Math.min(100, value))))])
    }

    function setBrightness(value) {
        root.run(["brightness", "set", String(Math.round(Math.max(0, Math.min(100, value))))])
    }

    function batteryWarningSettingsPayload() {
        return {
            warningPercent: root.batteryWarningPercent,
            criticalPercent: root.batteryCriticalPercent,
            emergencyPercent: root.batteryEmergencyPercent,
            warningEnabled: root.batteryWarningEnabled,
            criticalEnabled: root.batteryCriticalEnabled,
            emergencyEnabled: root.batteryEmergencyEnabled
        }
    }

    function changeBatteryWarningThreshold(level, delta) {
        if (!["warning", "critical", "emergency"].includes(level))
            return

        const settings = root.batteryWarningSettingsPayload()
        const key = level + "Percent"
        let minimum = 1
        let maximum = 95
        if (level === "warning") {
            minimum = settings.criticalPercent + 1
        } else if (level === "critical") {
            minimum = settings.emergencyPercent + 1
            maximum = settings.warningPercent - 1
        } else {
            maximum = settings.criticalPercent - 1
        }

        const previous = settings[key]
        settings[key] = Math.max(minimum, Math.min(maximum, settings[key] + delta))
        if (settings[key] !== previous)
            root.batteryWarningSettingsRequested(settings)
    }

    function toggleBatteryWarning(level) {
        if (!["warning", "critical", "emergency"].includes(level))
            return
        const settings = root.batteryWarningSettingsPayload()
        const key = level + "Enabled"
        settings[key] = !settings[key]
        root.batteryWarningSettingsRequested(settings)
    }

    Timer {
        id: pollTimer
        interval: 2500
        repeat: true
        running: root.active
        onTriggered: root.loadDetails()
    }

    Timer {
        id: actionRefreshTimer
        interval: 350
        repeat: false
        onTriggered: {
            root.wifiConnecting = false
            root.loadDetails()
            if (root.mode === "wifi")
                root.refreshWifiNetworks(true)
            if (root.mode === "bluetooth")
                bluetoothReader.running = true
        }
    }

    Timer {
        id: bluetoothScanRefresh
        interval: 12500
        repeat: false
        onTriggered: {
            root.bluetoothScanning = false
            if (!bluetoothReader.running)
                bluetoothReader.running = true
        }
    }

    Timer {
        id: bluetoothDiscoveryPoll
        interval: 1100
        repeat: true
        running: root.active && root.mode === "bluetooth" && root.bluetoothScanning
        onTriggered: {
            if (!bluetoothReader.running)
                bluetoothReader.running = true
        }
    }

    Process {
        id: detailReader
        command: ["a16een-control", root.mode, "detail"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.parseDetails(text)
        }

        onRunningChanged: {
            if (!running && root.active && root.statusMessage === "READING SYSTEM")
                root.statusMessage = "SYSTEM READY"
        }
    }

    Process {
        id: wifiReader
        command: ["a16een-control", "wifi", "detail"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.parseDetails(text)
        }
    }

    Process {
        id: wifiNetworksReader
        command: ["a16een-control", "wifi", "networks"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.parseWifiNetworks(text)
        }
        onRunningChanged: {
            if (!running) {
                root.wifiRefreshing = false
                command = ["a16een-control", "wifi", "networks"]
            }
        }
    }

    Process {
        id: bluetoothReader
        command: ["a16een-control", "bluetooth", "detail"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.parseBluetoothDevices(text)
        }
    }

    property var actionArgs: []

    Process {
        id: actionProcess
        command: ["a16een-control"].concat(root.actionArgs || [])
        running: false

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length)
                    root.statusMessage = "ACTION FAILED"
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (root.actionArgs.length >= 2
                && root.actionArgs[0] === "wifi"
                && root.actionArgs[1] === "connect") {
                root.wifiConnecting = false
                if (exitCode === 0) {
                    root.clearWifiSelection()
                    root.wifiActionMenuSsid = ""
                } else if (root.wifiSelectedSaved) {
                    // If a saved profile cannot reconnect, offer a password
                    // fallback rather than leaving the user without a path forward.
                    root.wifiSelectedSaved = false
                    root.statusMessage = "CONNECTION FAILED"
                }
            }

            if (root.actionArgs.length >= 2
                && root.actionArgs[0] === "wifi"
                && root.actionArgs[1] === "toggle") {
                root.wifiTogglePending = false
                if (exitCode !== 0) {
                    root.wifiRadioState = root.wifiRadioState === "on" ? "off" : "on"
                    root.statusMessage = "WI-FI TOGGLE FAILED"
                }
            }

            if (root.actionArgs.length >= 2
                && root.actionArgs[0] === "wifi"
                && root.actionArgs[1] === "forget") {
                if (exitCode === 0) {
                    root.wifiActionMenuSsid = ""
                    if (root.wifiSelectedSsid === root.actionArgs[2])
                        root.clearWifiSelection()
                } else {
                    root.statusMessage = "FORGET FAILED"
                }
            }

            if (root.actionArgs.length >= 3
                && root.actionArgs[0] === "bluetooth"
                && ["pair", "connect", "disconnect"].includes(root.actionArgs[1])) {
                root.bluetoothActionMac = ""
                root.bluetoothActionVerb = ""
                if (exitCode !== 0)
                    root.statusMessage = "BLUETOOTH ACTION FAILED"
            }

            if (root.actionArgs.length >= 2
                && root.actionArgs[0] === "bluetooth"
                && root.actionArgs[1] === "scan"
                && exitCode !== 0) {
                root.bluetoothScanning = false
                bluetoothScanRefresh.stop()
            }

            if (root.actionArgs.length >= 2
                && root.actionArgs[0] === "bluetooth"
                && ["toggle", "scan-stop"].includes(root.actionArgs[1])) {
                root.bluetoothScanning = false
                bluetoothScanRefresh.stop()
            }
        }

        onRunningChanged: {
            if (!running)
                actionRefreshTimer.restart()
        }
    }

    Component.onCompleted: root.loadDetails()

    Item {
        anchors.fill: parent
        anchors.margins: root.embedded ? 12 : 26

        Row {
            id: header
            width: parent.width
            height: root.embedded ? 0 : 54
            visible: !root.embedded
            spacing: 14

            Rectangle {
                width: 38
                height: 38
                radius: 11
                color: "#F6F7F8"
                border.width: 1
                border.color: root.border
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    source: Qt.resolvedUrl("../assets/icons/lucide-arrow-left-dark.svg")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backRequested()
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    text: root.title
                    color: root.textPrimary
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.3
                }

                Text {
                    text: root.subtitle + "  •  " + root.statusMessage
                    color: root.textMuted
                    font.pixelSize: 8
                    font.weight: Font.Medium
                    font.letterSpacing: 0.9
                }
            }
        }

        Item {
            id: wifiView
            anchors.top: root.embedded ? parent.top : header.bottom
            anchors.topMargin: root.embedded ? 0 : 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            visible: root.mode === "wifi"
            clip: true

            Column {
                id: wifiLayout
                anchors.fill: parent
                spacing: root.embedded ? 8 : 12

                Rectangle {
                    id: wifiStatusCard
                    width: parent.width
                    height: root.embedded ? 68 : 88
                    radius: 15
                    color: root.themeSubtle
                    border.width: 1
                    border.color: root.themeBorder

                    Rectangle {
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.embedded ? 39 : 48
                        height: width
                        radius: 12
                        color: root.themeSurface

                        Image {
                            anchors.centerIn: parent
                            width: root.embedded ? 19 : 23
                            height: width
                            source: Qt.resolvedUrl("../assets/icons/lucide-wifi-refined-dark.svg")
                            sourceSize.width: 48
                            sourceSize.height: 48
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1
                                colorizationColor: root.themeIcon
                            }
                        }
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: root.embedded ? 59 : 72
                        anchors.right: wifiPowerButton.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            width: parent.width
                            text: root.wifiName !== "Not connected"
                                ? root.wifiName
                                : (root.wifiRadioState === "off" ? "Wi-Fi is off" : "Not connected")
                            color: root.themeText
                            font.pixelSize: root.embedded ? 10 : 13
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Row {
                            width: parent.width
                            spacing: 5

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 6
                                height: 6
                                radius: 3
                                color: root.wifiName !== "Not connected"
                                    ? root.themeSuccess
                                    : root.themeMutedText
                            }

                            Text {
                                width: parent.width - 11
                                text: root.wifiName !== "Not connected"
                                    ? "Connected · " + root.wifiDevice
                                    : (root.wifiRadioState === "off"
                                        ? "Switch Wi-Fi on to scan"
                                        : "Ready to find a network")
                                color: root.themeSecondaryText
                                font.pixelSize: root.embedded ? 7 : 9
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Rectangle {
                        id: wifiPowerButton
                        anchors.right: parent.right
                        anchors.rightMargin: 9
                        anchors.top: parent.top
                        anchors.topMargin: root.embedded ? 6 : 10
                        width: root.embedded ? 74 : 82
                        height: root.embedded ? 26 : 30
                        radius: 9
                        color: wifiPowerMouse.containsMouse ? Qt.darker(root.themeAction, 1.08) : root.themeAction
                        border.width: 1
                        border.color: root.themeAction

                        Text {
                            anchors.centerIn: parent
                            text: root.wifiTogglePending
                                ? (root.wifiRadioState === "on" ? "Turning on…" : "Turning off…")
                                : (root.wifiRadioState === "on" ? "Turn off" : "Turn on")
                            color: root.themeActionText
                            font.pixelSize: root.embedded ? 8 : 9
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: wifiPowerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !root.wifiTogglePending
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleWifiRadio()
                        }
                    }

                }

                Row {
                    id: wifiHeading
                    width: parent.width
                    height: root.embedded ? 32 : 38
                    spacing: 8

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - wifiRefreshButton.width - parent.spacing
                        spacing: 3

                        Text {
                            width: parent.width
                            text: "Nearby networks"
                            color: root.themeText
                            font.pixelSize: root.embedded ? 10 : 12
                            font.weight: Font.DemiBold
                        }

                        Text {
                            width: parent.width
                            text: root.wifiRefreshing
                                ? "Scanning for networks…"
                                : root.wifiNetworks.length + (root.wifiNetworks.length === 1 ? " network found" : " networks found")
                            color: root.themeMutedText
                            font.pixelSize: root.embedded ? 7 : 8
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        id: wifiRefreshButton
                        width: root.embedded ? 32 : 36
                        height: root.embedded ? 30 : 34
                        radius: 10
                        anchors.verticalCenter: parent.verticalCenter
                        color: refreshWifiMouse.containsMouse ? "#E9EDF2" : "#FFFFFF"
                        border.width: 1
                        border.color: "#D8DEE6"

                        Image {
                            id: wifiRefreshIcon
                            anchors.centerIn: parent
                            width: root.embedded ? 15 : 17
                            height: width
                            source: Qt.resolvedUrl("../assets/icons/lucide-rotate-cw-clean.svg")
                            sourceSize.width: 36
                            sourceSize.height: 36
                            smooth: true
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1
                                colorizationColor: "#18212B"
                            }

                            RotationAnimation on rotation {
                                from: 0
                                to: 360
                                duration: 760
                                loops: Animation.Infinite
                                running: root.wifiRefreshing
                            }
                        }

                        MouseArea {
                            id: refreshWifiMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: !root.wifiRefreshing && root.wifiRadioState === "on"
                            onClicked: root.refreshWifiNetworks(true)
                        }
                    }
                }

                Rectangle {
                    id: wifiConnectionCard
                    width: parent.width
                    height: root.wifiSelectedSsid.length > 0
                        && !root.wifiSelectedSaved
                        && root.wifiSelectedSecurity !== "--"
                        && root.wifiSelectedSecurity !== ""
                        ? (root.embedded ? 94 : 108) : 0
                    visible: height > 0
                    opacity: height > 0 ? 1 : 0
                    radius: 13
                    color: root.themeSubtle
                    border.width: 1
                    border.color: root.themeBorder
                    clip: true

                    Behavior on height {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 140
                            easing.type: Easing.OutCubic
                        }
                    }

                    Column {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        anchors.topMargin: 8
                        anchors.bottomMargin: 7
                        spacing: 6

                        Row {
                            width: parent.width
                            height: 14
                            spacing: 8

                            Text {
                                width: parent.width - wifiCancelLabel.width - parent.spacing
                                text: "JOIN  ·  " + root.wifiSelectedSsid
                                color: root.themeText
                                font.pixelSize: root.embedded ? 8 : 9
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                id: wifiCancelLabel
                                text: "CANCEL"
                                color: wifiCancelMouse.containsMouse ? root.themeText : root.themeMutedText
                                font.pixelSize: 7
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter

                                MouseArea {
                                    id: wifiCancelMouse
                                    anchors.fill: parent
                                    anchors.margins: -5
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.clearWifiSelection()
                                    }
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            height: root.embedded ? 32 : 36
                            spacing: 7

                            Rectangle {
                                id: wifiPasswordField
                                width: parent.width - wifiConnectButton.width - parent.spacing
                                height: parent.height
                                radius: 9
                                color: root.themeSurface
                                border.width: 1
                                border.color: wifiPasswordInput.activeFocus ? root.themeAction : root.themeBorder

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 9
                                    anchors.right: parent.right
                                    anchors.rightMargin: 42
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Wi-Fi password"
                                    color: root.themeMutedText
                                    font.pixelSize: 9
                                    visible: root.wifiPassword.length === 0
                                }

                                TextInput {
                                    id: wifiPasswordInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 9
                                    anchors.rightMargin: 42
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: root.themeText
                                    selectionColor: root.themeSelected
                                    selectedTextColor: root.themeText
                                    font.pixelSize: 10
                                    echoMode: root.wifiPasswordVisible ? TextInput.Normal : TextInput.Password
                                    clip: true
                                    text: root.wifiPassword
                                    onTextChanged: root.wifiPassword = text
                                    activeFocusOnPress: true
                                    selectByMouse: true
                                    Keys.onReturnPressed: root.connectWifi()
                                    Keys.onEnterPressed: root.connectWifi()
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 7
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 31
                                    text: root.wifiPasswordVisible ? "HIDE" : "SHOW"
                                    color: root.themeSecondaryText
                                    font.pixelSize: 7
                                    font.weight: Font.DemiBold
                                    horizontalAlignment: Text.AlignHCenter

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -5
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.wifiPasswordVisible = !root.wifiPasswordVisible
                                    }
                                }
                            }

                                
                            Rectangle {
                                id: wifiConnectButton
                                width: root.embedded ? 76 : 86
                                height: parent.height
                                radius: 9
                                color: root.wifiConnecting ? root.themeMutedText : root.themeAction

                                Text {
                                    anchors.centerIn: parent
                                    text: root.wifiConnecting ? "Joining…" : "Connect"
                                    color: root.themeActionText
                                    font.pixelSize: root.embedded ? 8 : 9
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !root.wifiConnecting
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.connectWifi()
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            text: "Your password is used to join this network."
                            color: root.themeMutedText
                            font.pixelSize: root.embedded ? 7 : 8
                            elide: Text.ElideRight
                        }
                    }
                }

                Flickable {
                    id: wifiNetworkList
                    width: parent.width
                    height: Math.max(0, wifiView.height - wifiStatusCard.height
                        - wifiHeading.height - wifiConnectionCard.height
                        - wifiLayout.spacing * 3)
                    clip: true
                    contentHeight: wifiColumn.height
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick

                    Column {
                        id: wifiColumn
                        width: wifiNetworkList.width
                        spacing: 6

                        Item {
                            width: wifiColumn.width
                            height: root.wifiNetworks.length === 0 ? Math.min(112, wifiNetworkList.height) : 0
                            visible: root.wifiNetworks.length === 0

                            Column {
                                anchors.centerIn: parent
                                spacing: 7

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 32
                                    height: 32
                                    radius: 10
                                    color: root.themeSurface
                                    border.width: 1
                                    border.color: root.themeBorder

                                    Image {
                                        anchors.centerIn: parent
                                        width: 16
                                        height: 16
                                        source: Qt.resolvedUrl("../assets/icons/lucide-wifi-refined-dark.svg")
                                        sourceSize.width: 32
                                        sourceSize.height: 32
                                        opacity: 0.85
                                        layer.enabled: true
                                        layer.effect: MultiEffect {
                                            colorization: 1
                                            colorizationColor: root.themeIcon
                                        }
                                    }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.wifiRefreshing ? "Looking for nearby networks" : "No networks found"
                                    color: root.themeSecondaryText
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.wifiRefreshing ? "This can take a moment." : "Try refreshing the scan."
                                    color: root.themeMutedText
                                    font.pixelSize: 8
                                }
                            }
                        }

                        Repeater {
                            model: root.wifiNetworks

                            delegate: Item {
                                id: wifiNetworkTile
                                required property var modelData
                                readonly property int tileHeight: root.embedded ? 54 : 62
                                readonly property bool menuOpen: root.wifiActionMenuSsid === modelData.ssid
                                readonly property int menuHeight: modelData.saved ? 68 : 36
                                width: wifiColumn.width
                                height: tileHeight + (menuOpen ? menuHeight + 5 : 0)

                                Rectangle {
                                    id: wifiNetworkTileBody
                                    width: parent.width
                                    height: wifiNetworkTile.tileHeight
                                    radius: 12
                                    color: wifiNetworkTile.modelData.inUse
                                        ? root.themeSelected
                                        : (networkMouse.containsMouse || wifiNetworkTile.modelData.ssid === root.wifiSelectedSsid
                                            ? root.themeHover : root.themeSurface)
                                    border.width: wifiNetworkTile.modelData.inUse
                                        || wifiNetworkTile.modelData.ssid === root.wifiSelectedSsid ? 1.3 : 1
                                    border.color: wifiNetworkTile.modelData.inUse
                                        || wifiNetworkTile.modelData.ssid === root.wifiSelectedSsid
                                        ? root.themeAction : root.themeBorder
                                }

                                MouseArea {
                                    id: networkMouse
                                    anchors.fill: wifiNetworkTileBody
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectWifiNetwork(wifiNetworkTile.modelData)
                                }

                                Column {
                                    anchors.left: wifiNetworkTileBody.left
                                    anchors.leftMargin: 14
                                    anchors.right: wifiSignalInfo.left
                                    anchors.rightMargin: 7
                                    anchors.verticalCenter: wifiNetworkTileBody.verticalCenter
                                    spacing: 4

                                    Text {
                                        width: parent.width
                                        text: wifiNetworkTile.modelData.ssid
                                        color: root.themeText
                                        font.pixelSize: root.embedded ? 9 : 10
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: wifiNetworkTile.modelData.inUse
                                            ? "CONNECTED"
                                            : (wifiNetworkTile.modelData.saved
                                                ? "SAVED NETWORK"
                                                : (wifiNetworkTile.modelData.security === "--"
                                                    ? "OPEN NETWORK" : "SECURED NETWORK"))
                                        color: wifiNetworkTile.modelData.inUse ? root.themeText : root.themeMutedText
                                        font.pixelSize: 7
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 0.55
                                    }
                                }

                                Column {
                                    id: wifiSignalInfo
                                    anchors.right: wifiOptionsButton.left
                                    anchors.rightMargin: 6
                                    anchors.verticalCenter: wifiNetworkTileBody.verticalCenter
                                    width: 34
                                    spacing: 3

                                    Text {
                                        width: parent.width
                                        text: wifiNetworkTile.modelData.signal + "%"
                                        color: root.themeSecondaryText
                                        font.pixelSize: 8
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    Row {
                                        width: parent.width
                                        height: 11
                                        spacing: 3

                                        Repeater {
                                            model: [3, 5, 8, 11]

                                            delegate: Rectangle {
                                                required property int modelData
                                                required property int index
                                                width: 6
                                                height: modelData
                                                anchors.bottom: parent.bottom
                                                radius: 2
                                                color: wifiNetworkTile.modelData.signal >= (index + 1) * 25
                                                    ? root.themeAction : root.themeBorder
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    id: wifiOptionsButton
                                    width: 25
                                    height: 27
                                    radius: 8
                                    anchors.right: wifiNetworkTileBody.right
                                    anchors.rightMargin: 6
                                    anchors.verticalCenter: wifiNetworkTileBody.verticalCenter
                                    color: wifiOptionsMouse.containsMouse ? root.themeHover : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "⋮"
                                        color: root.themeSecondaryText
                                        font.pixelSize: 18
                                        font.weight: Font.DemiBold
                                    }

                                    MouseArea {
                                        id: wifiOptionsMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.wifiActionMenuSsid =
                                            wifiNetworkTile.menuOpen ? "" : wifiNetworkTile.modelData.ssid
                                    }
                                }

                                Rectangle {
                                    id: wifiNetworkActionMenu
                                    visible: wifiNetworkTile.menuOpen
                                    x: parent.width - width
                                    y: wifiNetworkTile.tileHeight + 4
                                    width: 140
                                    height: wifiNetworkTile.menuHeight
                                    z: 20
                                    radius: 11
                                    color: root.themeSurface
                                    border.width: 1
                                    border.color: root.themeBorder

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        spacing: 2

                                        Rectangle {
                                            id: wifiDisconnectButton
                                            width: parent.width
                                            height: 28
                                            radius: 7
                                            color: wifiNetworkActionMouse.containsMouse ? root.themeHover : "transparent"

                                            Text {
                                                anchors.left: parent.left
                                                anchors.leftMargin: 9
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: wifiNetworkTile.modelData.inUse ? "Disconnect" : "Connect"
                                                color: root.themeText
                                                font.pixelSize: 9
                                                font.weight: Font.Medium
                                            }

                                            MouseArea {
                                                id: wifiNetworkActionMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    const network = wifiNetworkTile.modelData
                                                    root.wifiActionMenuSsid = ""
                                                    if (network.inUse) {
                                                        root.run(["wifi", "disconnect"])
                                                    } else {
                                                        root.selectWifiNetwork(network)
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle {
                                            visible: wifiNetworkTile.modelData.saved
                                            width: parent.width
                                            height: visible ? 28 : 0
                                            radius: 7
                                            color: wifiForgetMouse.containsMouse ? root.themeHover : "transparent"

                                            Text {
                                                anchors.left: parent.left
                                                anchors.leftMargin: 9
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Forget network"
                                                color: root.themeText
                                                font.pixelSize: 9
                                                font.weight: Font.Medium
                                            }

                                            MouseArea {
                                                id: wifiForgetMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                enabled: wifiNetworkTile.modelData.saved
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    const ssid = wifiNetworkTile.modelData.ssid
                                                    root.wifiActionMenuSsid = ""
                                                    root.run(["wifi", "forget", ssid])
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: bluetoothView
            anchors.top: root.embedded ? parent.top : header.bottom
            anchors.topMargin: root.embedded ? 0 : 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            visible: root.mode === "bluetooth"
            clip: true

            Column {
                id: bluetoothLayout
                anchors.fill: parent
                spacing: root.embedded ? 8 : 12

                Rectangle {
                    id: bluetoothStatusCard
                    width: parent.width
                    height: root.embedded ? 68 : 88
                    radius: 15
                    color: root.themeSubtle
                    border.width: 1
                    border.color: root.themeBorder

                    Rectangle {
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.embedded ? 39 : 48
                        height: width
                        radius: 12
                        color: root.themeSurface

                        Image {
                            anchors.centerIn: parent
                            width: root.embedded ? 20 : 24
                            height: width
                            source: Qt.resolvedUrl("../assets/icons/lucide-bluetooth-refined-dark.svg")
                            sourceSize.width: 48
                            sourceSize.height: 48
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1
                                colorizationColor: root.themeIcon
                            }
                        }
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: root.embedded ? 59 : 72
                        anchors.right: bluetoothPowerButton.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            width: parent.width
                            text: root.bluetoothState === "on"
                                ? "Bluetooth is ready"
                                : root.bluetoothState === "off" ? "Bluetooth is off" : "Bluetooth unavailable"
                            color: root.themeText
                            font.pixelSize: root.embedded ? 10 : 13
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Row {
                            width: parent.width
                            spacing: 5

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 6
                                height: 6
                                radius: 3
                                color: root.bluetoothState === "on"
                                    ? root.themeSuccess : root.themeMutedText
                            }

                            Text {
                                width: parent.width - 11
                                text: root.bluetoothState !== "on"
                                    ? "Turn Bluetooth on to discover devices"
                                    : (root.bluetoothScanning
                                        ? "Searching nearby devices…"
                                        : root.bluetoothDevices.length
                                            + (root.bluetoothDevices.length === 1
                                                ? " device available" : " devices available"))
                                color: root.themeSecondaryText
                                font.pixelSize: root.embedded ? 7 : 9
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Rectangle {
                        id: bluetoothPowerButton
                        anchors.right: parent.right
                        anchors.rightMargin: 9
                        anchors.top: parent.top
                        anchors.topMargin: root.embedded ? 6 : 10
                        width: root.embedded ? 74 : 82
                        height: root.embedded ? 26 : 30
                        radius: 9
                        color: bluetoothPowerMouse.containsMouse
                            ? Qt.darker(root.themeAction, 1.08) : root.themeAction
                        border.width: 1
                        border.color: root.themeAction

                        Text {
                            anchors.centerIn: parent
                            text: root.bluetoothState === "on" ? "Turn off" : "Turn on"
                            color: root.themeActionText
                            font.pixelSize: root.embedded ? 8 : 9
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: bluetoothPowerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.run(["bluetooth", "toggle"])
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 9
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: root.embedded ? 6 : 10
                        width: root.embedded ? 74 : 82
                        height: root.embedded ? 20 : 24
                        radius: 8
                        visible: root.bluetoothScanning && root.bluetoothState === "on"
                        color: bluetoothStopMouse.containsMouse ? root.themeHover : root.themeSurface
                        border.width: 1
                        border.color: root.themeBorder

                        Text {
                            anchors.centerIn: parent
                            text: "Stop scan"
                            color: root.themeText
                            font.pixelSize: root.embedded ? 7 : 8
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: bluetoothStopMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.stopBluetoothScan()
                        }
                    }
                }

                Row {
                    id: bluetoothHeading
                    width: parent.width
                    height: root.embedded ? 32 : 38
                    spacing: 8

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - bluetoothRefreshButton.width - parent.spacing
                        spacing: 3

                        Text {
                            width: parent.width
                            text: "Nearby devices"
                            color: root.themeText
                            font.pixelSize: root.embedded ? 10 : 12
                            font.weight: Font.DemiBold
                        }

                        Text {
                            width: parent.width
                            text: root.bluetoothScanning
                                ? "Searching for discoverable devices…"
                                : root.bluetoothDevices.length
                                    + (root.bluetoothDevices.length === 1
                                        ? " device found" : " devices found")
                            color: root.themeMutedText
                            font.pixelSize: root.embedded ? 7 : 8
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        id: bluetoothRefreshButton
                        width: root.embedded ? 32 : 36
                        height: root.embedded ? 30 : 34
                        radius: 10
                        anchors.verticalCenter: parent.verticalCenter
                        color: bluetoothRefreshMouse.containsMouse
                            ? Qt.darker(root.themeAction, 1.08) : root.themeAction
                        border.width: 1
                        border.color: root.themeAction
                        opacity: root.bluetoothState === "on" ? 1 : 0.45

                        Image {
                            anchors.centerIn: parent
                            width: root.embedded ? 15 : 17
                            height: width
                            source: Qt.resolvedUrl("../assets/icons/lucide-rotate-cw-clean.svg")
                            sourceSize.width: 36
                            sourceSize.height: 36
                            smooth: true
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1
                                colorizationColor: root.themeActionText
                            }

                            RotationAnimation on rotation {
                                from: 0
                                to: 360
                                duration: 760
                                loops: Animation.Infinite
                                running: root.bluetoothScanning
                            }
                        }

                        MouseArea {
                            id: bluetoothRefreshMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: root.bluetoothState === "on"
                                && root.bluetoothActionMac.length === 0
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (root.bluetoothScanning)
                                    root.stopBluetoothScan()
                                else
                                    root.startBluetoothScan()
                            }
                        }
                    }
                }

                Flickable {
                    id: bluetoothDeviceList
                    width: parent.width
                    height: Math.max(0, bluetoothView.height
                        - bluetoothStatusCard.height - bluetoothHeading.height
                        - bluetoothLayout.spacing * 2)
                    clip: true
                    contentHeight: bluetoothColumn.height
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick

                    Column {
                        id: bluetoothColumn
                        width: bluetoothDeviceList.width
                        spacing: 6

                        Item {
                            width: bluetoothColumn.width
                            height: root.bluetoothDevices.length === 0
                                ? Math.min(112, bluetoothDeviceList.height) : 0
                            visible: root.bluetoothDevices.length === 0

                            Column {
                                anchors.centerIn: parent
                                spacing: 7

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 32
                                    height: 32
                                    radius: 10
                                    color: root.themeSurface
                                    border.width: 1
                                    border.color: root.themeBorder

                                    Image {
                                        anchors.centerIn: parent
                                        width: 16
                                        height: 16
                                        source: Qt.resolvedUrl("../assets/icons/lucide-bluetooth-refined-dark.svg")
                                        sourceSize.width: 32
                                        sourceSize.height: 32
                                        smooth: true
                                        layer.enabled: true
                                        layer.effect: MultiEffect {
                                            colorization: 1
                                            colorizationColor: root.themeIcon
                                        }
                                    }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.bluetoothState !== "on"
                                        ? "Bluetooth is turned off"
                                        : (root.bluetoothScanning
                                            ? "Looking for nearby devices" : "No devices found yet")
                                    color: root.themeSecondaryText
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.bluetoothState !== "on"
                                        ? "Turn it on to discover accessories."
                                        : (root.bluetoothScanning
                                            ? "Put your accessory in pairing mode." : "Tap scan to search again.")
                                    color: root.themeMutedText
                                    font.pixelSize: 8
                                }
                            }
                        }

                        Repeater {
                            model: root.bluetoothDevices

                            delegate: Rectangle {
                                id: bluetoothDeviceTile
                                required property var modelData
                                width: bluetoothColumn.width
                                height: root.embedded ? 54 : 64
                                radius: 12
                                color: btMouse.containsMouse
                                    ? root.themeHover
                                    : (bluetoothDeviceTile.modelData.connected
                                        ? root.themeSelected : root.themeSurface)
                                border.width: bluetoothDeviceTile.modelData.connected ? 1.3 : 1
                                border.color: bluetoothDeviceTile.modelData.connected
                                    ? root.themeAction : root.themeBorder

                                Rectangle {
                                    x: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: root.embedded ? 28 : 34
                                    height: width
                                    radius: 9
                                    color: root.themeSubtle
                                    border.width: 1
                                    border.color: root.themeBorder

                                    Image {
                                        anchors.centerIn: parent
                                        width: root.embedded ? 15 : 18
                                        height: width
                                        source: Qt.resolvedUrl("../assets/icons/lucide-bluetooth-refined-dark.svg")
                                        sourceSize.width: 36
                                        sourceSize.height: 36
                                        smooth: true
                                        layer.enabled: true
                                        layer.effect: MultiEffect {
                                            colorization: 1
                                            colorizationColor: bluetoothDeviceTile.modelData.connected
                                                ? root.themeAction : root.themeIcon
                                        }
                                    }
                                }

                                Text {
                                    x: root.embedded ? 44 : 52
                                    y: root.embedded ? 9 : 12
                                    width: parent.width - (root.embedded ? 130 : 155)
                                    text: bluetoothDeviceTile.modelData.name
                                    color: root.themeText
                                    font.pixelSize: root.embedded ? 9 : 10
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    x: root.embedded ? 44 : 52
                                    y: root.embedded ? 29 : 34
                                    width: parent.width - (root.embedded ? 130 : 155)
                                    text: bluetoothDeviceTile.modelData.connected
                                        ? "CONNECTED"
                                        : (bluetoothDeviceTile.modelData.paired
                                            ? (bluetoothDeviceTile.modelData.trusted
                                                ? "PAIRED · TRUSTED" : "PAIRED")
                                            : "AVAILABLE NEARBY")
                                    color: bluetoothDeviceTile.modelData.connected
                                        ? root.themeSuccess : root.themeMutedText
                                    font.pixelSize: root.embedded ? 6 : 7
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.45
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    id: bluetoothDeviceAction
                                    anchors.right: parent.right
                                    anchors.rightMargin: root.embedded ? 7 : 9
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: root.embedded ? 66 : 78
                                    height: root.embedded ? 26 : 30
                                    radius: 9
                                    color: bluetoothDeviceTile.modelData.connected
                                        ? root.themeSurface
                                        : (root.bluetoothActionMac === bluetoothDeviceTile.modelData.mac
                                            ? root.themeMutedText : root.themeAction)
                                    border.width: bluetoothDeviceTile.modelData.connected ? 1 : 0
                                    border.color: root.themeBorder

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.bluetoothActionMac === bluetoothDeviceTile.modelData.mac
                                            ? (root.bluetoothActionVerb === "pair" ? "Pairing…"
                                                : root.bluetoothActionVerb === "connect" ? "Connecting…"
                                                : "Disconnecting…")
                                            : (bluetoothDeviceTile.modelData.connected ? "Disconnect"
                                                : bluetoothDeviceTile.modelData.paired ? "Connect" : "Pair")
                                        color: bluetoothDeviceTile.modelData.connected
                                            ? root.themeText : root.themeActionText
                                        font.pixelSize: root.embedded ? 7 : 8
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: root.bluetoothActionMac.length === 0
                                        onClicked: {
                                            const action = bluetoothDeviceTile.modelData.connected
                                                ? "disconnect"
                                                : bluetoothDeviceTile.modelData.paired ? "connect" : "pair"
                                            root.runBluetoothDeviceAction(action,
                                                bluetoothDeviceTile.modelData.mac)
                                        }
                                    }
                                }

                                MouseArea {
                                    id: btMouse
                                    anchors.fill: parent
                                    z: -1
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: simpleView
            anchors.top: header.bottom
            anchors.topMargin: root.mode === "battery" ? 6 : 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            visible: root.mode !== "wifi" && root.mode !== "bluetooth"

            Column {
                anchors.fill: parent
                spacing: root.mode === "battery" ? 8 : 12

                Rectangle {
                    width: parent.width
                    height: root.mode === "battery" ? 78 : 100
                    radius: root.mode === "battery" ? 14 : 18
                    color: root.tile
                    border.width: 1
                    border.color: root.border

                    Image {
                        x: root.mode === "battery" ? 15 : 20
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.mode === "battery" ? 20 : 23
                        height: root.mode === "battery" ? 20 : 23
                        source: {
                            switch (root.mode) {
                            case "audio": return root.iconSource("volume-2")
                            case "brightness": return root.iconSource("sun")
                            case "night-light": return root.iconSource("moon")
                            case "battery": return root.iconSource("battery")
                            case "dnd": return root.iconSource("bell-off")
                            default: return ""
                            }
                        }
                    }

                    Column {
                        x: root.mode === "battery" ? 47 : 58
                        y: root.mode === "battery" ? 10 : 19
                        width: root.mode === "battery" ? parent.width - 61 : implicitWidth
                        spacing: root.mode === "battery" ? 2 : 4

                        Text {
                            text: {
                                switch (root.mode) {
                                case "audio": return root.audioMuted ? "Muted" : root.audioPercent + "%"
                                case "brightness": return root.brightnessPercent + "%"
                                case "night-light": return root.nightLightEnabled ? "Night Light Active" : "Night Light Off"
                                case "battery": return root.batteryPercent + "%"
                                case "dnd": return root.dndEnabled ? "Focus Mode Active" : "Notifications On"
                                default: return "—"
                                }
                            }
                            color: root.textPrimary
                            font.pixelSize: root.mode === "battery" ? 18 : 15
                            font.weight: Font.DemiBold
                        }

                        Text {
                            width: root.mode === "battery" ? parent.width : implicitWidth
                            elide: Text.ElideRight
                            text: {
                                switch (root.mode) {
                                case "audio": return root.audioSink
                                case "brightness": return "Display brightness"
                                case "night-light": return root.nightLightTemperature + "  •  " + root.nightLightSchedule
                                case "battery": return root.batteryState.toUpperCase() + "  •  " + root.batteryCapacity
                                case "dnd": return "A16EEN notification toasts are suppressed"
                                default: return ""
                                }
                            }
                            color: root.textSecondary
                            font.pixelSize: root.mode === "battery" ? 8 : 9
                            font.letterSpacing: 0.4
                        }
                    }

                    Rectangle {
                        visible: root.mode === "battery"
                        x: 47
                        y: 60
                        width: parent.width - 62
                        height: 4
                        radius: 2
                        color: "#E8EBEF"

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(100, root.batteryPercent)) / 100
                            height: parent.height
                            radius: 2
                            color: root.batteryPercent <= 10 ? "#D84A4F" : root.accent
                        }
                    }
                }

                Rectangle {
                    visible: root.mode === "audio" || root.mode === "brightness"
                    width: parent.width
                    height: 124
                    radius: 18
                    color: root.page
                    border.width: 1
                    border.color: root.border

                    Text {
                        x: 18
                        y: 16
                        text: root.mode === "audio" ? "OUTPUT LEVEL" : "DISPLAY LEVEL"
                        color: root.textPrimary
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.0
                    }

                    Rectangle {
                        x: 18
                        y: 49
                        width: parent.width - 36
                        height: 7
                        radius: 4
                        color: "#E8EBEF"

                        Rectangle {
                            width: parent.width * (
                                root.mode === "audio"
                                    ? root.audioPercent / 100
                                    : root.brightnessPercent / 100
                            )
                            height: parent.height
                            radius: 4
                            color: root.accent
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onPressed: {
                                const value = (mouse.x / width) * 100
                                if (root.mode === "audio")
                                    root.setAudio(value)
                                else
                                    root.setBrightness(value)
                            }
                            onPositionChanged: {
                                if (pressed) {
                                    const value = (mouse.x / width) * 100
                                    if (root.mode === "audio")
                                        root.setAudio(value)
                                    else
                                        root.setBrightness(value)
                                }
                            }
                        }
                    }

                    Row {
                        x: 18
                        y: 78
                        width: parent.width - 36
                        height: 30
                        spacing: 7

                        Repeater {
                            model: [25, 50, 75, 100]
                            delegate: Rectangle {
                                width: (parent.width - 21) / 4
                                height: 30
                                radius: 9
                                color: "#FFFFFF"
                                border.width: 1
                                border.color: root.border
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData + "%"
                                    color: root.textSecondary
                                    font.pixelSize: 7
                                    font.weight: Font.DemiBold
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.mode === "audio")
                                            root.setAudio(modelData)
                                        else
                                            root.setBrightness(modelData)
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    visible: root.mode === "audio"
                    width: parent.width
                    height: 74
                    radius: 18
                    color: root.tile
                    border.width: 1
                    border.color: root.border

                    Text {
                        x: 18
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.audioMuted ? "UNMUTE OUTPUT" : "MUTE OUTPUT"
                        color: root.textPrimary
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.8
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.run(["audio", "toggle"])
                    }
                }

                Rectangle {
                    visible: root.mode === "night-light"
                    width: parent.width
                    height: 74
                    radius: 18
                    color: root.tile
                    border.width: 1
                    border.color: root.border

                    Text {
                        x: 18
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.nightLightEnabled ? "TURN NIGHT LIGHT OFF" : "TURN NIGHT LIGHT ON"
                        color: root.textPrimary
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.8
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.run(["night-light", "toggle"])
                    }
                }

                Rectangle {
                    visible: root.mode === "battery"
                    width: parent.width
                    height: 82
                    radius: 14
                    color: root.tile
                    border.width: 1
                    border.color: root.border

                    Column {
                        x: 14
                        y: 9
                        spacing: 3
                        Text { text: "TIME REMAINING"; color: root.textMuted; font.pixelSize: 7; font.weight: Font.DemiBold; font.letterSpacing: 0.8 }
                        Text { text: root.batteryTime; color: root.textPrimary; font.pixelSize: 12; font.weight: Font.DemiBold }
                        Text { text: "ENERGY RATE   " + root.batteryRate; color: root.textSecondary; font.pixelSize: 8 }
                        Text { text: "HEALTH          " + root.batteryCapacity; color: root.textSecondary; font.pixelSize: 8 }
                    }
                }

                Rectangle {
                    id: batteryAlertsCard
                    visible: root.mode === "battery"
                    width: parent.width
                    height: 130
                    radius: 14
                    color: root.page
                    border.width: 1
                    border.color: root.border

                    Column {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 3

                        Row {
                            width: parent.width
                            height: 15
                            spacing: 4

                            Text {
                                text: "BATTERY ALERTS"
                                color: root.textPrimary
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.7
                            }

                            Item { width: Math.max(0, parent.width - 160); height: 1 }

                            Text {
                                text: "ON BATTERY"
                                color: root.textMuted
                                font.pixelSize: 6
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.5
                            }
                        }

                        Repeater {
                            model: [
                                { id: "warning", label: "LOW", description: "First warning", percent: root.batteryWarningPercent, enabled: root.batteryWarningEnabled },
                                { id: "critical", label: "VERY LOW", description: "Second warning", percent: root.batteryCriticalPercent, enabled: root.batteryCriticalEnabled },
                                { id: "emergency", label: "CRITICAL", description: "Urgent warning", percent: root.batteryEmergencyPercent, enabled: root.batteryEmergencyEnabled }
                            ]

                            delegate: Row {
                                id: batteryAlertRow
                                required property var modelData
                                width: parent.width
                                height: 23
                                spacing: 4

                                Column {
                                    width: 78
                                    height: parent.height
                                    spacing: 0
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        text: batteryAlertRow.modelData.label
                                        color: root.textPrimary
                                        font.pixelSize: 7
                                        font.weight: Font.DemiBold
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    Text {
                                        text: batteryAlertRow.modelData.description
                                        color: root.textMuted
                                        font.pixelSize: 6
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: root.tile
                                    border.width: 1
                                    border.color: root.border

                                    Text {
                                        anchors.centerIn: parent
                                        text: "−"
                                        color: root.textSecondary
                                        font.pixelSize: 12
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.changeBatteryWarningThreshold(batteryAlertRow.modelData.id, -1)
                                    }
                                }

                                Text {
                                    width: 28
                                    height: parent.height
                                    text: batteryAlertRow.modelData.percent + "%"
                                    color: root.textPrimary
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: root.tile
                                    border.width: 1
                                    border.color: root.border

                                    Text {
                                        anchors.centerIn: parent
                                        text: "+"
                                        color: root.textSecondary
                                        font.pixelSize: 11
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.changeBatteryWarningThreshold(batteryAlertRow.modelData.id, 1)
                                    }
                                }

                                Item {
                                    width: Math.max(0, parent.width - 78 - 20 - 28 - 20 - 34 - 20)
                                    height: 1
                                }

                                Rectangle {
                                    width: 34
                                    height: 18
                                    radius: 9
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: batteryAlertRow.modelData.enabled ? "#242B35" : "#E7EAEE"
                                    border.width: 1
                                    border.color: batteryAlertRow.modelData.enabled ? "#242B35" : root.border

                                    Rectangle {
                                        width: 12
                                        height: 12
                                        radius: 6
                                        y: 2
                                        x: batteryAlertRow.modelData.enabled ? 18 : 2
                                        color: "#FFFFFF"

                                        Behavior on x {
                                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.toggleBatteryWarning(batteryAlertRow.modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    visible: root.mode === "dnd"
                    width: parent.width
                    height: 110
                    radius: 18
                    color: root.tile
                    border.width: 1
                    border.color: root.border

                    Column {
                        x: 18
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5
                        Text {
                            text: root.dndEnabled ? "FOCUS MODE ACTIVE" : "NOTIFICATIONS ON"
                            color: root.textPrimary
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: "A16EEN notification toasts are " + (root.dndEnabled ? "suppressed." : "allowed.")
                            color: root.textSecondary
                            font.pixelSize: 9
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        width: 88
                        height: 34
                        radius: 10
                        color: root.dndEnabled ? "#111318" : "#FFFFFF"
                        border.width: root.dndEnabled ? 0 : 1
                        border.color: root.borderStrong

                        Text {
                            anchors.centerIn: parent
                            text: root.dndEnabled ? "TURN OFF" : "TURN ON"
                            color: root.dndEnabled ? "#FFFFFF" : root.textPrimary
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.doNotDisturbRequested(!root.dndEnabled)
                        }
                    }
                }
            }
        }
    }

    Keys.onEscapePressed: root.backRequested()

    focus: root.active
    activeFocusOnTab: true
}