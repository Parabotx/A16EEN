import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool active: false
    property bool doNotDisturb: false

    signal backRequested()
    signal doNotDisturbRequested(bool enabled)
    signal batteryRequested()

    property string wifiState: "unavailable"
    property string wifiName: "Not connected"
    property string bluetoothState: "unavailable"
    property int audioPercent: 0
    property bool audioMuted: false
    property int brightnessPercent: 0
    property int batteryPercent: 0
    property string batteryState: "unknown"
    property bool batteryAvailable: false
    property bool nightLightEnabled: false
    property string statusMessage: "READING SYSTEM"

    readonly property color page: "#08090B"
    readonly property color tile: "#0D0F12"
    readonly property color tileHover: "#12151A"
    readonly property color tileActive: "#151A20"
    readonly property color border: "#1C2026"
    readonly property color textPrimary: "#F5F7FA"
    readonly property color textSecondary: "#8E98A7"
    readonly property color textMuted: "#515A67"
    readonly property color accent: "#D7B56D"

    function iconSource(name) {
        return Qt.resolvedUrl("../assets/icons/lucide-" + name + ".svg")
    }

    function normalizeState(value) {
        const state = String(value || "").trim().toLowerCase()
        if (state === "enabled" || state === "on" || state === "connected")
            return "on"
        if (state === "disabled" || state === "off" || state === "disconnected")
            return "off"
        return "unavailable"
    }

    function parseSnapshot(output) {
        const lines = String(output || "").split("\n")

        for (const rawLine of lines) {
            const index = rawLine.indexOf("=")
            if (index < 0)
                continue

            const key = rawLine.slice(0, index).trim()
            const value = rawLine.slice(index + 1).trim()

            switch (key) {
            case "wifi":
                root.wifiState = root.normalizeState(value)
                break
            case "wifi_name":
                root.wifiName = value || "Not connected"
                break
            case "bluetooth":
                root.bluetoothState = root.normalizeState(value)
                break
            case "audio":
                if (/^[0-9]+$/.test(value))
                    root.audioPercent = Math.max(0, Math.min(100, Number(value)))
                else
                    root.audioPercent = 0
                break
            case "audio_muted":
                root.audioMuted = value === "1"
                break
            case "brightness":
                if (/^[0-9]+$/.test(value))
                    root.brightnessPercent = Math.max(0, Math.min(100, Number(value)))
                else
                    root.brightnessPercent = 0
                break
            case "battery":
                root.batteryAvailable = /^[0-9]+$/.test(value)
                root.batteryPercent = root.batteryAvailable
                    ? Math.max(0, Math.min(100, Number(value)))
                    : 0
                break
            case "battery_state":
                root.batteryState = value || "unknown"
                break
            case "night_light":
                root.nightLightEnabled = root.normalizeState(value) === "on"
                break
            case "dnd":
                break
            }
        }

        root.statusMessage = "SYSTEM READY"
    }

    function refresh() {
        if (!root.active || statusReader.running)
            return

        root.statusMessage = "UPDATING"
        statusReader.running = true
    }

    function runAction(args) {
        if (!args || !args.length || actionProcess.running)
            return

        root.statusMessage = "APPLYING"
        actionArgs = args
        actionProcess.running = true
    }

    function adjustBrightness(value) {
        if (root.brightnessPercent < 0)
            return

        const next = Math.max(0, Math.min(100, Math.round(value)))
        root.runAction(["brightness", "set", String(next)])
    }

    function stateLabel(state) {
        switch (state) {
        case "on": return "ON"
        case "off": return "OFF"
        default: return "UNAVAILABLE"
        }
    }

    function batteryLabel() {
        if (!root.batteryAvailable)
            return "AC POWER"

        if (root.batteryState === "charging")
            return "CHARGING"

        if (root.batteryState === "fully-charged")
            return "FULL"

        return "ON BATTERY"
    }

    function addPressFeedback(target) {
        target.scale = 0.985
        Qt.callLater(() => target.scale = 1.0)
    }

    Process {
        id: statusReader
        command: ["a16een-control", "snapshot"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.parseSnapshot(text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length)
                    root.statusMessage = "CONTROL SERVICE UNAVAILABLE"
            }
        }

        onRunningChanged: {
            if (!running && root.active && root.statusMessage === "UPDATING")
                root.statusMessage = "SYSTEM READY"
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
            if (!running) {
                refreshTimer.restart()
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 180
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        id: pollTimer
        interval: 2500
        repeat: true
        running: root.active
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()

    Item {
        anchors.fill: parent
        anchors.margins: 26

        Row {
            id: header
            width: parent.width
            height: 54
            spacing: 14

            Rectangle {
                width: 38
                height: 38
                radius: 11
                color: "#101318"
                border.width: 1
                border.color: root.border
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    source: root.iconSource("arrow-left")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backRequested()
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    text: "SYSTEM CONTROLS"
                    color: root.textPrimary
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.3
                }

                Text {
                    text: root.statusMessage + "  •  ESC TO CLOSE"
                    color: root.textMuted
                    font.pixelSize: 8
                    font.weight: Font.Medium
                    font.letterSpacing: 1.0
                }
            }
        }

        Grid {
            id: controlGrid
            anchors.top: header.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width, 820)
            height: parent.height - header.height - 12
            columns: 4
            rows: 2
            columnSpacing: 12
            rowSpacing: 12

            Repeater {
                model: [
                    { key: "wifi", label: "Wi-Fi", icon: "wifi" },
                    { key: "bluetooth", label: "Bluetooth", icon: "bluetooth" },
                    { key: "audio", label: "Audio", icon: "volume-2" },
                    { key: "brightness", label: "Brightness", icon: "sun" },
                    { key: "night", label: "Night Light", icon: "moon" },
                    { key: "battery", label: "Battery", icon: "battery" },
                    { key: "dnd", label: "Do Not Disturb", icon: "bell-off" }
                ]

                delegate: Rectangle {
                    id: controlTile
                    width: (controlGrid.width - 36) / 4
                    height: (controlGrid.height - 12) / 2
                    radius: 17
                    color: {
                        const active = modelData.key === "dnd"
                            ? root.doNotDisturb
                            : modelData.key === "night"
                                ? root.nightLightEnabled
                                : modelData.key === "wifi"
                                    ? root.wifiState === "on"
                                    : modelData.key === "bluetooth"
                                        ? root.bluetoothState === "on"
                                        : modelData.key === "audio"
                                            ? !root.audioMuted
                                            : modelData.key === "brightness"
                                                ? root.brightnessPercent > 0
                                                : root.batteryAvailable
                        return tileMouse.containsMouse
                            ? root.tileHover
                            : active
                                ? root.tileActive
                                : root.tile
                    }
                    border.width: 1
                    border.color: {
                        const active = modelData.key === "dnd"
                            ? root.doNotDisturb
                            : modelData.key === "night"
                                ? root.nightLightEnabled
                                : modelData.key === "wifi"
                                    ? root.wifiState === "on"
                                    : modelData.key === "bluetooth"
                                        ? root.bluetoothState === "on"
                                        : modelData.key === "audio"
                                            ? !root.audioMuted
                                            : modelData.key === "brightness"
                                                ? root.brightnessPercent > 0
                                                : root.batteryAvailable
                        return active ? "#2B3038" : root.border
                    }

                    scale: 1.0
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }
                    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

                    Image {
                        id: tileIcon
                        x: 16
                        y: 16
                        width: 19
                        height: 19
                        source: root.iconSource(modelData.icon)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        opacity: 0.92
                    }

                    Text {
                        x: 16
                        y: 43
                        width: parent.width - 32
                        text: modelData.label.toUpperCase()
                        color: root.textPrimary
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.8
                        elide: Text.ElideRight
                    }

                    Text {
                        x: 16
                        y: 65
                        width: parent.width - 32
                        color: root.textSecondary
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        text: {
                            switch (modelData.key) {
                            case "wifi": return root.wifiName
                            case "bluetooth": return root.stateLabel(root.bluetoothState)
                            case "audio": return root.audioMuted ? "MUTED • " + root.audioPercent + "%" : root.audioPercent + "%"
                            case "brightness": return root.brightnessPercent + "%"
                            case "night": return root.nightLightEnabled ? "4000K • ACTIVE" : "6500K • OFF"
                            case "battery": return root.batteryAvailable ? root.batteryPercent + "% • " + root.batteryLabel() : "AC POWER"
                            case "dnd": return root.doNotDisturb ? "FOCUSING • MUTED" : "NOTIFICATIONS ON"
                            default: return "—"
                            }
                        }
                    }

                    Rectangle {
                        id: meterTrack
                        visible: modelData.key === "audio" || modelData.key === "brightness" || modelData.key === "battery"
                        x: 16
                        y: parent.height - 25
                        width: parent.width - 32
                        height: 4
                        radius: 2
                        color: "#1A1E24"

                        Rectangle {
                            width: parent.width * (
                                modelData.key === "audio"
                                    ? root.audioPercent / 100
                                    : modelData.key === "brightness"
                                        ? root.brightnessPercent / 100
                                        : root.batteryPercent / 100
                            )
                            height: parent.height
                            radius: 2
                            color: root.accent
                        }
                    }

                    MouseArea {
                        id: brightnessMouse
                        visible: modelData.key === "brightness"
                        x: 16
                        y: parent.height - 48
                        width: parent.width - 32
                        height: 30
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.PointingHandCursor
                        onPressed: root.adjustBrightness((mouse.x / width) * 100)
                    }

                    MouseArea {
                        id: tileMouse
                        anchors.fill: parent
                        z: 1
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.addPressFeedback(controlTile)

                            switch (modelData.key) {
                            case "wifi":
                                root.runAction(["wifi", "toggle"])
                                break
                            case "bluetooth":
                                root.runAction(["bluetooth", "toggle"])
                                break
                            case "audio":
                                root.runAction(["audio", "toggle"])
                                break
                            case "brightness":
                                break
                            case "night":
                                root.runAction(["night-light", "toggle"])
                                break
                            case "battery":
                                root.batteryRequested()
                                break
                            case "dnd":
                                root.doNotDisturbRequested(!root.doNotDisturb)
                                break
                            }
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
