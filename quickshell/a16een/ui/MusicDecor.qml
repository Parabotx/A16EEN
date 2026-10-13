import QtQuick
import Quickshell.Io

Item {
    id: root

    // WebP artwork is loaded once per widget enable and track change. Decoding
    // is scaled down and playback is paused outside active music playback.
    property bool active: false
    property bool playing: false
    property string selectionKey: ""
    property var elements: []
    property string elementSource: ""
    property bool elementsLoaded: false

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
                ? result.elements.filter(source => typeof source === "string" && source.startsWith("file:"))
                : []
        } catch (error) {
            root.elements = []
            console.warn("A16EEN music artwork: could not parse artwork list:", String(error))
        }

        root.elementsLoaded = true
        if (root.elements.length > 0)
            console.info("A16EEN music artwork: discovered", root.elements.length, "WebP file(s)")
        else
            console.warn("A16EEN music artwork: no usable WebP files were discovered. Run 'a16 music diagnose'.")
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

    // AnimatedImage uses Qt's animation-capable image reader, including the
    // WebP handler supplied by qt6-imageformats. cache:false avoids retaining
    // every decoded frame; sourceSize caps working resolution for this small art.
    AnimatedImage {
        id: elementImage
        anchors.fill: parent
        anchors.margins: 1
        source: root.active ? root.elementSource : ""
        visible: root.active && root.playing && status === AnimatedImage.Ready
        playing: root.active && root.playing
        paused: !root.active || !root.playing
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: false
        smooth: true
        sourceSize.width: 192
        sourceSize.height: 192

        onStatusChanged: {
            if (status === AnimatedImage.Ready) {
                console.info("A16EEN music artwork: image loaded:", source)
            } else if (status === AnimatedImage.Error) {
                console.warn("A16EEN music artwork: image load failed:", source,
                    "Check qt6-imageformats and the WebP file with 'a16 music diagnose'.")
            }
        }
    }

    // While paused, no artwork animation is rendered: the quiet music glyph
    // remains visible. It is also the fallback for a missing/unsupported asset.
    Text {
        anchors.centerIn: parent
        text: "♫"
        color: "#7E9BC7"
        opacity: 0.35
        font.pixelSize: 34
        font.weight: Font.Light
        visible: !root.playing || elementImage.status !== AnimatedImage.Ready
    }
}
