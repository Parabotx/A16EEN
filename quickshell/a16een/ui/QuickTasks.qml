import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    required property string navbarPosition
    property bool opened: false
    property bool dockVisible: true
    property bool creating: false
    property var tasks: []
    property bool storageReady: false
    property date now: new Date()
    property int calendarYear: 0
    property int calendarMonth: 1
    property int selectedYear: 0
    property int selectedMonth: 1
    property int selectedDay: 1

    signal closeRequested()

    readonly property bool horizontalNavbar:
        root.navbarPosition === "top" || root.navbarPosition === "bottom"

    readonly property var ethiopianMonths: [
        "መስከረም", "ጥቅምት", "ሕዳር", "ታህሳስ",
        "ጥር", "የካቲት", "መጋቢት", "ሚያዝያ",
        "ግንቦት", "ሰኔ", "ሐምሌ", "ነሐሴ", "ጳጉሜ"
    ]
    readonly property var weekdayShortNames: ["ሰ", "ማ", "ረ", "ሐ", "አ", "ቅ", "እ"]

    readonly property var todayEthiopian: root.toEthiopianDate(root.now)

    readonly property var calendarCells: {
        const firstDayJdn = root.ethiopianYearStartJdn(root.calendarYear)
            + 30 * (root.calendarMonth - 1)
        const offset = firstDayJdn % 7
        const monthLength = root.calendarMonth === 13
            ? (root.calendarYear % 4 === 3 ? 6 : 5)
            : 30
        const cells = []
        for (let i = 0; i < 42; i++) {
            const day = i - offset + 1
            cells.push({ day: day > 0 && day <= monthLength ? day : 0 })
        }
        return cells
    }

    screen: root.modelData
    visible: root.opened && root.dockVisible && root.modelData !== null
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    focusable: false
    readonly property real screenWidth: root.modelData ? root.modelData.width : 1920
    readonly property real screenHeight: root.modelData ? root.modelData.height : 1080
    readonly property int popupWidth: 304
    readonly property int popupHeight: root.creating ? 410 : 292

    // Keep this overlay explicitly screen-sized so popup coordinates are
    // stable when the navbar is moved to the left or right edge.
    width: root.screenWidth
    height: root.screenHeight

    // Transparent full-screen surface for click-outside dismissal.
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-quick-tasks"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    FileView {
        id: taskStorage
        path: Quickshell.stateDir + "/quick-tasks.json"
        preload: true
        printErrors: false
        atomicWrites: true
        onLoaded: root.loadTasks()
        onLoadFailed: root.storageReady = true
    }

    Timer {
        id: saveTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (root.storageReady)
                taskStorage.setText(JSON.stringify({ version: 1, tasks: root.tasks }))
        }
    }

    Timer {
        interval: 60000
        repeat: true
        running: root.opened
        onTriggered: root.now = new Date()
    }

    function pad(value) {
        return value < 10 ? "0" + value : String(value)
    }

    // Gregorian -> JDN, then JDN -> Ethiopian civil date.
    function gregorianToJdn(date) {
        const month = date.getMonth() + 1
        const day = date.getDate()
        let year = date.getFullYear()
        const a = Math.floor((14 - month) / 12)
        year += 4800 - a
        const m = month + 12 * a - 3
        return day
            + Math.floor((153 * m + 2) / 5)
            + 365 * year
            + Math.floor(year / 4)
            - Math.floor(year / 100)
            + Math.floor(year / 400)
            - 32045
    }

    function ethiopianYearStartJdn(year) {
        return 1723856 + 365 * year + Math.floor(year / 4)
    }

    function toEthiopianDate(date) {
        const jdn = root.gregorianToJdn(date)
        let year = date.getFullYear() - 7
        while (root.ethiopianYearStartJdn(year) > jdn)
            year--
        while (root.ethiopianYearStartJdn(year + 1) <= jdn)
            year++
        const dayOfYear = jdn - root.ethiopianYearStartJdn(year)
        return {
            year: year,
            month: Math.max(1, Math.min(13, Math.floor(dayOfYear / 30) + 1)),
            day: dayOfYear % 30 + 1
        }
    }

    function dateKey(year, month, day) {
        return String(year) + "-" + root.pad(month) + "-" + root.pad(day)
    }

    function dateLabel(key) {
        const parts = String(key || "").split("-")
        if (parts.length !== 3)
            return ""
        const year = Number(parts[0])
        const month = Number(parts[1])
        const day = Number(parts[2])
        if (month < 1 || month > 13 || day < 1)
            return ""
        return root.ethiopianMonths[month - 1] + " " + day + ", " + year + " ዓ.ም."
    }

    function loadTasks() {
        if (root.storageReady)
            return
        try {
            const parsed = JSON.parse(String(taskStorage.text() || "{}"))
            root.tasks = Array.isArray(parsed.tasks)
                ? parsed.tasks.filter(item => item && String(item.title || "").trim().length)
                    .map(item => ({
                        id: String(item.id || Date.now()),
                        title: String(item.title || "").trim(),
                        date: String(item.date || ""),
                        completed: Boolean(item.completed)
                    }))
                : []
        } catch (error) {
            root.tasks = []
        }
        root.storageReady = true
    }

    function startCreating() {
        root.now = new Date()
        const today = root.todayEthiopian
        root.calendarYear = today.year
        root.calendarMonth = today.month
        root.selectedYear = today.year
        root.selectedMonth = today.month
        root.selectedDay = today.day
        root.creating = true
        Qt.callLater(() => taskNameField.forceActiveFocus())
    }

    function moveCalendarMonth(amount) {
        let year = root.calendarYear
        let month = root.calendarMonth + amount
        if (month < 1) {
            month = 13
            year--
        } else if (month > 13) {
            month = 1
            year++
        }
        root.calendarYear = year
        root.calendarMonth = month
    }

    function selectCalendarDay(day) {
        if (day < 1)
            return
        root.selectedYear = root.calendarYear
        root.selectedMonth = root.calendarMonth
        root.selectedDay = day
    }

    function createTask() {
        const title = taskNameField.text.trim()
        if (!title || !root.storageReady)
            return
        const next = root.tasks.slice()
        next.unshift({
            id: String(Date.now()),
            title: title,
            date: root.dateKey(root.selectedYear, root.selectedMonth, root.selectedDay),
            completed: false
        })
        root.tasks = next
        saveTimer.restart()
        taskNameField.text = ""
        root.creating = false
    }

    function toggleTask(id) {
        root.tasks = root.tasks.map(item => String(item.id) === String(id)
            ? { id: item.id, title: item.title, date: item.date, completed: !item.completed }
            : item)
        saveTimer.restart()
    }

    onOpenedChanged: {
        if (opened) {
            root.now = new Date()
            root.creating = false
            const today = root.todayEthiopian
            if (root.selectedYear === 0) {
                root.selectedYear = today.year
                root.selectedMonth = today.month
                root.selectedDay = today.day
            }
        } else {
            saveTimer.stop()
            if (root.storageReady)
                taskStorage.setText(JSON.stringify({ version: 1, tasks: root.tasks }))
        }
    }

    MouseArea {
        id: outsideClickArea
        anchors.fill: parent
        z: 0
        acceptedButtons: Qt.LeftButton
        onClicked: root.closeRequested()
    }

    PanelWindow {
        id: taskPopup
        screen: root.modelData
        visible: root.opened && root.dockVisible && root.modelData !== null
        color: "transparent"
        aboveWindows: true
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        focusable: root.opened
        width: root.popupWidth
        height: root.popupHeight

        anchors {
            left: !root.horizontalNavbar && root.navbarPosition === "left"
            right: root.horizontalNavbar || root.navbarPosition === "right"
            top: root.horizontalNavbar && root.navbarPosition === "top"
            bottom: root.horizontalNavbar
                ? root.navbarPosition === "bottom"
                : true
        }

        margins {
            left: !root.horizontalNavbar && root.navbarPosition === "left" ? 66 : 0
            right: root.horizontalNavbar
                ? 102
                : (root.navbarPosition === "right" ? 68 : 0)
            top: root.horizontalNavbar && root.navbarPosition === "top" ? 40 : 0
            bottom: root.horizontalNavbar
                ? (root.navbarPosition === "bottom" ? 40 : 0)
                : 72
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "a16een-quick-tasks-popup"
        WlrLayershell.keyboardFocus: root.opened
            ? WlrKeyboardFocus.OnDemand
            : WlrKeyboardFocus.None

        Rectangle {
            id: taskCard
            anchors.fill: parent
            radius: 20
        color: "#FFFFFF"
        border.width: 1
        border.color: "#D9DEE5"

        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: 24
            color: "#16000000"
            z: -1
        }

        MouseArea {
            anchors.fill: parent
            z: 0
            acceptedButtons: Qt.AllButtons
            onClicked: mouse.accepted = true
        }

        Column {
            z: 1
            anchors.fill: parent
            anchors.margins: 15
            spacing: 10

            Row {
                width: parent.width
                height: 31
                spacing: 8

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 83
                    spacing: 2

                    Text {
                        text: root.creating ? "NEW TASK" : "TASKS"
                        color: "#171B20"
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.7
                    }
                    Text {
                        text: root.creating ? "Choose a name and date" : root.tasks.length + " saved"
                        color: "#818B98"
                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    width: 31
                    height: 31
                    radius: 10
                    color: closeHover.containsMouse ? "#EEF1F4" : "#F8F9FA"
                    border.width: 1
                    border.color: "#E5E9EE"
                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: "#414A55"
                        font.pixelSize: 21
                    }
                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#E9EDF1"
            }

            Item {
                width: parent.width
                height: parent.height - 53

                Column {
                    anchors.fill: parent
                    spacing: 9
                    visible: !root.creating

                    Rectangle {
                        width: parent.width
                        height: 34
                        radius: 11
                        color: createHover.containsMouse ? "#171B20" : "#242A32"
                        Row {
                            anchors.centerIn: parent
                            spacing: 7
                            Text {
                                text: "+"
                                color: "#FFFFFF"
                                font.pixelSize: 18
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Create task"
                                color: "#FFFFFF"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        MouseArea {
                            id: createHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.startCreating()
                        }
                    }

                    ListView {
                        id: tasksList
                        width: parent.width
                        height: parent.height - 42
                        clip: true
                        spacing: 5
                        model: root.tasks

                        Text {
                            parent: tasksList
                            anchors.centerIn: parent
                            visible: tasksList.count === 0
                            text: "No tasks yet. Create your first task."
                            color: "#8A939E"
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                        }

                        delegate: Rectangle {
                            id: taskRow
                            required property var modelData
                            width: tasksList.width
                            height: 45
                            radius: 11
                            color: "#FAFBFC"
                            border.width: 1
                            border.color: "#E9EDF1"

                            Rectangle {
                                id: completeButton
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 22
                                height: 22
                                radius: 7
                                color: taskRow.modelData.completed ? "#20262E"
                                    : (completeHover.containsMouse ? "#EDF1F5" : "#FFFFFF")
                                border.width: 1
                                border.color: taskRow.modelData.completed ? "#20262E" : "#DDE3E9"

                                Text {
                                    anchors.centerIn: parent
                                    text: taskRow.modelData.completed ? "✓" : ""
                                    color: "#FFFFFF"
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    id: completeHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.toggleTask(taskRow.modelData.id)
                                }
                            }

                            Column {
                                anchors.left: completeButton.right
                                anchors.right: parent.right
                                anchors.leftMargin: 7
                                anchors.rightMargin: 9
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                Text {
                                    width: parent.width
                                    text: taskRow.modelData.title
                                    color: "#28313C"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    font.strikeout: Boolean(taskRow.modelData.completed)
                                    opacity: taskRow.modelData.completed ? 0.62 : 1
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width
                                    text: root.dateLabel(taskRow.modelData.date)
                                    color: "#8A939E"
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                }

                Column {
                    anchors.fill: parent
                    spacing: 7
                    visible: root.creating

                    Rectangle {
                        width: parent.width
                        height: 34
                        radius: 10
                        color: "#FAFBFC"
                        border.width: 1
                        border.color: taskNameField.activeFocus ? "#B8C5D4" : "#E5EAF0"

                        TextInput {
                            id: taskNameField
                            anchors.fill: parent
                            anchors.leftMargin: 11
                            anchors.rightMargin: 9
                            verticalAlignment: TextInput.AlignVCenter
                            color: "#222A34"
                            font.pixelSize: 12
                            clip: true
                            selectByMouse: true
                            onAccepted: root.createTask()
                        }
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 11
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Task name"
                            color: "#A0A9B4"
                            font.pixelSize: 12
                            visible: taskNameField.text.length === 0 && !taskNameField.activeFocus
                            enabled: false
                        }
                    }

                    Row {
                        width: parent.width
                        height: 22
                        spacing: 5
                        Text {
                            text: "DATE"
                            color: "#87919E"
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.7
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: root.ethiopianMonths[root.selectedMonth - 1] + " "
                                + root.selectedDay + ", " + root.selectedYear + " ዓ.ም."
                            color: "#4D5967"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        width: parent.width
                        height: 27
                        spacing: 8

                        Rectangle {
                            width: 27
                            height: 27
                            radius: 8
                            color: prevHover.containsMouse ? "#EEF1F4" : "#F8F9FA"
                            Text { anchors.centerIn: parent; text: "‹"; color: "#343D47"; font.pixelSize: 20 }
                            MouseArea {
                                id: prevHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.moveCalendarMonth(-1)
                            }
                        }

                        Text {
                            width: parent.width - 70
                            text: root.ethiopianMonths[root.calendarMonth - 1] + " "
                                + root.calendarYear + " ዓ.ም."
                            color: "#202731"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        Rectangle {
                            width: 27
                            height: 27
                            radius: 8
                            color: nextHover.containsMouse ? "#EEF1F4" : "#F8F9FA"
                            Text { anchors.centerIn: parent; text: "›"; color: "#343D47"; font.pixelSize: 20 }
                            MouseArea {
                                id: nextHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.moveCalendarMonth(1)
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 17
                        spacing: 4

                        Repeater {
                            model: root.weekdayShortNames
                            delegate: Text {
                                required property var modelData
                                width: 30
                                height: 17
                                text: modelData
                                color: "#8E97A2"
                                font.family: "Noto Sans Ethiopic"
                                font.pixelSize: 9
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    Grid {
                        id: dateGrid
                        width: parent.width
                        columns: 7
                        columnSpacing: 4
                        rowSpacing: 2
                        anchors.horizontalCenter: parent.horizontalCenter

                        Repeater {
                            model: root.calendarCells
                            delegate: Rectangle {
                                id: dateCell
                                required property var modelData
                                width: 30
                                height: 22
                                radius: 7
                                readonly property bool chosen:
                                    dateCell.modelData.day > 0
                                    && root.selectedYear === root.calendarYear
                                    && root.selectedMonth === root.calendarMonth
                                    && root.selectedDay === dateCell.modelData.day
                                color: dateCell.chosen ? "#20262E"
                                    : (dateCell.modelData.day > 0 ? "#F4F6F8" : "transparent")
                                Text {
                                    anchors.centerIn: parent
                                    text: dateCell.modelData.day > 0 ? String(dateCell.modelData.day) : ""
                                    color: dateCell.chosen ? "#FFFFFF" : "#505B68"
                                    font.pixelSize: 10
                                    font.weight: dateCell.chosen ? Font.DemiBold : Font.Normal
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: dateCell.modelData.day > 0
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectCalendarDay(dateCell.modelData.day)
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 30
                        spacing: 8

                        Rectangle {
                            width: (parent.width - 8) / 2
                            height: 30
                            radius: 9
                            color: cancelHover.containsMouse ? "#EEF1F4" : "#F7F8FA"
                            border.width: 1
                            border.color: "#E3E7EC"
                            Text {
                                anchors.centerIn: parent
                                text: "Cancel"
                                color: "#5F6A76"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }
                            MouseArea {
                                id: cancelHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.creating = false
                            }
                        }

                        Rectangle {
                            width: (parent.width - 8) / 2
                            height: 30
                            radius: 9
                            color: saveTaskHover.containsMouse ? "#161B22" : "#242A32"
                            Text {
                                anchors.centerIn: parent
                                text: "Save task"
                                color: "#FFFFFF"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                            MouseArea {
                                id: saveTaskHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.createTask()
                            }
                        }
                    }
                }
            }
        }
    }
    }
}
