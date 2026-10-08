import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool active: false
    property var navbarSettings: ({})
    property string selectedSlot: "home"
    property string pendingIcon: "house.svg"
    property string pendingColor: "#111318"
    property int workspaceCount: 6
    property int pendingWorkspaceCount: 6
    property string workspaceStatus: "READY"
    property string iconSearch: ""

    signal backRequested()

    readonly property string stateDir: {
        const stateHome = Quickshell.env("XDG_STATE_HOME")
        const home = Quickshell.env("HOME") || ""
        return (stateHome && stateHome.length ? stateHome : home + "/.local/state") + "/a16een"
    }

    readonly property string settingsPath: root.stateDir + "/navbar.json"

    readonly property color page: "#FFFFFF"
    readonly property color panel: "#F4F6F8"
    readonly property color panelHover: "#E7EBEF"
    readonly property color border: "#CBD3DB"
    readonly property color borderStrong: "#9AA6B2"
    readonly property color textPrimary: "#111318"
    readonly property color textSecondary: "#334155"
    readonly property color textMuted: "#64748B"
    readonly property color selectedBackground: "#E2E8F0"
    readonly property color accent: "#111318"

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

    readonly property var colorChoices: [
        { id: "#111318", name: "Black" },
        { id: "#FFFFFF", name: "White" },
        { id: "#334155", name: "Slate" },
        { id: "#3B82F6", name: "Blue" },
        { id: "#06B6D4", name: "Cyan" },
        { id: "#16A34A", name: "Green" },
        { id: "#F59E0B", name: "Amber" },
        { id: "#D97706", name: "Orange" },
        { id: "#EF4444", name: "Red" },
        { id: "#DB2777", name: "Pink" },
        { id: "#7C3AED", name: "Violet" }
    ]

    readonly property var filteredIconChoices: {
        const q = root.iconSearch.trim().toLowerCase()
        if (!q)
            return root.iconChoices

        return root.iconChoices.filter(icon =>
            icon.name.toLowerCase().includes(q)
            || icon.id.toLowerCase().includes(q)
        )
    }

    function defaultIcon(slot) {
        for (const value of root.slots) {
            if (value.id === slot)
                return value.defaultIcon
        }
        return "house.svg"
    }

    function baseIconPath(slot) {
        return Qt.resolvedUrl("../assets/icons/" + root.defaultIcon(slot))
    }

    function generatedIconPath(slot) {
        return "file://" + root.stateDir + "/navbar-icons/" + slot + ".svg"
    }

    function settingFor(slot) {
        const value = root.navbarSettings && root.navbarSettings[slot]
            ? root.navbarSettings[slot]
            : null

        return {
            icon: value && value.icon ? value.icon : root.defaultIcon(slot),
            color: value && value.color ? value.color : "#111318"
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

    function patch(p) {
        const current = root.settingFor(root.selectedSlot)
        const icon = p.icon || current.icon
        const color = p.color || current.color

        const next = {}
        for (const slot of root.slots)
            next[slot.id] = root.settingFor(slot.id)

        next[root.selectedSlot] = {
            icon: icon,
            color: color
        }

        root.pendingIcon = icon
        root.pendingColor = color
        root.navbarSettings = next
        root.workspaceStatus = "APPLYING " + root.selectedSlot.toUpperCase()

        rebuildProcess.running = false
        Qt.callLater(() => rebuildProcess.running = true)
    }

    function resetSelected() {
        root.patch({
            icon: root.defaultIcon(root.selectedSlot),
            color: "#111318"
        })
    }

    function selectWorkspace(id) {
        root.selectedSlot = id
    }

    function applyWorkspaceCount(count) {
        const value = Math.max(2, Math.min(9, Number(count)))
        if (value === root.workspaceCount && value === root.pendingWorkspaceCount)
            return

        root.pendingWorkspaceCount = value
        root.workspaceStatus = "APPLYING " + value + " WORKSPACES"
        workspaceProcess.running = false
        Qt.callLater(() => workspaceProcess.running = true)
    }

    FileView {
        id: settingsFile
        path: root.settingsPath
        watchChanges: true
        printErrors: false

        onLoaded: root.loadSettings(this.text())
        onFileChanged: root.loadSettings(this.text())
    }

    Process {
        id: workspaceReader
        command: ["a16een-workspaces", "current"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const value = Number(String(text).trim())
                if (value >= 2 && value <= 9)
                    root.workspaceCount = value
            }
        }
    }

    Process {
        id: workspaceProcess
        command: ["a16een-workspaces", "set", String(root.pendingWorkspaceCount)]
        running: false

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                root.workspaceCount = root.pendingWorkspaceCount
                root.workspaceStatus = "APPLIED • " + root.workspaceCount
                if (!root.visibleSlots.some(slot => slot.id === root.selectedSlot))
                    root.selectedSlot = root.visibleSlots[root.visibleSlots.length - 1].id
                Qt.callLater(() => workspaceReader.running = true)
            } else {
                root.workspaceStatus = "CHANGE BLOCKED"
                Qt.callLater(() => workspaceReader.running = true)
            }
        }
    }

    Process {
        id: rebuildProcess
        command: [
            "/usr/local/bin/a16een-navbar",
            "set",
            root.selectedSlot,
            root.pendingIcon,
            root.pendingColor
        ]
        running: false

        onExited: function(exitCode, exitStatus) {
            root.workspaceStatus = exitCode === 0
                ? "APPLIED • " + root.selectedSlot.toUpperCase()
                : "ICON APPLY FAILED"
            if (exitCode !== 0)
                settingsFile.reload()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.page
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 11
                color: root.panel
                border.width: 1
                border.color: root.border

                Text {
                    anchors.centerIn: parent
                    text: "←"
                    color: root.textSecondary
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backRequested()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "NAVBAR"
                    color: root.textPrimary
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.3
                }

                Text {
                    text: "LUCIDE ICONS • WORKSPACES 2–9 • " + root.workspaceStatus
                    color: root.textMuted
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    font.letterSpacing: 0.55
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                Layout.preferredWidth: 80
                Layout.preferredHeight: 32
                radius: 10
                color: "#FFFFFF"
                border.width: 1
                border.color: root.borderStrong

                Text {
                    anchors.centerIn: parent
                    text: root.workspaceCount + " WORKSPACES"
                    color: root.textPrimary
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.6
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 236
                Layout.fillHeight: true
                radius: 17
                color: root.panel
                border.width: 1
                border.color: root.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 11
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        spacing: 6

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: "WORKSPACES"
                                color: root.textPrimary
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.0
                            }

                            Text {
                                text: "NAVBAR POSITIONS"
                                color: root.textMuted
                                font.pixelSize: 6
                                font.weight: Font.Medium
                                font.letterSpacing: 0.7
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            radius: 9
                            color: minusMouse.containsMouse ? root.panelHover : "#FFFFFF"
                            border.width: 1
                            border.color: root.borderStrong

                            Text {
                                anchors.centerIn: parent
                                text: "−"
                                color: root.textPrimary
                                font.pixelSize: 15
                            }

                            MouseArea {
                                id: minusMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: root.workspaceCount > 2 && !workspaceProcess.running
                                opacity: enabled ? 1 : 0.35
                                onClicked: root.applyWorkspaceCount(root.workspaceCount - 1)
                            }
                        }

                        Text {
                            Layout.preferredWidth: 27
                            horizontalAlignment: Text.AlignHCenter
                            text: root.workspaceCount
                            color: root.textPrimary
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            radius: 9
                            color: plusMouse.containsMouse ? root.panelHover : "#FFFFFF"
                            border.width: 1
                            border.color: root.borderStrong

                            Text {
                                anchors.centerIn: parent
                                text: "+"
                                color: root.textPrimary
                                font.pixelSize: 14
                            }

                            MouseArea {
                                id: plusMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: root.workspaceCount < 9 && !workspaceProcess.running
                                opacity: enabled ? 1 : 0.35
                                onClicked: root.applyWorkspaceCount(root.workspaceCount + 1)
                            }
                        }
                    }

                    Flickable {
                        id: workspaceScroll
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: width
                        contentHeight: workspaceColumn.height
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: workspaceColumn
                            width: workspaceScroll.width
                            spacing: 5

                            Repeater {
                                model: root.visibleSlots

                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 58
                                    radius: 13

                                    readonly property bool selected: root.selectedSlot === modelData.id

                                    color: selected ? "#FFFFFF" : (slotMouse.containsMouse ? root.panelHover : "transparent")
                                    border.width: selected ? 1.4 : 1
                                    border.color: selected ? root.accent : "transparent"

                                    Rectangle {
                                        width: 3
                                        height: 24
                                        radius: 2
                                        anchors.left: parent.left
                                        anchors.leftMargin: 3
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: selected ? root.accent : "transparent"
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 11
                                        anchors.rightMargin: 9
                                        spacing: 10

                                        Rectangle {
                                            Layout.preferredWidth: 34
                                            Layout.preferredHeight: 34
                                            radius: 11
                                            color: "#FFFFFF"
                                            border.width: 1
                                            border.color: selected ? root.borderStrong : root.border

                                            Image {
                                                anchors.centerIn: parent
                                                width: 17
                                                height: 17
                                                sourceSize.width: width
                                                sourceSize.height: height
                                                fillMode: Image.PreserveAspectFit
                                                asynchronous: true
                                                smooth: true
                                                mipmap: true
                                                cache: false
                                                source: root.generatedIconPath(modelData.id)
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            Text {
                                                text: (index + 1).toString().padStart(2, "0") + "  " + modelData.name
                                                color: root.textPrimary
                                                font.pixelSize: 8
                                                font.weight: Font.DemiBold
                                            }

                                            Text {
                                                text: modelData.description
                                                color: root.textMuted
                                                font.pixelSize: 6.5
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: slotMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.selectWorkspace(modelData.id)
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.workspaceCount >= 9
                            ? "MAXIMUM WORKSPACES"
                            : "USE + / − TO CHANGE WORKSPACE COUNT"
                        color: root.textMuted
                        font.pixelSize: 6
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.6
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 17
                color: root.panel
                border.width: 1
                border.color: root.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                            radius: 13
                            color: "#FFFFFF"
                            border.width: 1
                            border.color: root.borderStrong

                            Image {
                                anchors.centerIn: parent
                                width: 23
                                height: 23
                                sourceSize.width: width
                                sourceSize.height: height
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                smooth: true
                                mipmap: true
                                cache: false
                                source: root.generatedIconPath(root.selectedSlot)
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                text: root.selectedSlot.toUpperCase()
                                color: root.textPrimary
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.9
                            }

                            Text {
                                text: root.settingFor(root.selectedSlot).icon
                                    .replace(".svg", "")
                                    .toUpperCase()
                                    + " • "
                                    + root.settingFor(root.selectedSlot).color.toUpperCase()
                                color: root.textSecondary
                                font.pixelSize: 7
                                font.weight: Font.Medium
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 74
                            Layout.preferredHeight: 30
                            radius: 10
                            color: resetMouse.containsMouse ? root.panelHover : "#FFFFFF"
                            border.width: 1
                            border.color: root.borderStrong

                            Text {
                                anchors.centerIn: parent
                                text: "RESET"
                                color: root.textPrimary
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.9
                            }

                            MouseArea {
                                id: resetMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.resetSelected()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        radius: 10
                        color: "#FFFFFF"
                        border.width: 1
                        border.color: root.borderStrong

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 11
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Search Lucide icons"
                            color: root.textMuted
                            font.pixelSize: 8
                            visible: iconSearchInput.text.length === 0 && !iconSearchInput.activeFocus
                        }

                        TextInput {
                            id: iconSearchInput
                            anchors.fill: parent
                            anchors.leftMargin: 11
                            anchors.rightMargin: 11
                            color: root.textPrimary
                            selectionColor: "#DCE2E7"
                            selectedTextColor: root.textPrimary
                            font.pixelSize: 8
                            verticalAlignment: Text.AlignVCenter
                            clip: true
                            text: root.iconSearch
                            selectByMouse: true

                            onTextChanged: root.iconSearch = text
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.filteredIconChoices.length + " / " + root.iconChoices.length
                            color: root.textMuted
                            font.pixelSize: 6.5
                            font.weight: Font.DemiBold
                        }
                    }

                    Flickable {
                        id: iconScroll
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: width
                        contentHeight: iconGrid.height
                        boundsBehavior: Flickable.StopAtBounds

                        GridLayout {
                            id: iconGrid
                            width: iconScroll.width
                            columns: 7
                            rowSpacing: 6
                            columnSpacing: 6
                            height: Math.max(
                                58,
                                Math.ceil(root.filteredIconChoices.length / 7) * 55
                            )

                            Repeater {
                                model: root.filteredIconChoices

                                delegate: Rectangle {
                                    Layout.preferredWidth: (iconGrid.width - 36) / 7
                                    Layout.preferredHeight: 55
                                    radius: 11

                                    readonly property bool selected:
                                        root.settingFor(root.selectedSlot).icon === modelData.id

                                    color: selected ? root.selectedBackground
                                        : (iconMouse.containsMouse ? root.panelHover : "#FFFFFF")
                                    border.width: selected ? 1.4 : 1
                                    border.color: selected ? root.accent : root.border

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 3

                                        Image {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 20
                                            height: 20
                                            sourceSize.width: width
                                            sourceSize.height: height
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            smooth: true
                                            mipmap: true
                                            cache: false
                                            source: Qt.resolvedUrl("../assets/icons/" + modelData.id)
                                        }

                                        Text {
                                            width: Math.max(40, parent.width - 4)
                                            horizontalAlignment: Text.AlignHCenter
                                            text: modelData.name
                                            color: root.textSecondary
                                            font.pixelSize: 6
                                            font.weight: selected ? Font.DemiBold : Font.Normal
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        id: iconMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.patch({ icon: modelData.id })
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 7

                        Text {
                            text: "COLOR"
                            color: root.textMuted
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.9
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.settingFor(root.selectedSlot).color.toUpperCase()
                            color: root.textSecondary
                            font.pixelSize: 7
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: root.colorChoices

                            delegate: Rectangle {
                                Layout.preferredWidth: 27
                                Layout.preferredHeight: 27
                                radius: 9
                                color: "#FFFFFF"
                                border.width: 1
                                border.color: root.settingFor(root.selectedSlot).color.toUpperCase() === modelData.id.toUpperCase()
                                    ? root.accent : root.border

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 15
                                    height: 15
                                    radius: 8
                                    color: modelData.id
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.patch({ color: modelData.id })
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Selected states stay light so the Lucide glyph remains fully visible."
                        color: root.textMuted
                        font.pixelSize: 8
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }

    Keys.onEscapePressed: root.backRequested()

    onActiveChanged: {
        if (root.active) {
            workspaceReader.running = true
            settingsFile.reload()
        }
    }

    focus: root.active
    activeFocusOnTab: true
}
