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
    readonly property int widgetLeftMargin: root.navbarPosition === "left" ? 88 : 26
    readonly property int widgetTopMargin: root.navbarPosition === "top" ? 72 : 30

    readonly property var currentQuote: root.quotes.length > 0
        ? root.quotes[root.quoteIndex % root.quotes.length]
        : ({
            text: "Cash flow buys options; options buy freedom.",
            author: "A16EEN",
            source: "The Wealth Mindset",
            category: "Beginnings"
        })

    screen: root.modelData
    visible: root.widgetEnabled && root.modelData !== null
    color: "transparent"
    aboveWindows: false
    exclusiveZone: 0

    anchors {
        top: true
        left: true
        bottom: true
        right: true
    }

    // The quote panel is decorative. Restrict its input region to the card so
    // its full-screen Wayland surface cannot intercept clicks on other widgets.
    mask: Region { item: card }

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "a16een-widget-quotes"

    Rectangle {
        id: card
        width: Math.min(318, Math.max(245, parent.width - root.widgetLeftMargin - 28))
        height: 138
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: root.widgetTopMargin
        anchors.leftMargin: root.widgetLeftMargin
        radius: 17
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
            radius: 16
            color: "transparent"
            border.width: 1
            border.color: "#12FFFFFF"
        }

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            Row {
                width: parent.width
                height: 18
                spacing: 8

                Rectangle {
                    width: 22
                    height: 22
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 7
                    color: "#1FFFFFFF"
                    border.width: 1
                    border.color: "#24FFFFFF"

                    Image {
                        anchors.centerIn: parent
                        width: 15
                        height: 15
                        source: Qt.resolvedUrl("../assets/icons/quote-mark.svg")
                        sourceSize.width: 30
                        sourceSize.height: 30
                        asynchronous: true
                        smooth: true
                        fillMode: Image.PreserveAspectFit
                    }
                }

                Text {
                    text: "THE WEALTH MINDSET"
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#C6D0DD"
                    font.family: "Inter"
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.15
                    renderType: Text.NativeRendering
                }
            }

            Text {
                width: parent.width
                height: 61
                text: root.currentQuote.text
                color: root.ink
                font.family: "Inter"
                font.pixelSize: 13
                font.weight: Font.Medium
                lineHeight: 1.1
                lineHeightMode: Text.ProportionalHeight
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                renderType: Text.NativeRendering
            }

            Column {
                width: parent.width
                height: 18
                spacing: 2

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

    // Six-hour rotation stays local/offline and consumes no background CPU while disabled.
    Timer {
        id: quoteRotationTimer
        interval: 60 * 60 * 1000
        repeat: true
        running: root.widgetEnabled && root.quotes.length > 1
        onTriggered: root.pickRandomQuote()
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
                        author: item.author.trim() || "A16EEN",
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
            next = (previous + 1 + Math.floor(Math.random() * (root.quotes.length - 1))) % root.quotes.length
        root.quoteIndex = next
    }

    function useFallbackQuote() {
        root.quotes = [{
            id: "a16een-begin-again",
            text: "Earn with intent. Keep with discipline. Deploy with conviction.",
            author: "A16EEN",
            source: "The Wealth Mindset",
            category: "Capital"
        }]
        root.quoteIndex = 0
    }
}
