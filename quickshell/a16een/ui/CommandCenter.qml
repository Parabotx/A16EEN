import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool opened: false
    property string commandText: ""

    signal closeRequested()
    signal launcherRequested()
    signal dashboardRequested()

    readonly property color surface: "#0B0D12F5"
    readonly property color surfaceSoft: "#11141BF2"
    readonly property color borderColor: "#FFFFFF18"
    readonly property color fieldBackground: "#141821"
    readonly property color fieldBorder: "#FFFFFF18"
    readonly property color fieldFocusBorder: "#FFFFFF32"
    readonly property color primaryText: "#F5F2EA"
    readonly property color secondaryText: "#8D94A3"
    readonly property color accent: "#D7B56D"
    readonly property color selectedBackground: "#FFFFFF0D"

    readonly property var commands: [
        {
            id: "launcher",
            name: "Application Launcher",
            description: "Open the A16EEN application launcher",
            keywords: ["apps", "applications", "launch", "launcher"]
        },
        {
            id: "dashboard",
            name: "Dashboard",
            description: "Open the A16EEN system dashboard",
            keywords: ["system", "status", "dashboard"]
        },
        {
            id: "overview",
            name: "Workspace Overview",
            description: "Show the Niri workspace overview",
            keywords: ["workspaces", "windows", "overview"]
        },
        {
            id: "restart-shell",
            name: "Restart A16EEN Shell",
            description: "Restart the desktop shell",
            keywords: ["reload", "restart", "shell", "quickshell"]
        },
        {
            id: "doctor",
            name: "A16EEN Doctor",
            description: "Run A16EEN foundation diagnostics",
            keywords: ["diagnostics", "doctor", "health", "check"]
        }
    ]

    readonly property var filteredCommands: {
        const query = root.commandText.trim().toLowerCase()
        if (!query)
            return root.commands

        return root.commands.filter(command => {
            const haystack = [
                command.name,
                command.description,
                ...(command.keywords || [])
            ].join(" ").toLowerCase()

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
        opacity: root.opened ? 0.18 : 0
    }

    Rectangle {
        id: card
        z: 2
        width: Math.min(560, parent.width - 48)
        height: Math.min(380, parent.height - 120)
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 120
        radius: 24
        color: root.surface
        border.width: 1
        border.color: root.borderColor

        Rectangle {
            anchors.fill: parent
            anchors.margins: -5
            radius: 29
            color: "#30000000"
            z: -1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "A16EEN"
                    color: root.accent
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    font.letterSpacing: 2
                }

                Text {
                    text: "COMMAND CENTER"
                    color: root.secondaryText
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    font.letterSpacing: 1.2
                    Layout.fillWidth: true
                }

                Text {
                    text: "ESC"
                    color: "#5D6471"
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                }
            }

            Rectangle {
                id: searchBox
                Layout.fillWidth: true
                height: 54
                radius: 15
                color: search.activeFocus ? "#171B24" : root.fieldBackground
                border.width: 1
                border.color: search.activeFocus
                    ? root.fieldFocusBorder
                    : root.fieldBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Text {
                        text: "/"
                        color: root.accent
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                        verticalAlignment: Text.AlignVCenter
                    }

                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        color: root.primaryText
                        selectionColor: "#FFFFFF18"
                        selectedTextColor: root.primaryText
                        font.pixelSize: 13
                        clip: true
                        focus: root.opened
                        activeFocusOnPress: true
                        verticalAlignment: Text.AlignVCenter
                        selectByMouse: true

                        onTextChanged: {
                            root.commandText = text
                            commandList.currentIndex = commandList.count > 0 ? 0 : -1
                        }

                        Keys.onEscapePressed: root.closeRequested()

                        Keys.onReturnPressed: {
                            if (commandList.currentItem)
                                root.executeCommand(commandList.currentItem.modelData)
                        }

                        Keys.onDownPressed: {
                            if (commandList.count > 0)
                                commandList.currentIndex = Math.min(
                                    commandList.count - 1,
                                    commandList.currentIndex + 1
                                )
                        }

                        Keys.onUpPressed: {
                            if (commandList.count > 0)
                                commandList.currentIndex = Math.max(
                                    0,
                                    commandList.currentIndex - 1
                                )
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Type an A16EEN command"
                            color: "#626A78"
                            font.pixelSize: 12
                            visible: search.text.length === 0
                        }
                    }
                }
            }

            Text {
                text: root.commandText.length
                    ? "MATCHING COMMANDS"
                    : "A16EEN COMMANDS"
                color: "#626A78"
                font.pixelSize: 8
                font.weight: Font.DemiBold
                font.letterSpacing: 1.5
            }

            ListView {
                id: commandList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 5
                model: root.filteredCommands
                currentIndex: count > 0 ? 0 : -1

                delegate: Rectangle {
                    id: commandRow
                    required property var modelData

                    width: commandList.width
                    height: 54
                    radius: 13
                    color: commandList.currentIndex === index
                        ? root.selectedBackground
                        : "transparent"

                    Rectangle {
                        width: 3
                        height: 22
                        radius: 2
                        anchors.left: parent.left
                        anchors.leftMargin: 7
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.accent
                        visible: commandList.currentIndex === index
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            width: parent.width
                            text: commandRow.modelData.name
                            color: root.primaryText
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: commandRow.modelData.description
                            color: root.secondaryText
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: commandList.currentIndex === index ? "↵" : ""
                        color: "#626A78"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: commandList.currentIndex = index
                        onClicked: root.executeCommand(commandRow.modelData)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: commandList.count === 0
                    text: "No A16EEN command found"
                    color: root.secondaryText
                    font.pixelSize: 10
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
            Quickshell.execDetached([
                "niri", "msg", "action", "toggle-overview"
            ])
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
            root.commandText = ""
            search.text = ""
            Qt.callLater(() => search.forceActiveFocus())
        } else {
            root.commandText = ""
            search.text = ""
        }
    }
}
