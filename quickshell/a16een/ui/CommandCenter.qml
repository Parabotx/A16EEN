import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool opened: false
    property string commandText: "/"
    property int selectedCommandIndex: 0

    signal closeRequested()
    signal launcherRequested()
    signal dashboardRequested()

    readonly property color surface: "#000000"
    readonly property color borderColor: "#1C1C1C"
    readonly property color fieldBackground: "#0A0A0A"
    readonly property color fieldBorder: "#1F1F1F"
    readonly property color fieldFocusBorder: "#333333"
    readonly property color primaryText: "#F5F5F5"
    readonly property color secondaryText: "#767676"
    readonly property color accent: "#FFFFFF"
    readonly property color selectedBackground: "#111111"

    readonly property var commands: [
        { id: "wallpaper", name: "wallpaper", keywords: ["wallpaper", "background", "image"] },
        { id: "launcher", name: "launcher", keywords: ["launcher", "applications", "apps"] },
        { id: "dashboard", name: "dashboard", keywords: ["dashboard", "system"] },
        { id: "overview", name: "overview", keywords: ["overview", "workspaces", "windows"] },
        { id: "restart-shell", name: "restart-shell", keywords: ["restart", "shell", "reload", "quickshell"] },
        { id: "doctor", name: "doctor", keywords: ["doctor", "diagnostics", "health"] }
    ]

    readonly property string query: {
        const value = root.commandText
        return value.startsWith("/") ? value.slice(1).trim().toLowerCase() : value.trim().toLowerCase()
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

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.opened ? 0.16 : 0
    }

    Rectangle {
        id: card
        z: 2
        width: Math.min(500, parent.width - 48)
        height: Math.min(300, parent.height - 160)
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 185
        radius: 18
        color: root.surface
        border.width: 1
        border.color: root.borderColor

        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: 22
            color: "#22000000"
            z: -1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Rectangle {
                id: searchBox
                Layout.fillWidth: true
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
                    focus: root.opened
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
                                root.filteredCommands[root.selectedCommandIndex]
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
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: "#000000"

                Column {
                    id: commandColumn
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 2

                    Repeater {
                        model: root.filteredCommands

                        delegate: Rectangle {
                            id: commandRow
                            required property var modelData

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
                                text: "/" + commandRow.modelData.name
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
                                onClicked: root.executeCommand(commandRow.modelData)
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
                        topPadding: 12
                    }
                }
            }
        }
    }

    MouseArea {
        z: 1
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    function executeCommand(command) {
        if (!command)
            return

        switch (command.id) {
        case "wallpaper":
            root.closeRequested()
            Quickshell.execDetached(["a16een", "wallpaper", "next"])
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
        if (opened) {
            root.commandText = "/"
            root.selectedCommandIndex = 0
            search.text = "/"
            Qt.callLater(() => search.forceActiveFocus())
        } else {
            root.commandText = "/"
            root.selectedCommandIndex = 0
            search.text = "/"
        }
    }
}
