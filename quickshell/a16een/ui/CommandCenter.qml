import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool opened: false
    property bool powerViewOpen: false
    property string commandText: "/"
    property int selectedCommandIndex: 0
    property string currentPowerProfile: ""
    property string pendingPowerProfile: ""
    property string powerStatus: "READY"

    signal closeRequested()
    signal launcherRequested()
    signal dashboardRequested()
    signal wallpaperRequested()

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

    function refreshPowerProfile() {
        if (!root.powerViewOpen || profileReader.running)
            return

        profileReader.running = true
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

    function selectPowerProfile(profile) {
        if (!profile)
            return

        root.pendingPowerProfile = profile
        root.powerStatus = "APPLYING " + profile.toUpperCase()

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

        Qt.callLater(() => root.refreshPowerProfile())
    }

    function closePowerView() {
        root.powerViewOpen = false
        root.commandText = "/"
        root.selectedCommandIndex = 0
        root.powerStatus = "READY"
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
                const errorText = text.trim()
                if (errorText.length)
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

    Timer {
        id: powerRefreshTimer
        interval: 450
        repeat: false

        onTriggered: {
            root.refreshPowerProfile()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.opened ? 0.32 : 0
    }

    Rectangle {
        id: card
        width: root.powerViewOpen
            ? Math.min(880, parent.width - 80)
            : Math.min(500, parent.width - 48)
        height: root.powerViewOpen ? Math.min(500, parent.height - 100) : 326
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.powerViewOpen ? 0 : 185
        radius: root.powerViewOpen ? 24 : 18
        color: root.surface
        border.width: 1
        border.color: root.borderColor

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
            anchors.margins: -4
            radius: root.powerViewOpen ? 28 : 22
            color: "#18000000"
            z: -1
        }

        Item {
            anchors.fill: parent
            visible: !root.powerViewOpen

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

        Item {
            id: powerView
            anchors.fill: parent
            visible: root.powerViewOpen

            Column {
                anchors.fill: parent
                anchors.margins: 34
                spacing: 22

                Row {
                    width: parent.width
                    height: 50

                    Column {
                        spacing: 3

                        Text {
                            text: "POWER MODE"
                            color: root.primaryText
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                            font.letterSpacing: 2.2
                        }

                        Text {
                            text: "SYSTEM PERFORMANCE & BATTERY"
                            color: "#505050"
                            font.pixelSize: 8
                            font.letterSpacing: 1.4
                        }
                    }

                    Item { width: parent.width - 285; height: 1 }

                    Column {
                        width: 210
                        spacing: 3

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignRight
                            text: root.currentPowerProfile.length
                                ? root.currentPowerProfile === "power-saver"
                                    ? "ECO"
                                    : root.currentPowerProfile.toUpperCase()
                                : "—"
                            color: "#D7B56D"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignRight
                            text: root.powerStatus
                            color: "#5A5A5A"
                            font.pixelSize: 8
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#151515"
                }

                Row {
                    width: parent.width
                    height: 250
                    spacing: 12

                    PowerCard {
                        title: "PERFORMANCE"
                        subtitle: "Maximum system performance"
                        details: [
                            "CPU / system: performance priority",
                            "Live wallpaper: keeps moving with normal windows",
                            "Monitoring: updates every 1 second"
                        ]
                        profile: "performance"
                        active: root.powerProfileIsActive("performance")
                    }

                    PowerCard {
                        title: "BALANCED"
                        subtitle: "Adaptive everyday mode"
                        details: [
                            "CPU / system: balanced efficiency",
                            "Live wallpaper: pauses while an app is focused",
                            "Monitoring: updates every 3 seconds"
                        ]
                        profile: "balanced"
                        active: root.powerProfileIsActive("balanced")
                    }

                    PowerCard {
                        title: "ECO"
                        subtitle: "Maximum battery saving"
                        details: [
                            "CPU / system: power-saver priority",
                            "Live wallpaper: always static",
                            "Monitoring: updates every 7 seconds"
                        ]
                        profile: "power-saver"
                        active: root.powerProfileIsActive("power-saver")
                    }
                }

                Row {
                    width: parent.width
                    height: 36

                    Rectangle {
                        width: 44
                        height: 30
                        radius: 9
                        color: "#0B0B0B"
                        border.width: 1
                        border.color: "#191919"

                        Text {
                            anchors.centerIn: parent
                            text: "←"
                            color: "#5A5A5A"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closePowerView()
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Return to command search"
                        color: "#444444"
                        font.pixelSize: 9
                    }

                    Item { width: 1; height: 1 }
                }
            }
        }
    }

    MouseArea {
        z: -1
        anchors.fill: parent
        onClicked: {
            if (root.powerViewOpen)
                root.closeRequested()
            else
                root.closeRequested()
        }
    }

    Keys.onEscapePressed: {
        if (root.powerViewOpen)
            root.closePowerView()
        else
            root.closeRequested()
    }

    component PowerCard: Rectangle {
        required property string title
        required property string subtitle
        required property var details
        required property string profile
        required property bool active

        width: (parent.width - 24) / 3
        height: 250
        radius: 18
        color: active ? "#111111" : "#080808"
        border.width: active ? 1 : 0
        border.color: "#303030"

        Behavior on color {
            ColorAnimation { duration: 140 }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 10

            Rectangle {
                width: 42
                height: 42
                radius: 12
                color: active ? "#222222" : "#101010"

                Text {
                    anchors.centerIn: parent
                    text: title.charAt(0)
                    color: "#FFFFFF"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }

            Text {
                text: parent.parent.title
                color: "#FFFFFF"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                font.letterSpacing: 0.9
            }

            Text {
                width: parent.width
                text: parent.parent.subtitle
                color: "#777777"
                font.pixelSize: 9
                wrapMode: Text.WordWrap
            }

            Column {
                width: parent.width
                spacing: 5

                Repeater {
                    model: parent.parent.details

                    delegate: Text {
                        width: parent.width
                        text: "•  " + modelData
                        color: "#4F4F4F"
                        font.pixelSize: 8
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Item {
                height: 1
                width: 1
            }

            Text {
                text: active ? "ACTIVE" : "SELECT"
                color: active ? "#D7B56D" : "#555555"
                font.pixelSize: 8
                font.weight: Font.DemiBold
                font.letterSpacing: 1.2
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
