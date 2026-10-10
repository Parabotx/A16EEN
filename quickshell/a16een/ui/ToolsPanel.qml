import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: root

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
    readonly property int popupWidth: root.page === "data-meter" ? 360 : 322
    readonly property int popupHeight: root.page === "stash" ? 388
        : (root.page === "monitor" ? 310
        : (root.page === "calculator" ? 420 : (root.page === "data-meter" ? 390 : 316)))
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
        { id: "data-meter", label: "Data Meter", detail: "Daily internet usage and speed", icon: "lucide-activity.svg" }
    ]

    readonly property real popupX: root.horizontalNavbar
        ? root.screenWidth - root.popupWidth - 102
        : (root.navbarPosition === "left" ? 66 : root.screenWidth - root.popupWidth - 68)
    readonly property real popupY: root.horizontalNavbar
        ? (root.navbarPosition === "top" ? 40 : root.screenHeight - root.popupHeight - 40)
        : root.screenHeight - root.popupHeight - 72

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
        onClicked: root.closeRequested()
        Keys.onEscapePressed: root.closeRequested()
    }

    Item {
        id: card
        x: Math.max(8, Math.min(root.popupX, root.screenWidth - width - 8))
        y: Math.max(8, Math.min(root.popupY, root.screenHeight - height - 8)) + (root.opened ? 0 : 6)
        width: Math.min(root.popupWidth, root.screenWidth - 16)
        height: Math.min(root.popupHeight, root.screenHeight - 16)
        z: 1
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.985

        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: "#FFFFFF"
            border.width: 1
            border.color: "#D9DEE5"

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
                        color: "#F2F4F7"
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            source: Qt.resolvedUrl(root.page === "stash"
                                ? "../assets/icons/lucide-archive.svg"
                                : (root.page === "monitor"
                                    ? "../assets/icons/lucide-activity.svg"
                                    : (root.page === "calculator"
                                        ? "../assets/icons/lucide-calculator.svg"
                                        : (root.page === "data-meter"
                                            ? "../assets/icons/lucide-activity.svg"
                                            : "../assets/icons/lucide-toolbox.svg"))))
                            sourceSize.width: 48
                            sourceSize.height: 48
                            smooth: true
                        }
                    }

                    Column {
                        width: Math.max(0, parent.width - 28 - 16 - (root.page !== "tools" ? 25 : 0))
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            width: parent.width
                            text: root.page === "stash" ? "NEST"
                                : (root.page === "monitor" ? "SYSTEM MONITOR"
                                : (root.page === "calculator" ? "CALCULATOR"
                                : (root.page === "data-meter" ? "DATA METER" : "QUICK TOOLS")))
                            color: "#171B21"
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
                                : "Useful actions, one click away"))
                            color: "#89929E"
                            font.pixelSize: 8
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        visible: root.page !== "tools"
                        width: root.page !== "tools" ? 25 : 0
                        height: 25
                        radius: 8
                        color: backMouse.containsMouse ? "#EEF1F4" : "transparent"
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            source: Qt.resolvedUrl("../assets/icons/lucide-arrow-left.svg")
                            sourceSize.width: 48
                            sourceSize.height: 48
                            smooth: true
                        }

                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.backRequested()
                        }
                    }
                }

                Flow {
                    id: toolsGrid
                    visible: root.page === "tools"
                    width: parent.width
                    flow: Flow.LeftToRight
                    spacing: 8
                    height: 3 * 70 + 2 * spacing

                    Repeater {
                        model: root.tools

                        delegate: Rectangle {
                            id: toolTile
                            required property var modelData
                            width: toolTile.modelData.id === "data-meter"
                                ? toolsGrid.width
                                : (toolsGrid.width - toolsGrid.spacing) / 2
                            height: 70
                            radius: 11
                            color: toolMouse.containsMouse ? "#F0F2F5" : "#FAFBFC"
                            border.width: 1
                            border.color: toolMouse.containsMouse ? "#DDE3E9" : "#EDF0F3"
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
                                    color: "#F0F3F6"
                                    anchors.verticalCenter: parent.verticalCenter

                                    Image {
                                        anchors.centerIn: parent
                                        width: 17
                                        height: 17
                                        source: Qt.resolvedUrl("../assets/icons/" + toolTile.modelData.icon)
                                        sourceSize.width: 48
                                        sourceSize.height: 48
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                    }
                                }

                                Column {
                                    width: parent.width - 44
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4

                                    Text {
                                        width: parent.width
                                        text: toolTile.modelData.label
                                        color: "#242B34"
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: toolTile.modelData.detail
                                        color: "#8A939E"
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

                Rectangle {
                    visible: root.page === "calculator"
                    width: parent.width
                    height: 64
                    radius: 12
                    color: "#F7F8FA"
                    border.width: 1
                    border.color: "#EDF0F3"
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
                            color: "#B93832"
                            font.pixelSize: 8
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            height: 35
                            text: root.expression.replace(/\*/g, "×").replace(/\//g, "÷").replace(/-/g, "−")
                            color: "#161B22"
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
                            color: calculatorKeyMouse.containsMouse ? "#E9EDF1"
                                : (calculatorTile.modelData.kind === "equals" ? "#171B21"
                                : (calculatorTile.modelData.kind === "digit" ? "#FAFBFC" : "#F0F3F6"))
                            border.width: 1
                            border.color: calculatorTile.modelData.kind === "equals" ? "#171B21" : "#E7EBEF"
                            Behavior on color { ColorAnimation { duration: 90 } }
                            Text {
                                anchors.centerIn: parent
                                text: calculatorTile.modelData.label
                                color: calculatorTile.modelData.kind === "equals" ? "#FFFFFF" : "#38414C"
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
                            color: "#FAFBFC"
                            border.width: 1
                            border.color: "#EDF0F3"

                            Column {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 5

                                Row {
                                    width: parent.width
                                    height: 14

                                    Text {
                                        text: metricCard.modelData.label
                                        color: "#697482"
                                        font.pixelSize: 8
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 0.5
                                    }

                                    Item { width: Math.max(0, parent.width - 85); height: 1 }

                                    Text {
                                        text: metricCard.modelData.value
                                        color: "#1B2027"
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 4
                                    radius: 2
                                    color: "#E9EDF1"
                                    clip: true

                                    Rectangle {
                                        width: parent.width * Math.max(0, Math.min(1, Number(metricCard.modelData.ratio || 0)))
                                        height: parent.height
                                        radius: 2
                                        color: "#414B57"
                                        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                    }
                                }

                                Text {
                                    text: root.monitorError.length ? root.monitorError : metricCard.modelData.detail
                                    color: root.monitorError.length ? "#B4534B" : "#8A939E"
                                    font.pixelSize: 7
                                    elide: Text.ElideRight
                                }
                            }
                        }
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
                        top: parent.top
                        height: 34
                        radius: 10
                        color: "#F1F3F6"

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
                                    color: root.dataMeterPeriod === modelData.id ? "#FFFFFF" : "transparent"
                                    border.width: root.dataMeterPeriod === modelData.id ? 1 : 0
                                    border.color: "#E1E5EA"

                                    Text {
                                        anchors.centerIn: parent
                                        text: periodChoiceTile.modelData.label
                                        color: root.dataMeterPeriod === periodChoiceTile.modelData.id ? "#20262E" : "#7D8793"
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
                                color: "#FAFBFC"
                                border.width: 1
                                border.color: "#E8ECF0"

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
                                        color: "#7D8793"
                                        font.pixelSize: 8
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 0.45
                                    }

                                    Text {
                                        width: parent.width
                                        text: trafficTile.modelData.value
                                        color: "#171B21"
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
                        color: "#77818D"
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
                                    color: networkRow.modelData.is_default ? "#F4F6F8" : "transparent"

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
                                            color: networkRow.modelData.is_default ? "#27303A" : "#626D79"
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
                                            color: "#586371"
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
                            color: root.dataMeterError.length ? "#B4534B" : "#939CA7"
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
                        color: toggleMeterMouse.containsMouse ? "#F4F6F8" : "#FFFFFF"
                        border.width: 1
                        border.color: "#E8ECF0"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 11
                            anchors.right: meterToggle.left
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Data speed meter on the navbar"
                            color: "#252D36"
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
                            color: root.dataMeterEnabled ? "#252B33" : "#E4E8ED"
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
                            color: stashIconMouse.containsMouse ? "#F0F2F5" : "#F7F8FA"
                            border.width: 1
                            border.color: "#E8ECF0"

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
                            color: "#444D58"
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
                            color: "#F4F6F8"
                            border.width: 1
                            border.color: "#E8ECF0"

                            Image {
                                anchors.centerIn: parent
                                width: 23
                                height: 23
                                source: Qt.resolvedUrl("../assets/icons/lucide-archive.svg")
                                sourceSize.width: 64
                                sourceSize.height: 64
                                smooth: true
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Nest is empty"
                            color: "#252B34"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Press Super + H to tuck away a window."
                            color: "#89929E"
                            font.pixelSize: 9
                        }
                    }
                }

                Text {
                    visible: root.page !== "data-meter"
                    width: parent.width
                    height: 11
                    text: root.page === "stash"
                        ? "Choose an icon to restore its window"
                        : (root.page === "monitor" ? "Refreshes only while open"
                        : (root.page === "calculator" ? "Basic arithmetic · percentage included"
                            : "Nest · Ctrl + Super + H"))
                    color: "#9AA3AE"
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
