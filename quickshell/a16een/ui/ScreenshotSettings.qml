import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool opened: false
    property string saveDirectory: "~/Pictures/Screenshots"
    property bool copyToClipboard: true
    property bool showPointer: true
    property int delaySeconds: 0

    signal closeRequested()

    readonly property color textPrimary: "#15171A"
    readonly property color textSecondary: "#66717F"
    readonly property color accent: "#2F80ED"
    readonly property color surface: "#FFFFFF"
    readonly property color soft: "#F7F9FB"
    readonly property color border: "#DEE5EB"

    screen: modelData
    color: "transparent"
    visible: root.opened
    focusable: root.opened
    aboveWindows: true
    exclusiveZone: 0

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-screenshot-settings"
    WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    function saveSetting(key, value) {
        settingsProcess.command = [
            "a16een-screenshot",
            "settings",
            "set",
            key,
            String(value)
        ]
        settingsProcess.running = false
        settingsProcess.running = true
    }

    Process {
        id: settingsReader
        command: ["a16een-screenshot", "settings", "get"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split(/?
/)
                for (const line of lines) {
                    const parts = line.split("=")
                    if (parts.length < 2)
                        continue

                    const key = parts[0]
                    const value = parts.slice(1).join("=")

                    if (key === "save_dir")
                        root.saveDirectory = value
                    else if (key === "clipboard")
                        root.copyToClipboard = value === "true"
                    else if (key === "pointer")
                        root.showPointer = value === "true"
                    else if (key === "delay")
                        root.delaySeconds = Number(value) || 0
                }
            }
        }
    }

    Process {
        id: settingsProcess
        running: false
    }

    MouseArea {
        anchors.fill: parent
        z: 0
        onClicked: root.closeRequested()
    }

    Rectangle {
        id: card
        z: 2
        width: Math.min(520, parent.width - 48)
        height: Math.min(430, parent.height - 64)
        anchors.centerIn: parent
        radius: 22
        color: root.surface
        border.width: 1
        border.color: root.border

        Column {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 14

            Row {
                width: parent.width
                height: 34
                spacing: 10

                IconImage {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 20
                    implicitHeight: 20
                    source: Qt.resolvedUrl("../assets/icons/lucide-settings.svg")
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "SCREENSHOT SETTINGS"
                    color: root.textPrimary
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.1
                }

                Item { width: parent.width - 250; height: 1 }

                Rectangle {
                    width: 34
                    height: 34
                    radius: 10
                    color: closeMouse.containsMouse ? "#EEF1F4" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: root.textSecondary
                        font.pixelSize: 17
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 72
                radius: 14
                color: root.soft
                border.width: 1
                border.color: root.border

                Row {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 18
                        implicitHeight: 18
                        source: Qt.resolvedUrl("../assets/icons/lucide-folder-open.svg")
                    }

                    Column {
                        width: parent.width - 32
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        Text {
                            text: "SAVE LOCATION"
                            color: root.textPrimary
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                        }

                        TextInput {
                            id: pathInput
                            width: parent.width
                            text: root.saveDirectory
                            color: root.textSecondary
                            font.pixelSize: 8
                            clip: true
                            selectByMouse: true

                            onEditingFinished: {
                                root.saveDirectory = text
                                root.saveSetting("save_dir", text)
                            }
                        }
                    }
                }
            }

            Repeater {
                model: [
                    { key: "clipboard", title: "COPY TO CLIPBOARD", icon: "../assets/icons/lucide-clipboard.svg" },
                    { key: "pointer", title: "SHOW POINTER", icon: "../assets/icons/lucide-mouse-pointer.svg" }
                ]

                delegate: Rectangle {
                    required property var modelData

                    width: parent.width
                    height: 56
                    radius: 13
                    color: root.soft
                    border.width: 1
                    border.color: root.border

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 13
                        anchors.rightMargin: 13
                        spacing: 10

                        IconImage {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: 18
                            implicitHeight: 18
                            source: Qt.resolvedUrl(modelData.icon)
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.title
                            color: root.textPrimary
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.7
                        }

                        Item { width: parent.width - 190; height: 1 }

                        Rectangle {
                            width: 42
                            height: 24
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 12
                            color: modelData.key === "clipboard"
                                ? (root.copyToClipboard ? root.accent : "#D7DEE6")
                                : (root.showPointer ? root.accent : "#D7DEE6")

                            Rectangle {
                                width: 18
                                height: 18
                                y: 3
                                x: modelData.key === "clipboard"
                                    ? (root.copyToClipboard ? 21 : 3)
                                    : (root.showPointer ? 21 : 3)
                                radius: 9
                                color: "#FFFFFF"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.key === "clipboard") {
                                        root.copyToClipboard = !root.copyToClipboard
                                        root.saveSetting("clipboard", root.copyToClipboard)
                                    } else {
                                        root.showPointer = !root.showPointer
                                        root.saveSetting("pointer", root.showPointer)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 72
                radius: 14
                color: root.soft
                border.width: 1
                border.color: root.border

                Row {
                    anchors.fill: parent
                    anchors.margins: 13
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "CAPTURE DELAY"
                        color: root.textPrimary
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.7
                    }

                    Item { width: parent.width - 245; height: 1 }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Repeater {
                            model: [0, 3, 5]

                            delegate: Rectangle {
                                required property int modelData

                                width: 48
                                height: 30
                                radius: 10
                                color: root.delaySeconds === modelData ? "#EAF3FF" : "#FFFFFF"
                                border.width: 1
                                border.color: root.delaySeconds === modelData ? "#BBD7F5" : root.border

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData === 0 ? "NOW" : modelData + "S"
                                    color: root.delaySeconds === modelData ? root.accent : root.textSecondary
                                    font.pixelSize: 7
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.delaySeconds = modelData
                                        root.saveSetting("delay", modelData)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                width: parent.width
                text: "PNG • PREVIEW 2S"
                color: "#98A3AE"
                font.pixelSize: 6
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
            }
        }
    }

    Keys.onEscapePressed: root.closeRequested()

    onOpenedChanged: {
        if (root.opened) {
            settingsReader.running = false
            settingsReader.running = true
            Qt.callLater(() => pathInput.forceActiveFocus())
        }
    }
}
