import QtQuick
import Quickshell.Io

Item {
    id: root

    // Source assets remain WebM/WebP in the artwork folders. WebM is prepared
    // into a tiny alpha-preserving animated WebP cache because Qt Multimedia's
    // frame conversion can flatten WebM alpha on some Linux backends.
    property bool active: false
    property bool playing: false
    property bool surfaceUncovered: true
    property string outputName: ""
    property string selectionKey: ""
    property var elements: []
    property string elementSource: ""
    property string lastElementSource: ""
    property string retiredVideoSource: ""
    property bool elementsLoaded: false
    property bool cachePrepared: false
    property bool cacheRefreshPending: false
    property string lastCacheRequest: ""
    property int nextSwitchDelayMs: 30000
    property var preparedVideos: []

    readonly property bool imageElement: root.elementSource.toLowerCase().endsWith(".webp")
    readonly property bool videoElement: root.elementSource.toLowerCase().endsWith(".webm")
    readonly property var preparedCurrentVideo: {
        for (const entry of root.preparedVideos) {
            if (entry && entry.source === root.elementSource)
                return entry
        }
        return null
    }

    function shuffled(values) {
        const result = values.slice()
        for (let index = result.length - 1; index > 0; index--) {
            const other = Math.floor(Math.random() * (index + 1))
            const temp = result[index]
            result[index] = result[other]
            result[other] = temp
        }
        return result
    }

    function randomizeSwitchDelay() {
        // Unpredictable per-cycle timing: never below 10 seconds, usually
        // between 10 and 75 seconds rather than aligned to the song timeline.
        root.nextSwitchDelayMs = 10000 + Math.floor(Math.random() * 65001)
    }

    function refreshElements() {
        if (!root.active || root.elementsLoaded || elementsProcess.running)
            return
        elementsProcess.running = true
    }

    function chooseRandomElement() {
        if (!root.elements.length) {
            root.elementSource = ""
            root.randomizeSwitchDelay()
            return
        }

        const webpChoices = root.elements.filter(source => source.toLowerCase().endsWith(".webp"))
        const preparedWebmChoices = root.preparedVideos
            .filter(entry => entry && typeof entry.source === "string")
            .map(entry => entry.source)
        // Once the first queue is prepared, only choose videos that are ready
        // in memory. New videos enter the queue in the background.
        let choices = preparedWebmChoices.length
            ? webpChoices.concat(preparedWebmChoices)
            : root.elements
        if (choices.length > 1 && root.elementSource.length > 0)
            choices = choices.filter(source => source !== root.elementSource)

        root.elementSource = choices[Math.floor(Math.random() * choices.length)] || ""
        root.randomizeSwitchDelay()
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
        Qt.callLater(root.refreshVideoCache)
    }

    function refreshVideoCache() {
        if (!root.active || !root.playing || !root.surfaceUncovered || !root.elementsLoaded)
            return
        if (prepareCacheProcess.running) {
            root.cacheRefreshPending = true
            return
        }

        const allVideos = root.elements.filter(source => source.toLowerCase().endsWith(".webm"))
        if (!allVideos.length) {
            root.preparedVideos = []
            root.cachePrepared = true
            root.lastCacheRequest = "[]"
            return
        }

        const queue = []
        const addUnique = function(source) {
            if (source && allVideos.includes(source)
                && source !== root.retiredVideoSource
                && !queue.includes(source)
                && queue.length < 4)
                queue.push(source)
        }

        // The current animation is first. Keep other prepared choices warm,
        // discard the just-used video, then fill remaining slots at random.
        if (root.videoElement)
            addUnique(root.elementSource)
        for (const entry of root.preparedVideos)
            addUnique(entry && entry.source)
        for (const source of shuffled(allVideos))
            addUnique(source)

        if (!queue.length) {
            root.preparedVideos = []
            root.cachePrepared = true
            return
        }

        const signature = JSON.stringify(queue)
        const preparedList = root.preparedVideos.map(entry => entry.source)
        const alreadyReady = queue.length === preparedList.length
            && queue.every(source => root.preparedVideos.some(entry =>
                entry.source === source && String(entry.prepared || "").startsWith("file:")))
        if (signature === root.lastCacheRequest && alreadyReady)
            return

        root.lastCacheRequest = signature
        root.cachePrepared = false
        prepareCacheProcess.command = [
            "a16een-music", "prepare-elements", signature
        ]
        prepareCacheProcess.running = true
    }

    function applyPreparedCache(raw) {
        try {
            const result = JSON.parse(String(raw || "{}"))
            root.preparedVideos = Array.isArray(result.items)
                ? result.items.filter(entry =>
                    entry && typeof entry.source === "string"
                    && typeof entry.prepared === "string"
                    && entry.prepared.startsWith("file:")).slice(0, 4)
                : []
            if (Array.isArray(result.errors) && result.errors.length)
                console.warn("A16EEN music artwork cache:", result.errors.join("; "))
        } catch (error) {
            root.preparedVideos = []
            console.warn("A16EEN music artwork: could not read prepared video cache:", String(error))
        }
        root.cachePrepared = true

        if (root.videoElement && !root.preparedCurrentVideo)
            console.warn("A16EEN music artwork: WebM transparency preparation was unavailable; using the native video renderer.")

        if (root.cacheRefreshPending) {
            root.cacheRefreshPending = false
            Qt.callLater(root.refreshVideoCache)
        }
    }

    function refreshOcclusion() {
        if (!root.active || !root.playing) {
            root.surfaceUncovered = false
            return
        }
        if (!root.outputName.length || occlusionProcess.running) {
            if (!root.outputName.length)
                root.surfaceUncovered = true
            return
        }

        const point = root.mapToGlobal(Qt.point(0, 0))
        occlusionProcess.command = [
            "a16een-music", "occlusion",
            String(point.x), String(point.y),
            String(root.width), String(root.height),
            root.outputName
        ]
        occlusionProcess.running = true
    }

    onElementSourceChanged: {
        if (root.lastElementSource !== root.elementSource
            && root.lastElementSource.toLowerCase().endsWith(".webm")) {
            // Remove the most recently used video from the next cache queue.
            root.retiredVideoSource = root.lastElementSource
        }
        root.lastElementSource = root.elementSource
        root.cachePrepared = false
        Qt.callLater(root.refreshVideoCache)
    }

    Component.onCompleted: {
        root.refreshElements()
        root.refreshOcclusion()
        root.randomizeSwitchDelay()
    }

    onActiveChanged: {
        if (!root.active) {
            root.surfaceUncovered = false
            return
        }
        root.refreshElements()
        root.refreshOcclusion()
        if (root.elementsLoaded) {
            root.chooseRandomElement()
            Qt.callLater(root.refreshVideoCache)
        }
    }

    onPlayingChanged: {
        if (!root.playing) {
            root.surfaceUncovered = false
            return
        }
        root.refreshOcclusion()
        Qt.callLater(root.refreshVideoCache)
    }

    onSurfaceUncoveredChanged: {
        if (root.surfaceUncovered)
            Qt.callLater(root.refreshVideoCache)
    }

    onSelectionKeyChanged: {
        if (root.active && root.elementsLoaded && root.elements.length > 0)
            root.chooseRandomElement()
    }

    Timer {
        id: rotationTimer
        interval: root.nextSwitchDelayMs
        repeat: false
        running: root.active && root.playing && root.surfaceUncovered
            && root.elements.length > 1
        onTriggered: {
            root.chooseRandomElement()
            if (running)
                restart()
        }
    }

    // One low-frequency compositor geometry check, only while the artwork is
    // actually playing. Hidden-window animation stops as soon as overlap is seen.
    Timer {
        interval: 1800
        repeat: true
        running: root.active && root.playing
        onTriggered: root.refreshOcclusion()
    }

    Process {
        id: occlusionProcess
        command: []
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(String(this.text || "{}"))
                    root.surfaceUncovered = result.uncovered !== false
                } catch (error) {
                    // Fail open if Niri doesn't expose usable geometry.
                    root.surfaceUncovered = true
                }
            }
        }
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

    Process {
        id: prepareCacheProcess
        command: ["a16een-music", "prepare-elements", "[]"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.applyPreparedCache(this.text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(this.text || "").trim()
                if (message.length)
                    console.warn("A16EEN music artwork: cache helper failed:", message)
            }
        }
    }

    AnimatedImage {
        id: elementImage
        anchors.fill: parent
        anchors.margins: 1
        source: root.active && root.imageElement ? root.elementSource : ""
        visible: root.active && root.playing && root.surfaceUncovered
            && root.imageElement && status === AnimatedImage.Ready
        playing: root.active && root.playing && root.surfaceUncovered && root.imageElement
        paused: !root.active || !root.playing || !root.surfaceUncovered || !root.imageElement
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

    // Exactly the helper's maximum four prepared videos are resident in this
    // repeater. AnimatedImage cache=true loads frames once; only the selected
    // item plays, while the rest stay paused and ready for a zero-wait switch.
    Repeater {
        model: root.preparedVideos

        delegate: AnimatedImage {
            required property var modelData
            anchors.fill: parent
            anchors.margins: 1
            source: modelData.prepared
            visible: root.active && root.playing && root.surfaceUncovered
                && root.videoElement && modelData.source === root.elementSource
                && status === AnimatedImage.Ready
            playing: root.active && root.playing && root.surfaceUncovered
                && root.videoElement && modelData.source === root.elementSource
            paused: !root.active || !root.playing || !root.surfaceUncovered
                || !root.videoElement || modelData.source !== root.elementSource
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: true
            smooth: true
            sourceSize.width: 192
            sourceSize.height: 192

            onStatusChanged: {
                if (status === AnimatedImage.Error && modelData.source === root.elementSource)
                    console.warn("A16EEN music artwork: transparent WebM cache failed to load:", source)
            }
        }
    }

    // Fallback to native WebM playback when ffmpeg/libwebp isn't available.
    // The component has no painted background, so its video output floats over
    // the widget card rather than adding an opaque artwork container.
    Loader {
        id: nativeVideoFallback
        anchors.fill: parent
        active: root.active && root.playing && root.surfaceUncovered
            && root.videoElement && root.cachePrepared && !root.preparedCurrentVideo
        source: active ? "MusicVideoDecor.qml" : ""

        onLoaded: {
            item.active = Qt.binding(() => root.active)
            item.playing = Qt.binding(() =>
                root.playing && root.surfaceUncovered)
            item.source = Qt.binding(() => root.elementSource)
        }
    }

    Text {
        anchors.centerIn: parent
        text: "♫"
        color: "#7E9BC7"
        opacity: 0.35
        font.pixelSize: 34
        font.weight: Font.Light
        visible: !root.active || !root.playing || !root.surfaceUncovered
            || (!root.imageElement && !root.videoElement)
            || (root.imageElement && elementImage.status !== AnimatedImage.Ready)
            || (root.videoElement
                && ((root.preparedCurrentVideo
                    && !root.preparedVideos.some(entry =>
                        entry.source === root.elementSource
                        && entry.prepared.length > 0))
                    ? true
                    : (!root.preparedCurrentVideo
                        && (!root.cachePrepared
                            || nativeVideoFallback.status !== Loader.Ready
                            || !nativeVideoFallback.item
                            || !nativeVideoFallback.item.videoReady))))
    }
}
