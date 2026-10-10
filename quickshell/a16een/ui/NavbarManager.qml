import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts

Item {
    id: root

    property bool active: false
    property var navbarSettings: ({})
    property int navbarIconRevision: 0
    property string selectedSlot: "home"
    property string currentSection: "workspace"
    property string pendingSection: "workspace"
    property string statusText: "READY"
    property string pendingIcon: "house.svg"
    property string pendingColor: "#111318"

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


    readonly property color page: "transparent"
    readonly property color card: "#FFFFFF"
    readonly property color cardHover: "#F3F4F6"
    readonly property color border: "#E6E8EB"
    readonly property color borderStrong: "#D4D8DE"
    readonly property color textPrimary: "#111318"
    readonly property color textSecondary: "#5C6673"
    readonly property color textMuted: "#777B82"
    readonly property color accent: "#303238"

    readonly property var slots: [
        { id: "home", name: "HOME", description: "Main workspace" },
        { id: "code", name: "CODE", description: "Development workspace" },
        { id: "web", name: "WEB", description: "Browser workspace" },
        { id: "comms", name: "COMMS", description: "Communication workspace" },
        { id: "studio", name: "STUDIO", description: "Creative workspace" },
        { id: "music", name: "MUSIC", description: "Music workspace" }
    ]

    readonly property var iconChoices: [
        { id: "house.svg", name: "House" },
        { id: "lucide-monitor.svg", name: "Monitor" },
        { id: "lucide-app-window.svg", name: "App Window" },
        { id: "folder.svg", name: "Folder" },
        { id: "lucide-folder-open.svg", name: "Folder Open" },
        { id: "code.svg", name: "Code" },
        { id: "code-2.svg", name: "Code 2" },
        { id: "terminal.svg", name: "Terminal" },
        { id: "globe.svg", name: "Globe" },
        { id: "messages-square.svg", name: "Messages" },
        { id: "music.svg", name: "Music" },
        { id: "sparkles.svg", name: "Sparkles" },
        { id: "lucide-palette.svg", name: "Palette" },
        { id: "lucide-sun.svg", name: "Sun" },
        { id: "lucide-moon.svg", name: "Moon" },
        { id: "lucide-volume-2.svg", name: "Volume" },
        { id: "lucide-settings.svg", name: "Settings" },
        { id: "lucide-sliders-horizontal.svg", name: "Sliders" },
        { id: "lucide-battery.svg", name: "Battery" },
        { id: "lucide-wifi.svg", name: "Wi-Fi" },
        { id: "lucide-bluetooth.svg", name: "Bluetooth" },
        { id: "lucide-bell-off.svg", name: "Notifications Off" },
        { id: "lucide-clipboard.svg", name: "Clipboard" },
        { id: "lucide-crop.svg", name: "Crop" },
        { id: "lucide-mouse-pointer.svg", name: "Pointer" },
        { id: "search.svg", name: "Search" },
        { id: "lucide-arrow-left.svg", name: "Arrow Left" }
    ]

    readonly property var colorChoices: [
        { id: "#111318", name: "Black" },
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

    function colorHexFromStyle(style) {
        // Navbar settings store styles as solid:#RRGGBB or split/gradient strings.
        // QML color properties need a real color, so extract the first hex stop.
        const match = String(style || "#111318").match(/#[0-9A-Fa-f]{6}/)
        return match ? match[0].toUpperCase() : "#111318"
    }

    function previewIconColor(slot) {
        // The manager uses a light surface: keep default black icons black.
        // A user-selected white icon is previewed in black for visibility only.
        const color = root.colorHexFromStyle(root.settingFor(slot).color)
        return color === "#FFFFFF" ? "#111318" : color
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

        next[root.selectedSlot] = {
            icon: p.icon || root.settingFor(root.selectedSlot).icon,
            color: p.color || root.settingFor(root.selectedSlot).color
        }

        const current = next[root.selectedSlot]
        root.navbarSettings = next
        root.pendingIcon = current.icon
        root.pendingColor = current.color
        root.statusText = "APPLYING"
        iconProcess.running = false
        Qt.callLater(() => iconProcess.running = true)
    }

    function resetSelected() {
        root.patch({
            icon: root.defaultIcon(root.selectedSlot),
            color: "#FFFFFF"
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
        onLoaded: root.loadSettings(this.text())
        onFileChanged: root.loadSettings(this.text())
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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                radius: 8
                color: "transparent"
                border.width: 0
                border.color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "←"
                    color: root.textSecondary
                    font.pixelSize: 17
                    font.weight: Font.Normal
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

            }
        }

        NavbarPlacement {
            id: placementControl
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            active: root.active
            onPositionApplied: root.navbarPositionChanged(position)
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
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
            opacity: 1
            clip: true

            StackLayout {
                anchors.fill: parent
                currentIndex: root.currentSection === "workspace" ? 0
                    : root.currentSection === "position" ? 1
                    : root.currentSection === "appearance" ? 2 : 3

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
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
                    spacing: 3

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
                        model: root.slots

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            radius: 7
                            color: root.selectedSlot === modelData.id
                                ? "#E9EDF2"
                                : (slotMouse.containsMouse ? root.cardHover : "transparent")

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Rectangle {
                                    Layout.preferredWidth: 26
                                    Layout.preferredHeight: 26
                                    radius: 0
                                    color: "transparent"
                                    border.width: 0
                                    border.color: "transparent"

                                    NavbarIcon {
                                        anchors.centerIn: parent
                                        width: 18
                                        height: 18
                                        iconName: root.settingFor(modelData.id).icon
                                        iconColor: root.previewIconColor(modelData.id)
                                        refreshRevision: root.navbarIconRevision
                                        active: root.selectedSlot === modelData.id
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: modelData.name
                                        color: root.textPrimary
                                        font.pixelSize: 10
                                        font.weight: Font.Medium
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
                    spacing: 7

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

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
                                iconName: root.settingFor(root.selectedSlot).icon
                                iconColor: root.previewIconColor(root.selectedSlot)
                                refreshRevision: root.navbarIconRevision
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                text: root.selectedSlot.toUpperCase()
                                color: root.textPrimary
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.5
                            }

                            Text {
                                text: root.settingFor(root.selectedSlot).icon
                                    .replace(".svg", "")
                                    .replace("lucide-", "")
                                    .toUpperCase()
                                    + " • " + root.colorHexFromStyle(root.settingFor(root.selectedSlot).color)
                                color: root.textSecondary
                                font.pixelSize: 8
                                font.weight: Font.Medium
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 64
                            Layout.preferredHeight: 26
                            radius: 7
                            color: resetMouse.containsMouse ? "#F0F1F3" : "transparent"
                            border.width: 0
                            border.color: "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "RESET"
                                color: root.textPrimary
                                font.pixelSize: 8
                                font.weight: Font.Medium
                                font.letterSpacing: 0.3
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
                        Layout.preferredHeight: 225
                        clip: true
                        contentWidth: width
                        contentHeight: iconGrid.height

                        GridLayout {
                            id: iconGrid

                            width: iconScroll.width
                            height: Math.ceil(root.iconChoices.length / 6) * 41
                                + Math.max(0, Math.ceil(root.iconChoices.length / 6) - 1) * 4
                            columns: 6
                            rowSpacing: 4
                            columnSpacing: 5

                            Repeater {
                                model: root.iconChoices

                                delegate: Rectangle {
                                    Layout.preferredWidth: (iconGrid.width - 25) / 6
                                    Layout.preferredHeight: 41
                                    radius: 7
                                    color: root.settingFor(root.selectedSlot).icon === modelData.id
                                        ? "#E9EDF2"
                                        : (iconMouse.containsMouse ? root.cardHover : "transparent")
                                    border.width: root.settingFor(root.selectedSlot).icon === modelData.id ? 1 : 0
                                    border.color: root.settingFor(root.selectedSlot).icon === modelData.id
                                        ? "#D4D8DE" : "transparent"

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 3

                                        NavbarIcon {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 18
                                            height: 18
                                            iconName: modelData.id
                                            iconColor: root.previewIconColor(root.selectedSlot)
                                        }

                                        Text {
                                            width: 58
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
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                radius: 12
                                color: "transparent"
                                border.width: root.colorHexFromStyle(root.settingFor(root.selectedSlot).color) === modelData.id.toUpperCase()
                                    ? 1.5 : 0
                                border.color: root.colorHexFromStyle(root.settingFor(root.selectedSlot).color) === modelData.id.toUpperCase()
                                    ? root.accent : "transparent"

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 14
                                    height: 14
                                    radius: 7
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
