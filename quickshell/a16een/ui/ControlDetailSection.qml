import QtQuick
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

    property string statusMessage: "READING SYSTEM"
    property string wifiState: "unavailable"
    property string wifiRadioState: "unavailable"
    property string wifiName: "Not connected"
    property string wifiDevice: "—"
    property var wifiNetworks: []
    property string wifiSelectedSsid: ""
    property string wifiSelectedSecurity: ""
    property string wifiPassword: ""
    property bool wifiConnecting: false

    property string bluetoothState: "unavailable"
    property var bluetoothDevices: []
    property bool bluetoothScanning: false

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
        if (root.mode === "wifi") {
            if (!wifiReader.running)
                wifiReader.running = true
            if (!wifiNetworksReader.running)
                wifiNetworksReader.running = true
        }
        if (root.mode === "bluetooth" && !bluetoothReader.running)
            bluetoothReader.running = true
    }

    function refreshVisibleMode() {
        root.loadDetails()
        if (root.mode === "wifi") {
            root.run(["wifi", "rescan"])
            wifiScanRefresh.restart()
        }
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

    function parseWifiNetworks(output) {
        const result = []
        const lines = String(output || "").split("\n")
        for (const raw of lines) {
            if (!raw.trim())
                continue
            const parts = raw.split("|")
            if (parts.length < 3)
                continue
            result.push({
                ssid: parts[0],
                signal: Number(parts[1]) || 0,
                security: parts[2] || "Open",
                inUse: parts.length > 3 && parts[3] === "*"
            })
        }
        root.wifiNetworks = result
    }

    function parseBluetoothDevices(output) {
        const result = []
        const state = root.parseKeyValue(output, "state")
        if (state.length)
            root.bluetoothState = root.normalizeState(state)
        const lines = String(output || "").split("\n")
        for (const raw of lines) {
            if (!raw.trim())
                continue
            const parts = raw.split("|")
            if (parts.length < 2)
                continue
            result.push({
                mac: parts[0],
                name: parts[1] || "Unknown device",
                connected: parts[2] === "yes",
                trusted: parts[3] === "yes"
            })
        }
        root.bluetoothDevices = result
    }

    function connectWifi() {
        if (!root.wifiSelectedSsid.length || (wifiPasswordInput.visible && !root.wifiPassword.length && root.wifiSelectedSecurity !== "--"))
            return
        root.wifiConnecting = true
        const password = root.wifiSelectedSecurity === "--" || root.wifiSelectedSecurity === "" ? "" : root.wifiPassword
        root.run(["wifi", "connect", root.wifiSelectedSsid, password])
    }

    function selectWifiNetwork(network) {
        root.wifiSelectedSsid = network.ssid
        root.wifiSelectedSecurity = network.security
        root.wifiPassword = ""
        if (network.security === "--" || network.security === "")
            root.connectWifi()
        else
            Qt.callLater(() => wifiPasswordInput.forceActiveFocus())
    }

    function setAudio(value) {
        root.run(["audio", "set", String(Math.round(Math.max(0, Math.min(100, value))))])
    }

    function setBrightness(value) {
        root.run(["brightness", "set", String(Math.round(Math.max(0, Math.min(100, value))))])
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
                wifiNetworksReader.running = true
            if (root.mode === "bluetooth")
                bluetoothReader.running = true
        }
    }

    Timer {
        id: wifiScanRefresh
        interval: 1400
        repeat: false
        onTriggered: wifiNetworksReader.running = true
    }

    Timer {
        id: bluetoothScanRefresh
        interval: 7200
        repeat: false
        onTriggered: {
            root.bluetoothScanning = false
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

            Rectangle {
                id: wifiStatusCard
                width: parent.width
                height: 100
                radius: 18
                color: root.tile
                border.width: 1
                border.color: root.border

                Image {
                    x: 20
                    y: 21
                    width: 22
                    height: 22
                    source: Qt.resolvedUrl("../assets/icons/lucide-wifi-dark.svg")
                    opacity: 0.84
                }

                Column {
                    x: 58
                    y: 17
                    spacing: 4

                    Text {
                        text: root.wifiName
                        color: root.textPrimary
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        text: (root.wifiState === "on" ? "CONNECTED" : "NOT CONNECTED") + "  •  " + root.wifiDevice
                        color: root.textSecondary
                        font.pixelSize: 9
                        font.letterSpacing: 0.8
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.wifiState === "on" ? 92 : 84
                    height: 34
                    radius: 10
                    color: "#FFFFFF"
                    border.width: 1
                    border.color: root.borderStrong

                    Text {
                        anchors.centerIn: parent
                        text: root.wifiState === "on"
                            ? "DISCONNECT"
                            : (root.wifiRadioState === "on" ? "TURN OFF" : "TURN ON")
                        color: root.textPrimary
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.8
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.wifiState === "on")
                                root.run(["wifi", "disconnect"])
                            else
                                root.run(["wifi", "toggle"])
                        }
                    }
                }
            }

            Row {
                anchors.top: wifiStatusCard.bottom
                anchors.topMargin: 12
                width: parent.width
                height: 34

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "AVAILABLE NETWORKS"
                    color: root.textPrimary
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.0
                }

                Item { width: parent.width - 190; height: 1 }

                Rectangle {
                    width: 74
                    height: 30
                    radius: 9
                    color: refreshWifiMouse.containsMouse ? root.tileHover : root.tile
                    border.width: 1
                    border.color: root.border
                    Text {
                        anchors.centerIn: parent
                        text: "REFRESH"
                        color: root.textSecondary
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.8
                    }
                    MouseArea {
                        id: refreshWifiMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.run(["wifi", "rescan"])
                            wifiScanRefresh.restart()
                        }
                    }
                }
            }

            Flickable {
                anchors.top: wifiStatusCard.bottom
                anchors.topMargin: 52
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                clip: true
                contentHeight: wifiColumn.height

                Column {
                    id: wifiColumn
                    width: parent.width
                    spacing: 7

                    Text {
                        width: parent.width
                        height: root.wifiNetworks.length === 0 ? 42 : 0
                        visible: root.wifiNetworks.length === 0
                        text: root.statusMessage === "READING SYSTEM"
                            ? "Finding nearby networks…"
                            : "No networks found. Refresh to scan again."
                        color: root.textMuted
                        font.pixelSize: 9
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Repeater {
                        model: root.wifiNetworks

                        delegate: Rectangle {
                            width: wifiColumn.width
                            height: 52
                            radius: 13
                            color: networkMouse.containsMouse || modelData.ssid === root.wifiSelectedSsid ? root.tileHover : root.tile
                            border.width: 1
                            border.color: modelData.inUse ? root.borderStrong : root.border

                            Text {
                                x: 15
                                y: 9
                                width: parent.width - 150
                                text: modelData.ssid
                                color: root.textPrimary
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                x: 15
                                y: 28
                                text: (modelData.security === "--" ? "OPEN" : modelData.security) + (modelData.inUse ? "  •  CONNECTED" : "")
                                color: root.textMuted
                                font.pixelSize: 7
                                font.letterSpacing: 0.7
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 15
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.signal + "%"
                                color: root.textSecondary
                                font.pixelSize: 9
                            }

                            MouseArea {
                                id: networkMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectWifiNetwork(modelData)
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: root.wifiSelectedSsid.length > 0 && root.wifiSelectedSecurity !== "--" && root.wifiSelectedSecurity !== ""
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: Math.min(parent.width - 30, 430)
                height: 80
                radius: 15
                color: "#FFFFFF"
                border.width: 1
                border.color: root.borderStrong

                Text {
                    x: 13
                    y: 10
                    text: "PASSWORD FOR " + root.wifiSelectedSsid
                    color: root.textMuted
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.8
                }

                TextInput {
                    id: wifiPasswordInput
                    x: 13
                    y: 30
                    width: parent.width - 105
                    height: 34
                    color: root.textPrimary
                    font.pixelSize: 11
                    echoMode: TextInput.Password
                    clip: true
                    text: root.wifiPassword
                    onTextChanged: root.wifiPassword = text
                    activeFocusOnPress: true
                    selectByMouse: true
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 76
                    height: 34
                    radius: 10
                    color: "#111318"

                    Text {
                        anchors.centerIn: parent
                        text: root.wifiConnecting ? "..." : "CONNECT"
                        color: "#FFFFFF"
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.connectWifi()
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

            Rectangle {
                width: parent.width
                height: 76
                radius: 17
                color: root.tile
                border.width: 1
                border.color: root.border

                Text {
                    x: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.bluetoothState === "on" ? "BLUETOOTH ON" : root.bluetoothState === "off" ? "BLUETOOTH OFF" : "UNAVAILABLE"
                    color: root.textPrimary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 86
                    height: 34
                    radius: 10
                    color: "#FFFFFF"
                    border.width: 1
                    border.color: root.borderStrong

                    Text {
                        anchors.centerIn: parent
                        text: root.bluetoothState === "on" ? "POWER OFF" : "POWER ON"
                        color: root.textPrimary
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.7
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.run(["bluetooth", "toggle"])
                    }
                }
            }

            Row {
                anchors.top: parent.top
                anchors.topMargin: 88
                width: parent.width
                height: 32

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "KNOWN DEVICES"
                    color: root.textPrimary
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.0
                }

                Item { width: parent.width - 155; height: 1 }

                Rectangle {
                    width: 75
                    height: 30
                    radius: 9
                    color: scanMouse.containsMouse ? root.tileHover : root.tile
                    border.width: 1
                    border.color: root.border
                    Text {
                        anchors.centerIn: parent
                        text: root.bluetoothScanning ? "SCANNING" : "SCAN"
                        color: root.textSecondary
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        id: scanMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.bluetoothScanning = true
                            root.run(["bluetooth", "scan"])
                            bluetoothScanRefresh.restart()
                        }
                    }
                }
            }

            Flickable {
                anchors.top: parent.top
                anchors.topMargin: 130
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                clip: true
                contentHeight: bluetoothColumn.height

                Column {
                    id: bluetoothColumn
                    width: parent.width
                    spacing: 7

                    Repeater {
                        model: root.bluetoothDevices
                        delegate: Rectangle {
                            width: bluetoothColumn.width
                            height: 58
                            radius: 13
                            color: btMouse.containsMouse ? root.tileHover : root.tile
                            border.width: 1
                            border.color: root.border

                            Text {
                                x: 15
                                y: 10
                                width: parent.width - 190
                                text: modelData.name
                                color: root.textPrimary
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                x: 15
                                y: 31
                                text: modelData.mac + (modelData.trusted ? "  •  TRUSTED" : "")
                                color: root.textMuted
                                font.pixelSize: 7
                                font.letterSpacing: 0.4
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: modelData.connected ? 15 : 82
                                anchors.verticalCenter: parent.verticalCenter
                                width: modelData.connected ? 84 : 66
                                height: 30
                                radius: 9
                                color: modelData.connected ? "#111318" : "#FFFFFF"
                                border.width: modelData.connected ? 0 : 1
                                border.color: root.borderStrong

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.connected ? "DISCONNECT" : "CONNECT"
                                    color: modelData.connected ? "#FFFFFF" : root.textPrimary
                                    font.pixelSize: 7
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.run(["bluetooth", modelData.connected ? "disconnect" : "connect", modelData.mac])
                                }
                            }

                            Rectangle {
                                visible: !modelData.connected && !modelData.trusted
                                anchors.right: parent.right
                                anchors.rightMargin: 15
                                anchors.verticalCenter: parent.verticalCenter
                                width: 58
                                height: 30
                                radius: 9
                                color: "#FFFFFF"
                                border.width: 1
                                border.color: root.border

                                Text {
                                    anchors.centerIn: parent
                                    text: "PAIR"
                                    color: root.textSecondary
                                    font.pixelSize: 7
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.run(["bluetooth", "pair", modelData.mac])
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
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            visible: root.mode !== "wifi" && root.mode !== "bluetooth"

            Column {
                anchors.fill: parent
                spacing: 12

                Rectangle {
                    width: parent.width
                    height: 100
                    radius: 18
                    color: root.tile
                    border.width: 1
                    border.color: root.border

                    Image {
                        x: 20
                        anchors.verticalCenter: parent.verticalCenter
                        width: 23
                        height: 23
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
                        x: 58
                        y: 19
                        spacing: 4

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
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }

                        Text {
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
                            font.pixelSize: 9
                            font.letterSpacing: 0.4
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
                    height: 142
                    radius: 18
                    color: root.tile
                    border.width: 1
                    border.color: root.border

                    Column {
                        x: 18
                        y: 16
                        spacing: 9
                        Text { text: "TIME REMAINING"; color: root.textMuted; font.pixelSize: 7; font.weight: Font.DemiBold; font.letterSpacing: 0.8 }
                        Text { text: root.batteryTime; color: root.textPrimary; font.pixelSize: 13; font.weight: Font.DemiBold }
                        Text { text: "ENERGY RATE   " + root.batteryRate; color: root.textSecondary; font.pixelSize: 8 }
                        Text { text: "HEALTH          " + root.batteryCapacity; color: root.textSecondary; font.pixelSize: 8 }
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