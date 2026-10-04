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

    property color cardColor: "#0B0D12F5"
    property color cardBorder: "#FFFFFF18"
    property color primaryText: "#F5F2EA"
    property color secondaryText: "#8D94A3"
    property color accent: "#D7B56D"

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

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.opened ? 0.42 : 0
    }

    Rectangle {
        id: card
        width: Math.min(760, parent.width - 48)
        height: Math.min(680, parent.height - 120)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 76
        radius: 24
        color: root.cardColor
        border.width: 1
        border.color: root.cardBorder

        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 140 } }

        scale: root.opened ? 1.0 : 0.96
        opacity: root.opened ? 1.0 : 0.0

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 54
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
                            font.pixelSize: 16
                            clip: true
                            focus: root.opened
                            activeFocusOnPress: true
                            text: root.searchText
                            onTextChanged: {
                                root.searchText = text
                                appList.currentIndex = 0
                            }
                            Keys.onEscapePressed: root.opened = false
                            Keys.onReturnPressed: {
                                if (appList.currentItem && appList.currentItem.entry) {
                                    appList.currentItem.entry.execute()
                                    root.opened = false
                                }
                            }
                            Keys.onDownPressed: {
                                appList.currentIndex = Math.min(appList.count - 1, appList.currentIndex + 1)
                            }
                            Keys.onUpPressed: {
                                appList.currentIndex = Math.max(0, appList.currentIndex - 1)
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
            }

            Text {
                text: root.searchText.length ? "APPLICATIONS / FILTERED" : "APPLICATIONS"
                color: root.secondaryText
                font.pixelSize: 9
                font.letterSpacing: 2
            }

            ListView {
                id: appList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                currentIndex: 0
                model: ScriptModel {
                    values: [...DesktopEntries.applications.values].filter(entry => {
                        if (!root.searchText.length) return true
                        const q = root.searchText.toLowerCase()
                        const haystack = [
                            entry.name,
                            entry.genericName,
                            entry.comment,
                            ...(entry.keywords || [])
                        ].filter(value => value).join(" ").toLowerCase()
                        return haystack.includes(q)
                    })
                }

                delegate: Rectangle {
                    id: appRow
                    width: appList.width
                    height: 68
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
                            implicitWidth: 40
                            implicitHeight: 40
                            source: Quickshell.iconPath(appRow.entry.icon, "application-x-executable")
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: appRow.entry.name
                                color: root.primaryText
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: appRow.entry.genericName || appRow.entry.comment || "Application"
                                color: root.secondaryText
                                font.pixelSize: 10
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
                        onClicked: {
                            appRow.entry.execute()
                            root.opened = false
                        }
                    }
                }

                footer: Text {
                    visible: appList.count === 0
                    text: "No application matches that search."
                    color: root.secondaryText
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
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
                    text: "SEARCH • ENTER TO OPEN"
                    color: root.secondaryText
                    font.pixelSize: 9
                    font.letterSpacing: 1.1
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.opened = false
    }

    onOpenedChanged: {
        if (opened) {
            Qt.callLater(() => search.forceActiveFocus())
        } else {
            search.text = ""
        }
    }
}
