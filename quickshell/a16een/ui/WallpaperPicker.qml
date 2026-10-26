import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool opened: false
    property var wallpapers: []
    property bool settingsOpen: false
    property string fileDialogPurpose: "set"
    property bool reopenAfterPicker: false
    property bool showSettingsAfterPicker: false
    property bool pickerOutputReady: false
    property bool pickerFinishHandled: false
    property bool wallpaperCatalogReady: false

    property bool autoRotate: false
    property int rotateInterval: 30
    property string rotateMode: "random"
    property string rotateSource: "both"
    property bool avoidRepeat: true
    property string morningTime: "07:00"
    property string eveningTime: "19:00"
    property string morningPath: ""
    property string eveningPath: ""

    property int selectedIndex: -1
    property int railCurrentIndex: -1
    property string selectedWallpaperKey: ""
    property string appliedWallpaperKey: ""
    property string failedWallpaperKey: ""
    property string runningWallpaperKey: ""
    property var pendingWallpaper: null
    property bool closeAfterApply: false

    signal closeRequested()
    signal openRequested()

    readonly property int pickerWidth: Math.max(0, Math.min(1480, root.width - 32))
    readonly property int thumbnailWidth: Math.max(48, Math.min(110, Math.floor((root.pickerWidth - 74) / 13)))
    readonly property int railWidth: Math.max(0, Math.min(root.thumbnailWidth * 13, root.pickerWidth - 58))
    readonly property int pickerContentWidth: root.railWidth + 55
    readonly property int pickerBarHeight: 76
    property bool animateRail: true

    // The catalog is repeated three times so the thumbnail rail can cycle
    // through the end and start of the randomized list without a hard stop.
    readonly property var loopWallpapers: {
        const entries = root.wallpapers
        const result = []
        const count = entries.length
        for (let cycle = 0; cycle < 3; cycle++) {
            for (let i = 0; i < count; i++) {
                result.push({
                    wallpaper: entries[i],
                    wallpaperIndex: i,
                    loopIndex: cycle * count + i,
                    key: root.wallpaperKey(entries[i])
                })
            }
        }
        return result
    }

    function wallpaperKey(entry) {
        return entry
            ? String(entry.source || "") + "|" + String(entry.path || entry.name || "")
            : ""
    }

    function wrappedIndex(index, count) {
        if (count <= 0)
            return -1
        return ((index % count) + count) % count
    }

    function shuffleWallpapers(entries) {
        const shuffled = entries.slice()
        for (let i = shuffled.length - 1; i > 0; i--) {
            const target = Math.floor(Math.random() * (i + 1))
            const value = shuffled[i]
            shuffled[i] = shuffled[target]
            shuffled[target] = value
        }
        return shuffled
    }

    function chooseCatalog(entries) {
        const originalSelection = entries.find(entry => entry.selected) || null
        const originalKey = root.wallpaperKey(originalSelection)
        const shuffled = root.shuffleWallpapers(entries)

        root.wallpapers = shuffled
        root.wallpaperCatalogReady = true
        root.failedWallpaperKey = ""

        let nextIndex = originalKey.length
            ? shuffled.findIndex(entry => root.wallpaperKey(entry) === originalKey)
            : -1
        if (nextIndex < 0 && shuffled.length > 0)
            nextIndex = 0

        root.selectedIndex = nextIndex
        root.selectedWallpaperKey = nextIndex >= 0
            ? root.wallpaperKey(shuffled[nextIndex]) : ""
        root.appliedWallpaperKey = originalKey || root.selectedWallpaperKey
        root.railCurrentIndex = shuffled.length > 0 ? shuffled.length + nextIndex : -1

        Qt.callLater(function() {
            if (root.railCurrentIndex >= 0)
                wallpaperRail.positionViewAtIndex(Math.max(0, root.railCurrentIndex - 3), ListView.Beginning)
        })
    }

    function setSetting(key, value) {
        Quickshell.execDetached(["a16een-wallpaper", "settings", "set", key, String(value)])
    }

    function reloadSettings() {
        if (!settingsProcess.running)
            settingsProcess.running = true
    }

    function selectWallpaperByIndex(index, loopIndex) {
        const count = root.wallpapers.length
        const nextIndex = root.wrappedIndex(index, count)
        if (nextIndex < 0)
            return

        const entry = root.wallpapers[nextIndex]
        root.selectedIndex = nextIndex
        root.selectedWallpaperKey = root.wallpaperKey(entry)
        root.railCurrentIndex = Number.isInteger(loopIndex)
            ? Math.max(0, Math.min(root.loopWallpapers.length - 1, loopIndex))
            : count + nextIndex

        root.pendingWallpaper = entry
        root.failedWallpaperKey = ""
        Qt.callLater(() => root.startPendingWallpaperApply())
    }

    function stepWallpaper(direction) {
        const count = root.wallpapers.length
        if (count <= 0 || (direction !== -1 && direction !== 1))
            return

        const nextIndex = root.wrappedIndex(root.selectedIndex + direction, count)
        let nextLoopIndex = root.railCurrentIndex + direction
        if (nextLoopIndex < 0 || nextLoopIndex >= root.loopWallpapers.length)
            nextLoopIndex = count + nextIndex

        root.selectWallpaperByIndex(nextIndex, nextLoopIndex)
    }

    function confirmCurrentWallpaper() {
        if (root.selectedIndex < 0 || root.selectedIndex >= root.wallpapers.length) {
            root.closeRequested()
            return
        }

        root.closeAfterApply = true
        root.pendingWallpaper = root.wallpapers[root.selectedIndex]
        const selectedKey = root.wallpaperKey(root.pendingWallpaper)
        if (selectedKey === root.appliedWallpaperKey && !wallpaperApplyProcess.running) {
            root.closeAfterApply = false
            root.closeRequested()
            return
        }

        root.failedWallpaperKey = ""
        Qt.callLater(() => root.startPendingWallpaperApply())
    }

    function startPendingWallpaperApply() {
        if (!root.pendingWallpaper || wallpaperApplyProcess.running)
            return

        const entry = root.pendingWallpaper
        const key = root.wallpaperKey(entry)
        if (!key.length || key === root.appliedWallpaperKey || key === root.failedWallpaperKey)
            return

        root.runningWallpaperKey = key
        wallpaperApplyProcess.command = entry.source === "external"
            ? ["a16een-wallpaper", "set-path", entry.path]
            : ["a16een-wallpaper", "set", entry.source, entry.name]
        wallpaperApplyProcess.running = true
    }

    function finishWallpaperApply(exitCode) {
        const finishedKey = root.runningWallpaperKey
        if (exitCode === 0)
            root.appliedWallpaperKey = finishedKey
        else {
            root.failedWallpaperKey = finishedKey
            console.warn("A16EEN wallpaper switch failed for", finishedKey)
        }
        root.runningWallpaperKey = ""

        if (exitCode === 0 && root.closeAfterApply
                && finishedKey === root.selectedWallpaperKey) {
            root.closeAfterApply = false
            root.closeRequested()
            return
        }

        if (root.pendingWallpaper) {
            const pendingKey = root.wallpaperKey(root.pendingWallpaper)
            if (pendingKey !== root.appliedWallpaperKey && pendingKey !== root.failedWallpaperKey)
                Qt.callLater(() => root.startPendingWallpaperApply())
        }
    }

    function launchFilePicker(purpose) {
        root.fileDialogPurpose = purpose
        root.showSettingsAfterPicker = purpose !== "set"
        root.reopenAfterPicker = true
        root.pickerOutputReady = false
        root.pickerFinishHandled = false
        root.closeRequested()
        Qt.callLater(function() {
            wallpaperFilePickerProcess.running = false
            wallpaperFilePickerProcess.running = true
        })
    }

    function finishFilePicker() {
        if (!root.pickerOutputReady || wallpaperFilePickerProcess.running || root.pickerFinishHandled)
            return

        root.pickerFinishHandled = true
        const path = String(wallpaperFilePickerOutput.text || "").trim()
        const purpose = root.fileDialogPurpose

        if (path.length > 0) {
            if (purpose === "morning")
                root.morningPath = path
            else if (purpose === "evening")
                root.eveningPath = path
            if (purpose === "set")
                root.showSettingsAfterPicker = false
        }

        root.fileDialogPurpose = "set"
        if (root.reopenAfterPicker) {
            root.reopenAfterPicker = false
            root.openRequested()
        }
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
    WlrLayershell.namespace: "a16een-wallpaper-picker"
    WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    Process {
        id: settingsProcess
        command: ["a16een-wallpaper", "settings", "show"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const values = {}
                for (const line of String(text || "").trim().split(/\r?\n/)) {
                    const split = line.indexOf("=")
                    if (split > 0)
                        values[line.slice(0, split)] = line.slice(split + 1)
                }
                root.autoRotate = values.enabled === "1"
                root.rotateInterval = Number(values.interval || 30)
                root.rotateMode = values.mode || "random"
                root.rotateSource = values.source || "both"
                root.avoidRepeat = values.avoid_repeat !== "0"
                root.morningTime = values.morning_time || "07:00"
                root.eveningTime = values.evening_time || "19:00"
                root.morningPath = values.morning_path || ""
                root.eveningPath = values.evening_path || ""
            }
        }
    }

    Process {
        id: catalogProcess
        command: ["a16een-wallpaper", "catalog"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const next = []
                for (const line of String(text || "").trim().split(/\r?\n/)) {
                    if (!line.length)
                        continue
                    const fields = line.split("\t")
                    if (fields.length < 6)
                        continue

                    next.push({
                        source: fields[0],
                        name: fields[1],
                        displayName: fields[2] || fields[1].replace(/\.[^.]+$/, ""),
                        path: fields[3],
                        selected: fields[4] === "1",
                        type: fields[5]
                    })
                }
                root.chooseCatalog(next)
            }
        }
    }

    Process {
        id: wallpaperApplyProcess
        command: []
        running: false
        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(text || "").trim()
                if (message.length)
                    console.warn("A16EEN wallpaper:", message)
            }
        }
        onExited: (exitCode, exitStatus) => root.finishWallpaperApply(exitCode)
    }

    Process {
        id: wallpaperFilePickerProcess
        command: ["a16een-wallpaper", "pick-file", root.fileDialogPurpose]
        running: false
        stdout: StdioCollector {
            id: wallpaperFilePickerOutput
            onStreamFinished: {
                root.pickerOutputReady = true
                root.finishFilePicker()
            }
        }
        onRunningChanged: {
            if (!running)
                root.finishFilePicker()
        }
    }

    // Clicking the dimmed background closes settings first, then the switcher.
    MouseArea {
        anchors.fill: parent
        z: 1
        acceptedButtons: Qt.LeftButton
        onClicked: {
            if (root.settingsOpen)
                root.settingsOpen = false
            else
                root.closeRequested()
        }
    }

    Rectangle {
        anchors.fill: parent
        z: 0
        color: "#000000"
        opacity: root.settingsOpen ? 0.22 : 0
        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 180
        z: 0
        opacity: root.opened ? 1 : 0
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#00000000" }
            GradientStop { position: 1.0; color: "#64000000" }
        }
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        id: switcherCard
        z: 3
        width: Math.min(root.pickerContentWidth, root.width - 16)
        height: root.pickerBarHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 78
        radius: 14
        color: "#56F7F8FA"
        border.width: 1
        border.color: "#40FFFFFF"
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.97
        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: 18
            color: "#14000000"
            z: -1
        }

        Row {
            anchors.centerIn: parent
            spacing: 4

            Rectangle {
                id: settingsTile
                width: 42
                height: 42
                radius: 12
                color: settingsMouse.containsMouse ? "#3B4452" : "#252C37"
                border.width: 1
                border.color: "#475160"
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: 110 } }

                Image {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: Qt.resolvedUrl("../assets/icons/lucide-sliders-horizontal.svg")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                MouseArea {
                    id: settingsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.settingsOpen = !root.settingsOpen
                        if (root.settingsOpen)
                            root.reloadSettings()
                    }
                }
            }

            Rectangle {
                width: 1
                height: 40
                radius: 1
                color: "#DDE1E7"
                anchors.verticalCenter: parent.verticalCenter
            }

            ListView {
                id: wallpaperRail
                width: root.railWidth
                height: 66
                anchors.verticalCenter: parent.verticalCenter
                orientation: ListView.Horizontal
                spacing: 0
                clip: true
                interactive: false
                model: root.loopWallpapers
                currentIndex: root.railCurrentIndex
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: (root.thumbnailWidth + spacing) * 3
                preferredHighlightEnd: preferredHighlightBegin + root.thumbnailWidth
                boundsBehavior: Flickable.StopAtBounds
                highlightFollowsCurrentItem: true

                Behavior on contentX {
                    enabled: root.animateRail
                    NumberAnimation { duration: 165; easing.type: Easing.OutCubic }
                }

                onMovementEnded: {
                    const count = root.wallpapers.length
                    if (count > 0 && (root.railCurrentIndex < count || root.railCurrentIndex >= count * 2)) {
                        const canonicalIndex = count + root.selectedIndex
                        root.animateRail = false
                        root.railCurrentIndex = canonicalIndex
                        positionViewAtIndex(Math.max(0, canonicalIndex - 3), ListView.Beginning)
                        Qt.callLater(function() { root.animateRail = true })
                    }
                }

                delegate: Rectangle {
                    id: thumbnailDelegate
                    required property var modelData
                    property bool isCurrentItem: modelData.loopIndex === root.railCurrentIndex

                    width: root.thumbnailWidth
                    height: 64
                    radius: 5
                    color: "#111820"
                    clip: true
                    border.width: isCurrentItem ? 2 : 0
                    border.color: "#D3A64A"

                    Rectangle {
                        anchors.fill: parent
                        radius: thumbnailDelegate.isCurrentItem ? 3 : 5
                        color: "#111820"
                        clip: true

                        Image {
                            id: staticPreview
                            anchors.fill: parent
                            source: root.opened && thumbnailDelegate.modelData.wallpaper.type === "static"
                                ? thumbnailDelegate.modelData.wallpaper.path : ""
                            sourceSize.width: root.thumbnailWidth * 2
                            sourceSize.height: 0
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            cache: false
                            smooth: true
                            visible: thumbnailDelegate.modelData.wallpaper.type === "static"
                                && status === Image.Ready
                        }

                        AnimatedImage {
                            id: animatedPreview
                            anchors.fill: parent
                            source: root.opened && thumbnailDelegate.modelData.wallpaper.type === "animated"
                                ? thumbnailDelegate.modelData.wallpaper.path : ""
                            sourceSize.width: root.thumbnailWidth * 2
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            cache: false
                            playing: root.opened
                                && thumbnailDelegate.modelData.wallpaper.type === "animated"
                                && (thumbnailMouse.containsMouse || thumbnailDelegate.isCurrentItem)
                            visible: thumbnailDelegate.modelData.wallpaper.type === "animated"
                                && status === AnimatedImage.Ready
                        }

                        Loader {
                            id: videoPreviewLoader
                            anchors.fill: parent
                            active: root.opened && thumbnailDelegate.modelData.wallpaper.type === "video"
                                && (thumbnailMouse.containsMouse || thumbnailDelegate.isCurrentItem)
                            source: active ? "VideoWallpaperPreview.qml" : ""
                            onLoaded: {
                                item.sourcePath = Qt.binding(function() {
                                    return thumbnailDelegate.modelData.wallpaper.path
                                })
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: "#111820"
                            visible: thumbnailDelegate.modelData.wallpaper.type === "video"
                                && !(videoPreviewLoader.item && videoPreviewLoader.item.hasVideo)
                        }

                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: 4
                            anchors.rightMargin: 4
                            width: 14
                            height: 14
                            radius: 7
                            color: "#D3A64A"
                            visible: thumbnailDelegate.isCurrentItem
                            Text {
                                anchors.centerIn: parent
                                text: "✓"
                                color: "#151515"
                                font.pixelSize: 9
                                font.weight: Font.Bold
                            }
                        }

                        MouseArea {
                            id: thumbnailMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectWallpaperByIndex(
                                thumbnailDelegate.modelData.wallpaperIndex,
                                thumbnailDelegate.modelData.loopIndex
                            )
                        }
                    }
                }
            }

        }
    }

    Rectangle {
        id: settingsCard
        z: 4
        width: Math.min(600, parent.width - 28)
        height: Math.min(500, Math.max(220, parent.height - 136))
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.pickerBarHeight + 34
        radius: 20
        color: "#FBFCFD"
        border.width: 1
        border.color: "#FFFFFF"
        visible: root.opened && root.settingsOpen
        opacity: visible ? 1 : 0
        scale: visible ? 1 : 0.97
        transformOrigin: Item.Bottom
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -5
            radius: 25
            color: "#30000000"
            z: -1
        }

        Row {
            id: settingsHeader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 18
            anchors.rightMargin: 14
            anchors.topMargin: 14
            height: 32
            spacing: 8

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    text: "WALLPAPER SETTINGS"
                    color: "#151920"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.0
                }
                Text {
                    text: "Rotation, collections and scheduled changes"
                    color: "#7A8491"
                    font.pixelSize: 8
                }
            }

            Item { width: Math.max(0, parent.width - 220); height: 1 }

            Rectangle {
                width: 30
                height: 30
                radius: 10
                color: closeSettingsMouse.containsMouse ? "#E7EBF0" : "#F0F2F5"
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: "#454D59"
                    font.pixelSize: 18
                }
                MouseArea {
                    id: closeSettingsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.settingsOpen = false
                }
            }
        }

        Flickable {
            id: settingsScroll
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: settingsHeader.bottom
            anchors.bottom: parent.bottom
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            anchors.topMargin: 10
            anchors.bottomMargin: 14
            clip: true
            contentWidth: width
            contentHeight: settingsContent.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: settingsContent
                width: settingsScroll.width
                spacing: 10

                Rectangle {
                    width: parent.width
                    height: 54
                    radius: 12
                    color: "#F1F4F7"
                    border.width: 1
                    border.color: "#E2E7ED"
                    Image {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        height: 20
                        source: Qt.resolvedUrl("../assets/icons/quick-image.svg")
                        fillMode: Image.PreserveAspectFit
                    }
                    Column {
                        x: 42
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        Text { text: "Choose from files"; color: "#252B34"; font.pixelSize: 10; font.weight: Font.DemiBold }
                        Text { text: "Images, GIFs, animated WebP and videos"; color: "#75808D"; font.pixelSize: 8 }
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: "›"
                        color: "#5E6875"
                        font.pixelSize: 22
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launchFilePicker("set")
                    }
                }

                Rectangle { width: parent.width; height: 1; color: "#E4E8ED" }

                Row {
                    width: parent.width
                    height: 36
                    spacing: 8
                    Column {
                        width: parent.width - 62
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        Text { text: "Automatic rotation"; color: "#252B34"; font.pixelSize: 10; font.weight: Font.DemiBold }
                        Text { text: "Change wallpapers on a schedule"; color: "#7A8491"; font.pixelSize: 8 }
                    }
                    Rectangle {
                        width: 48
                        height: 26
                        radius: 13
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.autoRotate ? "#1A2029" : "#D8DDE4"
                        Rectangle {
                            x: root.autoRotate ? 25 : 3
                            y: 3
                            width: 20
                            height: 20
                            radius: 10
                            color: "#FFFFFF"
                            Behavior on x { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.autoRotate = !root.autoRotate
                                root.setSetting("enabled", root.autoRotate ? 1 : 0)
                                if (root.autoRotate)
                                    root.setSetting("last_rotation", Math.floor(Date.now() / 1000))
                            }
                        }
                    }
                }

                Text { text: "CHANGE EVERY"; color: "#7A8491"; font.pixelSize: 8; font.weight: Font.DemiBold; font.letterSpacing: 0.8 }

                Row {
                    width: parent.width
                    spacing: 5
                    Repeater {
                        model: [{v:5,t:"5m"},{v:15,t:"15m"},{v:30,t:"30m"},{v:60,t:"1h"},{v:120,t:"2h"},{v:1440,t:"Daily"}]
                        delegate: Rectangle {
                            required property var modelData
                            width: (settingsContent.width - 25) / 6
                            height: 30
                            radius: 8
                            color: root.rotateInterval === modelData.v ? "#202630" : "#F0F2F5"
                            border.width: 1
                            border.color: root.rotateInterval === modelData.v ? "#202630" : "#E0E5EB"
                            Text {
                                anchors.centerIn: parent
                                text: modelData.t
                                color: root.rotateInterval === modelData.v ? "#FFFFFF" : "#515B68"
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.rotateInterval = modelData.v
                                    root.setSetting("interval", modelData.v)
                                }
                            }
                        }
                    }
                }

                Text { text: "ORDER"; color: "#7A8491"; font.pixelSize: 8; font.weight: Font.DemiBold; font.letterSpacing: 0.8 }

                Row {
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: [{v:"random",t:"Random order"},{v:"sequential",t:"In order"}]
                        delegate: Rectangle {
                            required property var modelData
                            width: (settingsContent.width - 6) / 2
                            height: 32
                            radius: 9
                            color: root.rotateMode === modelData.v ? "#202630" : "#F0F2F5"
                            Text {
                                anchors.centerIn: parent
                                text: modelData.t
                                color: root.rotateMode === modelData.v ? "#FFFFFF" : "#515B68"
                                font.pixelSize: 9
                                font.weight: Font.Medium
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.rotateMode = modelData.v
                                    root.setSetting("mode", modelData.v)
                                }
                            }
                        }
                    }
                }

                Text { text: "INCLUDE"; color: "#7A8491"; font.pixelSize: 8; font.weight: Font.DemiBold; font.letterSpacing: 0.8 }

                Row {
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: [{v:"both",t:"Static + live"},{v:"static",t:"Static"},{v:"animated",t:"Live"}]
                        delegate: Rectangle {
                            required property var modelData
                            width: (settingsContent.width - 12) / 3
                            height: 32
                            radius: 9
                            color: root.rotateSource === modelData.v ? "#202630" : "#F0F2F5"
                            Text {
                                anchors.centerIn: parent
                                text: modelData.t
                                color: root.rotateSource === modelData.v ? "#FFFFFF" : "#515B68"
                                font.pixelSize: 8
                                font.weight: Font.Medium
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.rotateSource = modelData.v
                                    root.setSetting("source", modelData.v)
                                }
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    height: 32
                    spacing: 8
                    Text {
                        text: "Avoid repeating current wallpaper"
                        width: parent.width - 58
                        color: "#3F4854"
                        font.pixelSize: 9
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        width: 44
                        height: 24
                        radius: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.avoidRepeat ? "#202630" : "#D8DDE4"
                        Rectangle {
                            x: root.avoidRepeat ? 23 : 3
                            y: 3
                            width: 18
                            height: 18
                            radius: 9
                            color: "#FFFFFF"
                            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.avoidRepeat = !root.avoidRepeat
                                root.setSetting("avoid_repeat", root.avoidRepeat ? 1 : 0)
                            }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: "#E4E8ED" }
                Text { text: "TIME-OF-DAY WALLPAPERS"; color: "#202630"; font.pixelSize: 9; font.weight: Font.DemiBold; font.letterSpacing: 0.8 }
                Text {
                    text: "Optional morning and evening wallpapers. Empty slots are ignored."
                    color: "#7A8491"
                    font.pixelSize: 8
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Row {
                    width: parent.width
                    height: 34
                    spacing: 6
                    Text { text: "Morning"; color: "#48515D"; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter; width: 46 }
                    Rectangle {
                        width: 60
                        height: 30
                        radius: 8
                        color: "#F0F2F5"
                        Text { anchors.centerIn: parent; text: root.morningTime; color: "#323A45"; font.pixelSize: 9 }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const parts = root.morningTime.split(":")
                                const hour = (Number(parts[0]) + 1) % 24
                                root.morningTime = (hour < 10 ? "0" : "") + hour + ":" + parts[1]
                                root.setSetting("morning_time", root.morningTime)
                            }
                        }
                    }
                    Rectangle {
                        width: Math.max(60, parent.width - 112)
                        height: 30
                        radius: 8
                        color: "#F0F2F5"
                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.morningPath ? root.morningPath.split("/").pop() : "Choose file"
                            color: "#323A45"
                            font.pixelSize: 8
                            elide: Text.ElideMiddle
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.launchFilePicker("morning")
                        }
                    }
                }

                Row {
                    width: parent.width
                    height: 34
                    spacing: 6
                    Text { text: "Evening"; color: "#48515D"; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter; width: 46 }
                    Rectangle {
                        width: 60
                        height: 30
                        radius: 8
                        color: "#F0F2F5"
                        Text { anchors.centerIn: parent; text: root.eveningTime; color: "#323A45"; font.pixelSize: 9 }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const parts = root.eveningTime.split(":")
                                const hour = (Number(parts[0]) + 1) % 24
                                root.eveningTime = (hour < 10 ? "0" : "") + hour + ":" + parts[1]
                                root.setSetting("evening_time", root.eveningTime)
                            }
                        }
                    }
                    Rectangle {
                        width: Math.max(60, parent.width - 112)
                        height: 30
                        radius: 8
                        color: "#F0F2F5"
                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.eveningPath ? root.eveningPath.split("/").pop() : "Choose file"
                            color: "#323A45"
                            font.pixelSize: 8
                            elide: Text.ElideMiddle
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.launchFilePicker("evening")
                        }
                    }
                }
            }
        }
    }

    // A dedicated focus target ensures layer-shell keyboard events reach the picker.
    Item {
        id: keyboardReceiver
        anchors.fill: parent
        z: 100
        focus: root.opened
        enabled: root.opened
        Keys.priority: Keys.BeforeItem

        Keys.onPressed: function(event) {
            if (!root.opened)
                return

            if (event.key === Qt.Key_Left) {
                if (!root.settingsOpen)
                    root.stepWallpaper(-1)
                event.accepted = true
            } else if (event.key === Qt.Key_Right) {
                if (!root.settingsOpen)
                    root.stepWallpaper(1)
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (!root.settingsOpen)
                    root.confirmCurrentWallpaper()
                event.accepted = true
            } else if (event.key === Qt.Key_Escape) {
                if (root.settingsOpen)
                    root.settingsOpen = false
                else
                    root.closeRequested()
                event.accepted = true
            }
        }
    }


    Timer {
        id: releasePreviewTimer
        interval: 260
        repeat: false
        onTriggered: {
            if (root.opened)
                return
            root.wallpapers = []
            root.wallpaperCatalogReady = false
            root.selectedIndex = -1
            root.railCurrentIndex = -1
            root.selectedWallpaperKey = ""
        }
    }

    onOpenedChanged: {
        if (!opened) {
            root.settingsOpen = false
            root.closeAfterApply = false
            root.pendingWallpaper = null
            releasePreviewTimer.restart()
            return
        }

        releasePreviewTimer.stop()
        root.settingsOpen = root.showSettingsAfterPicker
        root.showSettingsAfterPicker = false
        Qt.callLater(function() {
            if (root.opened)
                keyboardReceiver.forceActiveFocus()
        })
        root.wallpaperCatalogReady = false
        root.wallpapers = []
        root.selectedIndex = -1
        root.railCurrentIndex = -1
        root.selectedWallpaperKey = ""

        settingsProcess.running = false
        catalogProcess.running = false
        Qt.callLater(function() {
            settingsProcess.running = true
            catalogProcess.running = true
        })
    }
}
