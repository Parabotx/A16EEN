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
    property string selectedTab: "ongoing"
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
    readonly property var visibleTasks: root.tasks.filter(item =>
        root.selectedTab === "done" ? Boolean(item.completed) : !Boolean(item.completed))
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

    readonly property real screenWidth: root.modelData ? root.modelData.width : 1920
    readonly property real screenHeight: root.modelData ? root.modelData.height : 1080
    readonly property int popupWidth: 316
    readonly property int popupHeight: root.creating ? 458 : 350
    readonly property real popupX: root.horizontalNavbar
        ? root.screenWidth - root.popupWidth - 102
        : (root.navbarPosition === "left"
            ? 66
            : root.screenWidth - root.popupWidth - 68)
    readonly property real popupY: root.horizontalNavbar
        ? (root.navbarPosition === "top"
            ? 40
            : root.screenHeight - root.popupHeight - 40)
        : root.screenHeight - root.popupHeight - 72

    screen: root.modelData
    visible: root.opened && root.dockVisible && root.modelData !== null
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    focusable: root.opened
    WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    // A screen-sized transparent surface makes outside-click dismissal reliable.
    width: root.screenWidth
    height: root.screenHeight
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-quick-tasks"

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
        interval: 300
        repeat: false
        onTriggered: {
            if (root.storageReady)
                taskStorage.setText(JSON.stringify({ version: 2, tasks: root.tasks }))
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

    // Gregorian -> JDN -> Ethiopian civil date. Month 13 (Pagume)
    // gets six days in Ethiopian leap years (year % 4 === 3).
    function gregorianToJdn(date) {
        const month = date.getMonth() + 1
        const day = date.getDate()
        let year = date.getFullYear()
        const a = Math.floor((14 - month) / 12)
        year += 4800 - a
        const m = month + 12 * a - 3
        return day + Math.floor((153 * m + 2) / 5) + 365 * year
            + Math.floor(year / 4) - Math.floor(year / 100)
            + Math.floor(year / 400) - 32045
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
                        description: String(item.description || ""),
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
        root.tasks = [{
            id: String(Date.now()),
            title: title,
            description: descriptionField.text.trim(),
            date: root.dateKey(root.selectedYear, root.selectedMonth, root.selectedDay),
            completed: false
        }, ...root.tasks]
        saveTimer.restart()
        taskNameField.text = ""
        descriptionField.text = ""
        root.creating = false
        root.selectedTab = "ongoing"
    }

    function toggleTask(id) {
        root.tasks = root.tasks.map(item => String(item.id) === String(id)
            ? {
                id: item.id,
                title: item.title,
                description: String(item.description || ""),
                date: item.date,
                completed: !item.completed
            }
            : item)
        saveTimer.restart()
    }

    function deleteTask(id) {
        root.tasks = root.tasks.filter(item => String(item.id) !== String(id))
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
                taskStorage.setText(JSON.stringify({ version: 2, tasks: root.tasks }))
        }
    }

    MouseArea {
        id: outsideClickArea
        anchors.fill: parent
        z: 0
        acceptedButtons: Qt.LeftButton
        onClicked: root.closeRequested()
    }

    Item {
        id: taskPopup
        visible: root.opened && root.dockVisible && root.modelData !== null
        x: root.popupX
        y: root.popupY
        width: root.popupWidth
        height: root.popupHeight
        z: 1

        Rectangle {
            id: taskCard
            anchors.fill: parent
            radius: 18
            color: "#FFFFFF"
            border.width: 1
            border.color: "#D9DEE5"

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: 22
                color: "#14000000"
                z: -1
            }

            MouseArea {
                anchors.fill: parent
                z: 0
                acceptedButtons: Qt.AllButtons
                onClicked: mouse.accepted = true
            }

            // Creation panel is deliberately simple: title, optional
            // description, and a compact Ethiopian-date picker.
            Column {
                z: 1
                anchors.fill: parent
                anchors.margins: 13
                spacing: 8
                visible: root.creating

                Row {
                    width: parent.width
                    height: 31
                    spacing: 7

                    Text {
                        width: parent.width - 2
                        text: "New task"
                        color: "#202630"
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 34
                    radius: 9
                    color: "#FAFBFC"
                    border.width: 1
                    border.color: taskNameField.activeFocus ? "#B8C5D4" : "#E5EAF0"

                    TextInput {
                        id: taskNameField
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#222A34"
                        font.pixelSize: 12
                        clip: true
                        selectByMouse: true
                        onAccepted: root.createTask()
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Task name"
                        color: "#A0A9B4"
                        font.pixelSize: 12
                        visible: taskNameField.text.length === 0 && !taskNameField.activeFocus
                        enabled: false
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 43
                    radius: 9
                    color: "#FAFBFC"
                    border.width: 1
                    border.color: descriptionField.activeFocus ? "#B8C5D4" : "#E5EAF0"

                    TextEdit {
                        id: descriptionField
                        anchors.fill: parent
                        anchors.margins: 9
                        text: ""
                        color: "#222A34"
                        font.pixelSize: 11
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        clip: true
                    }
                    Text {
                        anchors.left: descriptionField.left
                        anchors.top: descriptionField.top
                        text: "Description (optional)"
                        color: "#A0A9B4"
                        font.pixelSize: 11
                        visible: descriptionField.text.length === 0 && !descriptionField.activeFocus
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
                    height: 25
                    spacing: 7

                    Rectangle {
                        width: 25
                        height: 25
                        radius: 8
                        color: prevHover.containsMouse ? "#EEF1F4" : "#F8F9FA"
                        Text { anchors.centerIn: parent; text: "‹"; color: "#343D47"; font.pixelSize: 19 }
                        MouseArea {
                            id: prevHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.moveCalendarMonth(-1)
                        }
                    }

                    Text {
                        width: parent.width - 64
                        text: root.ethiopianMonths[root.calendarMonth - 1] + " " + root.calendarYear + " ዓ.ም."
                        color: "#202731"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Rectangle {
                        width: 25
                        height: 25
                        radius: 8
                        color: nextHover.containsMouse ? "#EEF1F4" : "#F8F9FA"
                        Text { anchors.centerIn: parent; text: "›"; color: "#343D47"; font.pixelSize: 19 }
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
                    height: 15
                    spacing: 3

                    Repeater {
                        model: root.weekdayShortNames
                        delegate: Text {
                            required property var modelData
                            width: 29
                            height: 15
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
                    columnSpacing: 3
                    rowSpacing: 2
                    anchors.horizontalCenter: parent.horizontalCenter

                    Repeater {
                        model: root.calendarCells
                        delegate: Rectangle {
                            id: dateCell
                            required property var modelData
                            width: 29
                            height: 20
                            radius: 6
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

                Item { width: 1; height: 1 }

                Row {
                    width: parent.width
                    height: 29
                    spacing: 7

                    Rectangle {
                        width: (parent.width - 7) / 2
                        height: 29
                        radius: 9
                        color: cancelHover.containsMouse ? "#EEF1F4" : "#F7F8FA"
                        border.width: 1
                        border.color: "#E3E7EC"
                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: "#5F6A76"
                            font.pixelSize: 10
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
                        width: (parent.width - 7) / 2
                        height: 29
                        radius: 9
                        color: saveTaskHover.containsMouse ? "#161B22" : "#242A32"
                        Text {
                            anchors.centerIn: parent
                            text: "Add task"
                            color: "#FFFFFF"
                            font.pixelSize: 10
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

            // List view has only two tabs and a small add button at bottom right.
            Column {
                z: 1
                anchors.fill: parent
                anchors.margins: 12
                spacing: 9
                visible: !root.creating

                Row {
                    width: parent.width
                    height: 29
                    spacing: 6

                    Repeater {
                        model: [
                            { id: "ongoing", label: "Ongoing" },
                            { id: "done", label: "Done" }
                        ]
                        delegate: Rectangle {
                            id: tabButton
                            required property var modelData
                            width: (parent.width - 6) / 2
                            height: 29
                            radius: 9
                            color: root.selectedTab === tabButton.modelData.id ? "#20262E" : "#F6F7F9"
                            border.width: 1
                            border.color: root.selectedTab === tabButton.modelData.id ? "#20262E" : "#E3E8ED"
                            Text {
                                anchors.centerIn: parent
                                text: tabButton.modelData.label
                                color: root.selectedTab === tabButton.modelData.id ? "#FFFFFF" : "#5D6875"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedTab = tabButton.modelData.id
                            }
                        }
                    }
                }

                ListView {
                    id: tasksList
                    width: parent.width
                    height: parent.height - 81
                    clip: true
                    spacing: 6
                    model: root.visibleTasks

                    Text {
                        parent: tasksList
                        anchors.centerIn: parent
                        visible: tasksList.count === 0
                        text: root.selectedTab === "done" ? "Nothing completed yet" : "Nothing here yet"
                        color: "#8A939E"
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                    }

                    delegate: Rectangle {
                        id: taskRow
                        required property var modelData
                        width: tasksList.width
                        height: taskRow.modelData.description ? 54 : 46
                        radius: 11
                        color: "#FAFBFC"
                        border.width: 1
                        border.color: "#E8EDF2"

                        Rectangle {
                            id: completeButton
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 17
                            height: 17
                            radius: 6
                            color: taskRow.modelData.completed ? "#20262E"
                                : (completeHover.containsMouse ? "#EFF2F5" : "#FFFFFF")
                            border.width: 1
                            border.color: taskRow.modelData.completed ? "#20262E" : "#D5DDE5"
                            Text {
                                anchors.centerIn: parent
                                text: taskRow.modelData.completed ? "✓" : ""
                                color: "#FFFFFF"
                                font.pixelSize: 11
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
                            anchors.right: deleteButton.left
                            anchors.leftMargin: 7
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Text {
                                width: parent.width
                                text: taskRow.modelData.title
                                color: "#28313C"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                font.strikeout: Boolean(taskRow.modelData.completed)
                                opacity: taskRow.modelData.completed ? 0.58 : 1
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                text: String(taskRow.modelData.description || "").trim().length
                                    ? String(taskRow.modelData.description).trim()
                                    : root.dateLabel(taskRow.modelData.date)
                                color: "#8A939E"
                                font.pixelSize: 9
                                font.strikeout: Boolean(taskRow.modelData.completed)
                                opacity: taskRow.modelData.completed ? 0.62 : 1
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            id: deleteButton
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 22
                            height: 22
                            radius: 7
                            color: deleteHover.containsMouse ? "#FBEDEE" : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                color: deleteHover.containsMouse ? "#B9444A" : "#98A1AD"
                                font.pixelSize: 15
                            }
                            MouseArea {
                                id: deleteHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.deleteTask(taskRow.modelData.id)
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: floatingAddButton
                visible: !root.creating
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: 13
                anchors.bottomMargin: 12
                width: 31
                height: 31
                radius: 11
                color: addHover.containsMouse ? "#171B20" : "#242A32"
                border.width: 1
                border.color: "#20262E"
                z: 3

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    color: "#FFFFFF"
                    font.pixelSize: 21
                    font.weight: Font.Light
                }
                MouseArea {
                    id: addHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.startCreating()
                }
            }
        }
    }
}
