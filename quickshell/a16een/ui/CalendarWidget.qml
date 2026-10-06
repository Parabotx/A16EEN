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
    property int viewMonth: root.now.getMonth()
    property int viewYear: root.now.getFullYear()

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]

    readonly property var weekdayNames: [
        "MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"
    ]

    readonly property string currentTime: {
        const h24 = root.now.getHours()
        const minute = root.now.getMinutes()
        const second = root.now.getSeconds()
        const hour = root.use24Hour ? h24 : ((h24 % 12) || 12)
        const base = root.pad(hour) + ":" + root.pad(minute)
        return root.showSeconds ? base + ":" + root.pad(second) : base
    }

    readonly property string currentMeridiem: root.now.getHours() >= 12 ? "PM" : "AM"

    readonly property string todayLabel: {
        const names = [
            "Sunday", "Monday", "Tuesday", "Wednesday",
            "Thursday", "Friday", "Saturday"
        ]
        return names[root.now.getDay()]
    }

    readonly property var calendarDays: {
        const first = new Date(root.viewYear, root.viewMonth, 1)
        const daysInMonth = new Date(root.viewYear, root.viewMonth + 1, 0).getDate()
        const daysInPrevious = new Date(root.viewYear, root.viewMonth, 0).getDate()

        // Convert Sunday-first JS indexing into a Monday-first calendar.
        const mondayIndex = (first.getDay() + 6) % 7
        const cells = []

        for (let index = 0; index < 42; index++) {
            const dayOffset = index - mondayIndex
            let day
            let monthOffset = 0

            if (dayOffset < 0) {
                day = daysInPrevious + dayOffset + 1
                monthOffset = -1
            } else if (dayOffset >= daysInMonth) {
                day = dayOffset - daysInMonth + 1
                monthOffset = 1
            } else {
                day = dayOffset + 1
            }

            cells.push({
                day: day,
                monthOffset: monthOffset,
                inMonth: monthOffset === 0,
                isToday: root.isToday(day, monthOffset)
            })
        }

        return cells
    }

    readonly property string monthTitle:
        root.monthNames[root.viewMonth] + " " + root.viewYear

    readonly property bool viewingCurrentMonth:
        root.viewMonth === root.now.getMonth()
        && root.viewYear === root.now.getFullYear()

    function pad(value) {
        return value < 10 ? "0" + value : String(value)
    }

    function isToday(day, monthOffset) {
        if (monthOffset === 0) {
            return day === root.now.getDate()
                && root.viewMonth === root.now.getMonth()
                && root.viewYear === root.now.getFullYear()
        }

        const candidate = new Date(root.viewYear, root.viewMonth + monthOffset, day)
        return candidate.getFullYear() === root.now.getFullYear()
            && candidate.getMonth() === root.now.getMonth()
            && candidate.getDate() === root.now.getDate()
    }

    function shiftMonth(delta) {
        const next = new Date(root.viewYear, root.viewMonth + delta, 1)
        root.viewMonth = next.getMonth()
        root.viewYear = next.getFullYear()
    }

    function returnToToday() {
        root.viewMonth = root.now.getMonth()
        root.viewYear = root.now.getFullYear()
    }

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
    WlrLayershell.namespace: "a16een-widget-time"

    Timer {
        interval: root.showSeconds ? 500 : 1000
        repeat: true
        running: root.widgetEnabled
        onTriggered: {
            const previousMonth = root.now.getMonth()
            const previousYear = root.now.getFullYear()

            root.now = new Date()

            if (root.viewingCurrentMonth
                && (root.now.getMonth() !== previousMonth
                    || root.now.getFullYear() !== previousYear)) {
                root.viewMonth = root.now.getMonth()
                root.viewYear = root.now.getFullYear()
            }
        }
    }

    Rectangle {
        id: glass
        width: 390
        height: 602
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 26
        anchors.rightMargin: 26
        radius: 28

        color: "#D80B111B"
        border.width: 1
        border.color: "#66D9E8FF"

        // Layered translucent surfaces create a restrained glass/frosted look
        // without depending on a compositor-specific blur API.
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 27
            color: "transparent"
            border.width: 1
            border.color: "#18FFFFFF"
        }

        Rectangle {
            x: 12
            y: 12
            width: 160
            height: 160
            radius: 80
            color: "#163C9EFF"
            opacity: 0.10
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.bottomMargin: 20
            anchors.rightMargin: -18
            width: 180
            height: 180
            radius: 90
            color: "#162BBEFF"
            opacity: 0.08
        }

        Column {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 14

            Row {
                width: parent.width
                height: 36

                Column {
                    width: parent.width - 88
                    spacing: 3

                    Text {
                        text: "A16EEN CALENDAR"
                        color: "#6E8AA6"
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.6
                    }

                    Text {
                        text: root.currentTime
                        color: "#FFFFFF"
                        font.pixelSize: 24
                        font.weight: Font.Light
                    }
                }

                Column {
                    width: 88
                    spacing: 3

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        text: root.todayLabel.toUpperCase()
                        color: "#E7F0F8"
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.8
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        text: root.use24Hour ? "24 HOUR" : root.currentMeridiem
                        color: "#52697E"
                        font.pixelSize: 6
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.8
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#22FFFFFF"
            }

            Row {
                width: parent.width
                height: 40

                Column {
                    width: parent.width - 88
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: root.monthTitle
                        color: "#FFFFFF"
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: root.viewingCurrentMonth ? "CURRENT MONTH" : "CALENDAR VIEW"
                        color: "#5D7186"
                        font.pixelSize: 6
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.1
                    }
                }

                Row {
                    width: 88
                    height: 32
                    spacing: 5

                    Rectangle {
                        width: 41
                        height: 32
                        radius: 10
                        color: "#0F1A26"
                        border.width: 1
                        border.color: "#22394E"

                        Text {
                            anchors.centerIn: parent
                            text: "‹"
                            color: "#D9E8F5"
                            font.pixelSize: 16
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.shiftMonth(-1)
                        }
                    }

                    Rectangle {
                        width: 41
                        height: 32
                        radius: 10
                        color: "#0F1A26"
                        border.width: 1
                        border.color: "#22394E"

                        Text {
                            anchors.centerIn: parent
                            text: "›"
                            color: "#D9E8F5"
                            font.pixelSize: 16
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.shiftMonth(1)
                        }
                    }
                }
            }

            Row {
                width: parent.width
                height: 22

                Repeater {
                    model: root.weekdayNames

                    delegate: Text {
                        width: parent.width / 7
                        height: 22
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: modelData
                        color: "#50657A"
                        font.pixelSize: 6
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.7
                    }
                }
            }

            Grid {
                width: parent.width
                height: 252
                columns: 7
                rows: 6
                rowSpacing: 4
                columnSpacing: 4

                Repeater {
                    model: root.calendarDays

                    delegate: Item {
                        width: (parent.width - 24) / 7
                        height: (parent.height - 20) / 6

                        Rectangle {
                            width: Math.min(parent.width, parent.height)
                            height: Math.min(parent.width, parent.height)
                            anchors.centerIn: parent
                            radius: width / 2
                            color: modelData.isToday ? "#2F8CFF" : "transparent"
                            border.width: modelData.isToday ? 1 : 0
                            border.color: "#91C7FF"

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -5
                                radius: width / 2
                                color: "transparent"
                                border.width: modelData.isToday ? 1 : 0
                                border.color: "#356FA8"
                                opacity: modelData.isToday ? 0.55 : 0
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.day
                                color: modelData.isToday
                                    ? "#FFFFFF"
                                    : (modelData.inMonth ? "#E2EAF1" : "#3D4B58")
                                font.pixelSize: 9
                                font.weight: modelData.isToday ? Font.DemiBold : Font.Normal
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#20FFFFFF"
            }

            Row {
                width: parent.width
                height: 42

                Column {
                    width: parent.width - 78
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        text: "UPCOMING EVENTS"
                        color: "#8095A8"
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.2
                    }

                    Text {
                        text: "No events scheduled"
                        color: "#DDE7EF"
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                    }
                }

                Rectangle {
                    width: 70
                    height: 32
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 10
                    color: root.viewingCurrentMonth ? "#0F1A26" : "#111111"
                    border.width: 1
                    border.color: "#22394E"

                    Text {
                        anchors.centerIn: parent
                        text: root.viewingCurrentMonth ? "TODAY" : "GO TO TODAY"
                        color: root.viewingCurrentMonth ? "#84BDFF" : "#6D7F90"
                        font.pixelSize: 6
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.7
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.returnToToday()
                    }
                }
            }

            Row {
                width: parent.width
                height: 18
                spacing: 7

                Rectangle {
                    width: 5
                    height: 5
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 3
                    color: "#4CA8FF"
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.now.getDate() + " " + root.monthNames[root.now.getMonth()] + " • TODAY"
                    color: "#506174"
                    font.pixelSize: 6
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.5
                }

                Item { width: parent.width - 135; height: 1 }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "LOCAL SYSTEM TIME"
                    color: "#354756"
                    font.pixelSize: 5
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.8
                }
            }
        }
    }
}
