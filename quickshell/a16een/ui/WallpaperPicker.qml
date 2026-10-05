import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool opened: false
    property var wallpapers: []
    property string activeTab: "wallpaper"

    signal closeRequested()

    readonly property var filteredWallpapers: {
        const next = []
        for (const item of root.wallpapers) {
            if (root.activeTab === "wallpaper" && item.type === "static")
                next.push(item)
            else if (root.activeTab === "animated"
                     && (item.type === "animated" || item.type === "video"))
                next.push(item)
        }
        return next
    }

    readonly property int columns: 3
    readonly property int tileWidth: 204
    readonly property int tileHeight: 146
    readonly property int tileGap: 10
    readonly property int gridWidth: columns * tileWidth + (columns - 1) * tileGap
    readonly property int gridHeight: filteredWallpapers.length > 0
        ? Math.ceil(filteredWallpapers.length / columns) * (tileHeight + tileGap) - tileGap
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
                    { key: "animated", label: "Animated" }
                ]

                delegate: Rectangle {
                    required property var modelData
                    width: 112
                    height: 38
                    radius: 11
                    color: root.activeTab === modelData.key ? "#151515" : "#F4F4F4"
                    border.width: root.activeTab === modelData.key ? 0 : 1
                    border.color: "#E7E7E7"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: root.activeTab === modelData.key ? "#FFFFFF" : "#555555"
                        font.pixelSize: 11
                        font.weight: root.activeTab === modelData.key
                            ? Font.DemiBold
                            : Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTab = modelData.key
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
            anchors.margins: 22
            anchors.topMargin: 14
            clip: true

            Flickable {
                id: wallpaperScroll
                anchors.fill: parent
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
                        model: root.filteredWallpapers

                        delegate: Rectangle {
                            required property var modelData

                            width: root.tileWidth
                            height: root.tileHeight
                            radius: 13
                            color: "#FFFFFF"
                            border.width: modelData.selected ? 2 : 1
                            border.color: modelData.selected ? "#111111" : "#E8E8E8"

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: 12
                                color: "#F7F7F7"
                                clip: true

                                Image {
                                    id: preview
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 5
                                    height: 104
                                    source: modelData.type === "static" ? modelData.path : ""
                                    sourceSize.width: root.tileWidth * 2
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    smooth: true
                                    visible: modelData.type === "static" && status === Image.Ready
                                }

                                AnimatedImage {
                                    id: gifPreview
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 5
                                    height: 104
                                    source: modelData.type === "animated" ? modelData.path : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: false
                                    playing: modelData.type === "animated"
                                    loops: Animation.Infinite
                                    visible: modelData.type === "animated" && status === AnimatedImage.Ready
                                }

                                MediaPlayer {
                                    id: videoPreviewPlayer
                                    source: modelData.type === "video" ? modelData.path : ""
                                    loops: MediaPlayer.Infinite
                                    audioOutput: AudioOutput {
                                        muted: true
                                        volume: 0
                                    }
                                }

                                VideoOutput {
                                    id: videoPreview
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 5
                                    height: 104
                                    source: videoPreviewPlayer
                                    fillMode: VideoOutput.PreserveAspectCrop
                                    visible: modelData.type === "video"
                                }

                                Connections {
                                    target: videoPreviewPlayer

                                    function onMediaStatusChanged(status) {
                                        if (modelData.type === "video"
                                                && (status === MediaPlayer.LoadedMedia
                                                    || status === MediaPlayer.BufferedMedia)) {
                                            videoPreviewPlayer.play()
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 5
                                    height: 104
                                    radius: 8
                                    color: "#F4F4F4"
                                    visible: {
                                        if (modelData.type === "static")
                                            return preview.status !== Image.Ready
                                        if (modelData.type === "animated")
                                            return gifPreview.status !== AnimatedImage.Ready
                                        return videoPreviewPlayer.mediaStatus !== MediaPlayer.LoadedMedia
                                            && videoPreviewPlayer.mediaStatus !== MediaPlayer.BufferedMedia
                                    }
                                }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    visible: modelData.type !== "video"
                                        ? (modelData.type === "static"
                                            ? preview.status !== Image.Ready && preview.status !== Image.Error
                                            : gifPreview.status !== AnimatedImage.Ready && gifPreview.status !== AnimatedImage.Error)
                                        : videoPreviewPlayer.mediaStatus !== MediaPlayer.LoadedMedia
                                            && videoPreviewPlayer.mediaStatus !== MediaPlayer.BufferedMedia

                                    Repeater {
                                        model: 3

                                        delegate: Rectangle {
                                            width: 5
                                            height: 5
                                            radius: 3
                                            color: "#8A8A8A"
                                            opacity: 0.35

                                            SequentialAnimation on opacity {
                                                loops: Animation.Infinite
                                                running: true
                                                PauseAnimation { duration: index * 140 }
                                                NumberAnimation { to: 1; duration: 280; easing.type: Easing.InOutQuad }
                                                NumberAnimation { to: 0.35; duration: 280; easing.type: Easing.InOutQuad }
                                                PauseAnimation { duration: (2 - index) * 140 }
                                            }
                                        }
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "Preview unavailable"
                                    color: "#A0A0A0"
                                    font.pixelSize: 9
                                    visible: modelData.type === "static"
                                        ? preview.status === Image.Error
                                        : modelData.type === "animated"
                                            ? gifPreview.status === AnimatedImage.Error
                                            : videoPreviewPlayer.error !== MediaPlayer.NoError
                                }

                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.topMargin: 10
                                    anchors.rightMargin: 10
                                    width: modelData.type === "video" ? 48 : 54
                                    height: 20
                                    radius: 10
                                    color: "#CCFFFFFF"
                                    visible: modelData.type === "animated" || modelData.type === "video"

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.type === "video" ? "VIDEO" : "GIF"
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
                                    font.weight: modelData.selected ? Font.DemiBold : Font.Medium
                                    elide: Text.ElideMiddle
                                    verticalAlignment: Text.AlignVCenter
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        root.closeRequested()
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

                Text {
                    anchors.centerIn: parent
                    visible: root.filteredWallpapers.length === 0
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
            root.activeTab = "wallpaper"
            root.wallpapers = []
            catalogProcess.running = false
            catalogProcess.running = true
        }
    }
}
