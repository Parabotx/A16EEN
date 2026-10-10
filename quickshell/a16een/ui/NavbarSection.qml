import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool active: false
    property var navbarSettings: ({})
    property string navbarIconRoot: ""
    property int navbarIconRevision: 0
    signal backRequested()
    signal navbarSettingsChanged(var settings)

    property string selectedSlot: "home"

    readonly property color page: "#FFFFFF"
    readonly property color card: "#F7F8FA"
    readonly property color cardHover: "#EEF1F4"
    readonly property color border: "#E1E5EA"
    readonly property color borderStrong: "#CDD3DA"
    readonly property color textPrimary: "#111318"
    readonly property color textSecondary: "#66707C"
    readonly property color textMuted: "#8A939E"
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
        { id: "house-heart.svg", name: "House Heart" },
        { id: "house-plus.svg", name: "House Plus" },
        { id: "house-wifi.svg", name: "House WiFi" },
        { id: "monitor.svg", name: "Monitor" },
        { id: "app-window.svg", name: "App Window" },
        { id: "folder.svg", name: "Folder" },
        { id: "folder-open.svg", name: "Folder Open" },
        { id: "code.svg", name: "Code" },
        { id: "code-2.svg", name: "Code 2" },
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
        { id: "alien.svg", name: "Alien" },
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
        { id: "circle-help.svg", name: "Help" },
        { id: "graduation-cap.svg", name: "Graduation" },
        { id: "briefcase-business.svg", name: "Briefcase" },
        { id: "cloud.svg", name: "Cloud" },
        { id: "map-pin.svg", name: "Map Pin" },
        { id: "compass.svg", name: "Compass" },
        { id: "command.svg", name: "Command" }
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
        if (!root.navbarIconRoot.length)
            return root.baseIconPath(slot)
        return "file://" + root.navbarIconRoot + "/" + slot + ".svg"
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

        root.navbarSettingsChanged(next)
    }

    function resetSelected() {
        root.patch({
            icon: root.defaultIcon(root.selectedSlot),
            color: "#111318"
        })
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
                        model: root.slots

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
                                        preserveSourceColors: true
                                        iconColor: root.selectedSlot === modelData.id ? "#FFFFFF" : root.textPrimary
                                        refreshRevision: root.navbarIconRevision
                                        active: root.selectedSlot === modelData.id
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: modelData.name
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
                                preserveSourceColors: true
                                iconColor: root.textPrimary
                                refreshRevision: root.navbarIconRevision
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                text: root.selectedSlot.toUpperCase()
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
                                            iconColor: root.settingFor(root.selectedSlot).icon === modelData.id ? "#FFFFFF" : root.textSecondary
                                        }

                                        Text {
                                            width: 58
                                            horizontalAlignment: Text.AlignHCenter
                                            text: modelData.name
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
    focus: root.active
    activeFocusOnTab: true
}
