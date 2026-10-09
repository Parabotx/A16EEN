import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool widgetEnabled: false
    property var tracks: []
    property var playback: ({
        running: false,
        path: "",
        title: "",
        duration: 0,
        time: 0,
        paused: true,
        error: ""
    })
    property string statusMessage: ""
    property bool actionBusy: false

    readonly property color ink: "#182331"
    readonly property color secondary: "#68788B"
    readonly property color muted: "#9AA7B5"
    readonly property color accent: "#4C82C8"
    readonly property color border: "#E1E8F0"
    readonly property int activeIndex: root.indexForPath(root.playback.path)
    readonly property var previewTracks: {
        if (root.tracks.length <= 3)
            return root.tracks
        const center = root.activeIndex >= 0 ? root.activeIndex : 0
        const start = Math.max(0, Math.min(center - 1, root.tracks.length - 3))
        return root.tracks.slice(start, start + 3)
    }
    readonly property real progress: root.playback.duration > 0
        ? Math.max(0, Math.min(1, root.playback.time / root.playback.duration))
        : 0
    readonly property string currentTitle: root.playback.title.length
        ? root.playback.title
        : root.activeIndex >= 0 ? root.tracks[root.activeIndex].title : "Pick something to play"
    readonly property string currentArtist: root.activeIndex >= 0
        ? root.tracks[root.activeIndex].artist
        : root.tracks.length ? "Your local library" : "Songs in ~/Music appear here"

    screen: modelData
    visible: root.widgetEnabled
    color: "transparent"
    aboveWindows: false
    exclusiveZone: 0

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "a16een-widget-music"

    function indexForPath(path) {
        if (!path || !path.length)
            return -1
        for (let i = 0; i < root.tracks.length; i++) {
            if (root.tracks[i].path === path)
                return i
        }
        return -1
    }

    function formatTime(seconds) {
        const safe = Math.max(0, Math.floor(Number(seconds) || 0))
        const minutes = Math.floor(safe / 60)
        const remainder = safe % 60
        return minutes + ":" + (remainder < 10 ? "0" : "") + remainder
    }

    function applyLibraryOutput(raw) {
        try {
            const result = JSON.parse(String(raw || "{}"))
            root.tracks = result.tracks || []
            if (!result.directoryExists)
                root.statusMessage = "Create ~/Music and add audio files"
            else if (!root.tracks.length)
                root.statusMessage = "No supported audio files found"
            else
                root.statusMessage = ""
        } catch (error) {
            root.statusMessage = "Couldn't read your music library"
            root.tracks = []
        }
    }

    function applyPlaybackOutput(raw) {
        try {
            const result = JSON.parse(String(raw || "{}"))
            root.playback = result
            if (result.error)
                root.statusMessage = result.error
        } catch (error) {
            // A failed or empty status query should not interrupt the widget.
        }
    }

    function applyActionOutput(raw) {
        root.actionBusy = false
        try {
            const result = JSON.parse(String(raw || "{}"))
            if (result.error)
                root.statusMessage = result.error
            else if (result.message)
                root.statusMessage = result.message
            else
                root.statusMessage = ""
        } catch (error) {
            root.statusMessage = "Music action failed"
        }
        root.refreshPlayback()
    }

    function refreshLibrary() {
        if (!root.widgetEnabled || libraryProcess.running)
            return
        libraryProcess.running = true
    }

    function refreshPlayback() {
        if (!root.widgetEnabled || statusProcess.running)
            return
        statusProcess.running = true
    }

    function runAction(argumentsList) {
        if (root.actionBusy || actionProcess.running)
            return
        root.actionBusy = true
        actionProcess.command = ["a16een-music"].concat(argumentsList)
        actionProcess.running = true
    }

    function playTrack(index) {
        if (index < 0 || index >= root.tracks.length)
            return
        root.statusMessage = ""
        root.runAction(["play", root.tracks[index].path])
    }

    function advanceTrack(amount) {
        if (!root.tracks.length)
            return
        let nextIndex = root.activeIndex
        if (nextIndex < 0)
            nextIndex = amount > 0 ? -1 : 0
        nextIndex = (nextIndex + amount + root.tracks.length) % root.tracks.length
        root.playTrack(nextIndex)
    }

    Component.onCompleted: {
        if (root.widgetEnabled) {
            root.refreshLibrary()
            root.refreshPlayback()
        }
    }

    onWidgetEnabledChanged: {
        if (root.widgetEnabled) {
            root.refreshLibrary()
            root.refreshPlayback()
        }
    }

    Process {
        id: libraryProcess
        command: ["a16een-music", "list"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.applyLibraryOutput(this.text)
        }
    }

    Process {
        id: statusProcess
        command: ["a16een-music", "status"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.applyPlaybackOutput(this.text)
        }
    }

    Process {
        id: actionProcess
        command: ["a16een-music", "status"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.applyActionOutput(this.text)
        }
    }

    Timer {
        interval: 1500
        repeat: true
        running: root.widgetEnabled
        onTriggered: root.refreshPlayback()
    }

    Rectangle {
        id: card
        width: 344
        height: 354
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 28
        anchors.rightMargin: 28
        radius: 22
        color: "#F9FFFFFF"
        border.width: 1
        border.color: root.border
        clip: true

        Column {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 9

            Row {
                width: parent.width
                height: 26
                spacing: 9

                Rectangle {
                    width: 27
                    height: 27
                    radius: 9
                    color: "#EAF2FC"
                    border.width: 1
                    border.color: "#DCE8F7"

                    Text {
                        anchors.centerIn: parent
                        text: "♫"
                        color: root.accent
                        font.pixelSize: 17
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: "MUSIC PLAYER"
                        color: root.ink
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.1
                    }

                    Text {
                        text: "LOCAL LIBRARY"
                        color: root.muted
                        font.pixelSize: 6
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1
                    }
                }

                Item { width: Math.max(1, parent.width - 192); height: 1 }

                Rectangle {
                    width: 28
                    height: 27
                    radius: 9
                    color: refreshHover.containsMouse ? "#EAF2FC" : "#FFFFFF"
                    border.width: 1
                    border.color: root.border

                    Text {
                        anchors.centerIn: parent
                        text: "↻"
                        color: root.secondary
                        font.pixelSize: 17
                    }

                    MouseArea {
                        id: refreshHover
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.refreshLibrary()
                    }
                }
            }

            Row {
                width: parent.width
                height: 78
                spacing: 12

                Rectangle {
                    width: 78
                    height: 78
                    radius: 17
                    color: "#E8F0FB"
                    border.width: 1
                    border.color: "#DBE6F5"
                    clip: true

                    Rectangle {
                        width: 74
                        height: 74
                        radius: 37
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: -27
                        anchors.bottomMargin: -24
                        color: "#D4E3F6"
                    }

                    Rectangle {
                        width: 42
                        height: 42
                        radius: 21
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.leftMargin: -16
                        anchors.topMargin: -15
                        color: "#F7FAFE"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "♫"
                        color: "#356BAE"
                        font.pixelSize: 38
                        font.weight: Font.Light
                    }
                }

                Column {
                    width: parent.width - 90
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    Text {
                        text: "NOW PLAYING"
                        color: root.accent
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1
                    }

                    Text {
                        width: parent.width
                        text: root.currentTitle
                        color: root.ink
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    Text {
                        width: parent.width
                        text: root.currentArtist
                        color: root.secondary
                        font.pixelSize: 8
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.statusMessage.length
                            ? root.statusMessage
                            : root.playback.running
                                ? (root.playback.paused ? "READY TO RESUME" : "PLAYING FROM MUSIC")
                                : "READY WHEN YOU ARE"
                        color: root.muted
                        font.pixelSize: 6
                        elide: Text.ElideRight
                    }
                }
            }

            Row {
                width: parent.width
                height: 13
                spacing: 5

                Text {
                    text: "YOUR LIBRARY"
                    color: root.ink
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.8
                }

                Item { width: Math.max(1, parent.width - 145); height: 1 }

                Text {
                    text: root.tracks.length + (root.tracks.length === 1 ? " TRACK" : " TRACKS")
                    color: root.muted
                    font.pixelSize: 6
                    font.weight: Font.DemiBold
                }
            }

            Item {
                width: parent.width
                height: 87
                clip: true

                ListView {
                    id: trackList
                    anchors.fill: parent
                    model: root.tracks
                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    currentIndex: root.activeIndex

                    onCurrentIndexChanged: {
                        if (currentIndex >= 0)
                            positionViewAtIndex(currentIndex, ListView.Contain)
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        readonly property bool isCurrent: modelData.path === root.playback.path

                        width: trackList.width
                        height: 27
                        radius: 8
                        color: isCurrent ? "#EAF2FC" : trackHover.containsMouse ? "#F2F6FA" : "transparent"
                        border.width: isCurrent ? 1 : 0
                        border.color: "#D8E6F7"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                width: 15
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.parent.isCurrent && !root.playback.paused
                                    ? "♫"
                                    : String(index + 1).padStart(2, "0")
                                color: parent.parent.isCurrent ? root.accent : root.muted
                                font.pixelSize: 7
                                font.weight: Font.DemiBold
                            }

                            Column {
                                width: parent.width - 48
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: modelData.title
                                    color: parent.parent.parent.isCurrent ? root.ink : root.secondary
                                    font.pixelSize: 7
                                    font.weight: parent.parent.parent.isCurrent ? Font.DemiBold : Font.Medium
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: modelData.artist
                                    color: root.muted
                                    font.pixelSize: 6
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            id: trackHover
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.playTrack(index)
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    visible: root.tracks.length === 0
                    spacing: 4

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "♫"
                        color: "#A8BFE0"
                        font.pixelSize: 21
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Your music will appear here"
                        color: root.secondary
                        font.pixelSize: 8
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 4

                Row {
                    width: parent.width
                    height: 10

                    Text {
                        text: root.formatTime(root.playback.time)
                        color: root.secondary
                        font.pixelSize: 6
                        font.family: "Inter"
                    }

                    Item { width: Math.max(1, parent.width - 90); height: 1 }

                    Text {
                        text: root.formatTime(root.playback.duration)
                        color: root.muted
                        font.pixelSize: 6
                    }
                }

                Rectangle {
                    id: progressTrack
                    width: parent.width
                    height: 4
                    radius: 2
                    color: "#E6ECF3"

                    Rectangle {
                        width: parent.width * root.progress
                        height: parent.height
                        radius: 2
                        color: root.accent

                        Behavior on width {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.playback.duration > 0)
                                root.runAction(["seek", String(root.playback.duration * mouse.x / width)])
                        }
                    }
                }
            }

            Row {
                width: parent.width
                height: 34
                spacing: 10

                Item { width: Math.max(1, parent.width / 2 - 57); height: 1 }

                Rectangle {
                    width: 31
                    height: 31
                    radius: 11
                    color: controlHoverPrev.containsMouse ? "#EFF4FA" : "#FFFFFF"
                    border.width: 1
                    border.color: root.border

                    Text {
                        anchors.centerIn: parent
                        text: "‹"
                        color: root.ink
                        font.pixelSize: 25
                        font.weight: Font.Light
                        y: -1
                    }

                    MouseArea {
                        id: controlHoverPrev
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.advanceTrack(-1)
                    }
                }

                Rectangle {
                    width: 42
                    height: 34
                    radius: 12
                    color: root.accent
                    opacity: root.actionBusy ? 0.6 : 1

                    Text {
                        anchors.centerIn: parent
                        text: root.playback.running && !root.playback.paused ? "Ⅱ" : "▶"
                        color: "#FFFFFF"
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.actionBusy && root.tracks.length > 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.playback.running && root.playback.path.length)
                                root.runAction(["toggle"])
                            else
                                root.playTrack(root.activeIndex >= 0 ? root.activeIndex : 0)
                        }
                    }
                }

                Rectangle {
                    width: 31
                    height: 31
                    radius: 11
                    color: controlHoverNext.containsMouse ? "#EFF4FA" : "#FFFFFF"
                    border.width: 1
                    border.color: root.border

                    Text {
                        anchors.centerIn: parent
                        text: "›"
                        color: root.ink
                        font.pixelSize: 25
                        font.weight: Font.Light
                        y: -1
                    }

                    MouseArea {
                        id: controlHoverNext
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.advanceTrack(1)
                    }
                }

                Item { width: Math.max(1, parent.width / 2 - 57); height: 1 }
            }
        }
    }
}
