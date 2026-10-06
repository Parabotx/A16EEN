import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: root

    required property var modelData
    property bool opened: false
    property string searchText: ""
    property string launchError: ""
    property int iconThemeRevision: 0
    property string iconThemeName: "system"
    property var resolvedIconPaths: ({})

    signal closeRequested()

    readonly property color surface: "#FFFFFFFF"
    readonly property color borderColor: "#E4E7EB"
    readonly property color primaryText: "#15171A"
    readonly property color secondaryText: "#7A7F87"
    readonly property color searchBackground: "#F6F7F8"
    readonly property color searchHoverBackground: "#FAFBFC"
    readonly property color searchFocusBackground: "#FFFFFF"
    readonly property color searchBorder: "#E3E6EA"
    readonly property color searchHoverBorder: "#CDD2D8"
    readonly property color searchFocusBorder: "#AEB5BE"
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

    function parseIconTheme(output) {
        root.iconThemeName = String(output || "").trim() || "system"
        root.resolvedIconPaths = ({})
        root.iconResolver.running = true
    }

    function parseIconPaths(output) {
        const result = {}
        const lines = String(output || "").split("\n")

        for (const raw of lines) {
            const tab = raw.indexOf("\t")
            if (tab < 0)
                continue

            const name = raw.slice(0, tab)
            const path = raw.slice(tab + 1)
            if (name && path)
                result[name] = path
        }

        root.resolvedIconPaths = result
    }

    function refreshIconTheme() {
        if (!root.iconThemeReader.running && !root.iconResolver.running)
            root.iconThemeReader.running = true
    }

    function iconSource(iconName) {
        const name = String(iconName || "")
        if (!name)
            return Quickshell.iconPath("application-x-executable", "application-x-executable")

        return root.resolvedIconPaths[name]
            || Quickshell.iconPath(name, "application-x-executable")
    }
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

    Process {
        id: iconThemeReader
        command: ["a16een-icon-theme", "current"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.parseIconTheme(text)
        }
    }

    Process {
        id: iconResolver
        command: {
            const icons = [...DesktopEntries.applications.values]
                .map(entry => String(entry.icon || ""))
                .filter(Boolean)
                .filter((value, index, values) => values.indexOf(value) === index)
            return ["a16een-icon-theme", "resolve", root.iconThemeName, ...icons]
        }
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.parseIconPaths(text)
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
        width: Math.min(480, parent.width - 64)
        height: Math.min(360, parent.height - 80)
        anchors.centerIn: parent
        radius: 22
        color: root.surface
        border.width: 1
        border.color: root.borderColor

        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: 26
            color: "#12000000"
            z: -1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Rectangle {
                id: searchBox
                Layout.preferredWidth: 300
                Layout.alignment: Qt.AlignHCenter
                height: 36
                radius: 12
                color: search.activeFocus
                    ? root.searchFocusBackground
                    : (searchMouse.containsMouse
                        ? root.searchHoverBackground
                        : root.searchBackground)
                border.width: 1
                border.color: search.activeFocus
                    ? root.searchFocusBorder
                    : (searchMouse.containsMouse
                        ? root.searchHoverBorder
                        : root.searchBorder)

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search"
                    color: root.secondaryText
                    font.pixelSize: 11
                    visible: search.text.length === 0 && !search.activeFocus
                }

                TextInput {
                    id: search
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    color: root.primaryText
                    selectionColor: "#DDE2E7"
                    selectedTextColor: root.primaryText
                    font.pixelSize: 11
                    clip: true
                    focus: root.opened
                    activeFocusOnPress: true
                    verticalAlignment: Text.AlignVCenter
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
                            const columns = 5
                            appGrid.currentIndex = Math.min(
                                appGrid.count - 1,
                                appGrid.currentIndex + columns
                            )
                        }
                    }

                    Keys.onUpPressed: {
                        if (appGrid.count > 0) {
                            const columns = 5
                            appGrid.currentIndex = Math.max(
                                0,
                                appGrid.currentIndex - columns
                            )
                        }
                    }
                }

                MouseArea {
                    id: searchMouse
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: true
                    z: 1
                }
            }

            GridView {
                id: appGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: 88
                cellHeight: 72
                currentIndex: count > 0 ? 0 : -1

                model: ScriptModel {
                    id: appModel
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

                    width: 82
                    height: 68
                    radius: 13
                    color: appMouse.containsMouse
                        ? "#F7F8FA"
                        : (GridView.isCurrentItem
                            ? root.selectedBackground
                            : "transparent")

                    property var entry: modelData

                    Column {
                        anchors.fill: parent
                        anchors.topMargin: 4
                        anchors.bottomMargin: 4
                        anchors.leftMargin: 2
                        anchors.rightMargin: 2
                        spacing: 2

                        Item {
                            width: parent.width
                            height: 34

                            IconImage {
                                anchors.centerIn: parent
                                implicitWidth: 28
                                implicitHeight: 28
                                source: root.iconSource(appTile.entry.icon)
                            }
                        }

                        Text {
                            width: parent.width
                            height: 20
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
                        id: appMouse
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
                height: 28
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
                    font.pixelSize: 8
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

    Component.onCompleted: root.refreshIconTheme()

    onIconThemeRevisionChanged: root.refreshIconTheme()
    onOpenedChanged: {
        root.launchError = ""

        if (opened) {
            Qt.callLater(() => search.forceActiveFocus())
        } else {
            search.text = ""
        }
    }
}
