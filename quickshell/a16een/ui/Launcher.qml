import QtQuick
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

    signal closeRequested()

    readonly property color surface: "#FFFFFFFF"
    readonly property color borderColor: "#E6E8EB"
    readonly property color primaryText: "#15171A"
    readonly property color secondaryText: "#737880"
    readonly property color searchBackground: "#F7F8FA"
    readonly property color selectedBackground: "#EEF0F3"

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
    WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    function launch(entry) {
        root.launchError = ""

        if (!entry) {
            root.launchError = "No application selected."
            return false
        }

        try {
            entry.execute()
            root.closeRequested()
            return true
        } catch (error) {
            root.launchError = "Couldn't launch " + entry.name + "."
            console.error("A16EEN launcher:", entry.name, error)
            return false
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.opened ? 0.16 : 0
    }

    Rectangle {
        id: card
        z: 2
        width: Math.min(780, parent.width - 116)
        height: Math.min(650, parent.height - 90)
        anchors.centerIn: parent
        radius: 28
        color: root.surface
        border.width: 1
        border.color: root.borderColor

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            Rectangle {
                Layout.fillWidth: true
                height: 58
                radius: 17
                color: root.searchBackground
                border.width: 1
                border.color: "#E9EBEE"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    Text {
                        text: "⌕"
                        color: root.primaryText
                        font.pixelSize: 23
                        Layout.alignment: Qt.AlignVCenter
                    }

                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        color: root.primaryText
                        selectionColor: "#11182722"
                        selectedTextColor: root.primaryText
                        font.pixelSize: 14
                        clip: true
                        focus: root.opened
                        activeFocusOnPress: true
                        text: root.searchText
                        selectByMouse: true

                        onTextChanged: {
                            root.searchText = text
                            appGrid.currentIndex = appGrid.count > 0 ? 0 : -1
                            root.launchError = ""
                        }

                        Keys.onEscapePressed: root.closeRequested()

                        Keys.onReturnPressed: {
                            if (appGrid.currentItem && appGrid.currentItem.entry)
                                root.launch(appGrid.currentItem.entry)
                        }

                        Keys.onRightPressed: {
                            if (appGrid.currentIndex >= 0)
                                appGrid.currentIndex = Math.min(
                                    appGrid.count - 1,
                                    appGrid.currentIndex + 1
                                )
                        }

                        Keys.onLeftPressed: {
                            if (appGrid.currentIndex > 0)
                                appGrid.currentIndex -= 1
                        }

                        Keys.onDownPressed: {
                            if (appGrid.count > 0)
                                appGrid.currentIndex = Math.min(
                                    appGrid.count - 1,
                                    appGrid.currentIndex + appGrid.columns
                                )
                        }

                        Keys.onUpPressed: {
                            if (appGrid.count > 0)
                                appGrid.currentIndex = Math.max(
                                    0,
                                    appGrid.currentIndex - appGrid.columns
                                )
                        }

                        Component.onCompleted: {
                            if (root.opened)
                                forceActiveFocus()
                        }
                    }

                    Text {
                        text: root.searchText.length ? "FILTER" : "SEARCH"
                        color: root.secondaryText
                        font.pixelSize: 8
                        font.letterSpacing: 1.4
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }

            GridView {
                id: appGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: 112
                cellHeight: 106
                currentIndex: count > 0 ? 0 : -1

                model: ScriptModel {
                    objectProp: "id"
                    values: [...DesktopEntries.applications.values]
                        .filter(entry => {
                            if (!root.searchText.length)
                                return true

                            const q = root.searchText.toLowerCase().trim()
                            const haystack = [
                                entry.name,
                                entry.genericName,
                                entry.comment,
                                ...(entry.keywords || [])
                            ].filter(value => value)
                             .join(" ")
                             .toLowerCase()

                            return haystack.includes(q)
                        })
                        .sort((a, b) =>
                            (a.name || "").localeCompare(b.name || "")
                        )
                }

                delegate: Rectangle {
                    required property var modelData

                    width: 102
                    height: 96
                    radius: 18
                    color: GridView.isCurrentItem
                        ? root.selectedBackground
                        : "transparent"
                    border.width: GridView.isCurrentItem ? 1 : 0
                    border.color: "#E0E3E7"

                    property var entry: modelData

                    Column {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 6

                        Item {
                            width: parent.width
                            height: 54

                            IconImage {
                                anchors.centerIn: parent
                                implicitWidth: 46
                                implicitHeight: 46
                                source: Quickshell.iconPath(
                                    delegateItem.entry.icon,
                                    "application-x-executable"
                                )
                            }
                        }

                        Text {
                            id: appName
                            width: parent.width
                            text: delegateItem.entry.name
                            color: root.primaryText
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }

                    readonly property Item delegateItem: this

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: appGrid.currentIndex = index
                        onClicked: root.launch(delegateItem.entry)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: appGrid.count === 0
                    text: "No applications found"
                    color: root.secondaryText
                    font.pixelSize: 12
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: root.launchError.length > 0
                height: 38
                radius: 12
                color: "#FFF5F5"
                border.width: 1
                border.color: "#F1D3D3"

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: Text.AlignVCenter
                    text: root.launchError
                    color: "#9B3A3A"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }
        }
    }

    MouseArea {
        z: 1
        anchors {
            top: parent.top
            left: parent.left
            bottom: parent.bottom
            right: parent.right
            rightMargin: 66
        }
        onClicked: root.closeRequested()
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
