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
    property var appUsage: ({})
    property var pendingAppUsage: ({})
    property bool appUsageLoaded: false
    property var lockedAppIds: []
    readonly property string appUsagePath: Quickshell.stateDir + "/launcher-usage.json"

    signal closeRequested()
    signal protectedAppRequested(string desktopId, string appName)

    readonly property color accent: "#66717F"
    readonly property color primaryText: "#E7E9ED"
    readonly property color secondaryText: "#A4AAB4"
    readonly property color mutedText: "#777F8A"
    readonly property color tileBackground: "#171B22"
    readonly property color tileHoverBackground: "#202630"
    readonly property color tileSelectedBackground: "#252D38"
    readonly property color tileBorder: "#303844"
    readonly property color tileActiveBorder: "#465263"
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

    function usageId(entry) {
        return String(entry && (entry.id || entry.desktopFile || entry.name) || "").trim()
    }

    function usageCount(entry) {
        const record = root.appUsage[root.usageId(entry)]
        return Math.max(0, Number(record && record.count || 0))
    }

    function usageLastUsed(entry) {
        const record = root.appUsage[root.usageId(entry)]
        return Math.max(0, Number(record && record.lastUsed || 0))
    }

    function loadAppUsage(rawText) {
        const saved = ({})
        try {
            const parsed = JSON.parse(String(rawText || "{}"))
            const stored = parsed && parsed.usage && typeof parsed.usage === "object"
                ? parsed.usage
                : {}

            for (const id in stored) {
                const record = stored[id]
                const count = Math.floor(Number(typeof record === "number" ? record : record && record.count || 0))
                const lastUsed = Math.max(0, Number(record && typeof record === "object" ? record.lastUsed || 0 : 0))
                if (id && isFinite(count) && count > 0)
                    saved[id] = { count: count, lastUsed: isFinite(lastUsed) ? lastUsed : 0 }
            }
        } catch (error) {
            console.warn("A16EEN launcher usage history could not be read:", error)
        }

        const pending = root.pendingAppUsage
        for (const id in pending) {
            const record = pending[id] || {}
            const existing = saved[id] || { count: 0, lastUsed: 0 }
            saved[id] = {
                count: Number(existing.count || 0) + Number(record.count || 0),
                lastUsed: Math.max(Number(existing.lastUsed || 0), Number(record.lastUsed || 0))
            }
        }

        root.appUsage = saved
        root.pendingAppUsage = ({})
        root.appUsageLoaded = true
        if (Object.keys(pending).length > 0)
            appUsageSaveTimer.restart()
    }

    function recordAppUsage(entry) {
        const id = root.usageId(entry)
        if (!id)
            return

        if (!root.appUsageLoaded) {
            const pending = ({})
            for (const key in root.pendingAppUsage)
                pending[key] = root.pendingAppUsage[key]
            const previous = pending[id] || { count: 0, lastUsed: 0 }
            pending[id] = {
                count: Number(previous.count || 0) + 1,
                lastUsed: Date.now()
            }
            root.pendingAppUsage = pending
            return
        }

        const next = ({})
        for (const key in root.appUsage)
            next[key] = root.appUsage[key]
        const previous = next[id] || { count: 0, lastUsed: 0 }
        next[id] = {
            count: Number(previous.count || 0) + 1,
            lastUsed: Date.now()
        }
        root.appUsage = next
        appUsageSaveTimer.restart()
    }

    function loadLockedAppIds(raw) {
        try {
            const store = JSON.parse(String(raw || "{}"))
            root.lockedAppIds = store && Array.isArray(store.apps)
                ? store.apps.map(item => String(item.desktop_id || "").toLowerCase())
                : []
        } catch (error) {
            root.lockedAppIds = []
            console.warn("A16EEN App Locker state could not be read:", error)
        }
    }

    function launch(entry) {
        root.launchError = ""

        if (!entry) {
            root.launchError = "No application selected."
            return false
        }

        const desktopId = String(entry.id || "").toLowerCase()
        if (desktopId.length && root.lockedAppIds.includes(desktopId)) {
            root.closeRequested()
            root.protectedAppRequested(String(entry.id || ""), String(entry.name || "Application"))
            return false
        }

        try {
            entry.execute()
            root.recordAppUsage(entry)
            root.closeRequested()
            return true
        } catch (error) {
            root.launchError = "Couldn't launch " + entry.name + "."
            console.error("A16EEN launcher:", entry.name, error)
            return false
        }
    }

    FileView {
        id: appLockerFile
        path: Quickshell.stateDir + "/app-locker.json"
        preload: true
        watchChanges: true
        printErrors: false
        onLoaded: root.loadLockedAppIds(appLockerFile.text())
        onFileChanged: root.loadLockedAppIds(appLockerFile.text())
        onLoadFailed: root.loadLockedAppIds("{}")
    }

    FileView {
        id: appUsageFile
        path: root.appUsagePath
        preload: true
        printErrors: false
        atomicWrites: true
        onLoaded: root.loadAppUsage(appUsageFile.text())
        onLoadFailed: root.loadAppUsage("{}")
    }

    Timer {
        id: appUsageSaveTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (root.appUsageLoaded) {
                appUsageFile.setText(JSON.stringify({
                    version: 1,
                    usage: root.appUsage
                }))
            }
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
                cellWidth: 72
                cellHeight: 72
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

                        const matchRank = entry => {
                            if (!q)
                                return 0

                            const name = String(entry.name || "").toLowerCase()
                            const genericName = String(entry.genericName || "").toLowerCase()
                            const comment = String(entry.comment || "").toLowerCase()
                            const keywords = (entry.keywords || []).map(value => String(value).toLowerCase())

                            if (name === q)
                                return 0
                            if (name.startsWith(q))
                                return 1
                            if (genericName === q || keywords.includes(q))
                                return 2
                            if (genericName.startsWith(q) || keywords.some(value => value.startsWith(q)))
                                return 3
                            if (name.includes(q))
                                return 4
                            if (genericName.includes(q) || comment.includes(q) || keywords.some(value => value.includes(q)))
                                return 5
                            return 6
                        }

                        entries.sort((a, b) => {
                            const rankDifference = matchRank(a) - matchRank(b)
                            if (rankDifference !== 0)
                                return rankDifference

                            const usageDifference = root.usageCount(b) - root.usageCount(a)
                            if (usageDifference !== 0)
                                return usageDifference

                            const recencyDifference = root.usageLastUsed(b) - root.usageLastUsed(a)
                            if (recencyDifference !== 0)
                                return recencyDifference

                            return (a.name || "").localeCompare(b.name || "")
                        })
                        return entries
                    }
                }

                delegate: Rectangle {
                    id: appTile

                    required property var modelData
                    required property int index

                    width: 64
                    height: 64
                    radius: 11
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
                        anchors.margins: 4
                        spacing: 1

                        Item {
                            width: parent.width
                            height: 29

                            Image {
                                anchors.centerIn: parent
                                width: 24
                                height: 24
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
                            height: 21
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
