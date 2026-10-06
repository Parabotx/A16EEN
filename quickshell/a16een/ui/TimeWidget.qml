import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property var modelData: null
    property bool widgetEnabled: true
    property bool use24Hour: true
    property bool showSeconds: false

    property var now: new Date()

    function pad(value) {
        return value < 10 ? "0" + value : String(value)
    }

    readonly property string timeMain: {
        const hour24 = root.now.getHours()
        const minute = root.now.getMinutes()
        const second = root.now.getSeconds()
        const hour = root.use24Hour ? hour24 : ((hour24 % 12) || 12)

        return root.pad(hour) + ":" + root.pad(minute) + (root.showSeconds ? ":" + root.pad(second) : "")
    }

    readonly property string period: {
        return root.now.getHours() >= 12 ? "PM" : "AM"
    }

    readonly property var dayNames: [
        "SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY",
        "THURSDAY", "FRIDAY", "SATURDAY"
    ]

    readonly property var monthNames: [
        "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
        "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"
    ]

    readonly property string dayName: root.dayNames[root.now.getDay()]
    readonly property string dateLine:
        root.monthNames[root.now.getMonth()]
        + " "
        + root.now.getDate()
        + " • "
        + root.now.getFullYear()

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
    WlrLayershell.namespace: "a16een-widget-time"

    Timer {
        interval: root.showSeconds ? 250 : 1000
        repeat: true
        running: root.widgetEnabled
        onTriggered: root.now = new Date()
    }

    Rectangle {
        width: 318
        height: 146
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 28
        anchors.rightMargin: 28
        radius: 22
        color: "#080808"
        border.width: 1
        border.color: "#202020"
        opacity: 0.97

        Rectangle {
            width: 74
            height: 2
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 18
            anchors.leftMargin: 22
            color: "#D7B56D"
            opacity: 0.85
        }

        Column {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 6

            Row {
                width: parent.width
                height: 18

                Text {
                    text: "A16EEN • LOCAL TIME"
                    color: "#565656"
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.4
                }

                Item {
                    width: parent.width - 150
                    height: 1
                }

                Text {
                    width: 150
                    horizontalAlignment: Text.AlignRight
                    text: root.use24Hour ? "24H" : root.period
                    color: "#3F3F3F"
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.2
                }
            }

            Row {
                width: parent.width
                height: 50

                Text {
                    text: root.timeMain
                    color: "#FFFFFF"
                    font.pixelSize: 39
                    font.weight: Font.Light
                    font.letterSpacing: -0.8
                }

                Item {
                    width: 1
                    height: 1
                }
            }

            Row {
                width: parent.width
                height: 26
                spacing: 10

                Text {
                    text: root.dayName
                    color: "#D7B56D"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.2
                }

                Rectangle {
                    width: 1
                    height: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#2A2A2A"
                }

                Text {
                    text: root.dateLine
                    color: "#666666"
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.8
                }
            }
        }

        Rectangle {
            width: 5
            height: 5
            radius: 3
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 20
            anchors.bottomMargin: 19
            color: "#D7B56D"
            opacity: root.showSeconds ? 1 : 0.35
        }
    }
}
