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

    readonly property color ink: "#F0F3F7"
    readonly property color secondary: "#BAC4D0"
    readonly property color muted: "#7F8A98"
    readonly property color border: "#3AFFFFFF"
    readonly property color accent: "#C8D5E4"
    readonly property int widgetRightMargin: root.navbarPosition === "right" ? 88 : 26

    readonly property var currentQuote: root.quotes.length > 0
        ? root.quotes[root.quoteIndex % root.quotes.length]
        : ({
            text: "Well done is better than well said.",
            author: "Benjamin Franklin",
            source: "Poor Richard’s Almanack",
            category: "Action"
        })

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

    // Upper-right, below the editorial clock and opposite the lower-left Music card.
    // The quote surface uses translucent fills only; no blur or continuous animation.
    Rectangle {
        id: card
        width: Math.min(380, Math.max(300, parent.width - root.widgetRightMargin - 28))
        height: 160
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Math.max(250, Math.min(360, parent.height * 0.40))
        anchors.rightMargin: root.widgetRightMargin
        radius: 18
        border.width: 1
        border.color: root.border
        clip: true

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#D51A2029" }
            GradientStop { position: 1.0; color: "#B80D1016" }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 17
            color: "transparent"
            border.width: 1
            border.color: "#12FFFFFF"
        }

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 6

            Row {
                width: parent.width
                height: 20
                spacing: 9

                Rectangle {
                    width: 25
                    height: 25
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 8
                    color: "#1FFFFFFF"
                    border.width: 1
                    border.color: "#24FFFFFF"

                    Image {
                        anchors.centerIn: parent
                        width: 17
                        height: 17
                        source: Qt.resolvedUrl("../assets/icons/quote-mark.svg")
                        sourceSize.width: 34
                        sourceSize.height: 34
                        asynchronous: true
                        smooth: true
                        fillMode: Image.PreserveAspectFit
                    }
                }

                Text {
                    text: "A THOUGHT TO KEEP"
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#C6D0DD"
                    font.family: "Inter"
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.25
                    renderType: Text.NativeRendering
                }
            }

            Text {
                width: parent.width
                height: 77
                text: root.currentQuote.text
                color: root.ink
                font.family: "Inter"
                font.pixelSize: 14
                font.weight: Font.Medium
                lineHeight: 1.12
                lineHeightMode: Text.ProportionalHeight
                wrapMode: Text.WordWrap
                maximumLineCount: 4
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                renderType: Text.NativeRendering
            }

            Column {
                width: parent.width
                height: 20
                spacing: 3

                Text {
                    width: parent.width
                    text: root.currentQuote.author
                    color: root.secondary
                    font.family: "Inter"
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                }

                Text {
                    width: parent.width
                    text: root.currentQuote.source
                    color: root.muted
                    font.family: "Inter"
                    font.pixelSize: 6
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
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

    onWidgetEnabledChanged: {
        if (root.widgetEnabled && root.quotes.length > 1)
            root.pickRandomQuote()
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
            root.pickRandomQuote()
        } catch (error) {
            console.warn("A16EEN could not read the quote library:", error)
            root.useFallbackQuote()
        }
    }

    function pickRandomQuote() {
        if (root.quotes.length === 0) {
            root.quoteIndex = 0
            return
        }

        if (root.quotes.length === 1) {
            root.quoteIndex = 0
            return
        }

        const previous = root.quoteIndex
        let next = Math.floor(Math.random() * root.quotes.length)
        if (next === previous)
            next = (next + 1 + Math.floor(Math.random() * (root.quotes.length - 1))) % root.quotes.length
        root.quoteIndex = next
    }

    function useFallbackQuote() {
        root.quotes = [{
            id: "franklin-actions",
            text: "Well done is better than well said.",
            author: "Benjamin Franklin",
            source: "Poor Richard’s Almanack",
            category: "Action"
        }]
        root.quoteIndex = 0
    }
}
