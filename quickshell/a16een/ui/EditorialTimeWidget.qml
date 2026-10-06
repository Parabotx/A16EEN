import QtQuick

Item {
    id: root

    property bool widgetEnabled: true
    property bool use24Hour: true
    property bool showSeconds: false

    property var now: new Date()

    readonly property var weekdayNames: [
        "SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY",
        "THURSDAY", "FRIDAY", "SATURDAY"
    ]

    readonly property string timeText: {
        const h24 = root.now.getHours()
        const hour = root.use24Hour ? h24 : ((h24 % 12) || 12)
        const base = root.pad(hour) + ":" + root.pad(root.now.getMinutes())
        return root.showSeconds
            ? base + ":" + root.pad(root.now.getSeconds())
            : base
    }

    readonly property string meridiem:
        root.now.getHours() >= 12 ? "PM" : "AM"

    readonly property string dayText:
        root.weekdayNames[root.now.getDay()]

    readonly property string dateText:
        root.monthNames[root.now.getMonth()].toUpperCase()
        + " "
        + root.now.getDate()
        + ", "
        + root.now.getFullYear()

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]

    function pad(value) {
        return value < 10 ? "0" + value : String(value)
    }

    visible: root.widgetEnabled

    Timer {
        interval: root.showSeconds ? 250 : 1000
        repeat: true
        running: root.widgetEnabled
        onTriggered: root.now = new Date()
    }

    Item {
        anchors.fill: parent

        Column {
            anchors.centerIn: parent
            width: Math.min(860, parent.width - 80)
            spacing: 10

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.dayText
                color: "#EAF2FB"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 5.0
            }

            Row {
                width: parent.width
                height: 112
                spacing: 14

                Text {
                    text: root.timeText
                    color: "#FFFFFF"
                    font.pixelSize: 88
                    font.weight: Font.Light
                    font.letterSpacing: -2.5
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 18
                    text: root.meridiem
                    color: "#7DBBFF"
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                    font.letterSpacing: 2.0
                }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.dateText
                color: "#7D91A5"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 3.0
            }

            Item {
                width: parent.width
                height: 22

                Rectangle {
                    anchors.centerIn: parent
                    width: 240
                    height: 1
                    color: "#49A7FF"
                    opacity: 0.9
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 160
                    height: 1
                    color: "#8CC8FF"
                    opacity: 0.42
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 92
                    height: 1
                    color: "#C5E3FF"
                    opacity: 0.24
                }
            }
        }
    }
}
