import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: root

    required property var modelData
    property bool opened: false
    property string searchText: ""
    property string launchError: ""

    property color cardColor: "#0B0D12F5"
    property color cardBorder: "#FFFFFF18"
    property color primaryText: "#F5F2EA"
    property color secondaryText: "#8D94A3"
    property color accent: "#D7B56D"
    property color errorAccent: "#E88F8F"

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
    WlrLayershell.namespace: "a16een-launcher"
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    function launch(entry) {
        root.launchError = ""

        if (!entry) {
            root.launchError = "No application selected."
            return false
        }

        if (!entry.command || entry.command.length === 0) {
            root.launchError = entry.name + " does not provide a launch command."
            return false
        }

        try {
            if (entry.runInTerminal) {
                // Respect desktop entries that explicitly request a terminal.
                Quickshell.execDetached({
                    command: ["foot", "--", ...entry.command],
                    workingDirectory: entry.workingDirectory || undefined
                })
            } else {
                // Uses the parsed desktop-entry command and its working directory.
                entry.execute()
            }

            root.opened = false
            return true
        } catch (error) {
            root.launchError = "Couldn't launch " + entry.name + ". Check the app installation."
            console.error("A16EEN launcher:", entry.name, error)
            return false
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.opened ? 0.20 : 0
    }

    Rectangle {
        id: card
        z: 2
        width: Math.min(470, parent.width - 118)
        height: Math.min(560, parent.height - 76)
        anchors.left: parent.left
        anchors.leftMargin: 104
        anchors.verticalCenter: parent.verticalCenter
        radius: 23
        color: root.cardColor
        border.width: 1
        border.color: root.cardBorder

        Behavior on scale {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 140
            }
        }

        scale: root.opened ? 1.0 : 0.96
        opacity: root.opened ? 1.0 : 0.0

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "A16"
                    color: root.accent
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.5
                }

                Text {
                    text: "QUICK LAUNCH"
                    color: root.secondaryText
                    font.pixelSize: 9
                    font.letterSpacing: 1.8
                    Layout.fillWidth: true
                }

                Text {
                    text: DesktopEntries.applications.values.length + " APPS"
                    color: "#5C6470"
                    font.pixelSize: 9
                    font.letterSpacing: 0.7
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 52
                radius: 15
                color: "#FFFFFF09"
                border.width: 1
                border.color: "#FFFFFF12"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 15
                    anchors.rightMargin: 15

                    Text {
                        text: "⌕"
                        color: root.accent
                        font.pixelSize: 23
                        Layout.alignment: Qt.AlignVCenter
                    }

                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        color: root.primaryText
                        selectionColor: "#D7B56D55"
                        selectedTextColor: root.primaryText
                        font.pixelSize: 14
                        clip: true
                        focus: root.opened
                        activeFocusOnPress: true
                        text: root.searchText
                        onTextChanged: {
                            root.searchText = text
                            appList.currentIndex = appList.count > 0 ? 0 : -1
                            root.launchError = ""
                        }

                        Keys.onEscapePressed: root.opened = false

                        Keys.onReturnPressed: {
                            if (appList.currentItem && appList.currentItem.entry) {
                                root.launch(appList.currentItem.entry)
                            }
                        }

                        Keys.onDownPressed: {
                            if (appList.count > 0) {
                                appList.currentIndex = Math.min(
                                    appList.count - 1,
                                    appList.currentIndex + 1
                                )
                            }
                        }

                        Keys.onUpPressed: {
                            if (appList.count > 0) {
                                appList.currentIndex = Math.max(
                                    0,
                                    appList.currentIndex - 1
                                )
                            }
                        }

                        Component.onCompleted: if (root.opened) forceActiveFocus()
                    }

                    Text {
                        text: "ESC"
                        color: root.secondaryText
                        font.pixelSize: 9
                        font.letterSpacing: 1.2
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }

            Text {
                text: root.searchText.length ? "MATCHES" : "INSTALLED APPLICATIONS"
                color: root.secondaryText
                font.pixelSize: 9
                font.letterSpacing: 2
            }

            ListView {
                id: appList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 5
                currentIndex: count > 0 ? 0 : -1

                model: ScriptModel {
                    objectProp: "id"
                    values: [...DesktopEntries.applications.values].filter(entry => {
                        if (!root.searchText.length) return true

                        const q = root.searchText.toLowerCase().trim()
                        const haystack = [
                            entry.name,
                            entry.genericName,
                            entry.comment,
                            ...(entry.keywords || [])
                        ].filter(value => value).join(" ").toLowerCase()

                        return haystack.includes(q)
                    }).sort((a, b) => (a.name || "").localeCompare(b.name || ""))
                }

                delegate: Rectangle {
                    id: appRow
                    width: appList.width
                    height: 58
                    radius: 15
                    color: ListView.isCurrentItem ? "#D7B56D16" : "#FFFFFF06"
                    border.width: ListView.isCurrentItem ? 1 : 0
                    border.color: "#D7B56D55"

                    property var entry: modelData

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        IconImage {
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 34
                            implicitHeight: 34
                            source: Quickshell.iconPath(
                                appRow.entry.icon,
                                "application-x-executable"
                            )
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: appRow.entry.name
                                color: root.primaryText
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: appRow.entry.runInTerminal
                                    ? "Terminal application"
                                    : (appRow.entry.genericName || appRow.entry.comment || "Application")
                                color: root.secondaryText
                                font.pixelSize: 9
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Text {
                            text: "↵"
                            color: ListView.isCurrentItem ? root.accent : "#4E5561"
                            font.pixelSize: 15
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: appList.currentIndex = index
                        onClicked: root.launch(appRow.entry)
                    }
                }

                footer: Text {
                    visible: appList.count === 0
                    text: "No application matches that search."
                    color: root.secondaryText
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    width: appList.width
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: root.launchError.length > 0
                implicitHeight: 42
                radius: 12
                color: "#E88F8F12"
                border.width: 1
                border.color: "#E88F8F35"

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: Text.AlignVCenter
                    text: root.launchError
                    color: root.errorAccent
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "A16EEN"
                    color: root.accent
                    font.pixelSize: 9
                    font.letterSpacing: 1.4
                }

                Text {
                    text: "ENTER TO OPEN  •  ↑↓ NAVIGATE  •  INSTALLED APPS ONLY"
                    color: root.secondaryText
                    font.pixelSize: 9
                    font.letterSpacing: 0.7
                    Layout.fillWidth: true
                }
            }
        }
    }

    MouseArea {
        z: 1
        anchors.fill: parent
        onClicked: root.opened = false
    }

    onOpenedChanged: {
        root.launchError = ""

        if (opened) {
            Qt.callLater(() => search.forceActiveFocus())
        } else {
            search.text = ""
        }
    }
}
