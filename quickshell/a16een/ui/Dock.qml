import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower

PanelWindow {
    id: root

    required property var modelData
    required property var workspaces
    required property int focusedWorkspaceId
    required property bool fullscreenActive

    signal launcherRequested()
    signal lockRequested()
    signal dockVisibilityChanged(bool visible)
    signal utilitiesRequested(string mode)

    property bool lockInProgress: false
    property bool powerMenuOpen: false
    property bool powerMenuSurfaceVisible: false
    property string pendingPowerAction: ""

    onPowerMenuOpenChanged: {
        if (root.powerMenuOpen) {
            powerMenuHideTimer.stop()
            root.powerMenuSurfaceVisible = true
        } else {
            powerMenuHideTimer.restart()
        }
    }

    Timer {
        id: powerMenuHideTimer
        interval: 190
        repeat: false
        onTriggered: {
            if (!root.powerMenuOpen)
                root.powerMenuSurfaceVisible = false
        }
    }

    // The quick-actions tray follows the dock's fullscreen edge-reveal state.

    readonly property color dockBackground: "#FFFFFF"
    readonly property color dockBorder: "#E5E7EB"
    readonly property color iconColor: "#111111"
    readonly property color hoverBackground: "#F3F4F6"

    readonly property string stateDir: {
        const stateHome = Quickshell.env("XDG_STATE_HOME")
        const home = Quickshell.env("HOME") || ""
        return (stateHome && stateHome.length ? stateHome : home + "/.local/state") + "/a16een"
    }

    readonly property string navbarIconRoot: root.stateDir + "/navbar-icons"
    readonly property string navbarReadyPath: root.navbarIconRoot + "/ready"
    readonly property string workspaceCountPath: root.stateDir + "/workspace-count"

    property int navbarRevision: 0
    property int workspaceCount: 6
    property bool edgeRevealed: false
    property bool utilitiesExpanded: false
    property string selectedUtility: "wifi"
    property string utilityWifiState: "unavailable"
    property string utilityWifiName: "Not connected"
    property string utilityBluetoothState: "unavailable"
    required property string navbarPosition

    function parseUtilitySnapshot(output) {
        const snapshot = {}
        String(output || "").split("\n").forEach(line => {
            const index = line.indexOf("=")
            if (index > 0)
                snapshot[line.slice(0, index).trim()] = line.slice(index + 1).trim()
        })

        const wifi = String(snapshot.wifi || "").toLowerCase()
        root.utilityWifiState = ["enabled", "on"].includes(wifi)
            ? "on"
            : (["disabled", "off"].includes(wifi) ? "off" : "unavailable")
        root.utilityWifiName = snapshot.wifi_name || "Not connected"

        const bluetooth = String(snapshot.bluetooth || "").toLowerCase()
        root.utilityBluetoothState = ["enabled", "on"].includes(bluetooth)
            ? "on"
            : (["disabled", "off"].includes(bluetooth) ? "off" : "unavailable")
    }

    Process {
        id: utilityStatusReader
        command: ["a16een-control", "snapshot"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.parseUtilitySnapshot(text)
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.dockVisible
        onTriggered: {
            if (!utilityStatusReader.running)
                utilityStatusReader.running = true
        }
    }

    Component.onCompleted: utilityStatusReader.running = true

    readonly property bool utilityWifiConnected:
        root.utilityWifiState === "on"
        && root.utilityWifiName !== "Not connected"
    readonly property bool utilityBluetoothEnabled:
        root.utilityBluetoothState === "on"

    readonly property var workspaceCatalog: [
        { id: "home", icon: "house.svg" },
        { id: "code", icon: "code.svg" },
        { id: "web", icon: "globe.svg" },
        { id: "comms", icon: "messages-square.svg" },
        { id: "studio", icon: "sparkles.svg" },
        { id: "music", icon: "music.svg" },
        { id: "games", icon: "gamepad-2.svg" },
        { id: "files", icon: "folder.svg" },
        { id: "lab", icon: "terminal.svg" }
    ]

    readonly property var visibleWorkspaces: root.workspaceCatalog.slice(0, root.workspaceCount)

    readonly property bool horizontalNavbar:
        root.navbarPosition === "top" || root.navbarPosition === "bottom"

    readonly property int dockHeight: root.horizontalNavbar
        ? 44
        : Math.max(
            260,
            root.visibleWorkspaces.length * 32
                + Math.max(0, root.visibleWorkspaces.length - 1) * 4
                + 18
        )

    readonly property int dockWidth: root.horizontalNavbar
        ? Math.max(
            44,
            root.visibleWorkspaces.length * 32
                + Math.max(0, root.visibleWorkspaces.length - 1) * 4
                + 20
        )
        : 44

    readonly property bool dockVisible:
        (!root.fullscreenActive || root.edgeRevealed) && !root.lockInProgress

    readonly property int surfaceWidth:
        root.horizontalNavbar
            ? (root.dockVisible ? root.dockWidth : root.modelData.width)
            : (root.dockVisible ? 66 : 8)

    readonly property int surfaceHeight:
        root.horizontalNavbar
            ? (root.dockVisible ? root.dockHeight : 8)
            : (root.dockVisible ? root.dockHeight : 240)

    readonly property int horizontalCenterMargin:
        Math.max(0, Math.round((root.modelData.width - root.surfaceWidth) / 2))

    readonly property int verticalCenterMargin:
        Math.max(0, Math.round((root.modelData.height - root.surfaceHeight) / 2))

    function loadWorkspaceCount(raw) {
        const value = Number(String(raw || "").trim())
        if (value >= 2 && value <= 9)
            root.workspaceCount = Math.floor(value)
    }

    function generatedIconPath(slot) {
        return "file://" + root.navbarIconRoot + "/" + slot + ".svg"
    }

    function fallbackIconPath(iconName) {
        return Qt.resolvedUrl("../assets/icons/" + iconName)
    }

    FileView {
        id: navbarReadyFile
        path: root.navbarReadyPath
        watchChanges: true
        printErrors: false
        onFileChanged: root.navbarRevision++
        onLoaded: root.navbarRevision++
    }

    FileView {
        id: workspaceCountFile
        path: root.workspaceCountPath
        watchChanges: true
        printErrors: false
        onLoaded: root.loadWorkspaceCount(this.text())
        onFileChanged: root.loadWorkspaceCount(this.text())
    }

    screen: modelData
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    width: root.surfaceWidth
    height: root.surfaceHeight

    // The actual Wayland surface is only the navbar-sized area. It never
    // covers the rest of the screen, even while the navbar is hidden.
    anchors {
        left: root.horizontalNavbar || root.navbarPosition === "left"
        right: !root.horizontalNavbar && root.navbarPosition === "right"
        top: root.horizontalNavbar ? root.navbarPosition === "top" : true
        bottom: root.horizontalNavbar && root.navbarPosition === "bottom"
    }

    margins {
        left: root.horizontalNavbar ? root.horizontalCenterMargin : 0
        right: 0
        top: root.horizontalNavbar ? 0 : root.verticalCenterMargin
        bottom: 0
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-dock"

    function workspaceIsFocused(name) {
        const current = root.workspaces.find(workspace => workspace.name === name)
        return !!current && current.id === root.focusedWorkspaceId
    }

    function focusWorkspace(name) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", name])
    }

    function revealDock() {
        root.edgeRevealed = true
        hideRevealTimer.stop()
    }

    function scheduleHide() {
        if (root.fullscreenActive)
            hideRevealTimer.restart()
    }

    Timer {
        id: hideRevealTimer
        interval: 320
        repeat: false
        onTriggered: root.edgeRevealed = false
    }

    onDockVisibleChanged: {
        root.dockVisibilityChanged(root.dockVisible)
        if (!root.dockVisible) {
            root.powerMenuOpen = false
            root.pendingPowerAction = ""
        }
    }

    Component.onCompleted: root.dockVisibilityChanged(root.dockVisible)

    onFullscreenActiveChanged: {
        root.edgeRevealed = false
        hideRevealTimer.stop()
    }

    MouseArea {
        id: edgeReveal
        x: root.horizontalNavbar
            ? 0
            : (root.navbarPosition === "right" ? parent.width - width : 0)
        y: root.horizontalNavbar
            ? (root.navbarPosition === "bottom" ? parent.height - height : 0)
            : 0
        width: root.horizontalNavbar ? parent.width : 8
        height: root.horizontalNavbar ? 8 : parent.height
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        // In fullscreen horizontal mode a separate full-width sensor must
        // own edge detection. The dock surface itself resizes when revealed.
        enabled: !(root.fullscreenActive && root.horizontalNavbar)
        z: 10
        onEntered: root.revealDock()
        onExited: root.scheduleHide()
    }

    // Keep the fullscreen TOP/BOTTOM trigger stable while the visual dock
    // changes from a full-width 8px hidden surface to a compact centered dock.
    // Otherwise resizing the dock surface moves it out from under a cursor
    // parked away from the center, immediately firing MouseArea.onExited.
    PanelWindow {
        id: horizontalEdgeSensor
        screen: root.modelData
        visible: root.fullscreenActive && root.horizontalNavbar
        color: "transparent"
        aboveWindows: true
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        width: root.modelData.width
        height: 8

        anchors {
            left: true
            right: true
            top: root.navbarPosition === "top"
            bottom: root.navbarPosition === "bottom"
        }

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "a16een-dock-edge-sensor"

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: root.revealDock()
            onExited: root.scheduleHide()
        }
    }

    // Hover-expandable battery capsule. Keep the Wayland panel at a fixed
    // maximum size so hover does not resize/reposition the native surface.
    // Only the inner pill animates, with its screen-facing edge pinned.
    PanelWindow {
        id: batteryStatusPanel
        screen: root.modelData
        visible: root.dockVisible
            && UPower.displayDevice.ready
            && UPower.displayDevice.isPresent
        color: "transparent"
        aboveWindows: true
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0

        // Stable outer surface prevents the pointer leaving the surface while
        // the pill opens/closes, which caused the repeated hover flicker.
        width: root.horizontalNavbar ? 88 : 70
        height: root.horizontalNavbar ? 36 : 44

        anchors {
            left: root.navbarPosition === "left"
            right: root.horizontalNavbar || root.navbarPosition === "right"
            top: root.navbarPosition === "top"
            bottom: root.navbarPosition !== "top"
        }

        margins {
            // Keep TOP/BOTTOM anchored as-is. In vertical layouts, pull the
            // power capsule inward by six pixels so its center aligns with
            // the wider clock capsule below it.
            left: root.horizontalNavbar ? 0
                : (root.navbarPosition === "left" ? 6 : 12)
            right: root.horizontalNavbar
                ? (root.navbarPosition === "right" ? 0 : 12)
                : (root.navbarPosition === "right" ? 6 : 12)
            top: root.navbarPosition === "top" ? 0 : 12
            bottom: root.navbarPosition === "bottom" ? 0 : 12
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "a16een-battery-status"

        function batteryPercent() {
            if (!UPower.displayDevice.ready || !UPower.displayDevice.isPresent)
                return 0

            const raw = Number(UPower.displayDevice.percentage)
            if (!Number.isFinite(raw))
                return 0

            // Some Quickshell/UPower builds expose charge as a 0..1 fraction,
            // while others expose a 0..100 percentage. Normalize both so 0.52
            // becomes 52%, instead of the incorrect 1%.
            const normalized = raw > 0 && raw <= 1 ? raw * 100 : raw
            return Math.max(0, Math.min(100, Math.round(normalized)))
        }

        function batteryIconColor() {
            const state = UPower.displayDevice.state

            if (state === UPowerDeviceState.Charging
                || state === UPowerDeviceState.PendingCharge)
                return "#16A34A"

            if (state !== UPowerDeviceState.FullyCharged
                && batteryStatusPanel.batteryPercent() < 20
                && UPower.onBattery)
                return "#E5484D"

            return "#111318"
        }

        Rectangle {
            id: batteryPill
            x: root.horizontalNavbar
                ? parent.width - width
                : (root.navbarPosition === "right" ? parent.width - width - 5 : 5)
            y: root.navbarPosition === "top"
                ? 0
                : (root.navbarPosition === "bottom"
                    ? parent.height - height
                    : Math.round((parent.height - height) / 2))
            width: root.horizontalNavbar
                ? (batteryHoverSensor.containsMouse ? 82 : 36)
                : (batteryHoverSensor.containsMouse ? 62 : 34)
            height: root.horizontalNavbar ? 32 : 40
            radius: 12
            color: "#FFFFFF"
            border.width: 1
            border.color: "#D9DEE5"
            z: 1

            Behavior on width {
                NumberAnimation {
                    duration: 190
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: 16
                color: "#10000000"
                z: -1
            }

            // Track the visible capsule, not the whole transparent native window.
            // Its parent grows away from the screen-facing edge, while the outer
            // PanelWindow remains fixed-size so Wayland geometry stays stable.
            MouseArea {
                id: batteryHoverSensor
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                cursorShape: Qt.ArrowCursor
                z: 10
            }

            BatteryGlyph {
                id: batteryGlyph
                horizontal: root.horizontalNavbar
                percentage: batteryStatusPanel.batteryPercent()
                tint: batteryStatusPanel.batteryIconColor()
                charging: UPower.displayDevice.state === UPowerDeviceState.Charging
                    || UPower.displayDevice.state === UPowerDeviceState.PendingCharge
                width: root.horizontalNavbar ? 22 : 16
                height: root.horizontalNavbar ? 16 : 24
                x: root.horizontalNavbar
                    ? batteryPill.width - width - 6
                    : (batteryHoverSensor.containsMouse
                        ? (root.navbarPosition === "right"
                            ? batteryPill.width - width - 5
                            : 5)
                        : Math.round((batteryPill.width - width) / 2))
                y: Math.round((batteryPill.height - height) / 2)

            }

            Text {
                id: batteryPercentLabel
                visible: opacity > 0.02
                opacity: batteryHoverSensor.containsMouse ? 1 : 0
                x: root.horizontalNavbar
                    ? 7
                    : (root.navbarPosition === "right" ? 4 : 24)
                y: Math.round((batteryPill.height - height) / 2)
                width: root.horizontalNavbar ? 38 : 32
                text: batteryStatusPanel.batteryPercent() + "%"
                color: "#111318"
                font.pixelSize: root.horizontalNavbar ? 11 : 10
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter

                Behavior on opacity {
                    NumberAnimation {
                        duration: 130
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    // Compact clock capsule at the corner opposite the battery.
    // Hovering opens a live Ethiopian calendar popup in Amharic.
    PanelWindow {
        id: navbarClockPanel
        screen: root.modelData
        visible: root.dockVisible
        color: "transparent"
        aboveWindows: true
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0

        // Keep the clock visually consistent with the navbar: a slim capsule
        // whose vertical width matches the workspace rail.
        width: root.horizontalNavbar ? 76 : 44
        height: root.horizontalNavbar ? 30 : 68

        anchors {
            left: root.horizontalNavbar || root.navbarPosition === "left"
            right: root.navbarPosition === "right"
            top: root.navbarPosition !== "bottom"
            bottom: root.navbarPosition === "bottom"
        }

        margins {
            // For horizontal layouts the power control leads from the edge,
            // with the time capsule immediately after it. For vertical layouts
            // each capsule hugs the side edge and sits in the upper corner.
            left: root.horizontalNavbar ? 30 : (root.navbarPosition === "left" ? 8 : 12)
            right: root.navbarPosition === "right" ? 8 : 12
            top: root.navbarPosition === "top" ? 0 : (root.horizontalNavbar ? 12 : 52)
            bottom: root.navbarPosition === "bottom" ? 0 : 12
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "a16een-clock"

        property date clockNow: new Date()
        property bool calendarOpen: false
        property bool calendarWindowVisible: false

        onCalendarOpenChanged: {
            if (calendarOpen) {
                calendarPopupHideTimer.stop()
                calendarWindowVisible = true
            } else {
                calendarPopupHideTimer.restart()
            }
        }

        readonly property var ethiopianMonths: [
            "መስከረም", "ጥቅምት", "ሕዳር", "ታህሳስ",
            "ጥር", "የካቲት", "መጋቢት", "ሚያዝያ",
            "ግንቦት", "ሰኔ", "ሐምሌ", "ነሐሴ", "ጳጉሜ"
        ]

        readonly property var ethiopianWeekdays: [
            "ሰኞ", "ማክሰኞ", "ረቡዕ", "ሐሙስ", "ዓርብ", "ቅዳሜ", "እሑድ"
        ]

        readonly property var weekdayShortNames: ["ሰ", "ማ", "ረ", "ሐ", "አ", "ቅ", "እ"]

        // Gregorian -> Julian Day Number, using integer arithmetic to avoid
        // timezone, month-boundary and leap-century errors.
        function gregorianToJdn(date) {
            const month = date.getMonth() + 1
            const day = date.getDate()
            let year = date.getFullYear()
            const a = Math.floor((14 - month) / 12)
            year = year + 4800 - a
            const m = month + 12 * a - 3

            return day
                + Math.floor((153 * m + 2) / 5)
                + 365 * year
                + Math.floor(year / 4)
                - Math.floor(year / 100)
                + Math.floor(year / 400)
                - 32045
        }

        // Ethiopian year 1 is anchored to JDN 1723856. Leap years are
        // every fourth Ethiopian year (year % 4 === 3), without Gregorian
        // century exceptions. This is the standard Ethiopic civil calendar.
        function ethiopianYearStartJdn(year) {
            return 1723856 + 365 * year + Math.floor(year / 4)
        }

        function toEthiopianDate(date) {
            const jdn = navbarClockPanel.gregorianToJdn(date)
            let year = date.getFullYear() - 7

            // Find the year whose first Meskerem day is on/before this JDN.
            while (navbarClockPanel.ethiopianYearStartJdn(year) > jdn)
                year--
            while (navbarClockPanel.ethiopianYearStartJdn(year + 1) <= jdn)
                year++

            const dayOfYear = jdn - navbarClockPanel.ethiopianYearStartJdn(year)
            const month = Math.floor(dayOfYear / 30) + 1
            const day = dayOfYear % 30 + 1

            return {
                year: year,
                month: Math.max(1, Math.min(13, month)),
                day: day,
                weekday: jdn % 7
            }
        }

        readonly property var ethiopianToday: toEthiopianDate(clockNow)

        readonly property var calendarCells: {
            const today = navbarClockPanel.ethiopianToday
            const firstDayJdn = navbarClockPanel.ethiopianYearStartJdn(today.year)
                + 30 * (today.month - 1)
            const offset = firstDayJdn % 7
            const monthLength = today.month === 13
                ? (today.year % 4 === 3 ? 6 : 5)
                : 30
            const cells = []

            for (let i = 0; i < 42; i++) {
                const day = i - offset + 1
                cells.push({
                    day: day > 0 && day <= monthLength ? day : 0,
                    today: day === today.day
                })
            }
            return cells
        }

        Timer {
            interval: 1000
            repeat: true
            running: navbarClockPanel.visible
            onTriggered: navbarClockPanel.clockNow = new Date()
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: root.horizontalNavbar ? 0 : 1
            radius: root.horizontalNavbar ? 17 : 16
            color: "#FFFFFF"
            border.width: 1
            border.color: "#D9DEE5"

            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: root.horizontalNavbar ? 21 : 19
                color: "#10000000"
                z: -1
            }

            Text {
                visible: root.horizontalNavbar
                anchors.centerIn: parent
                text: Qt.formatTime(navbarClockPanel.clockNow, "h:mm ap")
                color: "#111318"
                font.family: "Monospace"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 0.2
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Column {
                visible: !root.horizontalNavbar
                anchors.centerIn: parent
                spacing: 1

                Text {
                    width: 44
                    text: Qt.formatTime(navbarClockPanel.clockNow, "h")
                    color: "#111318"
                    font.family: "Monospace"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.25
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    width: 16
                    height: 1
                    radius: 1
                    color: "#D9DEE5"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    width: 44
                    text: Qt.formatTime(navbarClockPanel.clockNow, "mm")
                    color: "#111318"
                    font.family: "Monospace"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.25
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    width: 44
                    text: Qt.formatTime(navbarClockPanel.clockNow, "ap")
                    color: "#606A76"
                    font.family: "Monospace"
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            MouseArea {
                id: clockHoverSensor
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                cursorShape: Qt.ArrowCursor
                z: 10
                onEntered: {
                    calendarHideTimer.stop()
                    navbarClockPanel.calendarOpen = true
                }
                onExited: calendarHideTimer.restart()
            }
        }

        onVisibleChanged: {
            if (!visible) {
                navbarClockPanel.calendarOpen = false
                navbarClockPanel.calendarWindowVisible = false
                calendarHideTimer.stop()
                calendarPopupHideTimer.stop()
            }
        }
    }


    // Utilities launcher below the clock. Expanding it reveals Wi-Fi and
    // Bluetooth shortcuts with live status dots; either opens the matching page.
    PanelWindow {
        id: navbarUtilitiesLauncher
        screen: root.modelData
        visible: root.dockVisible
        color: "transparent"
        aboveWindows: true
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        width: 38
        height: root.utilitiesExpanded ? 104 : 38

        anchors {
            left: root.horizontalNavbar || root.navbarPosition === "left"
            right: root.navbarPosition === "right"
            top: root.navbarPosition !== "bottom"
            bottom: root.navbarPosition === "bottom"
        }

        margins {
            left: root.horizontalNavbar ? 100 : (root.navbarPosition === "left" ? 8 : 12)
            right: root.horizontalNavbar ? 12 : (root.navbarPosition === "right" ? 8 : 12)
            top: root.navbarPosition === "top" ? 0 : (root.horizontalNavbar ? 12 : 124)
            bottom: root.navbarPosition === "bottom" ? 12 : 0
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "a16een-navbar-utilities"

        Rectangle {
            anchors.fill: parent
            radius: 13
            color: "#FFFFFF"
            border.width: 1
            border.color: "#D9DEE5"

            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: 16
                color: "#10000000"
                z: -1
            }

            Column {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4

                Rectangle {
                    id: utilitiesMainButton
                    width: 28
                    height: 28
                    radius: 9
                    color: utilitiesMainMouse.containsMouse || root.utilitiesExpanded ? "#F0F2F5" : "transparent"
                    border.width: root.utilitiesExpanded ? 1 : 0
                    border.color: "#DFE4EA"

                    Image {
                        anchors.centerIn: parent
                        width: 15
                        height: 15
                        source: Qt.resolvedUrl("../assets/icons/lucide-sliders-horizontal.svg")
                        sourceSize.width: 30
                        sourceSize.height: 30
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    MouseArea {
                        id: utilitiesMainMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.utilitiesRequested("toggle")
                    }
                }

                Repeater {
                    model: root.utilitiesExpanded
                        ? [{ mode: "wifi", icon: "lucide-wifi.svg" },
                           { mode: "bluetooth", icon: "lucide-bluetooth.svg" }]
                        : []

                    delegate: Rectangle {
                        id: utilityShortcut
                        required property var modelData
                        width: 28
                        height: 28
                        radius: 9
                        color: root.selectedUtility === utilityShortcut.modelData.mode
                            ? "#F1F3F5"
                            : (utilityShortcutMouse.containsMouse ? "#F8F9FA" : "transparent")
                        border.width: root.selectedUtility === utilityShortcut.modelData.mode ? 1 : 0
                        border.color: "#DFE4EA"

                        Image {
                            anchors.centerIn: parent
                            width: 15
                            height: 15
                            source: Qt.resolvedUrl("../assets/icons/" + utilityShortcut.modelData.icon)
                            sourceSize.width: 30
                            sourceSize.height: 30
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.rightMargin: 2
                            anchors.bottomMargin: 2
                            color: utilityShortcut.modelData.mode === "wifi"
                                ? (root.utilityWifiConnected ? "#3FA779"
                                    : (root.utilityWifiState === "off" ? "#B8C0C9" : "#D5A94F"))
                                : (root.utilityBluetoothEnabled ? "#3FA779"
                                    : (root.utilityBluetoothState === "off" ? "#B8C0C9" : "#D5A94F"))
                            border.width: 1
                            border.color: "#FFFFFF"
                        }

                        MouseArea {
                            id: utilityShortcutMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.utilitiesRequested(utilityShortcut.modelData.mode)
                        }
                    }
                }
            }
        }
    }

    // Small power button above the time; the menu opens beside this cluster.
    PanelWindow {
        id: navbarPowerPanel
        screen: root.modelData
        visible: root.dockVisible
        color: "transparent"
        aboveWindows: true
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        width: 28
        height: 28

        anchors {
            left: root.horizontalNavbar || root.navbarPosition === "left"
            right: root.navbarPosition === "right"
            top: root.navbarPosition !== "bottom"
            bottom: root.navbarPosition === "bottom"
        }

        margins {
            // Keep the power button centered with the time pill on vertical
            // docks; both sit slightly inward from the screen edge.
            left: root.horizontalNavbar ? 0 : (root.navbarPosition === "left" ? 14 : 12)
            right: root.horizontalNavbar ? (root.navbarPosition === "right" ? 0 : 12)
                : (root.navbarPosition === "right" ? 14 : 12)
            top: root.navbarPosition === "top" ? 0 : 12
            bottom: root.navbarPosition === "bottom" ? 0 : 12
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "a16een-navbar-power"

        Rectangle {
            anchors.fill: parent
            radius: 11
            color: powerButtonMouse.containsMouse || root.powerMenuOpen ? "#F0F2F5" : "#FFFFFF"
            border.width: 1
            border.color: root.powerMenuOpen ? "#BFC7D1" : "#D9DEE5"

            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            Image {
                anchors.centerIn: parent
                width: 15
                height: 15
                source: Qt.resolvedUrl("../assets/icons/quick-power.svg")
                sourceSize.width: 30
                sourceSize.height: 30
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            MouseArea {
                id: powerButtonMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.togglePowerMenu()
            }
        }
    }

    // Full-screen transparent layer lets a click outside the card dismiss it.
    PanelWindow {
        id: navbarPowerMenu
        screen: root.modelData
        visible: root.powerMenuSurfaceVisible && root.dockVisible
        color: "transparent"
        aboveWindows: true
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        width: root.modelData ? root.modelData.width : 1920
        height: root.modelData ? root.modelData.height : 1080
        focusable: visible

        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "a16een-power-menu"
        WlrLayershell.keyboardFocus: visible
            ? WlrKeyboardFocus.OnDemand
            : WlrKeyboardFocus.None

        MouseArea {
            id: powerMenuOutsideClick
            anchors.fill: parent
            z: 0
            focus: true
            acceptedButtons: Qt.AllButtons
            onClicked: {
                root.powerMenuOpen = false
                root.pendingPowerAction = ""
            }
            Keys.onEscapePressed: {
                root.powerMenuOpen = false
                root.pendingPowerAction = ""
            }
        }

        Item {
            id: powerMenuCard
            x: root.horizontalNavbar
                ? 68
                : (root.navbarPosition === "left"
                    ? 56
                    : Math.max(8, navbarPowerMenu.width - width - 56))
            y: root.horizontalNavbar
                ? (root.navbarPosition === "top"
                    ? 78
                    : Math.max(8, navbarPowerMenu.height - height - 38))
                : 12
            width: 188
            height: 158
            z: 1

            Rectangle {
                id: powerMenuSurface
                anchors.fill: parent
                radius: 16
                color: "#FFFFFF"
                border.width: 1
                border.color: "#D9DEE5"
                opacity: root.powerMenuOpen ? 1 : 0
                scale: root.powerMenuOpen ? 1 : 0.96
                transformOrigin: root.navbarPosition === "right" ? Item.TopRight
                    : (root.navbarPosition === "bottom" ? Item.BottomLeft : Item.TopLeft)

                Behavior on opacity {
                    NumberAnimation { duration: 155; easing.type: Easing.OutCubic }
                }
                Behavior on scale {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    radius: 19
                    color: "#14000000"
                    z: -1
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    onClicked: mouse.accepted = true
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 9
                    spacing: 4

                    Repeater {
                        model: [
                            { id: "lock", label: "Lock screen", icon: "quick-lock.svg" },
                            { id: "logout", label: "Log out", icon: "quick-logout.svg" },
                            { id: "restart", label: "Restart", icon: "quick-restart.svg" },
                            { id: "poweroff", label: "Power off", icon: "quick-power.svg" }
                        ]

                        delegate: Rectangle {
                            id: powerActionRow
                            required property var modelData
                            width: parent.width
                            height: 30
                            radius: 9
                            color: powerActionMouse.containsMouse
                                ? (powerActionRow.modelData.id === "poweroff" ? "#FFF0F0" : "#F1F3F6")
                                : (root.pendingPowerAction === powerActionRow.modelData.id ? "#FFF5E8" : "transparent")
                            border.width: root.pendingPowerAction === powerActionRow.modelData.id ? 1 : 0
                            border.color: "#E6B66D"

                            Rectangle {
                                anchors.left: parent.left
                                anchors.leftMargin: 5
                                anchors.verticalCenter: parent.verticalCenter
                                width: 24
                                height: 24
                                radius: 7
                                color: powerActionRow.modelData.id === "poweroff"
                                    ? "#FFF0F0" : "#F6F7F9"

                                Image {
                                    anchors.centerIn: parent
                                    width: 15
                                    height: 15
                                    source: Qt.resolvedUrl("../assets/icons/" + powerActionRow.modelData.icon)
                                    sourceSize.width: 30
                                    sourceSize.height: 30
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 36
                                anchors.right: parent.right
                                anchors.rightMargin: 7
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.pendingPowerAction === powerActionRow.modelData.id
                                    ? "Confirm " + powerActionRow.modelData.label.toLowerCase() + "?"
                                    : powerActionRow.modelData.label
                                color: root.pendingPowerAction === powerActionRow.modelData.id
                                    ? "#9A5A14"
                                    : (powerActionRow.modelData.id === "poweroff" ? "#B83A42" : "#28313B")
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                id: powerActionMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.triggerPowerAction(powerActionRow.modelData.id)
                            }
                        }
                    }
                }
            }
        }

    }

    function togglePowerMenu() {
        if (root.powerMenuOpen) {
            root.powerMenuOpen = false
            root.pendingPowerAction = ""
            return
        }

        powerMenuHideTimer.stop()
        root.pendingPowerAction = ""
        // Mount the transparent layer first, then change the animated state on
        // the next event-loop turn so its initial opacity/scale can transition.
        root.powerMenuSurfaceVisible = true
        Qt.callLater(() => root.powerMenuOpen = true)
    }

    function triggerPowerAction(actionId) {
        const destructive = actionId === "poweroff" || actionId === "restart"
        if (destructive && root.pendingPowerAction !== actionId) {
            root.pendingPowerAction = actionId
            return
        }

        root.powerMenuOpen = false
        root.pendingPowerAction = ""
        switch (actionId) {
        case "lock":
            // ShellRoot closes every overlay before starting swaylock.
            // This avoids A16EEN overlay surfaces sitting over the lock UI.
            root.lockRequested()
            break
        case "logout":
            Quickshell.execDetached(["niri", "msg", "action", "quit"])
            break
        case "restart":
            Quickshell.execDetached(["systemctl", "reboot"])
            break
        case "poweroff":
            Quickshell.execDetached(["systemctl", "poweroff"])
            break
        }
    }

    // A separate popup keeps the clock compact and never changes dock geometry.
    // It bridges pointer movement from the clock with a short close delay.
    Timer {
        id: calendarHideTimer
        interval: 320
        repeat: false
        onTriggered: {
            if (!clockHoverSensor.containsMouse && !calendarPopupHoverSensor.containsMouse)
                navbarClockPanel.calendarOpen = false
        }
    }

    // Keep the layer-shell surface alive while its contents fade out.
    Timer {
        id: calendarPopupHideTimer
        interval: 190
        repeat: false
        onTriggered: {
            if (!navbarClockPanel.calendarOpen)
                navbarClockPanel.calendarWindowVisible = false
        }
    }

    PanelWindow {
        id: calendarPopup
        screen: root.modelData
        visible: navbarClockPanel.calendarWindowVisible && root.dockVisible
        color: "transparent"
        aboveWindows: true
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        width: 288
        height: 326

        anchors {
            left: root.navbarPosition !== "right"
            right: root.navbarPosition === "right"
            top: root.navbarPosition !== "bottom"
            bottom: root.navbarPosition === "bottom"
        }

        margins {
            // The visible vertical rail is inset 10px inside a 66px surface.
            // Leave a clean 12px gap beside the actual white rail.
            left: !root.horizontalNavbar && root.navbarPosition === "left" ? 66 : 12
            right: !root.horizontalNavbar && root.navbarPosition === "right" ? 68 : 12
            top: root.navbarPosition === "bottom" ? 12 : (root.horizontalNavbar ? 56 : 12)
            bottom: root.navbarPosition === "bottom" ? 56 : 12
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "a16een-ethiopian-calendar"

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: "#FFFFFF"
            border.width: 1
            border.color: "#D9DEE5"
            opacity: navbarClockPanel.calendarOpen ? 1 : 0
            scale: navbarClockPanel.calendarOpen ? 1 : 0.95
            transformOrigin: root.navbarPosition === "right"
                ? Item.TopRight
                : (root.navbarPosition === "bottom" ? Item.BottomLeft : Item.TopLeft)

            Behavior on opacity {
                NumberAnimation {
                    duration: 165
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 190
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: 24
                color: "#18000000"
                z: -1
            }

            Column {
                x: 16
                y: 14
                width: parent.width - 32
                spacing: 3

                Text {
                    width: parent.width
                    text: "ዛሬ  ·  " + navbarClockPanel.ethiopianWeekdays[navbarClockPanel.ethiopianToday.weekday]
                        + " " + navbarClockPanel.ethiopianToday.day
                    color: "#66707C"
                    font.family: "Noto Sans Ethiopic"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }

                Text {
                    width: parent.width
                    text: navbarClockPanel.ethiopianMonths[navbarClockPanel.ethiopianToday.month - 1]
                        + " " + String(navbarClockPanel.ethiopianToday.year)
                        + " ዓ.ም."
                    color: "#111318"
                    font.family: "Noto Sans Ethiopic"
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }

            Row {
                x: 18
                y: 82
                spacing: 4

                Repeater {
                    model: navbarClockPanel.weekdayShortNames

                    delegate: Text {
                        required property var modelData
                        width: 32
                        height: 18
                        text: modelData
                        color: "#8A939E"
                        font.family: "Noto Sans Ethiopic"
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Grid {
                id: ethiopianMonthGrid
                x: 18
                y: 105
                columns: 7
                rows: 6
                columnSpacing: 4
                rowSpacing: 4

                Repeater {
                    model: navbarClockPanel.calendarCells

                    delegate: Rectangle {
                        required property var modelData
                        width: 32
                        height: 29
                        radius: 9
                        color: modelData.day === navbarClockPanel.ethiopianToday.day
                            ? "#111318"
                            : (modelData.day > 0 ? "#F7F8FA" : "transparent")
                        border.width: modelData.day === navbarClockPanel.ethiopianToday.day ? 1 : 0
                        border.color: "#111318"

                        Text {
                            anchors.fill: parent
                            text: modelData.day > 0 ? String(modelData.day) : ""
                            color: modelData.today ? "#FFFFFF" : "#4B5563"
                            font.family: "Monospace"
                            font.pixelSize: 11
                            font.weight: modelData.today ? Font.DemiBold : Font.Normal
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            MouseArea {
                id: calendarPopupHoverSensor
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                cursorShape: Qt.ArrowCursor
                z: 20
                onEntered: calendarHideTimer.stop()
                onExited: calendarHideTimer.restart()
            }
        }
    }

    Rectangle {
        id: dock
        x: root.horizontalNavbar
            ? Math.round((parent.width - width) / 2)
            : (root.dockVisible
                ? (root.navbarPosition === "right"
                    ? parent.width - width
                    : 0)
                : (root.navbarPosition === "right" ? parent.width + 2 : -width - 2))
        y: root.horizontalNavbar
            ? (root.dockVisible
                ? 0
                : (root.navbarPosition === "bottom" ? parent.height + 2 : -height - 2))
            : Math.round((parent.height - height) / 2)

        width: root.horizontalNavbar ? root.dockWidth : 44
        height: root.dockHeight
        radius: 18
        color: root.dockBackground
        border.width: 1
        border.color: root.dockBorder

        Behavior on x {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: 21
            color: "#16000000"
            z: -1
        }

        Grid {
            anchors.centerIn: parent
            columns: root.horizontalNavbar ? root.visibleWorkspaces.length : 1
            rows: root.horizontalNavbar ? 1 : root.visibleWorkspaces.length
            rowSpacing: 4
            columnSpacing: 4

            Repeater {
                model: root.visibleWorkspaces

                delegate: Rectangle {
                    id: workspaceButton

                    required property var modelData
                    required property int index

                    width: 32
                    height: 32
                    radius: 11

                    readonly property bool active:
                        root.workspaceIsFocused(modelData.id)

                    color: workspaceMouse.containsMouse
                        ? root.hoverBackground
                        : "transparent"

                    // Keep the active marker on the physical edge of the screen.
                    // Explicit x/y geometry avoids stale conditional anchors when the
                    // dock changes between vertical and horizontal orientations.
                    Rectangle {
                        id: activeWorkspaceMarker
                        visible: workspaceButton.active
                        width: root.horizontalNavbar ? 16 : 3
                        height: root.horizontalNavbar ? 3 : 16
                        radius: 2
                        x: root.horizontalNavbar
                            ? Math.round((workspaceButton.width - width) / 2)
                            : (root.navbarPosition === "left"
                                ? 2
                                : workspaceButton.width - width - 2)
                        y: root.horizontalNavbar
                            ? (root.navbarPosition === "top"
                                ? 2
                                : workspaceButton.height - height - 2)
                            : Math.round((workspaceButton.height - height) / 2)
                        color: root.iconColor
                        z: 0
                    }

                    NavbarImage {
                        anchors.centerIn: parent
                        width: 19
                        height: 19
                        slot: modelData.id
                        generatedPath: root.generatedIconPath(modelData.id)
                        fallbackPath: root.fallbackIconPath(modelData.icon)
                        refreshRevision: root.navbarRevision
                        active: workspaceButton.active
                        hovered: workspaceMouse.containsMouse
                        z: 1
                    }

                    MouseArea {
                        id: workspaceMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.revealDock()
                        onExited: root.scheduleHide()
                        onClicked: root.focusWorkspace(modelData.id)
                    }
                }
            }
        }
    }

    component BatteryGlyph: Item {
        id: glyphRoot

        property bool horizontal: true
        property real percentage: 0
        property color tint: "#111318"
        property bool charging: false

        Behavior on percentage {
            NumberAnimation {
                duration: 260
                easing.type: Easing.OutCubic
            }
        }

        readonly property real bodyX: horizontal ? 0 : 3
        readonly property real bodyY: horizontal ? 2 : 4
        readonly property real bodyWidth: horizontal ? width - 4 : width - 6
        readonly property real bodyHeight: horizontal ? height - 4 : height - 6
        readonly property real innerWidth: Math.max(0, bodyWidth - 4)
        readonly property real innerHeight: Math.max(0, bodyHeight - 4)
        readonly property real fillRatio: Math.max(0, Math.min(100, percentage)) / 100

        // While charging, tint the empty interior lightly so the white lightning
        // bolt remains visible even at low charge. The stronger fill below still
        // tracks the actual percentage.
        Rectangle {
            x: glyphRoot.bodyX + 2
            y: glyphRoot.bodyY + 2
            width: glyphRoot.innerWidth
            height: glyphRoot.innerHeight
            visible: glyphRoot.charging
            color: "#DDF8E5"
            radius: 1
            z: -1
        }

        // Fill is drawn inside the battery body, proportional to actual charge.
        Rectangle {
            x: glyphRoot.bodyX + 2
            y: glyphRoot.horizontal
                ? glyphRoot.bodyY + 2
                : glyphRoot.bodyY + 2 + glyphRoot.innerHeight * (1 - glyphRoot.fillRatio)
            width: glyphRoot.horizontal
                ? glyphRoot.innerWidth * glyphRoot.fillRatio
                : glyphRoot.innerWidth
            height: glyphRoot.horizontal
                ? glyphRoot.innerHeight
                : glyphRoot.innerHeight * glyphRoot.fillRatio
            color: glyphRoot.tint
            radius: 1
            z: 0
        }

        Rectangle {
            x: glyphRoot.bodyX
            y: glyphRoot.bodyY
            width: glyphRoot.bodyWidth
            height: glyphRoot.bodyHeight
            color: "transparent"
            border.width: 1.5
            border.color: glyphRoot.tint
            radius: 2.5
            z: 1
        }

        Rectangle {
            x: glyphRoot.horizontal ? glyphRoot.width - width : Math.round((glyphRoot.width - width) / 2)
            y: glyphRoot.horizontal ? Math.round((glyphRoot.height - height) / 2) : 1
            width: glyphRoot.horizontal ? 3 : 4
            height: glyphRoot.horizontal ? 4 : 3
            color: glyphRoot.tint
            radius: 1
            z: 2
        }
        // A contrasting lightning bolt is drawn inside the body only while
        // charging. Its dark-green outline keeps it legible over both the pale
        // charging interior and the stronger proportional charge fill.
        Shape {
            anchors.fill: parent
            visible: glyphRoot.charging
            z: 3

            ShapePath {
                fillColor: "#FFFFFF"
                strokeColor: "#166534"
                strokeWidth: 0.65
                startX: glyphRoot.width * 0.54
                startY: glyphRoot.height * 0.17
                PathLine { x: glyphRoot.width * 0.34; y: glyphRoot.height * 0.52 }
                PathLine { x: glyphRoot.width * 0.48; y: glyphRoot.height * 0.52 }
                PathLine { x: glyphRoot.width * 0.41; y: glyphRoot.height * 0.83 }
                PathLine { x: glyphRoot.width * 0.67; y: glyphRoot.height * 0.42 }
                PathLine { x: glyphRoot.width * 0.53; y: glyphRoot.height * 0.42 }
                PathLine { x: glyphRoot.width * 0.54; y: glyphRoot.height * 0.17 }
            }
        }
    }

    component NavbarImage: Item {
        required property string slot
        property string generatedPath: ""
        property string fallbackPath: ""
        property int refreshRevision: 0
        property bool hovered: false
        property bool active: false

        implicitWidth: 19
        implicitHeight: 19
        scale: hovered ? 1.08 : (active ? 1.03 : 1)

        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        Image {
            id: navbarImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            sourceSize.width: width
            sourceSize.height: height
            smooth: true
            mipmap: true
            cache: false
            asynchronous: true
            source: parent.generatedPath.length
                ? parent.generatedPath
                : parent.fallbackPath

            onStatusChanged: {
                if (status === Image.Error && parent.fallbackPath.length
                    && source !== parent.fallbackPath) {
                    source = parent.fallbackPath
                }
            }
        }

        onRefreshRevisionChanged: {
            navbarImage.source = ""
            Qt.callLater(() => {
                navbarImage.source = root.generatedIconPath(slot)
            })
        }
    }
}
