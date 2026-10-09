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


    readonly property color page: "#F3F5F7"
    readonly property color card: "#F7F8FA"
    readonly property color cardHover: "#EEF2F6"
    readonly property color border: "#D9DEE5"
    readonly property color borderStrong: "#B8C1CC"
    readonly property color textPrimary: "#111318"
    readonly property color textSecondary: "#5C6673"
    readonly property color textMuted: "#66707C"
    readonly property color accent: "#3B82F6"

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
                    text: "LUCIDE ICONS • COLOR • WORKSPACE APPEARANCE"
                    color: root.textMuted
                    font.pixelSize: 8
                    font.weight: Font.Medium
                    font.letterSpacing: 0.7
                }
            }
        }

        NavbarPlacement {
            id: placementControl
            Layout.fillWidth: true
            Layout.preferredHeight: 58
            active: root.active
            onPositionApplied: root.navbarPositionChanged(position)
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 196
                Layout.fillHeight: true
                radius: 17
                color: "#F7F8FA"
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
                        model: root.slots

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 62
                            radius: 13
                            color: root.selectedSlot === modelData.id
                                ? "#E4EAF1"
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
                                    color: root.selectedSlot === modelData.id ? "#E7EDF4" : "#FFFFFF"
                                    border.width: 1
                                    border.color: root.selectedSlot === modelData.id ? "#B8C1CC" : root.border

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
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: modelData.description
                                        color: root.textMuted
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
                color: "#F7F8FA"
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
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1
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
                            Layout.preferredWidth: 78
                            Layout.preferredHeight: 30
                            radius: 10
                            color: resetMouse.containsMouse ? "#EEF2F6" : "#FFFFFF"
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
                                        ? "#E4EAF1"
                                        : (iconMouse.containsMouse ? root.cardHover : "#FFFFFF")
                                    border.width: root.settingFor(root.selectedSlot).icon === modelData.id ? 1.3 : 1
                                    border.color: root.settingFor(root.selectedSlot).icon === modelData.id
                                        ? "#8E9AA8" : root.border

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 3

                                        NavbarIcon {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 20
                                            height: 20
                                            iconName: modelData.id
                                            iconColor: root.previewIconColor(root.selectedSlot)
                                        }

                                        Text {
                                            width: 58
                                            horizontalAlignment: Text.AlignHCenter
                                            text: modelData.name
                                            color: root.textPrimary
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
                                border.width: root.colorHexFromStyle(root.settingFor(root.selectedSlot).color) === modelData.id.toUpperCase()
                                    ? 1.5 : 1
                                border.color: root.colorHexFromStyle(root.settingFor(root.selectedSlot).color) === modelData.id.toUpperCase()
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
