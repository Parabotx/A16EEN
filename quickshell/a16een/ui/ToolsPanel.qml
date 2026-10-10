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

    signal closeRequested()
    signal toolRequested(string toolId)
    signal appStashRequested()
    signal backRequested()
    signal restoreRequested(string windowId)

    readonly property bool horizontalNavbar: root.navbarPosition === "top" || root.navbarPosition === "bottom"
    readonly property real screenWidth: root.modelData ? root.modelData.width : 1920
    readonly property real screenHeight: root.modelData ? root.modelData.height : 1080
    readonly property int popupWidth: 322
    readonly property int popupHeight: root.page === "stash" ? 388 : (root.page === "monitor" ? 310 : 370)
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
        { id: "wallpapers", label: "Wallpapers", detail: "Change your background", icon: "lucide-image.svg" },
        { id: "clipboard", label: "Clipboard", detail: "Reuse copied text", icon: "lucide-clipboard.svg" },
        { id: "calculator", label: "Calculator", detail: "Quick calculations", icon: "lucide-calculator.svg" },
        { id: "monitor", label: "System Monitor", detail: "CPU, memory & disk", icon: "lucide-activity.svg" }
    ]

    readonly property real popupX: root.horizontalNavbar
        ? root.screenWidth - root.popupWidth - 102
        : (root.navbarPosition === "left" ? 66 : root.screenWidth - root.popupWidth - 68)
    readonly property real popupY: root.horizontalNavbar
        ? (root.navbarPosition === "top" ? 40 : root.screenHeight - root.popupHeight - 40)
        : root.screenHeight - root.popupHeight - 72

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
        scale: root.opened ? 1 : 0.97

        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

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
                                    : "../assets/icons/lucide-toolbox.svg"))
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
                                : (root.page === "monitor" ? "SYSTEM MONITOR" : "QUICK TOOLS")
                            color: "#171B21"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                        }

                        Text {
                            text: root.page === "stash"
                                ? "Your hidden windows, ready to return"
                                : (root.page === "monitor" ? "Live usage while this card is open"
                                    : "Useful actions, one click away")
                            color: "#89929E"
                            font.pixelSize: 8
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

                Grid {
                    id: toolsGrid
                    visible: root.page === "tools"
                    width: parent.width
                    columns: 2
                    spacing: 8
                    height: 3 * 70 + 2 * spacing

                    Repeater {
                        model: root.tools

                        delegate: Rectangle {
                            id: toolTile
                            required property var modelData
                            width: (toolsGrid.width - toolsGrid.spacing) / 2
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
                    visible: root.page === "tools"
                    width: parent.width
                    height: 44
                    radius: 11
                    color: stashRowMouse.containsMouse ? "#F0F2F5" : "#FFFFFF"
                    border.width: 1
                    border.color: stashRowMouse.containsMouse ? "#DDE3E9" : "#E8ECF0"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 9
                        spacing: 9

                        Rectangle {
                            width: 29
                            height: 29
                            radius: 9
                            color: "#F2F4F7"
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                anchors.centerIn: parent
                                width: 17
                                height: 17
                                source: Qt.resolvedUrl("../assets/icons/lucide-archive.svg")
                                sourceSize.width: 48
                                sourceSize.height: 48
                                smooth: true
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Text {
                                text: "Nest"
                                color: "#222831"
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: root.stashedApps.length === 0
                                    ? "Your hidden apps appear here"
                                    : String(root.stashedApps.length) + (root.stashedApps.length === 1 ? " hidden window" : " hidden windows")
                                color: "#8A939E"
                                font.pixelSize: 7
                            }
                        }

                    }

                    MouseArea {
                        id: stashRowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.appStashRequested()
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
                    width: parent.width
                    height: 11
                    text: root.page === "stash"
                        ? "Choose an icon to restore its window"
                        : (root.page === "monitor" ? "Refreshes only while open"
                            : "Nest · Ctrl + Super + H")
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
