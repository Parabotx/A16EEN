import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool widgetEnabled: false
    property string navbarPosition: "right"
    property var quotes: []
    property int quoteIndex: 0

    readonly property color ink: "#493C31"
    readonly property color secondary: "#837264"
    readonly property color muted: "#AA9A87"
    readonly property color border: "#E8D9C5"
    readonly property color cream: "#FFFBF4"
    readonly property color accent: "#C98765"
    readonly property int widgetLeftMargin: root.navbarPosition === "left" ? 88 : 24

    readonly property var currentQuote: root.quotes.length > 0
        ? root.quotes[root.quoteIndex % root.quotes.length]
        : ({
            text: "Make room for the work that matters.",
            author: "A16EEN",
            source: "A reminder to begin again",
            category: "Focus"
        })

    readonly property string quoteCounter: root.quotes.length > 0
        ? String((root.quoteIndex % root.quotes.length) + 1).padStart(2, "0")
            + " / " + String(root.quotes.length).padStart(2, "0")
        : "01 / 01"

    screen: root.modelData
    visible: root.widgetEnabled && root.modelData !== null
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
    WlrLayershell.namespace: "a16een-widget-quotes"

    // The quote sits in the open space above Music, below the centered clock.
    // Its left edge aligns with Music. Music's library opens to the right,
    // so its list never obscures this card.
    Rectangle {
        id: card
        width: Math.min(410, Math.max(280, parent.width - root.widgetLeftMargin - 24))
        height: 194
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.widgetLeftMargin
        anchors.bottomMargin: (root.navbarPosition === "bottom" ? 74 : 72) + 170 + 14
        radius: 20
        color: root.cream
        border.width: 1
        border.color: root.border
        clip: true

        Rectangle {
            x: 0
            y: 0
            width: Math.min(118, parent.width * 0.32)
            height: 2
            radius: 1
            color: root.accent
            opacity: 0.78
        }

        Column {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 7

            Row {
                width: parent.width
                height: 13
                spacing: 5

                Rectangle {
                    width: 5
                    height: 5
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 3
                    color: root.accent
                }

                Text {
                    text: "QUOTE FOR TODAY"
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.accent
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.05
                }

                Item {
                    width: Math.max(1, parent.width - 155)
                    height: 1
                }

                Text {
                    text: root.quoteCounter
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.muted
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.4
                }
            }

            Row {
                width: parent.width
                height: 103
                spacing: 4

                Text {
                    width: 27
                    text: "“"
                    color: "#E2CDB6"
                    font.family: "Inter"
                    font.pixelSize: 49
                    font.weight: Font.Light
                    verticalAlignment: Text.AlignTop
                }

                Text {
                    width: parent.width - 31
                    height: parent.height
                    text: root.currentQuote.text
                    color: root.ink
                    font.family: "Inter"
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    lineHeight: 1.15
                    lineHeightMode: Text.ProportionalHeight
                    wrapMode: Text.WordWrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }
            }

            Row {
                width: parent.width
                height: 25
                spacing: 7

                Column {
                    width: Math.max(100, parent.width - 95)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        width: parent.width
                        text: "— " + String(root.currentQuote.author || "Unknown")
                        color: root.secondary
                        font.family: "Inter"
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: String(root.currentQuote.source || root.currentQuote.category || "")
                        color: root.muted
                        font.family: "Inter"
                        font.pixelSize: 6
                        elide: Text.ElideRight
                    }
                }

                Item {
                    width: Math.max(1, parent.width - Math.max(100, parent.width - 95) - 74)
                    height: 1
                }

                Text {
                    text: "NEXT"
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.secondary
                    font.pixelSize: 6
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.8
                }

                Rectangle {
                    width: 25
                    height: 25
                    radius: 9
                    color: "#F4E6D7"
                    border.width: 1
                    border.color: "#EAD7C2"

                    Text {
                        anchors.centerIn: parent
                        text: "→"
                        color: root.ink
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showNextQuote()
                    }
                }
            }
        }
    }

    FileView {
        id: quoteFile
        path: Qt.resolvedUrl("../assets/quotes.json")
        preload: true
        printErrors: false

        onLoaded: root.loadQuotes(this.text())
        onLoadFailed: root.useFallbackQuote()
    }

    function loadQuotes(raw) {
        try {
            const document = JSON.parse(String(raw || "{}"))
            const items = Array.isArray(document) ? document : document.quotes
            const valid = Array.isArray(items)
                ? items.filter(item => item
                    && typeof item.text === "string"
                    && item.text.trim().length > 0
                    && typeof item.author === "string")
                    .map(item => ({
                        id: String(item.id || ""),
                        text: item.text.trim(),
                        author: item.author.trim() || "Unknown",
                        source: String(item.source || ""),
                        category: String(item.category || "Reflection")
                    }))
                : []

            if (!valid.length)
                throw new Error("The quote file contains no valid entries.")

            root.quotes = valid
            const now = new Date()
            const dayNumber = Math.floor(Date.UTC(
                now.getFullYear(), now.getMonth(), now.getDate()
            ) / 86400000)
            root.quoteIndex = ((dayNumber % valid.length) + valid.length) % valid.length
        } catch (error) {
            console.warn("A16EEN could not read the quote library:", error)
            root.useFallbackQuote()
        }
    }

    function useFallbackQuote() {
        root.quotes = [{
            id: "a16een-fallback",
            text: "Make room for the work that matters.",
            author: "A16EEN",
            source: "A reminder to begin again",
            category: "Focus"
        }]
        root.quoteIndex = 0
    }

    function showNextQuote() {
        if (root.quotes.length > 1)
            root.quoteIndex = (root.quoteIndex + 1) % root.quotes.length
    }
}
