import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool active: false
    property int workspaceCount: 6
    property int pendingWorkspaceCount: 6
    property string selectedSlot: "home"
    property string iconSearch: ""
    property var navbarSettings: ({})
    property string statusText: "READY"
    property string navbarPosition: "right"
    property string pendingNavbarPosition: "right"

    signal backRequested()

    readonly property string stateDir: {
        const stateHome = Quickshell.env("XDG_STATE_HOME")
        const home = Quickshell.env("HOME") || ""
        return (stateHome && stateHome.length ? stateHome : home + "/.local/state") + "/a16een"
    }

    readonly property string settingsPath: root.stateDir + "/navbar.json"
    readonly property string layoutPath: root.stateDir + "/navbar-layout.json"
    readonly property string generatedRoot: root.stateDir + "/navbar-icons"

    readonly property color page: "#FFFFFF"
    readonly property color panel: "#F4F6F8"
    readonly property color border: "#CBD3DB"
    readonly property color borderStrong: "#9AA6B2"
    readonly property color text: "#111318"
    readonly property color textSecondary: "#334155"
    readonly property color muted: "#64748B"
    readonly property color hover: "#E7EBEF"
    readonly property color selected: "#E2E8F0"

    readonly property var slots: [
        { id: "home", name: "HOME", description: "Main workspace", defaultIcon: "house.svg" },
        { id: "code", name: "CODE", description: "Development workspace", defaultIcon: "code.svg" },
        { id: "web", name: "WEB", description: "Browser workspace", defaultIcon: "globe.svg" },
        { id: "comms", name: "COMMS", description: "Communication workspace", defaultIcon: "messages-square.svg" },
        { id: "studio", name: "STUDIO", description: "Creative workspace", defaultIcon: "sparkles.svg" },
        { id: "music", name: "MUSIC", description: "Music workspace", defaultIcon: "music.svg" },
        { id: "games", name: "GAMES", description: "Gaming workspace", defaultIcon: "gamepad-2.svg" },
        { id: "files", name: "FILES", description: "Files & storage", defaultIcon: "folder.svg" },
        { id: "lab", name: "LAB", description: "Experiments & tools", defaultIcon: "terminal.svg" }
    ]

    readonly property var visibleSlots: root.slots.slice(0, root.workspaceCount)

    readonly property var iconChoices: [
        { id: "house.svg", name: "House" },
        { id: "house-heart.svg", name: "House Heart" },
        { id: "house-plus.svg", name: "House Plus" },
        { id: "house-wifi.svg", name: "House WiFi" },
        { id: "monitor.svg", name: "Monitor" },
        { id: "app-window.svg", name: "App Window" },
        { id: "folder.svg", name: "Folder" },
        { id: "folder-open.svg", name: "Folder Open" },
        { id: "code.svg", name: "Code" },
        { id: "terminal.svg", name: "Terminal" },
        { id: "globe.svg", name: "Globe" },
        { id: "messages-square.svg", name: "Messages" },
        { id: "music.svg", name: "Music" },
        { id: "sparkles.svg", name: "Sparkles" },
        { id: "palette.svg", name: "Palette" },
        { id: "sun.svg", name: "Sun" },
        { id: "moon.svg", name: "Moon" },
        { id: "volume-2.svg", name: "Volume" },
        { id: "skull.svg", name: "Skull" },
        { id: "ghost.svg", name: "Ghost" },
        { id: "bug.svg", name: "Bug" },
        { id: "bot.svg", name: "Bot" },
        { id: "radiation.svg", name: "Radiation" },
        { id: "biohazard.svg", name: "Biohazard" },
        { id: "orbit.svg", name: "Orbit" },
        { id: "rocket.svg", name: "Rocket" },
        { id: "gamepad-2.svg", name: "Gamepad" },
        { id: "dice-5.svg", name: "Dice" },
        { id: "coffee.svg", name: "Coffee" },
        { id: "camera.svg", name: "Camera" },
        { id: "heart.svg", name: "Heart" },
        { id: "flame.svg", name: "Flame" },
        { id: "crown.svg", name: "Crown" },
        { id: "diamond.svg", name: "Diamond" },
        { id: "zap.svg", name: "Zap" },
        { id: "fish.svg", name: "Fish" },
        { id: "cat.svg", name: "Cat" },
        { id: "eye.svg", name: "Eye" },
        { id: "brain.svg", name: "Brain" },
        { id: "wand-sparkles.svg", name: "Wand" },
        { id: "graduation-cap.svg", name: "Graduation" },
        { id: "briefcase-business.svg", name: "Briefcase" },
        { id: "cloud.svg", name: "Cloud" },
        { id: "map-pin.svg", name: "Map Pin" },
        { id: "compass.svg", name: "Compass" },
        { id: "command.svg", name: "Command" },
        { id: "accessibility.svg", name: "Accessibility" },
        { id: "alarm-clock.svg", name: "Alarm Clock" },
        { id: "archive.svg", name: "Archive" },
        { id: "badge-check.svg", name: "Badge Check" },
        { id: "bell.svg", name: "Bell" },
        { id: "book-open.svg", name: "Book Open" },
        { id: "bookmark.svg", name: "Bookmark" },
        { id: "calendar.svg", name: "Calendar" },
        { id: "check.svg", name: "Check" },
        { id: "badge-alert.svg", name: "Badge Alert" },
        { id: "circle.svg", name: "Circle" },
        { id: "circle-check.svg", name: "Circle Check" },
        { id: "circle-minus.svg", name: "Circle Minus" },
        { id: "circle-plus.svg", name: "Circle Plus" },
        { id: "clipboard.svg", name: "Clipboard" },
        { id: "clock.svg", name: "Clock" },
        { id: "cloud-sun.svg", name: "Cloud Sun" },
        { id: "cpu.svg", name: "CPU" },
        { id: "database.svg", name: "Database" },
        { id: "download.svg", name: "Download" },
        { id: "ellipsis.svg", name: "Ellipsis" },
        { id: "external-link.svg", name: "External Link" },
        { id: "file.svg", name: "File" },
        { id: "file-code.svg", name: "File Code" },
        { id: "list-filter.svg", name: "List Filter" },
        { id: "flag.svg", name: "Flag" },
        { id: "gauge.svg", name: "Gauge" },
        { id: "git-branch.svg", name: "Git Branch" },
        { id: "git-pull-request.svg", name: "Git Pull Request" },
        { id: "hard-drive.svg", name: "Hard Drive" },
        { id: "headphones.svg", name: "Headphones" },
        { id: "image.svg", name: "Image" },
        { id: "inbox.svg", name: "Inbox" },
        { id: "key.svg", name: "Key" },
        { id: "keyboard.svg", name: "Keyboard" },
        { id: "layers.svg", name: "Layers" },
        { id: "link.svg", name: "Link" },
        { id: "list.svg", name: "List" },
        { id: "lock.svg", name: "Lock" },
        { id: "mail.svg", name: "Mail" },
        { id: "menu.svg", name: "Menu" },
        { id: "mic.svg", name: "Mic" },
        { id: "mouse.svg", name: "Mouse" },
        { id: "network.svg", name: "Network" },
        { id: "package.svg", name: "Package" },
        { id: "pen.svg", name: "Pen" },
        { id: "phone.svg", name: "Phone" },
        { id: "play.svg", name: "Play" },
        { id: "printer.svg", name: "Printer" },
        { id: "save.svg", name: "Save" },
        { id: "search.svg", name: "Search" },
        { id: "server.svg", name: "Server" },
        { id: "settings.svg", name: "Settings" },
        { id: "shield-check.svg", name: "Shield Check" },
        { id: "shopping-bag.svg", name: "Shopping Bag" },
        { id: "sliders-horizontal.svg", name: "Sliders" },
        { id: "smartphone.svg", name: "Smartphone" },
        { id: "star.svg", name: "Star" },
        { id: "tag.svg", name: "Tag" },
        { id: "trash.svg", name: "Trash" },
        { id: "upload.svg", name: "Upload" },
        { id: "user.svg", name: "User" },
        { id: "users.svg", name: "Users" },
        { id: "video.svg", name: "Video" },
        { id: "wifi.svg", name: "WiFi" },
        { id: "wrench.svg", name: "Wrench" },
        { id: "x.svg", name: "Close" }
    ]

    readonly property var filteredIcons: {
        const q = root.iconSearch.trim().toLowerCase()
        if (!q)
            return root.iconChoices.slice(0, 42)
        return root.iconChoices.filter(icon =>
            icon.name.toLowerCase().includes(q) || icon.id.toLowerCase().includes(q)
        )
    }

    readonly property var colors: [
        "#111318", "#FFFFFF", "#334155", "#3B82F6", "#06B6D4",
        "#16A34A", "#F59E0B", "#D97706", "#EF4444", "#DB2777", "#7C3AED"
    ]

    function defaultIcon(slot) {
        for (const entry of root.slots)
            if (entry.id === slot)
                return entry.defaultIcon
        return "house.svg"
    }

    function settingFor(slot) {
        const entry = root.navbarSettings && root.navbarSettings[slot]
            ? root.navbarSettings[slot] : null
        return {
            icon: entry && entry.icon ? entry.icon : root.defaultIcon(slot),
            color: entry && entry.color ? entry.color : "#111318"
        }
    }

    function loadSettings(raw) {
        try {
            const parsed = JSON.parse(String(raw || ""))
            root.navbarSettings = parsed && typeof parsed === "object" ? parsed : ({})
        } catch (error) {
            root.navbarSettings = ({})
        }
    }

    function loadNavbarLayout(raw) {
        try {
            const parsed = JSON.parse(String(raw || ""))
            if (parsed && ["left", "right", "top", "bottom"].includes(parsed.position))
                root.navbarPosition = parsed.position
        } catch (error) {
            root.navbarPosition = "right"
        }
    }

    function setNavbarPosition(position) {
        if (!["left", "right", "top", "bottom"].includes(position)
            || position === root.navbarPosition
            || layoutProcess.running)
            return

        root.pendingNavbarPosition = position
        root.statusText = "MOVING NAVBAR"
        layoutProcess.running = true
    }

    function applyIcon(icon) {
        const current = root.settingFor(root.selectedSlot)
        const next = {}
        for (const slot of root.slots)
            next[slot.id] = root.settingFor(slot.id)
        next[root.selectedSlot] = { icon: icon, color: current.color }
        root.navbarSettings = next
        root.pendingIcon = icon
        root.pendingColor = current.color
        root.statusText = "APPLYING"
        iconProcess.running = false
        Qt.callLater(() => iconProcess.running = true)
    }

    function applyColor(color) {
        const current = root.settingFor(root.selectedSlot)
        const next = {}
        for (const slot of root.slots)
            next[slot.id] = root.settingFor(slot.id)
        next[root.selectedSlot] = { icon: current.icon, color: color }
        root.navbarSettings = next
        root.pendingIcon = current.icon
        root.pendingColor = color
        root.statusText = "APPLYING"
        iconProcess.running = false
        Qt.callLater(() => iconProcess.running = true)
    }

    function resetSelected() {
        applyIcon(root.defaultIcon(root.selectedSlot))
        Qt.callLater(() => applyColor("#111318"))
    }

    function changeWorkspaceCount(nextCount) {
        const value = Math.max(2, Math.min(9, Number(nextCount)))
        if (value === root.workspaceCount || workspaceProcess.running)
            return
        root.pendingWorkspaceCount = value
        root.statusText = "APPLYING " + value
        workspaceProcess.running = true
    }

    FileView {
        id: settingsFile
        path: root.settingsPath
        watchChanges: true
        printErrors: false
        onLoaded: root.loadSettings(this.text())
        onFileChanged: root.loadSettings(this.text())
    }

    FileView {
        id: layoutFile
        path: root.layoutPath
        watchChanges: true
        printErrors: false
        onLoaded: root.loadNavbarLayout(this.text())
        onFileChanged: root.loadNavbarLayout(this.text())
    }

    Process {
        id: layoutProcess
        command: ["a16een-navbar-layout", "set", root.pendingNavbarPosition]
        running: false
        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.navbarPosition = root.pendingNavbarPosition
                root.statusText = "READY"
                layoutFile.reload()
            } else {
                root.statusText = "NAVBAR MOVE FAILED"
                layoutFile.reload()
            }
        }
    }

    Process {
        id: workspaceReader
        command: ["a16een-workspaces", "current"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const value = Number(String(text).trim())
                if (value >= 2 && value <= 9)
                    root.workspaceCount = Math.floor(value)
            }
        }
    }

    Process {
        id: workspaceProcess
        command: ["a16een-workspaces", "set", String(root.pendingWorkspaceCount)]
        running: false
        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.workspaceCount = root.pendingWorkspaceCount
                root.statusText = "READY"
            } else {
                root.statusText = "BLOCKED"
            }
            Qt.callLater(() => workspaceReader.running = true)
        }
    }

    property string pendingIcon: "house.svg"
    property string pendingColor: "#111318"

    Process {
        id: iconProcess
        command: [
            "/usr/local/bin/a16een-navbar",
            "set",
            root.selectedSlot,
            root.pendingIcon,
            root.pendingColor
        ]
        running: false
        onExited: function(exitCode) {
            root.statusText = exitCode === 0 ? "READY" : "ICON APPLY FAILED"
            if (exitCode !== 0)
                settingsFile.reload()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.page
    }

    Column {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 12

        Row {
            width: parent.width
            height: 42
            spacing: 10

            Rectangle {
                width: 38
                height: 38
                radius: 10
                color: root.panel
                border.width: 1
                border.color: root.border
                Text {
                    anchors.centerIn: parent
                    text: "←"
                    color: root.textSecondary
                    font.pixelSize: 16
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backRequested()
                }
            }

            Column {
                width: parent.width - 170
                spacing: 2
                Text {
                    text: "NAVBAR"
                    color: root.text
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.2
                }
                Text {
                    text: "LUCIDE ICONS • WORKSPACES 2–9 • " + root.statusText
                    color: root.muted
                    font.pixelSize: 9
                }
            }

            Row {
                spacing: 4
                Rectangle {
                    width: 28; height: 30; radius: 9
                    color: minusMouse.containsMouse ? root.hover : "#FFFFFF"
                    border.width: 1; border.color: root.borderStrong
                    Text { anchors.centerIn: parent; text: "−"; color: root.text; font.pixelSize: 15 }
                    MouseArea {
                        id: minusMouse
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        enabled: root.workspaceCount > 2 && !workspaceProcess.running
                        opacity: enabled ? 1 : 0.35
                        onClicked: root.changeWorkspaceCount(root.workspaceCount - 1)
                    }
                }
                Text {
                    width: 30; height: 30; verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: root.workspaceCount
                    color: root.text; font.pixelSize: 12; font.weight: Font.DemiBold
                }
                Rectangle {
                    width: 28; height: 30; radius: 9
                    color: plusMouse.containsMouse ? root.hover : "#FFFFFF"
                    border.width: 1; border.color: root.borderStrong
                    Text { anchors.centerIn: parent; text: "+"; color: root.text; font.pixelSize: 14 }
                    MouseArea {
                        id: plusMouse
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        enabled: root.workspaceCount < 9 && !workspaceProcess.running
                        opacity: enabled ? 1 : 0.35
                        onClicked: root.changeWorkspaceCount(root.workspaceCount + 1)
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 46
            radius: 12
            color: "#FBFCFD"
            border.width: 1
            border.color: root.border

            Row {
                anchors.fill: parent
                anchors.margins: 7
                spacing: 7

                Text {
                    width: 88
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    text: "PLACEMENT"
                    color: root.muted
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                }

                Repeater {
                    model: [
                        { id: "left", name: "LEFT", icon: "menu.svg" },
                        { id: "right", name: "RIGHT", icon: "menu.svg" },
                        { id: "top", name: "TOP", icon: "monitor.svg" },
                        { id: "bottom", name: "BOTTOM", icon: "monitor.svg" }
                    ]

                    delegate: Rectangle {
                        width: (parent.width - 109) / 4
                        height: 32
                        radius: 9
                        color: root.navbarPosition === modelData.id ? root.text : "#FFFFFF"
                        border.width: 1
                        border.color: root.navbarPosition === modelData.id ? root.text : root.border

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            Image {
                                width: 14
                                height: 14
                                sourceSize.width: width
                                sourceSize.height: height
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                source: Qt.resolvedUrl("../assets/icons/" + modelData.icon)
                                opacity: root.navbarPosition === modelData.id ? 1 : 0.7
                            }

                            Text {
                                text: modelData.name
                                color: root.navbarPosition === modelData.id ? "#FFFFFF" : root.text
                                font.pixelSize: 7
                                font.weight: Font.DemiBold
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: !layoutProcess.running
                            onClicked: root.setNavbarPosition(modelData.id)
                        }
                    }
                }
            }
        }

        Row {
            width: parent.width
            height: parent.height - 112
            spacing: 12

            Rectangle {
                width: 210
                height: parent.height
                radius: 16
                color: root.panel
                border.width: 1
                border.color: root.border

                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 7

                    Text {
                        text: "WORKSPACES"
                        color: root.text
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1
                    }

                    Repeater {
                        model: root.visibleSlots
                        delegate: Rectangle {
                            width: parent.width
                            height: 46
                            radius: 11
                            color: root.selectedSlot === modelData.id ? root.text : "transparent"

                            Row {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 10

                                Rectangle {
                                    width: 30; height: 30; radius: 9
                                    color: "#FFFFFF"
                                    border.width: 1
                                    border.color: root.border
                                    Image {
                                        anchors.centerIn: parent
                                        width: 16; height: 16
                                        sourceSize.width: width; sourceSize.height: height
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: true
                                        source: "file://" + root.generatedRoot + "/" + modelData.id + ".svg"
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        text: modelData.name
                                        color: root.selectedSlot === modelData.id ? "#FFFFFF" : root.text
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        text: modelData.description
                                        color: root.selectedSlot === modelData.id ? "#AAB2BC" : root.muted
                                        font.pixelSize: 7
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedSlot = modelData.id
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width - 222
                height: parent.height
                radius: 16
                color: "#FBFCFD"
                border.width: 1
                border.color: root.border

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Row {
                        width: parent.width
                        height: 48
                        spacing: 10

                        Rectangle {
                            width: 46; height: 46; radius: 12
                            color: "#FFFFFF"
                            border.width: 1; border.color: root.border
                            Image {
                                anchors.centerIn: parent
                                width: 22; height: 22
                                sourceSize.width: width; sourceSize.height: height
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                source: "file://" + root.generatedRoot + "/" + root.selectedSlot + ".svg"
                            }
                        }

                        Column {
                            width: parent.width - 130
                            spacing: 2
                            Text {
                                text: root.selectedSlot.toUpperCase()
                                color: root.text
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: root.settingFor(root.selectedSlot).icon.toUpperCase()
                                    + " • " + root.settingFor(root.selectedSlot).color.toUpperCase()
                                color: root.textSecondary
                                font.pixelSize: 8
                            }
                        }

                        Rectangle {
                            width: 66; height: 30; radius: 9
                            color: "#FFFFFF"; border.width: 1; border.color: root.borderStrong
                            Text { anchors.centerIn: parent; text: "RESET"; color: root.text; font.pixelSize: 7; font.weight: Font.DemiBold }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.resetSelected() }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 32
                        spacing: 8

                        Rectangle {
                            width: parent.width - 70
                            height: 32
                            radius: 9
                            color: "#FFFFFF"
                            border.width: 1
                            border.color: root.borderStrong

                            TextInput {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                color: root.text
                                font.pixelSize: 8
                                verticalAlignment: Text.AlignVCenter
                                text: root.iconSearch
                                onTextChanged: root.iconSearch = text
                            }
                        }

                        Text {
                            width: 50; height: 32
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            text: (root.iconSearch.length ? root.filteredIcons.length : 42) + " / 113"
                            color: root.muted
                            font.pixelSize: 7
                        }
                    }

                    Flickable {
                        width: parent.width
                        height: parent.height - 190
                        clip: true
                        contentWidth: width
                        contentHeight: iconGrid.height
                        boundsBehavior: Flickable.StopAtBounds

                        Grid {
                            id: iconGrid
                            width: parent.width
                            columns: 6
                            rowSpacing: 6
                            columnSpacing: 6
                            height: Math.ceil(root.filteredIcons.length / 6) * 55

                            Repeater {
                                model: root.filteredIcons
                                delegate: Rectangle {
                                    width: (iconGrid.width - 30) / 6
                                    height: 55
                                    radius: 10
                                    color: root.settingFor(root.selectedSlot).icon === modelData.id ? root.selected : "#FFFFFF"
                                    border.width: 1
                                    border.color: root.settingFor(root.selectedSlot).icon === modelData.id ? root.text : root.border

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 3
                                        Image {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 20; height: 20
                                            sourceSize.width: width; sourceSize.height: height
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            source: Qt.resolvedUrl("../assets/icons/" + modelData.id)
                                        }
                                        Text {
                                            width: 68
                                            horizontalAlignment: Text.AlignHCenter
                                            text: modelData.name
                                            color: root.textSecondary
                                            font.pixelSize: 6
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.applyIcon(modelData.id)
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 30
                        spacing: 6
                        Text {
                            width: 52; height: 30
                            verticalAlignment: Text.AlignVCenter
                            text: "COLOR"
                            color: root.muted
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                        }
                        Repeater {
                            model: root.colors
                            delegate: Rectangle {
                                width: 22; height: 22; radius: 7
                                color: "#FFFFFF"
                                border.width: 1
                                border.color: root.settingFor(root.selectedSlot).color.toUpperCase() === modelData.toUpperCase()
                                    ? root.text : root.border
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 12; height: 12; radius: 6
                                    color: modelData
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.applyColor(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    onActiveChanged: {
        if (root.active) {
            workspaceReader.running = true
            settingsFile.reload()
            layoutFile.reload()
        }
    }

    focus: root.active
    activeFocusOnTab: true
}
