import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts

Item {
    id: root

    property bool active: false
    property var navbarSettings: ({})
    property var workspaceRegistry: []
    property int navbarIconRevision: 0
    property string selectedSlot: "home"
    property string currentSection: "workspace"
    property string pendingSection: "workspace"
    property string statusText: "READY"
    // Only one icon-generation process may write navbar settings at a time.
    // New clicks update the queued state and run after the active write finishes.
    property string pendingSlot: "home"
    property string pendingIcon: "house.svg"
    property string pendingColor: "solid:#111318"
    property string processSlot: "home"
    property string processIcon: "house.svg"
    property string processColor: "solid:#111318"
    property int requestedApplyRevision: 0
    property int processRevision: 0
    property bool applyPending: false

    signal backRequested()
    signal navbarPositionChanged(string position)

    readonly property string stateDir: {
        const stateHome = Quickshell.env("XDG_STATE_HOME")
        const home = Quickshell.env("HOME") || ""
        return (stateHome && stateHome.length ? stateHome : home + "/.local/state") + "/a16een"
    }

    readonly property string navbarIconRoot: root.stateDir + "/navbar-icons"
    readonly property string navbarReadyPath: root.navbarIconRoot + "/ready"
    readonly property string settingsPath: root.stateDir + "/navbar.json"
    readonly property string workspaceRegistryPath: root.stateDir + "/workspaces.json"


    readonly property color page: "transparent"
    readonly property color card: "#FFFFFF"
    readonly property color cardHover: "#F3F4F6"
    readonly property color border: "#E6E8EB"
    readonly property color borderStrong: "#D4D8DE"
    readonly property color textPrimary: "#111318"
    readonly property color textSecondary: "#5C6673"
    readonly property color textMuted: "#777B82"
    readonly property color accent: "#303238"

    readonly property var slots: {
        if (root.workspaceRegistry && root.workspaceRegistry.length > 0) {
            return root.workspaceRegistry.map(function(workspace) {
                return {
                    id: String(workspace.id || ""),
                    name: String(workspace.name || workspace.id || "").toUpperCase(),
                    description: String(workspace.description || ""),
                    icon: String(workspace.icon || "house.svg")
                }
            }).filter(function(workspace) { return workspace.id.length > 0 })
        }

        return [
            { id: "home", name: "HOME", description: "Main workspace", icon: "house.svg" },
            { id: "code", name: "CODE", description: "Development workspace", icon: "code.svg" },
            { id: "web", name: "WEB", description: "Browser workspace", icon: "globe.svg" },
            { id: "comms", name: "COMMS", description: "Communication workspace", icon: "messages-square.svg" },
            { id: "studio", name: "STUDIO", description: "Creative workspace", icon: "sparkles.svg" },
            { id: "music", name: "MUSIC", description: "Music workspace", icon: "music.svg" }
        ]
    }

    readonly property var iconChoices: [
        { id: "house.svg", name: "Home" },
        { id: "lucide-monitor.svg", name: "Desktop" },
        { id: "lucide-app-window.svg", name: "Window" },
        { id: "folder.svg", name: "Folder" },
        { id: "lucide-folder-open.svg", name: "Files" },
        { id: "folder-code.svg", name: "Code Folder" },
        { id: "file-code.svg", name: "Source File" },
        { id: "code.svg", name: "Code" },
        { id: "code-2.svg", name: "Code 2" },
        { id: "terminal.svg", name: "Terminal" },
        { id: "globe.svg", name: "Web" },
        { id: "messages-square.svg", name: "Messages" },
        { id: "music.svg", name: "Music" },
        { id: "headphones.svg", name: "Audio" },
        { id: "sparkles.svg", name: "Creative" },
        { id: "lucide-palette.svg", name: "Design" },
        { id: "camera.svg", name: "Camera" },
        { id: "video.svg", name: "Video" },
        { id: "clapperboard.svg", name: "Film" },
        { id: "gamepad-2.svg", name: "Gaming" },
        { id: "briefcase-business.svg", name: "Work" },
        { id: "graduation-cap.svg", name: "Study" },
        { id: "book-open.svg", name: "Reading" },
        { id: "brain.svg", name: "Research" },
        { id: "flask-conical.svg", name: "Lab" },
        { id: "atom.svg", name: "Science" },
        { id: "database.svg", name: "Database" },
        { id: "server.svg", name: "Server" },
        { id: "network.svg", name: "Network" },
        { id: "git-branch.svg", name: "Git Branch" },
        { id: "chart-no-axes-combined.svg", name: "Analytics" },
        { id: "layout-dashboard.svg", name: "Dashboard" },
        { id: "layers.svg", name: "Layers" },
        { id: "blocks.svg", name: "Components" },
        { id: "workflow.svg", name: "Workflow" },
        { id: "package.svg", name: "Package" },
        { id: "boxes.svg", name: "Projects" },
        { id: "puzzle.svg", name: "Tools" },
        { id: "wand-sparkles.svg", name: "Wand" },
        { id: "rocket.svg", name: "Launch" },
        { id: "bot.svg", name: "AI Lab" },
        { id: "bug.svg", name: "Debug" },
        { id: "compass.svg", name: "Explore" },
        { id: "cloud.svg", name: "Cloud" },
        { id: "orbit.svg", name: "Orbit" },
        { id: "cpu.svg", name: "System" },
        { id: "hard-drive.svg", name: "Storage" },
        { id: "lucide-archive.svg", name: "Archive" },
        { id: "lucide-activity.svg", name: "Activity" },
        { id: "lucide-calculator.svg", name: "Calculator" },
        { id: "lucide-toolbox.svg", name: "Toolbox" },
        { id: "lucide-wrench.svg", name: "Engineering" },
        { id: "lucide-image.svg", name: "Gallery" },
        { id: "coffee.svg", name: "Coffee" },
        { id: "lucide-settings.svg", name: "Settings" }
    ]

    readonly property var colorChoices: [
        { id: "#111318", name: "Black" },
        { id: "#374151", name: "Graphite" },
        { id: "#64748B", name: "Slate" },
        { id: "#1D4ED8", name: "Blue" },
        { id: "#3B82F6", name: "Bright Blue" },
        { id: "#0EA5E9", name: "Sky" },
        { id: "#06B6D4", name: "Cyan" },
        { id: "#0D9488", name: "Teal" },
        { id: "#16A34A", name: "Green" },
        { id: "#65A30D", name: "Lime" },
        { id: "#CA8A04", name: "Gold" },
        { id: "#F59E0B", name: "Amber" },
        { id: "#EA580C", name: "Orange" },
        { id: "#EF4444", name: "Red" },
        { id: "#F43F5E", name: "Rose" },
        { id: "#DB2777", name: "Pink" },
        { id: "#C026D3", name: "Fuchsia" },
        { id: "#A855F7", name: "Purple" },
        { id: "#7C3AED", name: "Violet" },
        { id: "#6366F1", name: "Indigo" }
    ]

    readonly property var colorModes: [
        { id: "solid", label: "Solid" },
        { id: "split-x", label: "Split X" },
        { id: "split-y", label: "Split Y" },
        { id: "gradient-x", label: "Grad X" },
        { id: "gradient-y", label: "Grad Y" },
        { id: "gradient-diag", label: "Diagonal" }
    ]

    function defaultIcon(slot) {
        const workspace = root.slots.find(function(item) { return item.id === slot })
        if (workspace && workspace.icon)
            return workspace.icon

        switch (slot) {
        case "code": return "code.svg"
        case "web": return "globe.svg"
        case "comms": return "messages-square.svg"
        case "studio": return "sparkles.svg"
        case "music": return "music.svg"
        default: return "house.svg"
        }
    }

    function workspaceNameFor(slot) {
        const workspace = root.slots.find(function(item) { return item.id === slot })
        return workspace && workspace.name ? workspace.name : String(slot).toUpperCase()
    }

    function baseIconPath(slot) {
        return Qt.resolvedUrl("../assets/icons/" + root.defaultIcon(slot))
    }

    function generatedIconPath(slot) {
        return "file://" + root.navbarIconRoot + "/" + slot + ".svg"
    }

    function loadSettings(raw) {
        try {
            const parsed = JSON.parse(String(raw || ""))
            root.navbarSettings = parsed && typeof parsed === "object" ? parsed : ({})
        } catch (error) {
            root.navbarSettings = ({})
        }
    }

    function loadWorkspaceRegistry(raw) {
        try {
            const parsed = JSON.parse(String(raw || "[]"))
            root.workspaceRegistry = Array.isArray(parsed) ? parsed : []
        } catch (error) {
            root.workspaceRegistry = []
        }
    }

    function colorHexFromStyle(style) {
        // Navbar settings store styles as solid:#RRGGBB or split/gradient strings.
        // QML color properties need a real color, so extract the first hex stop.
        const match = String(style || "#111318").match(/#[0-9A-Fa-f]{6}/)
        return match ? match[0].toUpperCase() : "#111318"
    }

    function previewIconColor(slot) {
        const color = root.colorHexFromStyle(root.settingFor(slot).color)
        return color === "#FFFFFF" ? "#111318" : color
    }

    function styleModeFor(slot) {
        const style = String(root.settingFor(slot).color || "").toLowerCase()
        const match = style.match(/^(split-x|split-y|gradient-x|gradient-y|gradient-diag):/)
        return match ? match[1] : "solid"
    }

    function styleColorAt(slot, index) {
        const matches = String(root.settingFor(slot).color || "#111318").match(/#[0-9a-fA-F]{6}/g)
        if (!matches || matches.length === 0)
            return "#111318"
        return String(matches[Math.min(index, matches.length - 1)]).toUpperCase()
    }

    function setStyleMode(mode) {
        const primary = root.styleColorAt(root.selectedSlot, 0)
        const secondary = root.styleColorAt(root.selectedSlot, 1)
        const style = mode === "solid" ? "solid:" + primary : mode + ":" + primary + ":" + secondary
        root.patch({ color: style })
    }

    function setStyleColor(color, index) {
        const mode = root.styleModeFor(root.selectedSlot)
        let primary = root.styleColorAt(root.selectedSlot, 0)
        let secondary = root.styleColorAt(root.selectedSlot, 1)
        if (index === 0)
            primary = color
        else
            secondary = color
        const style = mode === "solid" ? "solid:" + primary : mode + ":" + primary + ":" + secondary
        root.patch({ color: style })
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

    function patch(p) {
        const next = {}
        for (const slot of root.slots)
            next[slot.id] = root.settingFor(slot.id)

        const selected = root.settingFor(root.selectedSlot)
        next[root.selectedSlot] = {
            icon: p.icon !== undefined ? p.icon : selected.icon,
            color: p.color !== undefined ? p.color : selected.color
        }

        const current = next[root.selectedSlot]
        root.navbarSettings = next
        root.pendingSlot = root.selectedSlot
        root.pendingIcon = current.icon
        root.pendingColor = current.color
        root.requestedApplyRevision += 1
        root.applyPending = true
        root.statusText = "APPLYING"

        // Never terminate an in-flight write: the file watcher and process can
        // otherwise restore a previous icon/color combination. Coalesce clicks
        // into the newest requested settings, then apply them in sequence.
        if (!iconProcess.running)
            Qt.callLater(() => root.startPendingApply())
    }

    function startPendingApply() {
        if (iconProcess.running || !root.applyPending)
            return

        root.processSlot = root.pendingSlot
        root.processIcon = root.pendingIcon
        root.processColor = root.pendingColor
        root.processRevision = root.requestedApplyRevision
        iconProcess.running = true
    }

    function finishPendingApply(exitCode) {
        if (root.processRevision !== root.requestedApplyRevision) {
            // A newer edit arrived while the previous generated SVGs were
            // being written. Keep the UI state and apply that newest edit next.
            root.statusText = "APPLYING"
            Qt.callLater(() => root.startPendingApply())
            return
        }

        root.applyPending = false
        root.statusText = exitCode === 0 ? "READY" : "ICON APPLY FAILED"

        // Reload only after the final queued write has finished. During an
        // apply, FileView events are ignored so stale disk state cannot undo
        // the latest in-card selection.
        settingsFile.reload()
        navbarReadyFile.reload()
    }

    function resetSelected() {
        root.patch({
            icon: root.defaultIcon(root.selectedSlot),
            color: "solid:#111318"
        })
    }

    function selectSection(section) {
        if (root.currentSection === section)
            return
        root.pendingSection = section
        if (!sectionTransition.running)
            sectionTransition.start()
    }

    SequentialAnimation {
        id: sectionTransition

        NumberAnimation {
            target: sectionContent
            property: "opacity"
            to: 0
            duration: 90
            easing.type: Easing.OutCubic
        }

        ScriptAction {
            script: root.currentSection = root.pendingSection
        }

        NumberAnimation {
            target: sectionContent
            property: "opacity"
            to: 1
            duration: 140
            easing.type: Easing.OutCubic
        }
    }

    FileView {
        id: settingsFile
        path: root.settingsPath
        watchChanges: true
        printErrors: false
        onLoaded: {
            if (!root.applyPending)
                root.loadSettings(this.text())
        }
        onFileChanged: {
            if (!root.applyPending)
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

    FileView {
        id: navbarReadyFile
        path: root.navbarReadyPath
        watchChanges: true
        printErrors: false
        onLoaded: root.navbarIconRevision++
        onFileChanged: root.navbarIconRevision++
    }

    Process {
        id: iconProcess
        command: [
            "/usr/local/bin/a16een-navbar",
            "set",
            root.processSlot,
            root.processIcon,
            root.processColor
        ]
        running: false
        onExited: function(exitCode) {
            root.finishPendingApply(exitCode)
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.page
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.minimumHeight: 32
            Layout.preferredHeight: 32
            Layout.maximumHeight: 32
            spacing: 6

            Repeater {
                model: [
                    { id: "workspace", label: "Workspace" },
                    { id: "position", label: "Position" },
                    { id: "appearance", label: "Appearance" },
                    { id: "customize", label: "Customize" }
                ]

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 9
                    color: root.currentSection === modelData.id
                        ? "#20262E"
                        : (tabMouse.containsMouse ? "#EEF1F4" : "#F6F7F9")
                    border.width: 1
                    border.color: root.currentSection === modelData.id
                        ? "#20262E" : "#E3E8ED"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: root.currentSection === modelData.id
                            ? "#FFFFFF" : "#5D6875"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !sectionTransition.running
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectSection(modelData.id)
                    }
                }
            }
        }

        Item {
            id: sectionContent
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            opacity: 1
            clip: true

            StackLayout {
                anchors.fill: parent
                currentIndex: root.currentSection === "workspace" ? 0
                    : root.currentSection === "position" ? 1
                    : root.currentSection === "appearance" ? 2 : 3

        Item {
            id: workspacePage
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: 1
            implicitHeight: 1

            RowLayout {
                anchors.fill: parent
                spacing: 14

                Rectangle {
                    Layout.preferredWidth: 150
                    Layout.fillHeight: true
                    radius: 0
                    color: "transparent"
                    border.width: 0
                    border.color: "transparent"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 0
                        spacing: 5

                        Text {
                            Layout.leftMargin: 7
                            Layout.topMargin: 4
                            text: "WORKSPACES"
                            color: root.textMuted
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.0
                        }

                        Flickable {
                            id: workspaceList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 0
                            clip: true
                            contentWidth: width
                            contentHeight: workspaceRows.implicitHeight
                            boundsBehavior: Flickable.StopAtBounds

                            Column {
                                id: workspaceRows
                                width: workspaceList.width
                                spacing: 5

                                Repeater {
                                    model: root.slots

                                    delegate: Rectangle {
                                        required property var modelData
                                        width: workspaceRows.width
                                        height: 48
                                        radius: 9
                                        color: root.selectedSlot === modelData.id
                                            ? "#E9EDF2"
                                            : (slotMouse.containsMouse ? root.cardHover : "transparent")
                                        border.width: root.selectedSlot === modelData.id ? 1 : 1
                                        border.color: root.selectedSlot === modelData.id
                                            ? "#D4D8DE"
                                            : (slotMouse.containsMouse ? "#E3E8ED" : "transparent")

                                        Behavior on color {
                                            ColorAnimation { duration: 110 }
                                        }

                                        Column {
                                            anchors.centerIn: parent
                                            width: parent.width - 12
                                            spacing: 2

                                            NavbarIcon {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: 18
                                                height: 18
                                                iconPath: root.generatedIconPath(modelData.id)
                                                fallbackIconPath: Qt.resolvedUrl("../assets/icons/" + root.settingFor(modelData.id).icon)
                                                preserveSourceColors: true
                                                refreshRevision: root.navbarIconRevision
                                                active: root.selectedSlot === modelData.id
                                            }

                                            Text {
                                                width: parent.width
                                                horizontalAlignment: Text.AlignHCenter
                                                text: modelData.name
                                                color: root.textPrimary
                                                font.pixelSize: 8
                                                font.weight: root.selectedSlot === modelData.id ? Font.DemiBold : Font.Medium
                                                elide: Text.ElideRight
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
                            }
                        }
                    }
                }
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 0
                color: "transparent"
                border.width: 0
                border.color: "transparent"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            radius: 8
                            color: "transparent"
                            border.width: 0
                            border.color: "transparent"

                            NavbarIcon {
                                anchors.centerIn: parent
                                width: 20
                                height: 20
                                iconPath: root.generatedIconPath(root.selectedSlot)
                                fallbackIconPath: Qt.resolvedUrl("../assets/icons/" + root.settingFor(root.selectedSlot).icon)
                                preserveSourceColors: true
                                refreshRevision: root.navbarIconRevision
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                text: root.workspaceNameFor(root.selectedSlot)
                                color: root.textPrimary
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.5
                            }


                        }

                        Rectangle {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            radius: 9
                            color: resetMouse.containsMouse ? "#E8ECF1" : "#F5F6F8"
                            border.width: 1
                            border.color: resetMouse.containsMouse ? "#D5DBE3" : "#E7EBF0"
                            Accessible.name: "Reset workspace icon and style"

                            Behavior on color {
                                ColorAnimation { duration: 110 }
                            }

                            NavbarIcon {
                                anchors.centerIn: parent
                                width: 15
                                height: 15
                                iconName: "lucide-refresh-cw-refined-dark.svg"
                                iconColor: "#5C6673"
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
                        Layout.fillHeight: true
                        Layout.minimumHeight: 120
                        Layout.preferredHeight: 180
                        clip: true
                        contentWidth: width
                        contentHeight: iconGrid.height

                        GridLayout {
                            id: iconGrid

                            width: iconScroll.width
                            height: Math.ceil(root.iconChoices.length / 6) * 39
                                + Math.max(0, Math.ceil(root.iconChoices.length / 6) - 1) * 3
                            columns: 6
                            rowSpacing: 3
                            columnSpacing: 4

                            Repeater {
                                model: root.iconChoices

                                delegate: Rectangle {
                                    Layout.preferredWidth: (iconGrid.width - 20) / 6
                                    Layout.preferredHeight: 39
                                    radius: 7
                                    color: root.settingFor(root.selectedSlot).icon === modelData.id
                                        ? "#E9EDF2"
                                        : (iconMouse.containsMouse ? root.cardHover : "transparent")
                                    border.width: root.settingFor(root.selectedSlot).icon === modelData.id ? 1 : 0
                                    border.color: root.settingFor(root.selectedSlot).icon === modelData.id
                                        ? "#D4D8DE" : "transparent"

                                    Column {
                                        anchors.centerIn: parent
                                        width: Math.max(40, (iconGrid.width - 20) / 6 - 6)
                                        spacing: 2

                                        NavbarIcon {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 16
                                            height: 16
                                            iconName: modelData.id
                                            iconColor: "#586474"
                                        }

                                        Text {
                                            width: parent.width
                                            horizontalAlignment: Text.AlignHCenter
                                            text: modelData.name
                                            color: root.textPrimary
                                            font.pixelSize: 7
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
                        text: "ICON STYLE"
                        color: root.textMuted
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.0
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Repeater {
                            model: root.colorModes

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 22
                                radius: 6
                                color: root.styleModeFor(root.selectedSlot) === modelData.id
                                    ? "#20262E" : "#F5F6F8"
                                border.width: 1
                                border.color: root.styleModeFor(root.selectedSlot) === modelData.id
                                    ? "#20262E" : "#E3E7EC"

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: root.styleModeFor(root.selectedSlot) === modelData.id
                                        ? "#FFFFFF" : "#616B78"
                                    font.pixelSize: 7
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setStyleMode(modelData.id)
                                }
                            }
                        }
                    }

                    Text {
                        text: root.styleModeFor(root.selectedSlot) === "solid" ? "COLOR" : "PRIMARY COLOR"
                        color: root.textMuted
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.0
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Repeater {
                            model: root.colorChoices

                            delegate: Rectangle {
                                required property var modelData
                                Layout.preferredWidth: 17
                                Layout.preferredHeight: 17
                                radius: 9
                                color: "transparent"
                                border.width: root.styleColorAt(root.selectedSlot, 0) === modelData.id.toUpperCase() ? 1.5 : 0
                                border.color: root.styleColorAt(root.selectedSlot, 0) === modelData.id.toUpperCase()
                                    ? root.accent : "transparent"

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 11
                                    height: 11
                                    radius: 6
                                    color: modelData.id
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setStyleColor(modelData.id, 0)
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.styleModeFor(root.selectedSlot) !== "solid"
                        text: "SECOND COLOR"
                        color: root.textMuted
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.0
                    }

                    RowLayout {
                        visible: root.styleModeFor(root.selectedSlot) !== "solid"
                        Layout.fillWidth: true
                        spacing: 2

                        Repeater {
                            model: root.colorChoices

                            delegate: Rectangle {
                                required property var modelData
                                Layout.preferredWidth: 17
                                Layout.preferredHeight: 17
                                radius: 9
                                color: "transparent"
                                border.width: root.styleColorAt(root.selectedSlot, 1) === modelData.id.toUpperCase() ? 1.5 : 0
                                border.color: root.styleColorAt(root.selectedSlot, 1) === modelData.id.toUpperCase()
                                    ? root.accent : "transparent"

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 11
                                    height: 11
                                    radius: 6
                                    color: modelData.id
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setStyleColor(modelData.id, 1)
                                }
                            }
                        }
                    }

                }
            }
        }
            }

                Item {
                    id: positionPage

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 0

                        NavbarPlacement {
                            id: placementControl
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
                            active: root.active
                            onPositionApplied: root.navbarPositionChanged(position)
                        }

                        Item { Layout.fillWidth: true; Layout.fillHeight: true }
                    }
                }

                Item {
                    Column {
                        anchors.centerIn: parent

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "COMING SOON"
                            color: "#6B7280"
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.0
                        }
                    }
                }

                Item {
                    Column {
                        anchors.centerIn: parent

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "COMING SOON"
                            color: "#6B7280"
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.0
                        }
                    }
                }
            }
        }
    }

    onActiveChanged: {
        if (root.active) {
            settingsFile.reload()
            navbarReadyFile.reload()
            placementControl.active = true
        }
    }

    Keys.onEscapePressed: root.backRequested()
    focus: root.active
    activeFocusOnTab: true
}
