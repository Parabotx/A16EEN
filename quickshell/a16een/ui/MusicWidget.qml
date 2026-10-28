import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool widgetEnabled: false
    property string navbarPosition: "right"
    property string backgroundColor: "#EAF2F8"
    property int backgroundOpacity: 72
    property var completedPlayback: null
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
    property string libraryQuery: ""
    property bool shuffleEnabled: false
    property int repeatMode: 0
    property bool seekDragging: false
    property real seekFraction: 0

    readonly property color ink: "#1D2938"
    readonly property color secondary: "#5F7186"
    readonly property color muted: "#8391A1"
    readonly property color border: "#4D869FB8"
    readonly property color cream: "#B8EAF2F8"
    readonly property color accent: "#7E9BC7"
    readonly property int activeIndex: root.indexForPath(root.playback.path)
    readonly property var filteredTracks: {
        const query = String(root.libraryQuery || "").trim().toLowerCase()
        if (!query.length)
            return root.tracks
        return root.tracks.filter(track =>
            [track.title, track.artist, track.filename]
                .join(" ").toLowerCase().includes(query))
    }
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
    readonly property real displayedProgress: root.seekDragging
        ? root.seekFraction : root.progress
    // The phase drives a low-amplitude wave; it animates only during playback.
    property real progressWavePhase: 0
    readonly property real progressWaveGap: root.isPlaying && !root.seekDragging ? 1.35 : 0
    readonly property int libraryPopupRightMargin: root.navbarPosition === "right" ? 88 : 12

    // Canvas does not repaint automatically when arbitrary JS values change.
    // Repaint the tiny progress surface as the phase flows and the playback
    // state toggles the nearly invisible separation at its leading edge.
    onProgressWavePhaseChanged: waveCanvas.requestPaint()
    onProgressWaveGapChanged: waveCanvas.requestPaint()

    // Keep the song library beside the player so it never covers the Quotes card above it.
    readonly property bool libraryPopupOpensRight: root.modelData !== null
        && root.modelData.width - card.x - card.width - 8 - root.libraryPopupRightMargin >= 300

    screen: modelData
    visible: root.widgetEnabled
    focusable: root.libraryOpen
    color: "transparent"
    aboveWindows: false
    exclusiveZone: 0

    // Only the actual player and its open library receive pointer input.
    mask: Region {
        Region { item: card }
        Region {
            item: libraryPopup
            intersection: root.libraryOpen ? Intersection.Combine : Intersection.Subtract
        }
    }

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "a16een-widget-music"
    WlrLayershell.keyboardFocus: root.libraryOpen
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

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

    function backgroundWithOpacity(rawColor, percentage) {
        const base = Qt.color(String(rawColor || "#EAF2F8"))
        const alpha = Math.max(0, Math.min(100, Number(percentage) || 0)) / 100
        return Qt.rgba(base.r, base.g, base.b, base.a * alpha)
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

    function nextRepeatPlaylistIndex(path) {
        if (!root.tracks.length)
            return -1
        const currentIndex = root.indexForPath(path)
        // Infinity mode repeats the entire visible music library in order.
        return currentIndex < 0 ? 0 : (currentIndex + 1) % root.tracks.length
    }

    function applyPlaybackOutput(raw) {
        try {
            const result = JSON.parse(String(raw || "{}"))
            const previous = root.playback
            const resultPath = String(result.path || "")

            if (resultPath.length && root.completedPlayback
                    && resultPath !== String(root.completedPlayback.path || "")) {
                root.completedPlayback = null
            }

            const reachedEnd = !root.completedPlayback
                && previous.running
                && String(previous.path || "").length > 0
                && !previous.paused
                && Number(previous.duration) > 0
                && (result.eofReached === true
                    || (!resultPath.length
                        && Number(previous.time) >= Math.max(0, Number(previous.duration) - 2.5)))

            root.playback = result

            if (reachedEnd && root.repeatMode === 2) {
                const nextIndex = root.nextRepeatPlaylistIndex(previous.path)
                if (nextIndex >= 0)
                    Qt.callLater(() => root.playTrack(nextIndex))
            } else if (reachedEnd && root.repeatMode === 0) {
                // Normal mode retains the finished track and waits for the user.
                root.completedPlayback = Object.assign({}, previous, {
                    running: true,
                    path: previous.path,
                    title: previous.title,
                    artist: previous.artist,
                    album: previous.album,
                    cover: previous.cover,
                    duration: previous.duration,
                    time: previous.duration,
                    paused: true,
                    eofReached: true
                })
                root.playback = root.completedPlayback
                root.statusMessage = "Playback finished"
                Qt.callLater(() => root.runAction(["pause"]))
            } else if (!resultPath.length && root.completedPlayback
                    && root.repeatMode === 0) {
                // MPV can drop its path after EOF. Keep the completed item visible.
                root.playback = root.completedPlayback
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
        const wasPlayAction = actionProcess.command.length > 1
            && actionProcess.command[1] === "play"
        root.actionBusy = false
        let actionSucceeded = false
        try {
            const result = JSON.parse(String(raw || "{}"))
            actionSucceeded = result.ok === true
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
        if (wasPlayAction && actionSucceeded)
            Qt.callLater(() => root.runAction(["repeat", String(root.repeatMode)]))
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

    function setRepeatMode(mode) {
        const normalized = ((Number(mode) || 0) + 3) % 3
        root.repeatMode = normalized
        root.runAction(["repeat", String(normalized)])
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
        root.completedPlayback = null
        root.statusMessage = ""
        root.runAction(["play", root.tracks[index].path])
    }

    function advanceTrack(amount) {
        const count = root.tracks.length
        if (!count)
            return

        let nextIndex = root.activeIndex
        if (root.shuffleEnabled && amount > 0 && count > 1) {
            if (root.activeIndex < 0) {
                nextIndex = Math.floor(Math.random() * count)
            } else {
                nextIndex = Math.floor(Math.random() * (count - 1))
                if (nextIndex >= root.activeIndex)
                    nextIndex++
            }
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
        }
    }

    onLibraryQueryChanged: {
        // A TextInput can drop its initial binding after the first keypress.
        // Keep the displayed query synchronized without repeatedly stealing focus.
        if (libraryKeyboardInput.text !== root.libraryQuery)
            libraryKeyboardInput.text = root.libraryQuery
    }

    onLibraryOpenChanged: {
        root.libraryQuery = ""
        libraryKeyboardInput.text = ""
        if (root.libraryOpen) {
            root.refreshLibrary()
            Qt.callLater(function() {
                Qt.callLater(function() {
                    if (root.libraryOpen) {
                        libraryKeyboardInput.forceActiveFocus()
                        libraryKeyboardInput.cursorPosition = libraryKeyboardInput.text.length
                    }
                })
            })
        } else {
            libraryKeyboardInput.focus = false
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
        interval: 1200
        repeat: true
        running: root.widgetEnabled
        onTriggered: root.refreshPlayback()
    }

    // A slow, continuous phase shift makes the played segment flow like a
    // tiny silk ribbon instead of a rigid straight bar.
    NumberAnimation {
        target: root
        property: "progressWavePhase"
        from: 0
        to: Math.PI * 2
        duration: 1850
        loops: Animation.Infinite
        running: root.widgetEnabled && root.isPlaying && !root.seekDragging
    }

    // Two low-opacity layers give the compact card a soft, lifted shadow
    // without continuously running a blur effect.
    Rectangle {
        width: card.width
        height: card.height
        x: card.x
        y: card.y + 5
        radius: card.radius
        color: "#172437"
        opacity: 0.075 * root.backgroundOpacity / 100
        z: 0
    }

    Rectangle {
        width: card.width
        height: card.height
        x: card.x
        y: card.y + 2
        radius: card.radius
        color: "#273A52"
        opacity: 0.055 * root.backgroundOpacity / 100
        z: 0
    }

    Rectangle {
        id: card
        width: 410
        height: 170
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.navbarPosition === "left" ? 88 : 24
        anchors.bottomMargin: root.navbarPosition === "bottom" ? 74 : 72
        radius: 20
        color: root.backgroundWithOpacity(root.backgroundColor, root.backgroundOpacity)
        border.width: 1
        border.color: root.backgroundWithOpacity(root.border, root.backgroundOpacity)
        clip: false
        z: 1

        Rectangle {
            width: Math.min(148, parent.width * 0.46)
            height: 2
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            radius: 1
            z: 3
            opacity: root.backgroundOpacity / 100
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#8AB8D8" }
                GradientStop { position: 0.52; color: "#A9A5DF" }
                GradientStop { position: 1.0; color: "#82CBC5" }
            }
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
                    color: "#DCE6F0"
                    border.width: 1
                    border.color: "#B8C8DA"
                    clip: true

                    Rectangle {
                        width: 55
                        height: 55
                        radius: 28
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: -16
                        anchors.bottomMargin: -20
                        color: "#EEF3F8"
                    }

                    Rectangle {
                        width: 35
                        height: 35
                        radius: 18
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.rightMargin: -7
                        anchors.topMargin: -7
                        color: "#CAD9E8"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "♫"
                        color: "#5E7591"
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

                    Rectangle {
                        width: 8
                        height: 8
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.rightMargin: 5
                        anchors.topMargin: 5
                        radius: 4
                        color: "#F9FCFF"
                        border.width: 1
                        border.color: "#BDD0E2"
                        visible: root.isPlaying
                        z: 4

                        Rectangle {
                            anchors.centerIn: parent
                            width: 4
                            height: 4
                            radius: 2
                            color: "#7E9BC7"
                        }
                    }
                }

                Column {
                    width: parent.width - 68 - 98 - 20
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Row {
                        width: parent.width
                        height: 9
                        spacing: 4

                        Rectangle {
                            id: playingIndicatorDot
                            width: 4
                            height: 4
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 2
                            color: root.isPlaying ? "#7E9BC7" : "#9BAABD"
                            opacity: root.isPlaying ? 1 : 0.75

                            Behavior on color { ColorAnimation { duration: 180 } }

                            SequentialAnimation on opacity {
                                running: root.widgetEnabled && root.isPlaying
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.38; duration: 560; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0; duration: 620; easing.type: Easing.InOutSine }
                            }
                        }

                        Text {
                            width: parent.width - 8
                            text: root.isPlaying ? "NOW PLAYING" : "A16EEN MUSIC"
                            color: root.accent
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.15
                            elide: Text.ElideRight
                        }
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

                MusicDecor {
                    width: 98
                    height: 76
                    anchors.verticalCenter: parent.verticalCenter
                    active: root.widgetEnabled
                    playing: root.isPlaying
                    outputName: String(root.modelData.name || "")
                    selectionKey: String(root.playback.path || "")
                }
            }

            Column {
                width: parent.width
                spacing: 2

                Row {
                    id: timelineLabels
                    width: parent.width
                    height: 15

                    Rectangle {
                        id: elapsedTimePill
                        width: elapsedTime.implicitWidth + 12
                        height: 15
                        radius: 7.5
                        color: "#DCE8F3"
                        border.width: 1
                        border.color: "#CBD9E9"

                        Text {
                            id: elapsedTime
                            anchors.centerIn: parent
                            text: root.formatTime(root.seekDragging
                                ? root.seekFraction * root.playback.duration
                                : root.playback.time)
                            color: "#43586E"
                            font.pixelSize: 8
                            font.family: "Inter"
                            font.weight: Font.DemiBold
                            renderType: Text.NativeRendering
                        }
                    }

                    Item {
                        width: Math.max(0, timelineLabels.width
                            - elapsedTimePill.width - totalTimePill.width)
                        height: 1
                    }

                    Rectangle {
                        id: totalTimePill
                        width: totalTime.implicitWidth + 12
                        height: 15
                        radius: 7.5
                        color: "#F6F9FC"
                        border.width: 1
                        border.color: "#D9E4EF"

                        Text {
                            id: totalTime
                            anchors.centerIn: parent
                            text: root.formatTime(root.playback.duration)
                            color: "#6A7D91"
                            font.pixelSize: 8
                            font.family: "Inter"
                            font.weight: Font.Medium
                            renderType: Text.NativeRendering
                        }
                    }
                }

                Item {
                    id: progressTrack
                    width: parent.width
                    height: 16
                    // Animate normal playback updates, but keep pointer seeking exact.
                    property real fillProgress: root.displayedProgress
                    Behavior on fillProgress {
                        NumberAnimation {
                            duration: root.seekDragging ? 0 : 180
                            easing.type: Easing.OutCubic
                        }
                    }
                    onFillProgressChanged: waveCanvas.requestPaint()

                    Rectangle {
                        id: progressRail
                        x: 1
                        y: 4
                        width: Math.max(0, parent.width - 2)
                        height: 8
                        radius: 4
                        color: "#DCE6F0"
                        border.width: 0
                        clip: true

                        Canvas {
                            id: waveCanvas
                            anchors.fill: parent
                            antialiasing: true

                            onPaint: {
                                const ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)

                                const playedWidth = Math.max(0, Math.min(
                                    width,
                                    width * progressTrack.fillProgress - root.progressWaveGap
                                ))
                                if (playedWidth < 0.75)
                                    return

                                const centerY = height / 2
                                const amplitude = 1.15
                                const wavelength = 20
                                const phase = root.progressWavePhase
                                const gradient = ctx.createLinearGradient(0, 0, Math.max(1, playedWidth), 0)
                                gradient.addColorStop(0.0, "#8AB8D8")
                                gradient.addColorStop(0.48, "#A9A5DF")
                                gradient.addColorStop(1.0, "#82CBC5")

                                ctx.beginPath()
                                ctx.moveTo(0, centerY + Math.sin(phase) * amplitude)
                                for (let x = 1; x < playedWidth; x += 1) {
                                    const y = centerY
                                        + Math.sin((x / wavelength) * Math.PI * 2 + phase) * amplitude
                                    ctx.lineTo(x, y)
                                }
                                ctx.lineTo(playedWidth,
                                    centerY + Math.sin((playedWidth / wavelength) * Math.PI * 2 + phase) * amplitude)
                                ctx.strokeStyle = gradient
                                ctx.lineWidth = 4.1
                                ctx.lineCap = "round"
                                ctx.lineJoin = "round"
                                ctx.stroke()
                            }

                            Component.onCompleted: requestPaint()
                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()
                        }
                    }

                    // Keep the handle out of the way during playback so the tiny
                    // end gap and flowing wave stay visible. It returns on hover,
                    // while paused, or whenever the user seeks.
                    Rectangle {
                        id: progressThumb
                        width: 8
                        height: 8
                        x: Math.max(0, Math.min(parent.width - width,
                            1 + (parent.width - 2) * root.displayedProgress - width / 2))
                        y: 4
                        radius: 5
                        color: "#FAFCFF"
                        border.width: 1
                        border.color: "#95A9C2"
                        visible: root.playback.duration > 0
                            && (seekArea.containsMouse || root.seekDragging || !root.isPlaying)
                        z: 2

                        Rectangle {
                            anchors.centerIn: parent
                            width: 2.5
                            height: 2.5
                            radius: 1.25
                            color: "#8DA6CC"
                        }

                        Behavior on x {
                            NumberAnimation { duration: root.seekDragging ? 0 : 180; easing.type: Easing.OutCubic }
                        }
                    }

                    MouseArea {
                        id: seekArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: root.playback.duration > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onPressed: function(mouse) {
                            if (root.playback.duration <= 0)
                                return
                            root.seekDragging = true
                            root.seekFraction = Math.max(0, Math.min(1, mouse.x / width))
                        }
                        onPositionChanged: function(mouse) {
                            if (!pressed || root.playback.duration <= 0)
                                return
                            root.seekFraction = Math.max(0, Math.min(1, mouse.x / width))
                        }
                        onReleased: {
                            if (!root.seekDragging || root.playback.duration <= 0) {
                                root.seekDragging = false
                                return
                            }
                            const targetTime = Math.max(0, Math.min(root.playback.duration,
                                root.playback.duration * root.seekFraction))
                            root.playback = Object.assign({}, root.playback, { time: targetTime })
                            root.seekDragging = false
                            root.runAction(["seek", String(targetTime)])
                        }
                        onCanceled: root.seekDragging = false
                    }
                }
            }


            Item {
                width: parent.width
                height: 31

                Row {
                    id: controls
                    anchors.centerIn: parent
                    spacing: 7

                    ControlButton {
                        iconName: "music-shuffle"
                        selected: root.shuffleEnabled
                        onClicked: root.shuffleEnabled = !root.shuffleEnabled
                    }

                    ControlButton {
                        iconName: "music-skip-back"
                        onClicked: root.advanceTrack(-1)
                    }

                    ControlButton {
                        iconName: root.isPlaying ? "music-pause" : "music-play"
                        primary: true
                        enabledControl: root.tracks.length > 0 || String(root.playback.path || "").length > 0
                        onClicked: {
                            if (root.completedPlayback
                                    && String(root.playback.path || "") === String(root.completedPlayback.path || "")) {
                                root.playTrack(root.indexForPath(root.completedPlayback.path))
                            } else if (root.playback.running && String(root.playback.path || "").length) {
                                root.runAction(["toggle"])
                            } else if (root.tracks.length) {
                                root.playTrack(root.activeIndex >= 0 ? root.activeIndex : 0)
                            }
                        }
                    }

                    ControlButton {
                        iconName: "music-skip-forward"
                        onClicked: root.advanceTrack(1)
                    }

                    ControlButton {
                        iconName: "music-repeat"
                        repeatIndicatorMode: root.repeatMode
                        selected: root.repeatMode !== 0
                        onClicked: root.setRepeatMode(
                            root.repeatMode === 0 ? 2
                            : root.repeatMode === 2 ? 1 : 0)
                    }

                    ControlButton {
                        iconName: root.libraryOpen ? "music-close" : "music-list"
                        selected: root.libraryOpen
                        onClicked: root.libraryOpen = !root.libraryOpen
                    }
                }
            }

        }
    }

    // The library sits beside the player when space permits and uses the same height.
    Rectangle {
        id: libraryPopup
        x: root.libraryPopupOpensRight ? card.x + card.width + 8 : card.x
        y: root.libraryPopupOpensRight
            ? card.y + card.height - height
            : Math.max(12, card.y - height - 8)
        width: root.libraryPopupOpensRight
            ? Math.min(292, parent.width - card.x - card.width - 8 - root.libraryPopupRightMargin)
            : Math.min(292, Math.max(220, card.width - 80))
        height: card.height
        radius: 16
        color: root.backgroundWithOpacity(root.backgroundColor, root.backgroundOpacity)
        border.width: 1
        border.color: root.backgroundWithOpacity(root.border, root.backgroundOpacity)
        clip: true
        visible: root.libraryOpen
        z: 5
        opacity: root.libraryOpen ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            Rectangle {
                id: librarySearchField
                width: parent.width
                height: 30
                radius: 9
                color: "#F6FAFD"
                border.width: 1
                border.color: libraryKeyboardInput.activeFocus ? "#A8BED7" : "#DDE6F0"
                clip: true

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search songs or artists"
                    color: "#8391A1"
                    font.pixelSize: 9
                    visible: libraryKeyboardInput.text.length === 0
                }

                TextInput {
                    id: libraryKeyboardInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    color: root.ink
                    selectionColor: "#AFC7E2"
                    selectedTextColor: "#1D2938"
                    font.pixelSize: 9
                    text: root.libraryQuery
                    activeFocusOnTab: true
                    selectByMouse: true

                    onTextChanged: {
                        if (root.libraryQuery !== text)
                            root.libraryQuery = text
                    }

                    Keys.onEscapePressed: root.libraryOpen = false
                }
            }

            Item {
                width: parent.width
                height: Math.max(0, parent.height - librarySearchField.height - parent.spacing)
                clip: true

                ListView {
                    id: trackList
                    anchors.fill: parent
                    model: root.filteredTracks
                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    currentIndex: root.filteredTracks.findIndex(track => track.path === root.playback.path)

                    onCurrentIndexChanged: {
                        if (currentIndex >= 0)
                            positionViewAtIndex(currentIndex, ListView.Contain)
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool currentTrack: modelData.path === root.playback.path

                        width: trackList.width
                        height: 25
                        radius: 7
                        color: currentTrack ? "#DDE8F3" : trackHover.containsMouse ? "#EDF3F9" : "transparent"
                        border.width: currentTrack ? 1 : 0
                        border.color: "#B8C9DB"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 7

                            Text {
                                width: 16
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.parent.currentTrack && root.isPlaying ? "♫" : String(index + 1).padStart(2, "0")
                                color: parent.parent.currentTrack ? root.accent : root.muted
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                            }

                            Column {
                                width: parent.width - 43
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 0

                                Text {
                                    width: parent.width
                                    text: modelData.title
                                    color: parent.parent.parent.currentTrack ? root.ink : root.secondary
                                    font.pixelSize: 9
                                    font.weight: parent.parent.parent.currentTrack ? Font.DemiBold : Font.Medium
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: modelData.artist
                                    color: root.muted
                                    font.pixelSize: 7
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            id: trackHover
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.playTrack(root.indexForPath(modelData.path))
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    visible: root.filteredTracks.length === 0
                    spacing: 3

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.tracks.length === 0
                            ? (root.statusMessage.length ? root.statusMessage : "No songs yet")
                            : "No matching tracks"
                        color: root.secondary
                        font.pixelSize: 9
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.tracks.length === 0
                            ? "Add tracks to ~/Music"
                            : "Try another title or artist"
                        color: root.muted
                        font.pixelSize: 7
                    }
                }
            }
        }
    }


    component ControlButton: Rectangle {
        property string iconName: "music-play"
        property bool primary: false
        property bool selected: false
        property bool enabledControl: true
        property int repeatIndicatorMode: 0
        signal clicked()

        width: primary ? 39 : 29
        height: 30
        radius: primary ? 11 : 9
        color: primary
            ? "#2D3A4D"
            : selected ? "#DBE7F4" : buttonHover.containsMouse ? "#EDF3F9" : "#F6FAFD"
        border.width: primary ? 0 : 1
        border.color: selected ? "#B6C8DB" : "#DDE6F0"
        opacity: enabledControl ? 1 : 0.48

        Image {
            anchors.centerIn: parent
            width: parent.primary ? 16 : 15
            height: parent.primary ? 16 : 15
            source: Qt.resolvedUrl("../assets/icons/" + parent.iconName
                + (parent.primary ? "-light.svg" : ".svg"))
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            opacity: parent.enabledControl ? 1 : 0.45
        }

        Rectangle {
            visible: parent.repeatIndicatorMode !== 0
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 1
            anchors.bottomMargin: 1
            width: parent.repeatIndicatorMode === 2 ? 14 : 11
            height: parent.repeatIndicatorMode === 2 ? 14 : 11
            radius: width / 2
            color: "#F9FCFF"
            border.width: 1
            border.color: "#D7E2ED"
            z: 2

            Text {
                anchors.centerIn: parent
                text: parent.parent.repeatIndicatorMode === 1 ? "1" : "∞"
                color: "#2D3A4D"
                font.pixelSize: parent.parent.repeatIndicatorMode === 2 ? 11 : 7
                font.weight: Font.Bold
            }
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
