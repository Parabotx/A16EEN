import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../theme" as AdaptiveTheme

Item {
    id: root

    property bool active: false
    property bool globalEnabled: false
    property int globalPercent: 20
    property bool navbarEnabled: false
    property int navbarPercent: 10
    property var appOverrides: ({})
    property var windows: []
    property string statusMessage: "READY"
    property bool wallpaperThemeEnabled: false
    property bool wallpaperThemeAvailable: true
    property string wallpaperThemeScheme: ""
    property string wallpaperThemeWallpaper: ""
    property string wallpaperThemeMessage: "OFF BY DEFAULT"
    property var pendingActions: ({})
    property var activeAction: []

    signal backRequested()

    readonly property color page: AdaptiveTheme.WallpaperTheme.enabled
        ? AdaptiveTheme.WallpaperTheme.surface : "#FFFFFF"
    readonly property color tile: AdaptiveTheme.WallpaperTheme.enabled
        ? AdaptiveTheme.WallpaperTheme.surfaceVariant : "#F7F8FA"
    readonly property color tileHover: AdaptiveTheme.WallpaperTheme.enabled
        ? Qt.lighter(AdaptiveTheme.WallpaperTheme.surfaceVariant, 1.08) : "#EEF1F4"
    readonly property color border: AdaptiveTheme.WallpaperTheme.enabled
        ? AdaptiveTheme.WallpaperTheme.outline : "#E1E5EA"
    readonly property color textPrimary: AdaptiveTheme.WallpaperTheme.enabled
        ? AdaptiveTheme.WallpaperTheme.onSurface : "#111318"
    readonly property color textSecondary: AdaptiveTheme.WallpaperTheme.enabled
        ? AdaptiveTheme.WallpaperTheme.onSurfaceVariant : "#66707C"
    readonly property color textMuted: AdaptiveTheme.WallpaperTheme.enabled
        ? AdaptiveTheme.WallpaperTheme.onSurfaceVariant : "#8A939E"
    readonly property color accent: AdaptiveTheme.WallpaperTheme.enabled
        ? AdaptiveTheme.WallpaperTheme.primary : "#B18B3F"

    readonly property var appRows: {
        const discovered = []
        const byId = ({})
        for (const window of root.windows) {
            const appId = String(window.app_id || "").trim()
            if (!appId)
                continue
            if (byId[appId] === undefined) {
                byId[appId] = {
                    appId: appId,
                    title: String(window.title || ""),
                    windowCount: 0,
                    running: true
                }
            }
            byId[appId].windowCount += 1
            if (!byId[appId].title.length && String(window.title || "").length)
                byId[appId].title = String(window.title)
        }
        const ids = Object.keys(byId)
        for (const appId of Object.keys(root.appOverrides || {})) {
            if (byId[appId] === undefined) {
                byId[appId] = {
                    appId: appId,
                    title: "Saved application rule",
                    windowCount: 0,
                    running: false
                }
                ids.push(appId)
            }
        }
        ids.sort((a, b) => a.localeCompare(b))
        for (const appId of ids) {
            const customEnabled = root.appOverrides[appId] !== undefined
            discovered.push({
                appId: appId,
                title: byId[appId].title,
                windowCount: byId[appId].windowCount,
                running: byId[appId].running,
                customEnabled: customEnabled,
                percent: customEnabled
                    ? Number(root.appOverrides[appId])
                    : root.globalPercent
            })
        }
        return discovered
    }

    function acceptState(rawText) {
        try {
            const parsed = JSON.parse(String(rawText || "{}"))
            const globalSettings = parsed.global || ({})
            const navbarSettings = parsed.navbar || ({})
            root.globalEnabled = globalSettings.enabled === true
            root.globalPercent = Math.max(0, Math.min(90, Math.round(Number(globalSettings.percent) || 0)))
            root.navbarEnabled = navbarSettings.enabled === true
            root.navbarPercent = Math.max(0, Math.min(90, Math.round(Number(navbarSettings.percent) || 0)))
            root.appOverrides = parsed.apps && typeof parsed.apps === "object" ? parsed.apps : ({})
            root.windows = Array.isArray(parsed.windows) ? parsed.windows : []
            root.statusMessage = parsed.niriAvailable === false
                ? "NIRI SESSION NOT DETECTED"
                : root.windows.length
                    ? root.windows.length + " WINDOWS DETECTED"
                    : "NO RUNNING APPLICATION WINDOWS"
        } catch (error) {
            root.statusMessage = "COULD NOT READ TRANSPARENCY SETTINGS"
            console.warn("A16EEN transparency settings could not be parsed:", error)
        }
    }

    function refresh() {
        if (!root.active || stateReader.running)
            return
        stateReader.running = true
        root.refreshWallpaperTheme()
    }

    function acceptWallpaperTheme(rawText) {
        try {
            const parsed = JSON.parse(String(rawText || "{}"))
            root.wallpaperThemeEnabled = parsed.enabled === true
            root.wallpaperThemeAvailable = parsed.available !== false
            root.wallpaperThemeScheme = String(parsed.scheme || "")
            root.wallpaperThemeWallpaper = String(parsed.wallpaper || "")
            root.wallpaperThemeMessage = !root.wallpaperThemeAvailable
                ? "MATUGEN NOT INSTALLED — RUN A16 -U"
                : root.wallpaperThemeEnabled
                    ? "ACTIVE • " + (root.wallpaperThemeScheme || "GENERATING").toUpperCase() + " PALETTE"
                    : "DISABLED • YOUR CURRENT THEME IS UNCHANGED"
        } catch (error) {
            root.wallpaperThemeMessage = "COULD NOT READ THEME STATUS"
        }
    }

    function refreshWallpaperTheme() {
        if (!root.active || wallpaperThemeReader.running)
            return
        wallpaperThemeReader.running = true
    }

    function setWallpaperTheme(enabled) {
        if (wallpaperThemeWriter.running)
            return
        root.wallpaperThemeMessage = enabled ? "GENERATING PALETTE…" : "RESTORING NORMAL APPEARANCE…"
        wallpaperThemeWriter.command = [
            "a16een-wallpaper-theme",
            enabled ? "enable" : "disable"
        ]
        wallpaperThemeWriter.running = true
    }

    function queueAction(key, args) {
        const next = ({})
        for (const existingKey of Object.keys(root.pendingActions))
            next[existingKey] = root.pendingActions[existingKey]
        next[key] = args
        root.pendingActions = next
        root.statusMessage = "SAVING SETTINGS"
        actionDebounce.restart()
    }

    function flushActions() {
        if (writer.running)
            return
        const keys = Object.keys(root.pendingActions)
        if (!keys.length)
            return

        const nextKey = keys[0]
        const args = root.pendingActions[nextKey]
        const remaining = ({})
        for (const key of keys.slice(1))
            remaining[key] = root.pendingActions[key]
        root.pendingActions = remaining
        root.activeAction = args
        writer.command = ["a16een-transparency"].concat(args)
        writer.running = true
    }

    function setGlobalEnabled(enabled) {
        root.globalEnabled = enabled
        root.queueAction("global", [
            "set-global",
            enabled ? "on" : "off",
            String(root.globalPercent)
        ])
    }

    function setNavbarEnabled(enabled) {
        root.navbarEnabled = enabled
        root.queueAction("navbar", [
            "set-navbar",
            enabled ? "on" : "off",
            String(root.navbarPercent)
        ])
    }

    function setAppEnabled(appId, enabled, percent) {
        if (enabled) {
            root.queueAction("app:" + appId, ["set-app", appId, String(percent)])
        } else {
            root.queueAction("app:" + appId, ["clear-app", appId])
        }
    }

    onActiveChanged: {
        if (root.active) {
            root.statusMessage = "READING SETTINGS"
            root.refresh()
            root.refreshWallpaperTheme()
            refreshTimer.start()
            Qt.callLater(() => root.forceActiveFocus())
        } else {
            refreshTimer.stop()
        }
    }

    Process {
        id: wallpaperThemeReader
        command: ["a16een-wallpaper-theme", "status"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.acceptWallpaperTheme(text)
        }
    }

    Process {
        id: wallpaperThemeWriter
        command: ["a16een-wallpaper-theme", "status"]
        running: false

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length)
                    root.wallpaperThemeMessage = text.trim()
            }
        }

        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.wallpaperThemeMessage = "THEME SETTINGS SAVED"
            } else {
                root.wallpaperThemeMessage = "COULD NOT APPLY THEME — CHECK THE STATUS"
            }
            root.refreshWallpaperTheme()
        }
    }

    Process {
        id: stateReader
        command: ["a16een-transparency", "get"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.acceptState(text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length)
                    root.statusMessage = "TRANSPARENCY SERVICE UNAVAILABLE"
            }
        }
    }

    Process {
        id: writer
        command: ["a16een-transparency"]
        running: false

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length)
                    root.statusMessage = "SAVE FAILED"
            }
        }

        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.statusMessage = "SAVE FAILED"
                if (Object.keys(root.pendingActions).length)
                    Qt.callLater(() => root.flushActions())
                return
            }
            if (Object.keys(root.pendingActions).length) {
                Qt.callLater(() => root.flushActions())
            } else {
                root.statusMessage = "SETTINGS SAVED"
                refreshTimer.restart()
            }
        }
    }

    Timer {
        id: actionDebounce
        interval: 160
        repeat: false
        onTriggered: root.flushActions()
    }

    Timer {
        id: refreshTimer
        interval: 5000
        repeat: true
        running: false
        onTriggered: root.refresh()
    }

    Rectangle {
        anchors.fill: parent
        color: root.page
        radius: 24
    }

    Column {
        anchors.fill: parent
        anchors.margins: 26
        spacing: 13

        Row {
            id: header
            width: parent.width
            height: 44
            spacing: 12

            Rectangle {
                width: 38
                height: 38
                radius: 11
                color: backMouse.containsMouse ? "#E8EBEF" : "#F2F4F6"
                border.width: 1
                border.color: root.border
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    color: root.textPrimary
                    font.pixelSize: 27
                    y: -1
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backRequested()
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    text: "TRANSPARENCY"
                    color: root.textPrimary
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.3
                }

                Text {
                    text: "WINDOWS • A16EEN UI • FOCUSED WINDOW"
                    color: root.textMuted
                    font.pixelSize: 8
                    font.weight: Font.Medium
                    font.letterSpacing: 0.9
                }
            }

            Item { width: 1; height: 1 }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.statusMessage
                color: root.textMuted
                font.pixelSize: 8
                font.weight: Font.DemiBold
                font.letterSpacing: 0.6
            }
        }

        Flickable {
            id: contentFlickable
            width: parent.width
            height: Math.max(0, parent.height - header.height - 13)
            contentWidth: width
            contentHeight: contentColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: contentColumn
                width: contentFlickable.width
                spacing: 12

                Rectangle {
                    width: parent.width
                    height: 112
                    radius: 17
                    color: root.tile
                    border.width: 1
                    border.color: root.border

                    Row {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 14

                        Rectangle {
                            width: 44
                            height: 44
                            radius: 13
                            color: AdaptiveTheme.WallpaperTheme.enabled
                                ? AdaptiveTheme.WallpaperTheme.primaryContainer : "#EEE8DC"
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: "◐"
                                color: AdaptiveTheme.WallpaperTheme.enabled
                                    ? AdaptiveTheme.WallpaperTheme.onPrimaryContainer : "#8C6D38"
                                font.pixelSize: 25
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 5
                            width: parent.width - 44 - 62 - 28

                            Text {
                                text: "WALLPAPER ADAPTIVE APPEARANCE"
                                color: root.textPrimary
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.6
                            }
                            Text {
                                width: parent.width
                                text: "Match Foot, Kitty, GTK, Qt and A16EEN to your wallpaper. Light wallpapers create light app surfaces; dark wallpapers create dark ones."
                                color: root.textSecondary
                                font.pixelSize: 8
                                wrapMode: Text.WordWrap
                            }
                            Text {
                                width: parent.width
                                text: root.wallpaperThemeMessage
                                color: root.wallpaperThemeEnabled ? root.accent : root.textMuted
                                font.pixelSize: 7
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            width: 42
                            height: 24
                            radius: 12
                            color: root.wallpaperThemeEnabled ? root.accent : "#D9DEE4"
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                y: 3
                                x: root.wallpaperThemeEnabled ? 21 : 3
                                color: "#FFFFFF"
                                Behavior on x {
                                    NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: !wallpaperThemeWriter.running && root.wallpaperThemeAvailable
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: root.setWallpaperTheme(!root.wallpaperThemeEnabled)
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 12

                    Rectangle {
                        width: (parent.width - 12) / 2
                        height: 174
                        radius: 17
                        color: root.tile
                        border.width: 1
                        border.color: root.border

                        Column {
                            anchors.fill: parent
                            anchors.margins: 17
                            spacing: 9

                            Row {
                                width: parent.width
                                height: 31
                                spacing: 8

                                Column {
                                    spacing: 3
                                    Text {
                                        text: "ALL APPLICATIONS"
                                        color: root.textPrimary
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 0.5
                                    }
                                    Text {
                                        text: "Also affects apps opened later"
                                        color: root.textMuted
                                        font.pixelSize: 8
                                    }
                                }
                                Item { width: 1; height: 1 }
                                Rectangle {
                                    width: 42
                                    height: 24
                                    radius: 12
                                    color: root.globalEnabled ? "#B18B3F" : "#D9DEE4"
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        y: 3
                                        x: root.globalEnabled ? 21 : 3
                                        color: "#FFFFFF"
                                        Behavior on x { NumberAnimation { duration: 130 } }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setGlobalEnabled(!root.globalEnabled)
                                    }
                                }
                            }

                            Text {
                                text: root.globalPercent + "% TRANSPARENT"
                                color: root.accent
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            Slider {
                                id: globalSlider
                                width: parent.width
                                height: 26
                                from: 0
                                to: 90
                                stepSize: 1
                                value: root.globalPercent
                                background: Rectangle {
                                    x: globalSlider.leftPadding
                                    y: globalSlider.topPadding + globalSlider.availableHeight / 2 - height / 2
                                    width: globalSlider.availableWidth
                                    height: 4
                                    radius: 2
                                    color: "#DCE1E6"
                                    Rectangle {
                                        width: globalSlider.visualPosition * parent.width
                                        height: parent.height
                                        radius: 2
                                        color: root.accent
                                    }
                                }
                                handle: Rectangle {
                                    x: globalSlider.leftPadding + globalSlider.visualPosition * (globalSlider.availableWidth - width)
                                    y: globalSlider.topPadding + globalSlider.availableHeight / 2 - height / 2
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: "#FFFFFF"
                                    border.width: 2
                                    border.color: root.accent
                                }
                                onMoved: {
                                    root.globalPercent = Math.round(value)
                                    root.queueAction("global", [
                                        "set-global",
                                        root.globalEnabled ? "on" : "off",
                                        String(root.globalPercent)
                                    ])
                                }
                            }

                            Text {
                                width: parent.width
                                text: "One rule for every normal application window. Individual app settings below can override it."
                                color: root.textSecondary
                                font.pixelSize: 8
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    Rectangle {
                        width: (parent.width - 12) / 2
                        height: 174
                        radius: 17
                        color: root.tile
                        border.width: 1
                        border.color: root.border

                        Column {
                            anchors.fill: parent
                            anchors.margins: 17
                            spacing: 9

                            Row {
                                width: parent.width
                                height: 31
                                spacing: 8

                                Column {
                                    spacing: 3
                                    Text {
                                        text: "A16EEN NAVBAR & PANELS"
                                        color: root.textPrimary
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 0.4
                                    }
                                    Text {
                                        text: "Navbar, trays, tools and shell panels"
                                        color: root.textMuted
                                        font.pixelSize: 8
                                    }
                                }
                                Item { width: 1; height: 1 }
                                Rectangle {
                                    width: 42
                                    height: 24
                                    radius: 12
                                    color: root.navbarEnabled ? "#B18B3F" : "#D9DEE4"
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        y: 3
                                        x: root.navbarEnabled ? 21 : 3
                                        color: "#FFFFFF"
                                        Behavior on x { NumberAnimation { duration: 130 } }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setNavbarEnabled(!root.navbarEnabled)
                                    }
                                }
                            }

                            Text {
                                text: root.navbarPercent + "% TRANSPARENT"
                                color: root.accent
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            Slider {
                                id: navbarSlider
                                width: parent.width
                                height: 26
                                from: 0
                                to: 90
                                stepSize: 1
                                value: root.navbarPercent
                                background: Rectangle {
                                    x: navbarSlider.leftPadding
                                    y: navbarSlider.topPadding + navbarSlider.availableHeight / 2 - height / 2
                                    width: navbarSlider.availableWidth
                                    height: 4
                                    radius: 2
                                    color: "#DCE1E6"
                                    Rectangle {
                                        width: navbarSlider.visualPosition * parent.width
                                        height: parent.height
                                        radius: 2
                                        color: root.accent
                                    }
                                }
                                handle: Rectangle {
                                    x: navbarSlider.leftPadding + navbarSlider.visualPosition * (navbarSlider.availableWidth - width)
                                    y: navbarSlider.topPadding + navbarSlider.availableHeight / 2 - height / 2
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: "#FFFFFF"
                                    border.width: 2
                                    border.color: root.accent
                                }
                                onMoved: {
                                    root.navbarPercent = Math.round(value)
                                    root.queueAction("navbar", [
                                        "set-navbar",
                                        root.navbarEnabled ? "on" : "off",
                                        String(root.navbarPercent)
                                    ])
                                }
                            }

                            Text {
                                width: parent.width
                                text: "Fades A16EEN layer surfaces, while keeping the wallpaper and ordinary app windows separate."
                                color: root.textSecondary
                                font.pixelSize: 8
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 126
                    radius: 17
                    color: root.tile
                    border.width: 1
                    border.color: root.border

                    Column {
                        anchors.fill: parent
                        anchors.margins: 17
                        spacing: 9

                        Text {
                            text: "FOCUSED WINDOW SHORTCUTS"
                            color: root.textPrimary
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.5
                        }

                        Row {
                            width: parent.width
                            spacing: 10

                            Rectangle {
                                width: (parent.width - 10) / 2
                                height: 44
                                radius: 10
                                color: "#FFFFFF"
                                border.width: 1
                                border.color: root.border

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "INCREASE  +5%"
                                        color: root.accent
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "CTRL + ALT + SHIFT + ="
                                        color: root.textPrimary
                                        font.pixelSize: 8
                                        font.weight: Font.Medium
                                    }
                                }
                            }

                            Rectangle {
                                width: (parent.width - 10) / 2
                                height: 44
                                radius: 10
                                color: "#FFFFFF"
                                border.width: 1
                                border.color: root.border

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "DECREASE  −5%"
                                        color: root.accent
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "CTRL + ALT + -"
                                        color: root.textPrimary
                                        font.pixelSize: 8
                                        font.weight: Font.Medium
                                    }
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            text: "Each press changes only the focused window. Transparency is limited to 90%; 0% is fully opaque."
                            color: root.textSecondary
                            font.pixelSize: 8
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Column {
                    id: appsColumn
                    width: parent.width
                    spacing: 8

                    Row {
                        width: parent.width
                        height: 34
                        spacing: 10

                        Column {
                            spacing: 3
                            Text {
                                text: "APPLICATION RULES"
                                color: root.textPrimary
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.6
                            }
                            Text {
                                text: "Custom opacity per running application"
                                color: root.textMuted
                                font.pixelSize: 8
                            }
                        }
                        Item { width: 1; height: 1 }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.appRows.length + " APPS"
                            color: root.textMuted
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                        }
                    }

                    Rectangle {
                        visible: root.appRows.length === 0
                        width: parent.width
                        height: 68
                        radius: 13
                        color: root.tile
                        border.width: 1
                        border.color: root.border
                        Text {
                            anchors.centerIn: parent
                            text: "No running applications detected yet. Open an app and it will appear here."
                            color: root.textSecondary
                            font.pixelSize: 9
                        }
                    }

                    Repeater {
                        model: root.appRows

                        delegate: Rectangle {
                            required property var modelData
                            width: appsColumn.width
                            height: modelData.customEnabled ? 88 : 64
                            radius: 13
                            color: root.tile
                            border.width: 1
                            border.color: root.border

                            Column {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 5

                                Row {
                                    width: parent.width
                                    height: 28
                                    spacing: 8

                                    Rectangle {
                                        width: 27
                                        height: 27
                                        radius: 8
                                        color: "#ECEFF2"
                                        Text {
                                            anchors.centerIn: parent
                                            text: String(modelData.appId).slice(0, 1).toUpperCase()
                                            color: root.textSecondary
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2
                                        Text {
                                            width: Math.max(120, appsColumn.width - 210)
                                            text: modelData.title.length
                                                ? modelData.title
                                                : modelData.appId
                                            color: root.textPrimary
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            width: Math.max(120, appsColumn.width - 210)
                                            text: modelData.appId
                                                + (modelData.running
                                                    ? "  •  " + modelData.windowCount + " WINDOW(S)"
                                                    : "  •  SAVED RULE")
                                            color: root.textMuted
                                            font.pixelSize: 7
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Item { width: 1; height: 1 }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.customEnabled ? "CUSTOM" : "FOLLOW ALL"
                                        color: root.textMuted
                                        font.pixelSize: 7
                                        font.weight: Font.DemiBold
                                    }

                                    Rectangle {
                                        width: 38
                                        height: 22
                                        radius: 11
                                        color: modelData.customEnabled ? root.accent : "#D9DEE4"
                                        anchors.verticalCenter: parent.verticalCenter

                                        Rectangle {
                                            width: 16
                                            height: 16
                                            radius: 8
                                            y: 3
                                            x: modelData.customEnabled ? 19 : 3
                                            color: "#FFFFFF"
                                            Behavior on x { NumberAnimation { duration: 130 } }
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.setAppEnabled(
                                                modelData.appId,
                                                !modelData.customEnabled,
                                                modelData.percent
                                            )
                                        }
                                    }
                                }

                                Row {
                                    width: parent.width
                                    visible: modelData.customEnabled
                                    spacing: 10

                                    Slider {
                                        id: appSlider
                                        width: parent.width - 78
                                        height: 22
                                        from: 0
                                        to: 90
                                        stepSize: 1
                                        value: modelData.percent
                                        background: Rectangle {
                                            x: appSlider.leftPadding
                                            y: appSlider.topPadding + appSlider.availableHeight / 2 - height / 2
                                            width: appSlider.availableWidth
                                            height: 4
                                            radius: 2
                                            color: "#DCE1E6"
                                            Rectangle {
                                                width: appSlider.visualPosition * parent.width
                                                height: parent.height
                                                radius: 2
                                                color: root.accent
                                            }
                                        }
                                        handle: Rectangle {
                                            x: appSlider.leftPadding + appSlider.visualPosition * (appSlider.availableWidth - width)
                                            y: appSlider.topPadding + appSlider.availableHeight / 2 - height / 2
                                            width: 14
                                            height: 14
                                            radius: 7
                                            color: "#FFFFFF"
                                            border.width: 2
                                            border.color: root.accent
                                        }
                                        onMoved: root.queueAction(
                                            "app:" + modelData.appId,
                                            ["set-app", modelData.appId, String(Math.round(value))]
                                        )
                                    }

                                    Text {
                                        width: 68
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: Math.round(appSlider.value) + "% transparent"
                                        color: root.accent
                                        font.pixelSize: 8
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }
                        }
                    }
                }

                Item { width: 1; height: 2 }
            }
        }
    }

    Keys.onEscapePressed: root.backRequested()

    Component.onCompleted: {
        if (root.active)
            root.refresh()
    }
}
