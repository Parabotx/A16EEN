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

    readonly property color accent: "#687382"
    readonly property color primaryText: "#E7E9ED"
    readonly property color secondaryText: "#A4AAB4"
    readonly property color mutedText: "#777F8A"
    readonly property color tileBackground: "#CC11151B"
    readonly property color tileHoverBackground: "#E01B222B"
    readonly property color tileSelectedBackground: "#F0242C37"
    readonly property color tileBorder: "#302D3540"
    readonly property color tileActiveBorder: "#586371"
    readonly property int navigationColumns: Math.max(1, Math.floor(appGrid.width / appGrid.cellWidth))
    readonly property string selectedAppDescription: {
        const item = appGrid.currentItem
        if (!item || !item.entry)
            return "Search by name, description, or keyword"
        return String(item.entry.genericName || item.entry.comment || item.entry.name || "")
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
    WlrLayershell.namespace: "a16een-launcher"
    WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    function parseIconTheme(output) {
        root.iconThemeName = String(output || "").trim() || "system"
        root.resolvedIconPaths = ({})
        iconResolver.running = true
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
        if (!iconThemeReader.running && !iconResolver.running)
            iconThemeReader.running = true
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

    // Keep the overlay itself transparent: only individual applications receive tiles.
    Rectangle {
        anchors.fill: parent
        color: "#05070B"
        opacity: root.opened ? 0.18 : 0
    }

    Item {
        id: content
        z: 2
        anchors.centerIn: parent
        width: Math.max(280, Math.min(parent.width - 48, 480))
        height: Math.max(280, Math.min(parent.height - 64, 360))

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 16
                spacing: 8

                Text {
                    text: "A16EEN"
                    color: root.accent
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.letterSpacing: 2.2
                }

                Text {
                    text: "/"
                    color: "#4F5662"
                    font.pixelSize: 10
                }

                Text {
                    text: "APPLICATIONS"
                    color: root.secondaryText
                    font.pixelSize: 10
                    font.letterSpacing: 1.8
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: appGrid.count + (appGrid.count === 1 ? " RESULT" : " RESULTS")
                    color: root.mutedText
                    font.pixelSize: 9
                    font.letterSpacing: 1.2
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(content.width, 560)
                Layout.maximumWidth: content.width
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    spacing: 0

                    Item {
                        id: searchInputSurface
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34

                        TextInput {
                            id: search
                            anchors.fill: parent
                            color: root.primaryText
                            selectionColor: "#343D49"
                            selectedTextColor: "#FFFFFF"
                            cursorDelegate: Rectangle {
                                width: 1.5
                                color: root.tileActiveBorder
                            }
                            font.pixelSize: 13
                            font.weight: Font.Normal
                            clip: true
                            focus: root.opened
                            activeFocusOnPress: true
                            verticalAlignment: Text.AlignVCenter
                            text: root.searchText
                            selectByMouse: true
                            renderType: Text.NativeRendering

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
                                    appGrid.currentIndex = Math.min(
                                        appGrid.count - 1,
                                        appGrid.currentIndex + root.navigationColumns
                                    )
                                }
                            }

                            Keys.onUpPressed: {
                                if (appGrid.count > 0) {
                                    appGrid.currentIndex = Math.max(
                                        0,
                                        appGrid.currentIndex - root.navigationColumns
                                    )
                                }
                            }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Type to find an application…"
                            color: root.mutedText
                            font.pixelSize: 13
                            visible: search.text.length === 0
                            elide: Text.ElideRight
                        }
                    }

                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    radius: 1
                    color: search.activeFocus ? root.tileActiveBorder : root.tileBorder

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }

                    Behavior on height {
                        NumberAnimation { duration: 120 }
                    }
                }
            }

            GridView {
                id: appGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: 78
                cellHeight: 78
                currentIndex: count > 0 ? 0 : -1
                keyNavigationWraps: true
                boundsBehavior: Flickable.StopAtBounds
                reuseItems: true

                model: ScriptModel {
                    id: appModel
                    objectProp: "id"
                    values: {
                        const q = root.searchText.toLowerCase().trim()
                        const entries = [...DesktopEntries.applications.values]
                            .filter(entry => {
                                if (!q)
                                    return true

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

                        const rank = entry => {
                            if (!q)
                                return 3
                            const name = String(entry.name || "").toLowerCase()
                            if (name === q)
                                return 0
                            if (name.startsWith(q))
                                return 1
                            if (name.includes(q))
                                return 2
                            return 3
                        }

                        entries.sort((a, b) => {
                            const rankDifference = rank(a) - rank(b)
                            if (rankDifference !== 0)
                                return rankDifference
                            return (a.name || "").localeCompare(b.name || "")
                        })
                        return entries
                    }
                }

                delegate: Rectangle {
                    id: appTile

                    required property var modelData
                    required property int index

                    width: 70
                    height: 70
                    radius: 12
                    color: appMouse.containsMouse
                        ? root.tileHoverBackground
                        : (GridView.isCurrentItem
                            ? root.tileSelectedBackground
                            : root.tileBackground)
                    border.width: 1
                    border.color: GridView.isCurrentItem || appMouse.containsMouse
                        ? root.tileActiveBorder
                        : root.tileBorder

                    property var entry: modelData

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }

                    Behavior on border.color {
                        ColorAnimation { duration: 100 }
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 2

                        Item {
                            width: parent.width
                            height: 32

                            Image {
                                anchors.centerIn: parent
                                width: 26
                                height: 26
                                sourceSize.width: width
                                sourceSize.height: height
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                smooth: true
                                mipmap: true
                                cache: true
                                source: root.iconSource(appTile.entry.icon)
                            }
                        }

                        Text {
                            width: parent.width
                            height: 24
                            text: appTile.entry.name || "Application"
                            color: root.primaryText
                            font.pixelSize: 9
                            font.weight: Font.Medium
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.Wrap
                        }
                    }

                    MouseArea {
                        id: appMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: appGrid.currentIndex = appTile.index
                        onClicked: root.launch(appTile.entry)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 48, 420)
                    visible: appGrid.count === 0
                    text: root.searchText.trim().length
                        ? "No applications match “" + root.searchText.trim() + "”"
                        : "No applications found"
                    color: root.secondaryText
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.preferredHeight: root.launchError.length > 0 ? 18 : 0
                visible: root.launchError.length > 0
                text: root.launchError
                color: "#F0A3A3"
                font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 16
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: root.selectedAppDescription
                    color: root.mutedText
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }

                Text {
                    text: "↑ ↓  MOVE"
                    color: root.mutedText
                    font.pixelSize: 9
                    font.letterSpacing: 0.8
                }

                Text {
                    text: "↵  LAUNCH"
                    color: root.mutedText
                    font.pixelSize: 9
                    font.letterSpacing: 0.8
                }

                Text {
                    text: "ESC  CLOSE"
                    color: root.mutedText
                    font.pixelSize: 9
                    font.letterSpacing: 0.8
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
            Qt.callLater(() => {
                search.forceActiveFocus()
                search.cursorPosition = search.text.length
            })
        } else {
            search.text = ""
        }
    }
}
