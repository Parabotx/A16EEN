import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool active: false
    property int workspaceCount: 6
    property string selectedSlot: "home"
    property string iconSearch: ""
    property bool addWorkspaceOpen: false
    property bool removeWorkspaceOpen: false
    property string newWorkspaceName: ""
    property string newWorkspaceIcon: "folder.svg"
    property string newWorkspaceSearch: ""
    property string createdWorkspaceId: ""
    property string workspaceStatus: ""
    property var navbarSettings: ({})
    property string statusText: "READY"
    property bool savingSettings: false
    property int renderRevision: 0

    signal backRequested()

    readonly property string stateDir: {
        const stateHome = Quickshell.env("XDG_STATE_HOME")
        const home = Quickshell.env("HOME") || ""
        return (stateHome && stateHome.length ? stateHome : home + "/.local/state") + "/a16een"
    }

    readonly property string settingsPath: root.stateDir + "/navbar.json"
    readonly property string workspaceRegistryPath: root.stateDir + "/workspaces.json"
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

    property var slots: [
        { id: "home", name: "HOME", description: "Main workspace", defaultIcon: "house.svg", icon: "house.svg" },
        { id: "code", name: "CODE", description: "Development workspace", defaultIcon: "code.svg", icon: "code.svg" },
        { id: "web", name: "WEB", description: "Browser workspace", defaultIcon: "globe.svg", icon: "globe.svg" },
        { id: "comms", name: "COMMS", description: "Communication workspace", defaultIcon: "messages-square.svg", icon: "messages-square.svg" },
        { id: "studio", name: "STUDIO", description: "Creative workspace", defaultIcon: "sparkles.svg", icon: "sparkles.svg" },
        { id: "music", name: "MUSIC", description: "Music workspace", defaultIcon: "music.svg", icon: "music.svg" }
    ]

    readonly property var visibleSlots: root.slots

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
            return root.iconChoices
        return root.iconChoices.filter(icon =>
            icon.name.toLowerCase().includes(q) || icon.id.toLowerCase().includes(q)
        )
    }

    readonly property var colors: [
        "#111318", "#FFFFFF", "#1F2937", "#475569", "#0F172A",
        "#2563EB", "#3B82F6", "#06B6D4", "#0EA5E9", "#14B8A6",
        "#16A34A", "#84CC16", "#F59E0B", "#F97316", "#EF4444",
        "#E11D48", "#DB2777", "#A855F7", "#7C3AED", "#C084FC",
        "#B8860B", "#D4AF37", "#9CA3AF", "#E5E7EB"
    ]

    readonly property var styleChoices: [
        { id: "solid-black", name: "BLACK", spec: "solid:#111318", kind: "solid", a: "#111318", b: "#111318" },
        { id: "solid-white", name: "WHITE", spec: "solid:#FFFFFF", kind: "solid", a: "#FFFFFF", b: "#FFFFFF" },
        { id: "solid-gold", name: "GOLD", spec: "solid:#D4AF37", kind: "solid", a: "#D4AF37", b: "#D4AF37" },
        { id: "solid-cyan", name: "CYAN", spec: "solid:#06B6D4", kind: "solid", a: "#06B6D4", b: "#06B6D4" },
        { id: "black-white", name: "B/W HALF", spec: "split-x:#111318:#FFFFFF", kind: "split", a: "#111318", b: "#FFFFFF" },
        { id: "white-black", name: "W/B HALF", spec: "split-x:#FFFFFF:#111318", kind: "split", a: "#FFFFFF", b: "#111318" },
        { id: "gold-black", name: "GOLD/BLACK", spec: "split-x:#D4AF37:#111318", kind: "split", a: "#D4AF37", b: "#111318" },
        { id: "black-gold", name: "BLACK/GOLD", spec: "split-y:#111318:#D4AF37", kind: "split", a: "#111318", b: "#D4AF37" },
        { id: "white-gold", name: "WHITE/GOLD", spec: "split-y:#FFFFFF:#D4AF37", kind: "split", a: "#FFFFFF", b: "#D4AF37" },
        { id: "mono-gradient", name: "MONO FLOW", spec: "gradient-x:#111318:#FFFFFF", kind: "gradient", a: "#111318", b: "#FFFFFF" },
        { id: "gold-gradient", name: "GOLD FLOW", spec: "gradient-x:#111318:#D4AF37", kind: "gradient", a: "#111318", b: "#D4AF37" },
        { id: "blue-gradient", name: "BLUE FLOW", spec: "gradient-x:#2563EB:#06B6D4", kind: "gradient", a: "#2563EB", b: "#06B6D4" },
        { id: "purple-gradient", name: "VIOLET FLOW", spec: "gradient-x:#7C3AED:#DB2777", kind: "gradient", a: "#7C3AED", b: "#DB2777" },
        { id: "teal-gradient", name: "TEAL FLOW", spec: "gradient-y:#06B6D4:#14B8A6", kind: "gradient", a: "#06B6D4", b: "#14B8A6" },
        { id: "sunset-gradient", name: "SUNSET", spec: "gradient-diag:#F97316:#DB2777", kind: "gradient", a: "#F97316", b: "#DB2777" },
        { id: "ice-gradient", name: "ICE", spec: "gradient-diag:#FFFFFF:#06B6D4", kind: "gradient", a: "#FFFFFF", b: "#06B6D4" },
        { id: "shadow-gradient", name: "SHADOW", spec: "gradient-diag:#111318:#475569", kind: "gradient", a: "#111318", b: "#475569" },
        { id: "emerald-gold", name: "EMERALD/GOLD", spec: "split-x:#16A34A:#D4AF37", kind: "split", a: "#16A34A", b: "#D4AF37" }
    ]

    function defaultIcon(slot) {
        for (const entry of root.slots)
            if (entry.id === slot)
                return entry.icon || entry.defaultIcon
        return "house.svg"
    }

    function workspaceIdForName(name) {
        return String(name || "")
            .toLowerCase()
            .replace(/[^a-z0-9]+/g, "-")
            .replace(/^-+|-+$/g, "")
    }

    function addIconMatches() {
        const q = root.newWorkspaceSearch.trim().toLowerCase()
        if (!q)
            return root.iconChoices
        return root.iconChoices.filter(icon =>
            icon.name.toLowerCase().includes(q) || icon.id.toLowerCase().includes(q)
        )
    }

    function openAddWorkspace() {
        if (root.slots.length >= 9)
            return
        root.newWorkspaceName = ""
        root.newWorkspaceSearch = ""
        root.newWorkspaceIcon = "folder.svg"
        root.workspaceStatus = ""
        root.addWorkspaceOpen = true
        root.removeWorkspaceOpen = false
        Qt.callLater(() => addNameInput.forceActiveFocus())
    }

    function cancelAddWorkspace() {
        root.addWorkspaceOpen = false
        root.workspaceStatus = ""
    }

    function submitAddWorkspace() {
        const name = root.newWorkspaceName.trim()
        const id = root.workspaceIdForName(name)
        if (!name.length || !id.length) {
            root.workspaceStatus = "ENTER A NAME"
            return
        }
        if (name.length > 28) {
            root.workspaceStatus = "NAME TOO LONG"
            return
        }
        if (root.slots.some(slot => slot.id === id)) {
            root.workspaceStatus = "NAME ALREADY EXISTS"
            return
        }

        root.createdWorkspaceId = id
        root.workspaceStatus = "ADDING..."
        workspaceOperation = "add"
        workspaceProcess.running = true
    }

    function openRemoveWorkspace() {
        if (root.slots.length <= 2)
            return
        root.removeWorkspaceOpen = true
        root.addWorkspaceOpen = false
        root.workspaceStatus = ""
    }

    function cancelRemoveWorkspace() {
        root.removeWorkspaceOpen = false
        root.workspaceStatus = ""
    }

    function submitRemoveWorkspace() {
        if (root.slots.length <= 2)
            return
        root.workspaceStatus = "REMOVING..."
        workspaceOperation = "remove"
        workspaceProcess.running = true
    }

    function loadWorkspaceRegistry(raw) {
        try {
            const parsed = JSON.parse(String(raw || ""))
            if (!Array.isArray(parsed) || parsed.length < 1)
                return

            root.slots = parsed
            root.workspaceCount = parsed.length

            if (!parsed.some(slot => slot.id === root.selectedSlot))
                root.selectedSlot = parsed[0].id
        } catch (error) {
            // Keep the last valid registry in memory during an atomic file update.
        }
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
        root.renderRevision++
    }

    function styleLabel(spec) {
        if (!spec)
            return "BLACK"
        if (spec.indexOf("solid:") === 0)
            return spec.substring(6).toUpperCase()
        if (spec.indexOf("split-x:") === 0)
            return "HALF HORIZONTAL"
        if (spec.indexOf("split-y:") === 0)
            return "HALF VERTICAL"
        if (spec.indexOf("gradient-diag:") === 0)
            return "DIAGONAL GRADIENT"
        if (spec.indexOf("gradient-y:") === 0)
            return "VERTICAL GRADIENT"
        if (spec.indexOf("gradient-x:") === 0)
            return "HORIZONTAL GRADIENT"
        return "CUSTOM"
    }

    function beginApply(icon, style) {
        const next = {}
        for (const slot of root.slots)
            next[slot.id] = root.settingFor(slot.id)
        next[root.selectedSlot] = { icon: icon, color: style }
        root.navbarSettings = next
        root.pendingIcon = icon
        root.pendingColor = style
        root.savingSettings = true
        root.statusText = "APPLYING"
        iconProcess.running = false
        Qt.callLater(() => iconProcess.running = true)
    }

    function applyIcon(icon) {
        beginApply(icon, root.settingFor(root.selectedSlot).color)
    }

    function applyStyle(style) {
        beginApply(root.settingFor(root.selectedSlot).icon, style)
    }

    function applyColor(color) {
        applyStyle("solid:" + color)
    }

    function resetSelected() {
        beginApply(root.defaultIcon(root.selectedSlot), "solid:#111318")
    }



    FileView {
        id: settingsFile
        path: root.settingsPath
        watchChanges: true
        printErrors: false
        onLoaded: root.loadSettings(this.text())
        onFileChanged: {
            if (!root.savingSettings)
                root.loadSettings(this.text())
        }
    }

    FileView {
        id: workspaceRegistryFile
        path: root.workspaceRegistryPath
        watchChanges: true
        printErrors: false
        onLoaded: root.loadWorkspaceRegistry(this.text())
        onFileChanged: root.loadWorkspaceRegistry(this.text())
    }

    property string workspaceOperation: ""

    Process {
        id: workspaceProcess
        command: root.workspaceOperation === "add"
            ? ["a16een-workspaces", "add", root.newWorkspaceName, root.newWorkspaceIcon]
            : ["a16een-workspaces", "remove", root.selectedSlot]
        running: false
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.workspaceStatus = root.workspaceOperation === "add"
                    ? "ADDING FAILED"
                    : "REMOVING FAILED"
                return
            }

            navbarApplyProcess.running = true
        }
    }

    Process {
        id: navbarApplyProcess
        command: ["/usr/local/bin/a16een-navbar", "apply"]
        running: false
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.statusText = "NAVBAR APPLY FAILED"
                return
            }

            workspaceRegistryFile.reload()
            settingsFile.reload()
            root.renderRevision++

            if (root.workspaceOperation === "add") {
                root.selectedSlot = root.createdWorkspaceId
                root.addWorkspaceOpen = false
                root.workspaceStatus = ""
                root.statusText = "READY"
            } else {
                root.removeWorkspaceOpen = false
                if (root.slots.length > 0)
                    root.selectedSlot = root.slots[Math.max(0, root.slots.length - 1)].id
                root.workspaceStatus = ""
                root.statusText = "READY"
            }

            root.workspaceOperation = ""
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
            root.savingSettings = false
            if (exitCode === 0) {
                root.statusText = "READY"
                settingsFile.reload()
                root.renderRevision++
            } else {
                root.statusText = "ICON APPLY FAILED"
                settingsFile.reload()
            }
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
                    Image {
                        anchors.centerIn: parent
                        width: 15
                        height: 15
                        sourceSize.width: width
                        sourceSize.height: height
                        fillMode: Image.PreserveAspectFit
                        source: Qt.resolvedUrl("../assets/icons/circle-minus.svg")
                        asynchronous: true
                    }
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
                    Image {
                        anchors.centerIn: parent
                        width: 15
                        height: 15
                        sourceSize.width: width
                        sourceSize.height: height
                        fillMode: Image.PreserveAspectFit
                        source: Qt.resolvedUrl("../assets/icons/circle-plus.svg")
                        asynchronous: true
                    }
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

        Row {
            width: parent.width
            height: parent.height - 54
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
                                        cache: false
                                        source: {
                                            root.renderRevision
                                            return "file://" + root.generatedRoot + "/" + modelData.id + ".svg"
                                        }
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
                                cache: false
                                source: {
                                    root.renderRevision
                                    return "file://" + root.generatedRoot + "/" + root.selectedSlot + ".svg"
                                }
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
                            text: root.filteredIcons.length + " / " + root.iconChoices.length
                            color: root.muted
                            font.pixelSize: 7
                        }
                    }

                    Flickable {
                        width: parent.width
                        height: Math.max(150, parent.height - 250)
                        clip: true
                        contentWidth: width
                        contentHeight: Math.max(iconGrid.height, height)
                        boundsBehavior: Flickable.StopAtBounds
                        interactive: iconGrid.height > height

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

                    Column {
                        width: parent.width
                        spacing: 6

                        Row {
                            width: parent.width
                            height: 26
                            spacing: 8

                            Text {
                                width: 58
                                height: 26
                                verticalAlignment: Text.AlignVCenter
                                text: "COLOR"
                                color: root.muted
                                font.pixelSize: 7
                                font.weight: Font.DemiBold
                            }

                            Flickable {
                                width: parent.width - 66
                                height: 26
                                clip: true
                                contentWidth: colorRow.width
                                contentHeight: colorRow.height
                                boundsBehavior: Flickable.StopAtBounds

                                Row {
                                    id: colorRow
                                    height: 22
                                    spacing: 5

                                    Repeater {
                                        model: root.colors

                                        delegate: Rectangle {
                                            width: 22
                                            height: 22
                                            radius: 7
                                            color: "#FFFFFF"
                                            border.width: 1
                                            border.color: root.settingFor(root.selectedSlot).color === "solid:" + modelData
                                                ? root.text : root.border

                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: 12
                                                height: 12
                                                radius: 6
                                                color: modelData
                                                border.width: modelData.toUpperCase() === "#FFFFFF" ? 1 : 0
                                                border.color: root.borderStrong
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

                        Row {
                            width: parent.width
                            height: 34
                            spacing: 8

                            Text {
                                width: 58
                                height: 34
                                verticalAlignment: Text.AlignVCenter
                                text: "DESIGN"
                                color: root.muted
                                font.pixelSize: 7
                                font.weight: Font.DemiBold
                            }

                            Flickable {
                                width: parent.width - 66
                                height: 34
                                clip: true
                                contentWidth: designRow.width
                                contentHeight: designRow.height
                                boundsBehavior: Flickable.StopAtBounds

                                Row {
                                    id: designRow
                                    height: 30
                                    spacing: 6

                                    Repeater {
                                        model: root.styleChoices

                                        delegate: Rectangle {
                                            width: 92
                                            height: 30
                                            radius: 8
                                            color: "#FFFFFF"
                                            border.width: 1
                                            border.color: root.settingFor(root.selectedSlot).color === modelData.spec
                                                ? root.text : root.border

                                            Rectangle {
                                                id: stylePreview
                                                anchors.left: parent.left
                                                anchors.leftMargin: 6
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 26
                                                height: 18
                                                radius: 5
                                                color: modelData.a

                                                Rectangle {
                                                    visible: modelData.kind === "split"
                                                    anchors.right: parent.right
                                                    anchors.top: parent.top
                                                    anchors.bottom: parent.bottom
                                                    width: parent.width / 2
                                                    radius: 5
                                                    color: modelData.b
                                                }

                                                Rectangle {
                                                    visible: modelData.kind === "gradient"
                                                    anchors.right: parent.right
                                                    anchors.top: parent.top
                                                    anchors.bottom: parent.bottom
                                                    width: parent.width / 3
                                                    color: modelData.b
                                                }
                                            }

                                            Text {
                                                anchors.left: stylePreview.right
                                                anchors.leftMargin: 5
                                                anchors.right: parent.right
                                                anchors.rightMargin: 4
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: modelData.name
                                                color: root.textSecondary
                                                font.pixelSize: 6
                                                elide: Text.ElideRight
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.applyStyle(modelData.spec)
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

    onActiveChanged: {
        if (root.active) {
            workspaceRegistryFile.reload()
            settingsFile.reload()
        }
    }

    focus: root.active
    activeFocusOnTab: true
}
