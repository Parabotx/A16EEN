import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool widgetEnabled: false
    property string navbarPosition: "right"
    property var tracks: []
    property var playback: ({
        running: false,
        path: "",
        title: "",
        artist: "",
        album: "",
        cover: "",
        duration: 0,
        time: 0,
        paused: true,
        repeat: false,
        error: ""
    })
    property string statusMessage: ""
    property bool actionBusy: false
    property bool libraryOpen: false
    property bool shuffleEnabled: false
    property string dancerSource: ""
    property real dancerOffsetX: 0
    property real dancerOffsetY: 0

    readonly property color ink: "#493C31"
    readonly property color secondary: "#837264"
    readonly property color muted: "#AA9A87"
    readonly property color border: "#E8D9C5"
    readonly property color cream: "#FFF5E7"
    readonly property color accent: "#C98765"
    readonly property int activeIndex: root.indexForPath(root.playback.path)
    readonly property bool isPlaying: root.playback.running
        && String(root.playback.path || "").length > 0
        && !root.playback.paused
    readonly property string currentTitle: root.playback.title && String(root.playback.title).length
        ? String(root.playback.title)
        : root.activeIndex >= 0 ? root.tracks[root.activeIndex].title : "Choose your next song"
    readonly property string currentArtist: root.playback.artist && String(root.playback.artist).length
        ? String(root.playback.artist)
        : root.activeIndex >= 0 ? root.tracks[root.activeIndex].artist : "Your music collection"
    readonly property string currentCover: root.playback.cover && String(root.playback.cover).length
        ? String(root.playback.cover)
        : root.activeIndex >= 0 ? String(root.tracks[root.activeIndex].cover || "") : ""
    readonly property real progress: root.playback.duration > 0
        ? Math.max(0, Math.min(1, root.playback.time / root.playback.duration))
        : 0

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
        if (!path || !String(path).length)
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
                root.statusMessage = "Add audio files to ~/Music"
            else if (!root.tracks.length)
                root.statusMessage = "No supported audio files found"
            else
                root.statusMessage = ""
        } catch (error) {
            root.statusMessage = "Couldn't read your music library"
            root.tracks = []
        }
    }

    function requestDancer() {
        if (!root.widgetEnabled || !root.isPlaying || dancerProcess.running)
            return
        root.dancerSource = ""
        root.dancerOffsetX = 0
        root.dancerOffsetY = 0
        dancerProcess.running = true
    }

    function applyDancerOutput(raw) {
        if (!root.widgetEnabled || !root.isPlaying)
            return
        try {
            const result = JSON.parse(String(raw || "{}"))
            root.dancerSource = String(result.path || "")
        } catch (error) {
            root.dancerSource = ""
        }
    }

    function applyPlaybackOutput(raw) {
        try {
            const result = JSON.parse(String(raw || "{}"))
            const wasPlaying = root.isPlaying
            const previousPath = String(root.playback.path || "")
            root.playback = result

            if (root.isPlaying) {
                if (!wasPlaying || previousPath !== String(root.playback.path || ""))
                    root.requestDancer()
            } else {
                // Clearing the URL deactivates the Loader and destroys the SVG
                // item completely; no animation keeps running while paused.
                root.dancerSource = ""
                root.dancerOffsetX = 0
                root.dancerOffsetY = 0
            }

            if (result.error)
                root.statusMessage = result.error
            else if (root.statusMessage === "The music player is not responding.")
                root.statusMessage = ""
        } catch (error) {
            // Bad status output shouldn't interrupt the desktop shell.
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
        const count = root.tracks.length
        if (!count)
            return

        let nextIndex = root.activeIndex
        if (root.shuffleEnabled && amount > 0 && count > 1) {
            nextIndex = Math.floor(Math.random() * (count - 1))
            if (nextIndex >= root.activeIndex)
                nextIndex++
        } else {
            if (nextIndex < 0)
                nextIndex = amount > 0 ? -1 : 0
            nextIndex = (nextIndex + amount + count) % count
        }
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
        } else {
            root.dancerSource = ""
            root.dancerOffsetX = 0
            root.dancerOffsetY = 0
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

    Process {
        id: dancerProcess
        command: ["a16een-music", "dancer"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.applyDancerOutput(this.text)
        }
    }

    Timer {
        interval: 1200
        repeat: true
        running: root.widgetEnabled
        onTriggered: root.refreshPlayback()
    }

    SequentialAnimation {
        running: root.widgetEnabled && root.isPlaying && root.dancerSource.length > 0
        loops: Animation.Infinite

        PauseAnimation { duration: 1700 }

        NumberAnimation {
            target: root
            property: "dancerOffsetX"
            to: 24
            duration: 360
            easing.type: Easing.OutBack
        }

        NumberAnimation {
            target: root
            property: "dancerOffsetY"
            to: -12
            duration: 220
            easing.type: Easing.OutCubic
        }

        PauseAnimation { duration: 360 }

        NumberAnimation {
            target: root
            property: "dancerOffsetX"
            to: 0
            duration: 480
            easing.type: Easing.OutBack
        }

        NumberAnimation {
            target: root
            property: "dancerOffsetY"
            to: 0
            duration: 280
            easing.type: Easing.OutCubic
        }

        PauseAnimation { duration: 1100 }
    }

    // Two low-opacity layers give the compact card a soft, lifted shadow
    // without continuously running a blur effect.
    Rectangle {
        width: card.width
        height: card.height
        x: card.x
        y: card.y + 5
        radius: card.radius
        color: "#72563D"
        opacity: 0.075
        z: 0
    }

    Rectangle {
        width: card.width
        height: card.height
        x: card.x
        y: card.y + 2
        radius: card.radius
        color: "#A38A6E"
        opacity: 0.055
        z: 0
    }

    Rectangle {
        id: card
        width: 410
        height: root.libraryOpen ? 284 : 170
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.navbarPosition === "left" ? 88 : 24
        anchors.bottomMargin: root.navbarPosition === "bottom" ? 74 : 72
        radius: 20
        color: root.cream
        border.width: 1
        border.color: root.border
        clip: false
        z: 1

        Behavior on height {
            NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 7

            Row {
                id: trackSummary
                width: parent.width
                height: 76
                spacing: 10

                Rectangle {
                    id: albumArt
                    width: 68
                    height: 68
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 14
                    color: "#EAD7BB"
                    border.width: 1
                    border.color: "#E2CEB2"
                    clip: true

                    Rectangle {
                        width: 55
                        height: 55
                        radius: 28
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: -16
                        anchors.bottomMargin: -20
                        color: "#F6E9D6"
                    }

                    Rectangle {
                        width: 35
                        height: 35
                        radius: 18
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.rightMargin: -7
                        anchors.topMargin: -7
                        color: "#D6BBA0"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "♫"
                        color: "#8A6449"
                        font.pixelSize: 31
                        font.weight: Font.Light
                        visible: albumCover.status !== Image.Ready
                    }

                    Image {
                        id: albumCover
                        anchors.fill: parent
                        source: root.currentCover
                        visible: source.toString().length > 0 && status === Image.Ready
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }
                }

                Column {
                    width: parent.width - 68 - 98 - 20
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        width: parent.width
                        text: root.isPlaying ? "NOW PLAYING" : "A16EEN MUSIC"
                        color: root.accent
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.15
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.currentTitle
                        color: root.ink
                        font.pixelSize: 13
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
                        maximumLineCount: 1
                    }

                    Text {
                        width: parent.width
                        text: root.statusMessage.length
                            ? root.statusMessage
                            : root.isPlaying ? "You're in the groove" : "Ready when you are"
                        color: root.muted
                        font.pixelSize: 6
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }

                Item {
                    id: dancerStage
                    width: 98
                    height: 76
                    anchors.verticalCenter: parent.verticalCenter
                    clip: false

                    Loader {
                        id: dancerLoader
                        width: 105
                        height: 100
                        x: root.dancerOffsetX
                        y: root.dancerOffsetY
                        active: root.widgetEnabled && root.isPlaying && root.dancerSource.length > 0
                        sourceComponent: dancerImageComponent
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 4

                Row {
                    width: parent.width
                    height: 11

                    Text {
                        text: root.formatTime(root.playback.time)
                        color: root.secondary
                        font.pixelSize: 7
                        font.family: "Inter"
                    }

                    Item { width: Math.max(1, parent.width - 76); height: 1 }

                    Text {
                        text: root.formatTime(root.playback.duration)
                        color: root.secondary
                        font.pixelSize: 7
                        font.family: "Inter"
                    }
                }

                Rectangle {
                    id: progressTrack
                    width: parent.width
                    height: 4
                    radius: 2
                    color: "#E9DCC9"

                    Rectangle {
                        width: parent.width * root.progress
                        height: parent.height
                        radius: 2
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#E5B276" }
                            GradientStop { position: 0.52; color: "#D78F83" }
                            GradientStop { position: 1.0; color: "#B9A2D4" }
                        }

                        Behavior on width {
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: root.playback.duration > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: function(mouse) {
                            if (root.playback.duration > 0)
                                root.runAction(["seek", String(root.playback.duration * mouse.x / width)])
                        }
                    }
                }
            }

            Row {
                id: controls
                anchors.horizontalCenter: parent.horizontalCenter
                height: 31
                spacing: 7

                ControlButton {
                    glyph: "⤨"
                    selected: root.shuffleEnabled
                    onClicked: root.shuffleEnabled = !root.shuffleEnabled
                }

                ControlButton {
                    glyph: "◂"
                    onClicked: root.advanceTrack(-1)
                }

                ControlButton {
                    glyph: root.isPlaying ? "Ⅱ" : "▶"
                    primary: true
                    enabledControl: root.tracks.length > 0 || String(root.playback.path || "").length > 0
                    onClicked: {
                        if (root.playback.running && String(root.playback.path || "").length)
                            root.runAction(["toggle"])
                        else if (root.tracks.length)
                            root.playTrack(root.activeIndex >= 0 ? root.activeIndex : 0)
                    }
                }

                ControlButton {
                    glyph: "▸"
                    onClicked: root.advanceTrack(1)
                }

                ControlButton {
                    glyph: "↻"
                    selected: root.playback.repeat === true
                    onClicked: root.runAction(["repeat"])
                }

                ControlButton {
                    glyph: root.libraryOpen ? "×" : "≡"
                    selected: root.libraryOpen
                    onClicked: root.libraryOpen = !root.libraryOpen
                }
            }

            Column {
                width: parent.width
                height: root.libraryOpen ? 104 : 0
                visible: root.libraryOpen
                spacing: 4

                Row {
                    width: parent.width
                    height: 12

                    Text {
                        text: "YOUR MUSIC"
                        color: root.ink
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.9
                    }

                    Item { width: Math.max(1, parent.width - 94); height: 1 }

                    Text {
                        text: String(root.tracks.length) + (root.tracks.length === 1 ? " SONG" : " SONGS")
                        color: root.muted
                        font.pixelSize: 6
                        font.weight: Font.DemiBold
                    }
                }

                ListView {
                    id: trackList
                    width: parent.width
                    height: 88
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

                        readonly property bool currentTrack: modelData.path === root.playback.path

                        width: trackList.width
                        height: 26
                        radius: 8
                        color: currentTrack ? "#F0E2CE" : trackHover.containsMouse ? "#F7EBDD" : "transparent"
                        border.width: currentTrack ? 1 : 0
                        border.color: "#E4CEB1"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                width: 16
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.parent.currentTrack && root.isPlaying ? "♫" : String(index + 1).padStart(2, "0")
                                color: parent.parent.currentTrack ? root.accent : root.muted
                                font.pixelSize: 7
                                font.weight: Font.DemiBold
                            }

                            Column {
                                width: parent.width - 48
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1

                                Text {
                                    width: parent.width
                                    text: modelData.title
                                    color: parent.parent.parent.currentTrack ? root.ink : root.secondary
                                    font.pixelSize: 7
                                    font.weight: parent.parent.parent.currentTrack ? Font.DemiBold : Font.Medium
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

                    Column {
                        anchors.centerIn: parent
                        visible: root.tracks.length === 0
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.statusMessage.length ? root.statusMessage : "No songs yet"
                            color: root.secondary
                            font.pixelSize: 8
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Add tracks to ~/Music"
                            color: root.muted
                            font.pixelSize: 6
                        }
                    }
                }
            }
        }
    }

    Component {
        id: dancerImageComponent

        Image {
            anchors.fill: parent
            source: root.dancerSource
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: false
            smooth: true
        }
    }

    component ControlButton: Rectangle {
        property string glyph: ""
        property bool primary: false
        property bool selected: false
        property bool enabledControl: true
        signal clicked()

        width: primary ? 39 : 29
        height: 30
        radius: primary ? 11 : 9
        color: primary
            ? "#57483B"
            : selected ? "#EBD8C0" : buttonHover.containsMouse ? "#F5E7D4" : "#FFFBF4"
        border.width: primary ? 0 : 1
        border.color: selected ? "#DCC2A3" : "#E9DCCB"
        opacity: enabledControl ? 1 : 0.48

        Text {
            anchors.centerIn: parent
            text: parent.glyph
            color: parent.primary ? "#FFF9F0" : parent.selected ? "#855D41" : root.ink
            font.pixelSize: parent.primary ? 13 : 12
            font.weight: Font.DemiBold
            y: parent.glyph === "▶" || parent.glyph === "▸" ? -1 : 0
        }

        MouseArea {
            id: buttonHover
            anchors.fill: parent
            enabled: parent.enabledControl
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: parent.clicked()
        }

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }
}
