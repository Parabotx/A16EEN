import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool opened: false
    property var wallpapers: []
    property string activeTab: "wallpaper"
    property string fileDialogPurpose: "set"
    property bool autoRotate: false
    property int rotateInterval: 30
    property string rotateMode: "random"
    property string rotateSource: "both"
    property bool avoidRepeat: true
    property string morningTime: "07:00"
    property string eveningTime: "19:00"
    property string morningPath: ""
    property string eveningPath: ""
    property string tabAfterPicker: "wallpaper"
    property bool reopenAfterPicker: false
    property bool pickerOutputReady: false
    property bool pickerFinishHandled: false

    signal closeRequested()
    signal openRequested()

    readonly property var visibleWallpapers: {
        const result = []
        for (const wallpaper of root.wallpapers) {
            if (root.activeTab === "wallpaper") {
                if (wallpaper.type === "static")
                    result.push(wallpaper)
            } else {
                if (wallpaper.type === "animated" || wallpaper.type === "video")
                    result.push(wallpaper)
            }
        }
        return result
    }

    readonly property int columns: 3
    readonly property int tileWidth: 204
    readonly property int tileHeight: 146
    readonly property int tileGap: 10
    readonly property int gridWidth: columns * tileWidth + (columns - 1) * tileGap
    readonly property int gridHeight: visibleWallpapers.length > 0
        ? Math.ceil(visibleWallpapers.length / columns) * (tileHeight + tileGap) - tileGap
        : 0

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
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    Process {
        id: settingsProcess
        command: ["a16een-wallpaper", "settings", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const values = {}
                for (const line of text.trim().split(/\r?\n/)) {
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

    function setSetting(key, value) {
        Quickshell.execDetached(["a16een-wallpaper", "settings", "set", key, String(value)])
    }

    function launchFilePicker(purpose) {
        root.fileDialogPurpose = purpose
        root.tabAfterPicker = root.activeTab
        root.reopenAfterPicker = true
        root.pickerOutputReady = false
        root.pickerFinishHandled = false
        // A layer-shell overlay stays above ordinary desktop windows. Hide it
        // before launching the desktop chooser so it cannot cover the dialog.
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
            // The helper applies/saves the selection before returning it.
            if (purpose === "set") {
                root.reopenAfterPicker = false
                root.tabAfterPicker = "wallpaper"
            }
            root.fileDialogPurpose = "set"
        }
        // Reopen on cancellation/error, and after choosing a scheduled file.
        // A normal wallpaper selection intentionally leaves the manager closed.
        if (root.reopenAfterPicker) {
            root.reopenAfterPicker = false
            root.openRequested()
        }
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

    Process {
        id: catalogProcess
        command: ["a16een-wallpaper", "catalog"]

        stdout: StdioCollector {
            onStreamFinished: {
                const next = []
                const lines = text.trim().split(/\r?\n/)

                for (const line of lines) {
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

                root.wallpapers = next
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.opened ? 0.28 : 0
    }

    Rectangle {
        id: card
        z: 2
        width: Math.min(720, parent.width - 64)
        height: Math.min(560, parent.height - 72)
        anchors.centerIn: parent
        radius: 22
        color: "#FFFFFF"
        border.width: 1
        border.color: "#E7E7E7"

        Rectangle {
            anchors.fill: parent
            anchors.margins: -5
            radius: 27
            color: "#28000000"
            z: -1
        }

        Row {
            id: tabs
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 18
            height: 38
            spacing: 6

            Repeater {
                model: [
                    { key: "wallpaper", label: "Wallpaper" },
                    { key: "animated", label: "Animated" },
                    { key: "settings", label: "Settings" }
                ]

                delegate: Rectangle {
                    required property var modelData

                    width: 116
                    height: 38
                    radius: 11
                    color: root.activeTab === modelData.key
                        ? "#151515"
                        : "#F4F4F4"
                    border.width: root.activeTab === modelData.key ? 0 : 1
                    border.color: "#E7E7E7"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: root.activeTab === modelData.key
                            ? "#FFFFFF"
                            : "#555555"
                        font.pixelSize: 11
                        font.weight: root.activeTab === modelData.key
                            ? Font.DemiBold
                            : Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.activeTab = modelData.key
                            wallpaperScroll.contentY = 0
                        }
                    }
                }
            }
        }

        Item {
            id: pickerViewport
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: tabs.bottom
            anchors.bottom: parent.bottom
            anchors.leftMargin: 22
            anchors.rightMargin: 22
            anchors.topMargin: 14
            anchors.bottomMargin: 22
            clip: true

            Flickable {
                id: wallpaperSettings
                anchors.fill: parent
                clip: true
                visible: root.activeTab === "settings"
                contentWidth: width
                contentHeight: settingsContent.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                id: settingsContent
                width: wallpaperSettings.width
                spacing: 14

                Text {
                    text: "Wallpaper settings"
                    color: "#171717"
                    font.pixelSize: 19
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "Choose any supported image, animated image, or video from your files. A16EEN uses the original file in place — you do not need to copy it into a wallpaper folder."
                    color: "#707070"
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Rectangle {
                    width: parent.width
                    height: 86
                    radius: 14
                    color: "#F6F6F6"
                    border.width: 1
                    border.color: "#E7E7E7"

                    Row {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        Rectangle {
                            width: 42
                            height: 42
                            radius: 12
                            color: "#E9E9E9"
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: "↗"
                                color: "#222222"
                                font.pixelSize: 21
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 120
                            spacing: 4

                            Text {
                                text: "Choose from files"
                                color: "#222222"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "PNG, JPG, WEBP, GIF, MP4, WEBM and more"
                                color: "#777777"
                                font.pixelSize: 10
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launchFilePicker("set")
                    }
                }

                Text {
                    text: "Your selected file stays wherever it is. If you move or delete it later, choose it again from here."
                    color: "#858585"
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Rectangle { width: parent.width; height: 1; color: "#EAEAEA" }

                Text { text: "Automatic rotation"; color: "#171717"; font.pixelSize: 15; font.weight: Font.DemiBold }

                Row {
                    width: parent.width
                    height: 42
                    spacing: 10
                    Text { text: "Change wallpaper automatically"; color: "#333333"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 76 }
                    Rectangle {
                        width: 52; height: 28; radius: 14; anchors.verticalCenter: parent.verticalCenter
                        color: root.autoRotate ? "#171717" : "#DADADA"
                        Rectangle { x: root.autoRotate ? 27 : 3; y: 3; width: 22; height: 22; radius: 11; color: "#FFFFFF" }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: {
                            root.autoRotate = !root.autoRotate
                            root.setSetting("enabled", root.autoRotate ? 1 : 0)
                            if (root.autoRotate)
                                root.setSetting("last_rotation", Math.floor(Date.now() / 1000))
                        } }
                    }
                }

                Text { text: "Change every"; color: "#777777"; font.pixelSize: 10 }
                Row {
                    width: parent.width; spacing: 6
                    Repeater {
                        model: [{v:5,t:"5 min"},{v:15,t:"15 min"},{v:30,t:"30 min"},{v:60,t:"1 hour"},{v:120,t:"2 hours"},{v:1440,t:"Daily"}]
                        delegate: Rectangle {
                            required property var modelData
                            width: (settingsContent.width - 30) / 6; height: 34; radius: 8
                            color: root.rotateInterval === modelData.v ? "#171717" : "#F3F3F3"
                            Text { anchors.centerIn: parent; text: modelData.t; color: root.rotateInterval === modelData.v ? "#FFFFFF" : "#555555"; font.pixelSize: 9 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.rotateInterval = modelData.v; root.setSetting("interval", modelData.v) } }
                        }
                    }
                }

                Text { text: "Selection mode"; color: "#777777"; font.pixelSize: 10 }
                Row {
                    width: parent.width; spacing: 8
                    Repeater {
                        model: [{v:"random",t:"Random"},{v:"sequential",t:"In order"}]
                        delegate: Rectangle {
                            required property var modelData
                            width: (settingsContent.width - 8) / 2; height: 36; radius: 9
                            color: root.rotateMode === modelData.v ? "#171717" : "#F3F3F3"
                            Text { anchors.centerIn: parent; text: modelData.t; color: root.rotateMode === modelData.v ? "#FFFFFF" : "#555555"; font.pixelSize: 10 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.rotateMode = modelData.v; root.setSetting("mode", modelData.v) } }
                        }
                    }
                }

                Text { text: "Wallpaper types"; color: "#777777"; font.pixelSize: 10 }
                Row {
                    width: parent.width; spacing: 8
                    Repeater {
                        model: [{v:"both",t:"Static + animated"},{v:"static",t:"Static only"},{v:"animated",t:"Animated only"}]
                        delegate: Rectangle {
                            required property var modelData
                            width: (settingsContent.width - 16) / 3; height: 36; radius: 9
                            color: root.rotateSource === modelData.v ? "#171717" : "#F3F3F3"
                            Text { anchors.centerIn: parent; text: modelData.t; color: root.rotateSource === modelData.v ? "#FFFFFF" : "#555555"; font.pixelSize: 9 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.rotateSource = modelData.v; root.setSetting("source", modelData.v) } }
                        }
                    }
                }

                Row {
                    width: parent.width; height: 34; spacing: 8
                    Text { text: "Avoid repeating current wallpaper"; color: "#555555"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 52 }
                    Rectangle {
                        width: 42; height: 24; radius: 12; anchors.verticalCenter: parent.verticalCenter
                        color: root.avoidRepeat ? "#171717" : "#DADADA"
                        Rectangle { x: root.avoidRepeat ? 21 : 3; y: 3; width: 18; height: 18; radius: 9; color: "#FFFFFF" }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.avoidRepeat = !root.avoidRepeat; root.setSetting("avoid_repeat", root.avoidRepeat ? 1 : 0) } }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: "#EAEAEA" }
                Text { text: "Time-of-day wallpapers"; color: "#171717"; font.pixelSize: 15; font.weight: Font.DemiBold }
                Text { text: "Choose a different wallpaper for morning and evening. Leave a slot empty to skip it."; color: "#777777"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }

                Row {
                    width: parent.width; spacing: 8; height: 38
                    Text { text: "Morning"; color: "#333333"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter; width: 60 }
                    Rectangle {
                        width: 76; height: 32; radius: 8; color: "#F3F3F3"; anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: root.morningTime; color: "#333333"; font.pixelSize: 10 }
                        MouseArea { anchors.fill: parent; onClicked: { let parts = root.morningTime.split(":"); let h = (Number(parts[0]) + 1) % 24; root.morningTime = (h < 10 ? "0" : "") + h + ":" + parts[1]; root.setSetting("morning_time", root.morningTime) } }
                    }
                    Rectangle {
                        width: parent.width - 160; height: 32; radius: 8; color: "#F3F3F3"; anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: root.morningPath ? root.morningPath.split("/").pop() : "Choose morning file"; color: "#333333"; font.pixelSize: 9; elide: Text.ElideMiddle; width: parent.width - 12 }
                        MouseArea { anchors.fill: parent; onClicked: root.launchFilePicker("morning") }
                    }
                }
                Row {
                    width: parent.width; spacing: 8; height: 38
                    Text { text: "Evening"; color: "#333333"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter; width: 60 }
                    Rectangle {
                        width: 76; height: 32; radius: 8; color: "#F3F3F3"; anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: root.eveningTime; color: "#333333"; font.pixelSize: 10 }
                        MouseArea { anchors.fill: parent; onClicked: { let parts = root.eveningTime.split(":"); let h = (Number(parts[0]) + 1) % 24; root.eveningTime = (h < 10 ? "0" : "") + h + ":" + parts[1]; root.setSetting("evening_time", root.eveningTime) } }
                    }
                    Rectangle {
                        width: parent.width - 152; height: 32; radius: 8; color: "#F3F3F3"; anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: root.eveningPath ? root.eveningPath.split("/").pop() : "Choose evening file"; color: "#333333"; font.pixelSize: 9; elide: Text.ElideMiddle; width: parent.width - 12 }
                        MouseArea { anchors.fill: parent; onClicked: root.launchFilePicker("evening") }
                    }
                }
                }
            }

            Flickable {
                id: wallpaperScroll
                anchors.fill: parent
                visible: root.activeTab !== "settings"
                contentWidth: width
                contentHeight: Math.max(root.gridHeight, height)
                boundsBehavior: Flickable.StopAtBounds

                Grid {
                    id: wallpaperGrid
                    x: Math.max(0, (wallpaperScroll.width - width) / 2)
                    y: 0
                    width: root.gridWidth
                    columns: root.columns
                    columnSpacing: root.tileGap
                    rowSpacing: root.tileGap

                    Repeater {
                        model: root.visibleWallpapers

                        delegate: Rectangle {
                            required property var modelData

                            width: root.tileWidth
                            height: root.tileHeight
                            radius: 13
                            color: "#FFFFFF"
                            border.width: modelData.selected ? 2 : 1
                            border.color: modelData.selected
                                ? "#111111"
                                : "#E8E8E8"

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: 12
                                color: "#F7F7F7"
                                clip: true

                                Image {
                                    id: staticPreview
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 5
                                    height: 104
                                    source: modelData.type === "static"
                                        ? Qt.resolvedUrl(modelData.path)
                                        : ""
                                    sourceSize.width: root.tileWidth * 2
                                    sourceSize.height: 0
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    smooth: true
                                    visible: modelData.type === "static"
                                        && status === Image.Ready
                                }

                                AnimatedImage {
                                    id: animatedPreview
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 5
                                    height: 104
                                    source: modelData.type === "animated"
                                        ? modelData.path
                                        : ""
                                    sourceSize.width: root.tileWidth * 2
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: false
                                    playing: modelData.type === "animated"
                                    visible: modelData.type === "animated"
                                        && status === AnimatedImage.Ready
                                }

                                // Load the optional Qt Multimedia preview only while a
                                // video tile is hovered. A broken plugin must not stop
                                // the wallpaper picker or the rest of the shell.
                                Loader {
                                    id: videoPreviewLoader
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 5
                                    height: 104
                                    active: modelData.type === "video" && tileMouseArea.containsMouse
                                    source: active ? "VideoWallpaperPreview.qml" : ""

                                    onLoaded: {
                                        item.sourcePath = Qt.binding(function() {
                                            return modelData.path
                                        })
                                    }
                                }

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 5
                                    height: 104
                                    radius: 8
                                    color: "#F0F0F0"
                                    visible: modelData.type === "video"
                                        && !(videoPreviewLoader.item && videoPreviewLoader.item.hasVideo)
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.type === "video"
                                        ? ((videoPreviewLoader.status === Loader.Error
                                            || (videoPreviewLoader.item && videoPreviewLoader.item.previewError))
                                            ? "Preview unavailable"
                                            : "VIDEO")
                                        : "Preview unavailable"
                                    color: "#9A9A9A"
                                    font.pixelSize: 9
                                    font.weight: Font.Medium
                                    visible: modelData.type === "video"
                                        ? !(videoPreviewLoader.item && videoPreviewLoader.item.hasVideo)
                                        : (modelData.type === "static"
                                            ? staticPreview.status === Image.Error
                                            : animatedPreview.status === AnimatedImage.Error)
                                }

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 5
                                    height: 104
                                    radius: 8
                                    color: "#F4F4F4"
                                    visible: modelData.type === "static"
                                        ? staticPreview.status !== Image.Ready
                                        : modelData.type === "animated"
                                            ? animatedPreview.status !== AnimatedImage.Ready
                                            : false

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        visible: modelData.type !== "video"

                                        Repeater {
                                            model: 3

                                            delegate: Rectangle {
                                                width: 5
                                                height: 5
                                                radius: 3
                                                color: "#8A8A8A"
                                                opacity: 0.35

                                                SequentialAnimation on opacity {
                                                    running: true

                                                    PauseAnimation {
                                                        duration: index * 140
                                                    }

                                                    NumberAnimation {
                                                        to: 1
                                                        duration: 280
                                                        easing.type: Easing.InOutQuad
                                                    }

                                                    NumberAnimation {
                                                        to: 0.35
                                                        duration: 280
                                                        easing.type: Easing.InOutQuad
                                                    }

                                                    PauseAnimation {
                                                        duration: (2 - index) * 140
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.topMargin: 10
                                    anchors.rightMargin: 10
                                    width: modelData.type === "video" ? 52 : modelData.name.toLowerCase().endsWith(".webp") ? 48 : 42
                                    height: 20
                                    radius: 10
                                    color: "#CCFFFFFF"
                                    visible: root.activeTab === "animated"

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.type === "video" ? "VIDEO" : modelData.name.toLowerCase().endsWith(".webp") ? "WEBP" : "GIF"
                                        color: "#222222"
                                        font.pixelSize: 8
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    anchors.bottomMargin: 8
                                    height: 18
                                    text: modelData.displayName
                                    color: "#161616"
                                    font.pixelSize: 10
                                    font.weight: modelData.selected
                                        ? Font.DemiBold
                                        : Font.Medium
                                    elide: Text.ElideMiddle
                                    verticalAlignment: Text.AlignVCenter
                                }

                                MouseArea {
                                    id: tileMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        root.closeRequested()
                                        if (modelData.source === "external") {
                                            Quickshell.execDetached([
                                                "a16een-wallpaper",
                                                "set-path",
                                                modelData.path
                                            ])
                                        } else {
                                            Quickshell.execDetached([
                                                "a16een-wallpaper",
                                                "set",
                                                modelData.source,
                                                modelData.name
                                            ])
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.visibleWallpapers.length === 0
                    text: root.activeTab === "animated"
                        ? "No animated wallpapers"
                        : "No wallpapers"
                    color: "#8A8A8A"
                    font.pixelSize: 11
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: 1
        onClicked: root.closeRequested()
    }

    Keys.onEscapePressed: root.closeRequested()

    onOpenedChanged: {
        if (opened) {
            root.activeTab = root.tabAfterPicker
            root.tabAfterPicker = "wallpaper"
            root.fileDialogPurpose = "set"
            root.wallpapers = []
            settingsProcess.running = false
            settingsProcess.running = true
            catalogProcess.running = false
            catalogProcess.running = true
        }
    }
}
