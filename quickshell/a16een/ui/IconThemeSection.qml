import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

Item {
    id: root

    property bool active: false
    signal backRequested()
    signal themeChangeRequested(string themeId)

    property string currentTheme: "system"
    property string statusMessage: "READING ICON THEMES"
    property var themes: []

    readonly property color page: "#FFFFFF"
    readonly property color card: "#F7F8FA"
    readonly property color cardHover: "#EEF1F4"
    readonly property color border: "#E1E5EA"
    readonly property color borderStrong: "#CDD3DA"
    readonly property color textPrimary: "#111318"
    readonly property color textSecondary: "#66707C"
    readonly property color textMuted: "#8A939E"
    readonly property color accent: "#B18B3F"

    function iconSource(name) {
        return Qt.resolvedUrl("../assets/icons/lucide-" + name + "-dark.svg")
    }

    function loadThemes() {
        if (!root.active || themeReader.running)
            return
        themeReader.running = true
    }

    function parseThemes(output) {
        const result = []
        const lines = String(output || "").split("\n")

        for (const raw of lines) {
            if (!raw.trim())
                continue

            const parts = raw.split("|")
            if (parts.length < 5)
                continue

            result.push({
                id: parts[0],
                name: parts[1],
                description: parts[2],
                installed: parts[3] === "1",
                themeName: parts[4]
            })
        }

        root.themes = result
        root.statusMessage = result.length ? "THEME LIBRARY READY" : "NO THEMES FOUND"
        root.currentThemeReader.running = true
    }

    function parseCurrent(output) {
        root.currentTheme = String(output || "").trim() || "system"
    }

    function applyTheme(theme) {
        if (!theme || actionProcess.running)
            return

        root.statusMessage = !theme.installed
            ? "INSTALLING " + theme.name.toUpperCase()
            : "APPLYING " + theme.name.toUpperCase()

        root.actionId = theme.id
        actionProcess.running = true
    }

    function activeFor(theme) {
        return theme.id === "system"
            ? root.currentTheme === "system"
            : root.currentTheme === theme.themeName
    }

    Process {
        id: themeReader
        command: ["a16een-icon-theme", "list"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.parseThemes(text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length)
                    root.statusMessage = "ICON THEME SERVICE UNAVAILABLE"
            }
        }
    }

    Process {
        id: currentThemeReader
        command: ["a16een-icon-theme", "current"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.parseCurrent(text)
        }
    }

    property string actionId: ""

    Process {
        id: actionProcess
        command: {
            const theme = String(root.actionId || "")
            return theme ? ["a16een-icon-theme", "set", theme] : ["true"]
        }
        running: false

        stdout: StdioCollector { }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length)
                    root.statusMessage = "INSTALL / APPLY ERROR"
            }
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                const selected = root.themes.find(item => item.id === root.actionId)
                if (selected) {
                    root.currentTheme = selected.id === "system" ? "system" : selected.themeName
                    root.statusMessage = "APPLIED " + selected.name.toUpperCase()
                    root.themeChangeRequested(selected.id)
                } else {
                    root.statusMessage = "THEME APPLIED"
                }
                // A16EEN stays alive while the launcher refreshes its icon map.
                // The selected theme is also written to GTK settings for external apps.
            } else {
                root.statusMessage = "INSTALL / APPLY ERROR"
                root.currentThemeReader.running = true
                root.themeReader.running = true
            }
        }
    }

    Component.onCompleted: root.loadThemes()

    Item {
        anchors.fill: parent
        anchors.margins: 26

        Row {
            id: header
            width: parent.width
            height: 54
            spacing: 14

            Rectangle {
                width: 38
                height: 38
                radius: 11
                color: root.card
                border.width: 1
                border.color: root.border
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    source: root.iconSource("arrow-left")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backRequested()
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    text: "ICON THEMES"
                    color: root.textPrimary
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.3
                }

                Text {
                    text: "APP ICONS • FOLDERS • SYSTEM LOOK  •  " + root.statusMessage
                    color: root.textMuted
                    font.pixelSize: 8
                    font.weight: Font.Medium
                    font.letterSpacing: 0.7
                }
            }
        }

        Rectangle {
            id: previewCard
            anchors.top: header.bottom
            anchors.topMargin: 12
            width: parent.width
            height: 86
            radius: 17
            color: "#FBFCFD"
            border.width: 1
            border.color: root.border

            Column {
                x: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    text: "CURRENT ICON THEME"
                    color: root.textMuted
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.0
                }

                Text {
                    text: root.currentTheme === "system" ? "SYSTEM DEFAULT" : root.currentTheme
                    color: root.textPrimary
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                spacing: 11

                IconImage {
                    implicitWidth: 27
                    implicitHeight: 27
                    source: Quickshell.iconPath("application-x-executable", "application-x-executable")
                }

                IconImage {
                    implicitWidth: 27
                    implicitHeight: 27
                    source: Quickshell.iconPath("folder", "inode-directory")
                }

                IconImage {
                    implicitWidth: 27
                    implicitHeight: 27
                    source: Quickshell.iconPath("folder-open", "inode-directory")
                }
            }
        }

        Flickable {
            anchors.top: previewCard.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true
            contentHeight: themeColumn.height

            Column {
                id: themeColumn
                width: parent.width
                spacing: 8

                Repeater {
                    model: root.themes

                    delegate: Rectangle {
                        width: themeColumn.width
                        height: 72
                        radius: 15
                        color: {
                            if (themeMouse.containsMouse)
                                return root.cardHover
                            return root.card
                        }
                        border.width: active ? 1.4 : 1
                        border.color: active ? "#B18B3F" : root.border

                        readonly property bool active: root.activeFor(modelData)

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 15
                            anchors.rightMargin: 15
                            spacing: 13

                            Rectangle {
                                width: 38
                                height: 38
                                radius: 11
                                color: "#FFFFFF"
                                border.width: 1
                                border.color: root.border
                                anchors.verticalCenter: parent.verticalCenter

                                IconImage {
                                    anchors.centerIn: parent
                                    implicitWidth: 22
                                    implicitHeight: 22
                                    source: root.iconSource("folder")
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 225
                                spacing: 4

                                Text {
                                    text: modelData.name
                                    color: root.textPrimary
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    width: parent.width
                                    text: modelData.description
                                    color: root.textSecondary
                                    font.pixelSize: 8
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: !modelData.installed
                                    text: "FIRST USE INSTALL • THEME STORED LOCALLY"
                                    color: root.textMuted
                                    font.pixelSize: 6
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.6
                                }
                            }

                            Rectangle {
                                width: 86
                                height: 32
                                radius: 10
                                anchors.verticalCenter: parent.verticalCenter
                                color: active ? "#111318" : "#FFFFFF"
                                border.width: active ? 0 : 1
                                border.color: root.borderStrong

                                Text {
                                    anchors.centerIn: parent
                                    text: active
                                        ? "ACTIVE"
                                        : modelData.installed
                                            ? "APPLY"
                                            : "INSTALL"
                                    color: active ? "#FFFFFF" : root.textPrimary
                                    font.pixelSize: 7
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.8
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.applyTheme(modelData)
                                }
                            }
                        }

                        MouseArea {
                            id: themeMouse
                            anchors.fill: parent
                            anchors.rightMargin: 102
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.applyTheme(modelData)
                        }
                    }
                }
            }
        }
    }

    onActiveChanged: {
        if (active) {
            root.statusMessage = "READING ICON THEMES"
            root.loadThemes()
        }
    }

    Keys.onEscapePressed: root.backRequested()

    focus: root.active
    activeFocusOnTab: true
}
