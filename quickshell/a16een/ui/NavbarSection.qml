import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: root

    property bool active: false
    property var navbarSettings: ({})
    property string navbarIconRoot: ""
    property int navbarIconRevision: 0

    readonly property string stateDir: {
        const stateHome = Quickshell.env("XDG_STATE_HOME")
        const home = Quickshell.env("HOME") || ""
        return (stateHome && stateHome.length ? stateHome : home + "/.local/state") + "/a16een"
    }

    readonly property string settingsPath: root.stateDir + "/navbar.json"
    readonly property string generatedPathRoot: root.stateDir + "/navbar-icons"
    signal backRequested()
    signal navbarSettingsChanged(var settings)

    property string selectedSlot: "home"

    readonly property color page: "#FFFFFF"
    readonly property color card: "#F4F6F8"
    readonly property color cardHover: "#E7EBEF"
    readonly property color border: "#CBD3DB"
    readonly property color borderStrong: "#9AA6B2"
    readonly property color textPrimary: "#111318"
    readonly property color textSecondary: "#334155"
    readonly property color textMuted: "#64748B"
    readonly property color accent: "#111318"

    property int workspaceCount: 6
    property int pendingWorkspaceCount: 6
    property string workspaceStatus: "READY"

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

    function defaultIcon(slot) {
        switch (slot) {
        case "code": return "code.svg"
        case "web": return "globe.svg"
        case "comms": return "messages-square.svg"
        case "studio": return "sparkles.svg"
        case "music": return "music.svg"
        default: return "house.svg"
        }
    }

    function baseIconPath(slot) {
        return Qt.resolvedUrl("../assets/icons/" + root.defaultIcon(slot))
    }

    function generatedIconPath(slot) {
        const pathRoot = root.navbarIconRoot.length
            ? root.navbarIconRoot
            : root.generatedPathRoot
        return "file://" + pathRoot + "/" + slot + ".svg"
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
        const next = {}
        for (const slot of root.slots)
            next[slot.id] = root.settingFor(slot.id)

        next[root.selectedSlot] = {
            icon: p.icon || root.settingFor(root.selectedSlot).icon,
            color: p.color || root.settingFor(root.selectedSlot).color
        }

        root.navbarSettings = next
        root.statusText = "SAVING " + root.selectedSlot.toUpperCase()
        settingsFile.setText(JSON.stringify(next, null, 2))
        root.navbarSettingsChanged(next)

        rebuildProcess.running = false
        Qt.callLater(() => rebuildProcess.running = true)
    }

    function applyWorkspaceCount(count) {
        const value = Math.max(2, Math.min(9, Number(count)))
        if (value === root.workspaceCount && value === root.pendingWorkspaceCount)
            return

        root.pendingWorkspaceCount = value
        root.workspaceStatus = "APPLYING " + value
        workspaceProcess.running = false
        Qt.callLater(() => workspaceProcess.running = true)
    }

    function resetSelected() {
        root.patch({
            icon: root.defaultIcon(root.selectedSlot),
            color: "#111318"
        })
    }

    property string statusText: "READY"

    FileView {
        id: settingsFile
        path: root.settingsPath
        watchChanges: true
        printErrors: false

        onLoaded: root.loadSettings(this.text())
        onFileChanged: root.loadSettings(this.text())
    }

    Process {
        id: rebuildProcess
        command: ["/usr/local/bin/a16een-navbar", "apply"]
        running: false

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                root.statusText = "APPLIED"
                root.navbarIconRevision++
            } else {
                root.statusText = "ICON REBUILD FAILED"
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

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                root.workspaceCount = root.pendingWorkspaceCount
                root.workspaceStatus = "APPLIED"
                if (!root.visibleSlots.some(slot => slot.id === root.selectedSlot))
                    root.selectedSlot = root.visibleSlots[root.visibleSlots.length - 1].id
            } else {
                root.workspaceStatus = "BLOCKED"
                Qt.callLater(() => workspaceReader.running = true)
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.page
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 26
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 54
            spacing: 14

            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 11
                color: root.card
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
                spacing: 3

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
                    font.pixelSize: 8
                    font.weight: Font.Medium
                    font.letterSpacing: 0.7
                }
            }

            RowLayout {
                spacing: 5

                Rectangle {
                    width: 28
                    height: 30
                    radius: 9
                    color: minusMouse.containsMouse ? root.cardHover : "#FFFFFF"
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
                    width: 30
                    horizontalAlignment: Text.AlignHCenter
                    text: root.workspaceCount
                    color: root.textPrimary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    width: 28
                    height: 30
                    radius: 9
                    color: plusMouse.containsMouse ? root.cardHover : "#FFFFFF"
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

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 196
                Layout.fillHeight: true
                radius: 17
                color: "#FBFCFD"
                border.width: 1
                border.color: root.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 9
                    spacing: 4

                    Text {
                        Layout.leftMargin: 7
                        Layout.topMargin: 4
                        text: "WORKSPACES"
                        color: root.textMuted
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.0
                    }

                    Repeater {
                        model: root.visibleSlots

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 62
                            radius: 13
                            color: root.selectedSlot === modelData.id
                                ? "#111318"
                                : (slotMouse.containsMouse ? root.cardHover : "transparent")

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 10

                                Rectangle {
                                    Layout.preferredWidth: 36
                                    Layout.preferredHeight: 36
                                    radius: 11
                                    color: root.selectedSlot === modelData.id ? "#1D2430" : "#FFFFFF"
                                    border.width: 1
                                    border.color: root.selectedSlot === modelData.id ? "#263140" : root.border

                                    NavbarIcon {
                                        anchors.centerIn: parent
                                        width: 18
                                        height: 18
                                        iconPath: root.generatedIconPath(modelData.id)
                                        fallbackIconPath: root.baseIconPath(modelData.id)
                                        refreshRevision: root.navbarIconRevision
                                        active: root.selectedSlot === modelData.id
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: modelData.name
                                        color: root.selectedSlot === modelData.id ? "#FFFFFF" : root.textPrimary
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: modelData.description
                                        color: root.selectedSlot === modelData.id ? "#9CA6B2" : root.textMuted
                                        font.pixelSize: 7
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            MouseArea {
                                id: slotMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedSlot = modelData.id
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        Layout.leftMargin: 7
                        text: "CHANGES APPLY INSTANTLY"
                        color: root.textMuted
                        font.pixelSize: 6
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.7
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 17
                color: "#FBFCFD"
                border.width: 1
                border.color: root.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 17
                    spacing: 9

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 46
                            Layout.preferredHeight: 46
                            radius: 13
                            color: "#FFFFFF"
                            border.width: 1
                            border.color: root.border

                            NavbarIcon {
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                iconPath: root.generatedIconPath(root.selectedSlot)
                                fallbackIconPath: root.baseIconPath(root.selectedSlot)
                                refreshRevision: root.navbarIconRevision
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
                                font.letterSpacing: 1
                            }

                            Text {
                                text: root.settingFor(root.selectedSlot).icon
                                    .replace(".svg", "")
                                    .replace("lucide-", "")
                                    .toUpperCase()
                                    + " • " + root.settingFor(root.selectedSlot).color.toUpperCase()
                                color: root.textSecondary
                                font.pixelSize: 8
                                font.weight: Font.Medium
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 78
                            Layout.preferredHeight: 30
                            radius: 10
                            color: resetMouse.containsMouse ? "#EEF1F4" : "#FFFFFF"
                            border.width: 1
                            border.color: root.borderStrong

                            Text {
                                anchors.centerIn: parent
                                text: "RESET"
                                color: root.textPrimary
                                font.pixelSize: 7
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

                    Text {
                        text: "ICON"
                        color: root.textMuted
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.0
                    }

                    Flickable {
                        id: iconScroll
                        Layout.fillWidth: true
                        Layout.preferredHeight: 248
                        clip: true
                        contentWidth: width
                        contentHeight: iconGrid.height

                        GridLayout {
                            id: iconGrid

                            width: iconScroll.width
                            height: Math.ceil(root.iconChoices.length / 6) * 57
                                + Math.max(0, Math.ceil(root.iconChoices.length / 6) - 1) * 7
                            columns: 6
                            rowSpacing: 7
                            columnSpacing: 7

                            Repeater {
                                model: root.iconChoices

                                delegate: Rectangle {
                                    Layout.preferredWidth: (iconGrid.width - 35) / 6
                                    Layout.preferredHeight: 57
                                    radius: 12
                                    color: root.settingFor(root.selectedSlot).icon === modelData.id
                                        ? "#111318"
                                        : (iconMouse.containsMouse ? root.cardHover : "#FFFFFF")
                                    border.width: root.settingFor(root.selectedSlot).icon === modelData.id ? 1.3 : 1
                                    border.color: root.settingFor(root.selectedSlot).icon === modelData.id
                                        ? "#111318" : root.border

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 3

                                        NavbarIcon {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 20
                                            height: 20
                                            iconPath: Qt.resolvedUrl("../assets/icons/" + modelData.id)
                                            fallbackIconPath: root.baseIconPath(root.selectedSlot)
                                        }

                                        Text {
                                            width: 58
                                            horizontalAlignment: Text.AlignHCenter
                                            text: modelData.name
                                            color: root.settingFor(root.selectedSlot).icon === modelData.id
                                                ? "#FFFFFF" : root.textSecondary
                                            font.pixelSize: 6
                                            font.weight: root.settingFor(root.selectedSlot).icon === modelData.id
                                                ? Font.DemiBold : Font.Normal
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

                    Text {
                        text: "COLOR"
                        color: root.textMuted
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.0
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 7

                        Repeater {
                            model: root.colorChoices

                            delegate: Rectangle {
                                Layout.preferredWidth: 29
                                Layout.preferredHeight: 29
                                radius: 9
                                color: "#FFFFFF"
                                border.width: root.settingFor(root.selectedSlot).color.toUpperCase() === modelData.id.toUpperCase()
                                    ? 1.5 : 1
                                border.color: root.settingFor(root.selectedSlot).color.toUpperCase() === modelData.id.toUpperCase()
                                    ? root.accent : root.border

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
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
                        text: "The selected icon and color are used directly by the right-side navbar."
                        color: root.textMuted
                        font.pixelSize: 7
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
