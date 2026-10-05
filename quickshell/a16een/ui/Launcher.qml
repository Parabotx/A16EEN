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
    readonly property color borderColor: "#E4E7EB"
    readonly property color primaryText: "#15171A"
    readonly property color secondaryText: "#7A7F87"
    readonly property color searchBackground: "#F6F7F8"
    readonly property color selectedBackground: "#EEF1F3"

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
        opacity: root.opened ? 0.12 : 0
    }

    Rectangle {
        id: card
        z: 2
        width: Math.min(560, parent.width - 80)
        height: Math.min(430, parent.height - 100)
        anchors.centerIn: parent
        radius: 24
        color: root.surface
        border.width: 1
        border.color: root.borderColor

        Rectangle {
            anchors.fill: parent
            anchors.margins: -5
            radius: 29
            color: "#12000000"
            z: -1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: 14
                color: root.searchBackground
                border.width: 1
                border.color: "#E7E9EC"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 13
                    anchors.rightMargin: 13
                    spacing: 9

                    Image {
                        Layout.alignment: Qt.AlignVCenter
                        width: 17
                        height: 17
                        source: Qt.resolvedUrl("../assets/icons/search.svg")
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        mipmap: true
                        smooth: true
                    }

                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        color: root.primaryText
                        selectionColor: "#DDE2E7"
                        selectedTextColor: root.primaryText
                        font.pixelSize: 12
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
                            if (appGrid.count > 0) {
                                const columns = Math.max(
                                    1,
                                    Math.floor(appGrid.width / appGrid.cellWidth)
                                )
                                appGrid.currentIndex = Math.min(
                                    appGrid.count - 1,
                                    appGrid.currentIndex + columns
                                )
                            }
                        }

                        Keys.onUpPressed: {
                            if (appGrid.count > 0) {
                                const columns = Math.max(
                                    1,
                                    Math.floor(appGrid.width / appGrid.cellWidth)
                                )
                                appGrid.currentIndex = Math.max(
                                    0,
                                    appGrid.currentIndex - columns
                                )
                            }
                        }
                    }

                    Text {
                        text: root.searchText.length ? "FILTER" : "SEARCH"
                        color: root.secondaryText
                        font.pixelSize: 8
                        font.letterSpacing: 1.2
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }

            GridView {
                id: appGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: 86
                cellHeight: 78
                currentIndex: count > 0 ? 0 : -1
                highlightFollowsCurrentItem: true
                highlightMoveDuration: 0

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
                    id: appTile

                    required property var modelData

                    width: 78
                    height: 70
                    radius: 14
                    color: GridView.isCurrentItem
                        ? root.selectedBackground
                        : "transparent"

                    property var entry: modelData

                    Column {
                        anchors.fill: parent
                        anchors.topMargin: 5
                        anchors.bottomMargin: 5
                        anchors.leftMargin: 3
                        anchors.rightMargin: 3
                        spacing: 3

                        Item {
                            width: parent.width
                            height: 38

                            IconImage {
                                anchors.centerIn: parent
                                implicitWidth: 30
                                implicitHeight: 30
                                source: Quickshell.iconPath(
                                    appTile.entry.icon,
                                    "application-x-executable"
                                )
                            }
                        }

                        Text {
                            width: parent.width
                            height: 18
                            text: appTile.entry.name || "Application"
                            color: root.primaryText
                            font.pixelSize: 9
                            font.weight: Font.Medium
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: appGrid.currentIndex = index
                        onClicked: root.launch(appTile.entry)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: appGrid.count === 0
                    text: "No applications found"
                    color: root.secondaryText
                    font.pixelSize: 11
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: root.launchError.length > 0
                height: 32
                radius: 10
                color: "#FFF5F5"
                border.width: 1
                border.color: "#F1D3D3"

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: Text.AlignVCenter
                    text: root.launchError
                    color: "#9B3A3A"
                    font.pixelSize: 9
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
