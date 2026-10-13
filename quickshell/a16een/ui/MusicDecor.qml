import QtQuick
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

    // Load the multimedia backend only when a WebM asset is selected.
    // Keeping QtMultimedia out of this component's imports means a missing or
    // mismatched optional video module cannot take down the entire A16EEN shell.
    Loader {
        id: videoRenderer
        anchors.fill: parent
        active: root.active && root.videoElement
        source: active ? "MusicVideoDecor.qml" : ""

        onLoaded: {
            item.active = Qt.binding(() => root.active)
            item.playing = Qt.binding(() => root.playing)
            item.source = Qt.binding(() => root.elementSource)
        }

        onStatusChanged: {
            if (status === Loader.Error && root.videoElement)
                console.warn("A16EEN music artwork: the optional WebM renderer could not load. "
                    + "Install/update qt6-multimedia with 'sudo pacman -Syu --needed qt6-multimedia'.")
        }
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
                && (videoRenderer.status !== Loader.Ready
                    || !videoRenderer.item || !videoRenderer.item.videoReady))
    }
}
