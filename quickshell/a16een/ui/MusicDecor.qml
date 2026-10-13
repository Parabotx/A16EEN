import QtQuick
import Quickshell.Io

Item {
    id: root

    // Personal transparent artwork lives outside the deployed A16EEN files.
    // Load it only while the music widget is enabled; never poll or animate.
    property bool active: false
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
        }

        root.elementsLoaded = true
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
    }

    Image {
        id: elementImage
        anchors.fill: parent
        anchors.margins: 1
        source: root.elementSource
        visible: status === Image.Ready
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: true
        smooth: true
        sourceSize.width: 192
        sourceSize.height: 192
    }

    // Quiet fallback while assets are missing or their first image is loading.
    Text {
        anchors.centerIn: parent
        text: "♫"
        color: "#7E9BC7"
        opacity: 0.35
        font.pixelSize: 34
        font.weight: Font.Light
        visible: elementImage.status !== Image.Ready
    }
}
