import QtQuick
import QtMultimedia
import Quickshell.Io

Item {
    id: root

    // WebP animations use Qt Quick. Telegram's animated stickers often arrive
    // as WebM videos, which must go through Qt Multimedia instead.
    property bool active: false
    property bool playing: false
    property string selectionKey: ""
    property var elements: []
    property string elementSource: ""
    property bool elementsLoaded: false

    readonly property bool imageElement: root.elementSource.toLowerCase().endsWith(".webp")
    readonly property bool videoElement: root.elementSource.toLowerCase().endsWith(".webm")

    function refreshElements() {
        if (!root.active || root.elementsLoaded || elementsProcess.running)
            return
        elementsProcess.running = true
    }

    function chooseRandomElement() {
        if (!root.elements.length) {
            root.elementSource = ""
            return
        }

        let choices = root.elements
        if (choices.length > 1 && root.elementSource.length > 0)
            choices = choices.filter(source => source !== root.elementSource)

        root.elementSource = choices[Math.floor(Math.random() * choices.length)] || ""
    }

    function applyElementsOutput(raw) {
        try {
            const result = JSON.parse(String(raw || "{}"))
            root.elements = Array.isArray(result.elements)
                ? result.elements.filter(source =>
                    typeof source === "string"
                    && source.startsWith("file:")
                    && /\.(webp|webm)(?:[?#].*)?$/i.test(source))
                : []
        } catch (error) {
            root.elements = []
            console.warn("A16EEN music artwork: could not parse artwork list:", String(error))
        }

        root.elementsLoaded = true
        if (root.elements.length > 0)
            console.info("A16EEN music artwork: discovered", root.elements.length, "WebP/WebM file(s)")
        else
            console.warn("A16EEN music artwork: no usable WebP/WebM files were discovered. Run 'a16 music diagnose'.")
        root.chooseRandomElement()
    }

    Component.onCompleted: root.refreshElements()

    onActiveChanged: {
        if (!root.active)
            return
        root.refreshElements()
        if (root.elementsLoaded)
            root.chooseRandomElement()
    }

    onSelectionKeyChanged: {
        if (root.active && root.elementsLoaded && root.elements.length > 0)
            root.chooseRandomElement()
    }

    Process {
        id: elementsProcess
        command: ["a16een-music", "elements"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.applyElementsOutput(this.text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(this.text || "").trim()
                if (message.length)
                    console.warn("A16EEN music artwork: discovery helper failed:", message)
            }
        }
    }

    // Frame caching stays off to keep memory use low for small decorative art.
    AnimatedImage {
        id: elementImage
        anchors.fill: parent
        anchors.margins: 1
        source: root.active && root.imageElement ? root.elementSource : ""
        visible: root.active && root.playing && root.imageElement && status === AnimatedImage.Ready
        playing: root.active && root.playing && root.imageElement
        paused: !root.active || !root.playing || !root.imageElement
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: false
        smooth: true
        sourceSize.width: 192
        sourceSize.height: 192

        onStatusChanged: {
            if (status === AnimatedImage.Ready && root.imageElement) {
                console.info("A16EEN music artwork: WebP image loaded:", source)
            } else if (status === AnimatedImage.Error && root.imageElement) {
                console.warn("A16EEN music artwork: WebP image load failed:", source,
                    "Check qt6-imageformats and the asset with 'a16 music diagnose'.")
            }
        }
    }

    // WebM stickers are videos, not image files. Keep their audio muted and
    // loop forever while music plays; pausing music pauses this video too.
    MediaPlayer {
        id: elementVideo
        source: root.active && root.videoElement ? root.elementSource : ""
        loops: MediaPlayer.Infinite
        playing: root.active && root.playing && root.videoElement
        audioOutput: AudioOutput {
            muted: true
            volume: 0.0
        }
        videoOutput: videoOutput

        onErrorOccurred: (error, errorString) => {
            if (root.videoElement)
                console.warn("A16EEN music artwork: WebM video load failed:", source,
                    "error", error, errorString)
        }

        onMediaStatusChanged: {
            if (root.videoElement && mediaStatus === MediaPlayer.InvalidMedia)
                console.warn("A16EEN music artwork: Qt Multimedia could not decode:", source,
                    errorString, "Check qt6-multimedia and 'a16 music diagnose'.")
        }
    }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        anchors.margins: 1
        visible: root.active && root.playing && root.videoElement
            && elementVideo.hasVideo && elementVideo.mediaStatus !== MediaPlayer.InvalidMedia
        fillMode: VideoOutput.PreserveAspectFit
    }

    // During pause the music glyph remains visible; video/image playback is
    // paused and hidden until the audio track resumes.
    Text {
        anchors.centerIn: parent
        text: "♫"
        color: "#7E9BC7"
        opacity: 0.35
        font.pixelSize: 34
        font.weight: Font.Light
        visible: !root.active || !root.playing
            || (!root.imageElement && !root.videoElement)
            || (root.imageElement && elementImage.status !== AnimatedImage.Ready)
            || (root.videoElement
                && (!elementVideo.hasVideo || elementVideo.mediaStatus === MediaPlayer.InvalidMedia))
    }
}
