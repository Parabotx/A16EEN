import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool widgetEnabled: false

    property var now: new Date()
    property var tasks: []
    property string searchText: ""
    property bool completedExpanded: false
    property int menuTaskId: -1
    property bool editorOpen: false
    property int editingTaskId: -1
    property string editorCategory: "Personal"
    property string editorPriority: "Medium"
    property bool optionsOpen: false
    property bool calendarOpen: false
    property bool storageReady: false
    property int monthOffset: 0

    property int widgetWidth: 1040
    property int widgetHeight: 690
    property real widgetX: -1
    property real widgetY: 54

    // A white-first glass system keeps the wallpaper atmospheric without
    // allowing strongly colored wallpapers to tint the UI yellow.
    readonly property color surfaceColor: "#F7F9FCF5"
    readonly property color glass: "#FFFFFFDE"
    readonly property color glassSoft: "#FFFFFFC8"
    readonly property color glassSubtle: "#F7F9FCB8"
    readonly property color border: "#DCE2E9"
    readonly property color borderSoft: "#E8EDF2"
    readonly property color ink: "#18212B"
    readonly property color secondary: "#66717D"
    readonly property color muted: "#9AA4AE"
    readonly property color accent: "#547FE8"
    readonly property color accentSoft: "#EDF2FF"
    readonly property color canvas: "#F4F7FA"
    readonly property color danger: "#B45F67"

    readonly property string todayKey: root.dateKey(root.now)
    readonly property var todayTasks: root.sortedTasks(
        root.tasks.filter(task => task.date === root.todayKey))
    readonly property var activeTasks: root.sortedTasks(
        root.todayTasks.filter(task => !task.completed))
    readonly property var completedTasks: root.sortedTasks(
        root.todayTasks.filter(task => task.completed))
    readonly property var visibleActiveTasks: root.activeTasks.filter(task =>
        root.searchText.trim().length === 0
        || String(task.title || "").toLowerCase().includes(root.searchText.trim().toLowerCase())
        || String(task.category || "").toLowerCase().includes(root.searchText.trim().toLowerCase())
        || String(task.notes || "").toLowerCase().includes(root.searchText.trim().toLowerCase()))
    readonly property int todayTotal: root.todayTasks.length
    readonly property int completedCount: root.completedTasks.length
    readonly property real progress:
        root.todayTotal > 0 ? root.completedCount / root.todayTotal : 0

    readonly property date displayedMonth: new Date(
        root.now.getFullYear(), root.now.getMonth() + root.monthOffset, 1)
    readonly property string displayedMonthTitle:
        root.monthNames[root.displayedMonth.getMonth()] + " "
        + root.displayedMonth.getFullYear()

    readonly property int totalFocusMinutes: {
        let total = 0
        for (const task of root.todayTasks)
            total += root.durationMinutes(task.time)
        return total
    }

    readonly property int streakDays: {
        let streak = 0
        const cursor = new Date(root.now.getFullYear(), root.now.getMonth(), root.now.getDate())
        for (let i = 0; i < 30; i++) {
            const key = root.dateKey(cursor)
            const dayHasCompletion = root.tasks.some(task =>
                task.date === key && task.completed)
            if (!dayHasCompletion)
                break
            streak++
            cursor.setDate(cursor.getDate() - 1)
        }
        return streak
    }

    readonly property int weekTasksDone: root.tasks.filter(task => {
        const cursor = new Date(root.now.getFullYear(), root.now.getMonth(), root.now.getDate())
        const then = new Date(cursor)
        then.setDate(then.getDate() - 6)
        const date = new Date(
            Number(String(task.date).slice(0, 4)),
            Number(String(task.date).slice(5, 7)) - 1,
            Number(String(task.date).slice(8, 10)))
        return task.completed && date >= then && date <= cursor
    }).length

    readonly property var calendarCells: {
        const first = root.displayedMonth
        const startIndex = (first.getDay() + 6) % 7
        const daysInMonth = new Date(
            first.getFullYear(), first.getMonth() + 1, 0).getDate()
        const daysInPrevious = new Date(
            first.getFullYear(), first.getMonth(), 0).getDate()
        const cells = []

        for (let i = 0; i < 42; i++) {
            const offset = i - startIndex
            if (offset < 0) {
                cells.push({
                    day: daysInPrevious + offset + 1,
                    monthOffset: -1,
                    key: ""
                })
            } else if (offset >= daysInMonth) {
                cells.push({
                    day: offset - daysInMonth + 1,
                    monthOffset: 1,
                    key: ""
                })
            } else {
                const day = offset + 1
                const key = first.getFullYear()
                    + "-" + root.pad(first.getMonth() + 1)
                    + "-" + root.pad(day)
                cells.push({
                    day: day,
                    monthOffset: 0,
                    key: key
                })
            }
        }
        return cells
    }

    readonly property var weeklySample: [2, 4, 3, 5, 4, 6, Math.max(3, root.todayTotal - 1)]
    readonly property var weekdayShort: ["M", "T", "W", "T", "F", "S", "S"]
    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]

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
    WlrLayershell.namespace: "a16een-widget-tasks"

    FileView {
        id: storage
        path: Quickshell.stateDir + "/tasks.json"
        preload: true
        printErrors: false
        atomicWrites: true
        onLoaded: root.loadState()
        onLoadFailed: root.initializeState()
    }

    Timer {
        interval: 30000
        repeat: true
        running: root.widgetEnabled
        onTriggered: root.now = new Date()
    }

    function pad(value) {
        return value < 10 ? "0" + value : String(value)
    }

    function dateKey(value) {
        return value.getFullYear()
            + "-" + root.pad(value.getMonth() + 1)
            + "-" + root.pad(value.getDate())
    }

    function durationMinutes(value) {
        const text = String(value || "")
        const pieces = text.split("–")
        if (pieces.length < 2)
            return 0
        function toMinutes(v) {
            const pair = String(v).trim().split(":")
            if (pair.length !== 2)
                return 0
            return Number(pair[0]) * 60 + Number(pair[1])
        }
        const start = toMinutes(pieces[0])
        const end = toMinutes(pieces[1])
        return end > start ? end - start : 0
    }

    function sortedTasks(source) {
        const copy = source.slice()
        copy.sort((a, b) => {
            const at = String(a.time || "99:99").slice(0, 5)
            const bt = String(b.time || "99:99").slice(0, 5)
            if (at !== bt)
                return at.localeCompare(bt)
            return String(a.title || "").localeCompare(String(b.title || ""))
        })
        return copy
    }

    function formatDateLabel() {
        const dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return dayNames[root.now.getDay()] + ", "
            + root.monthNames[root.now.getMonth()].slice(0, 3)
            + " " + root.now.getDate()
    }

    function formatDuration(minutes) {
        const hours = Math.floor(minutes / 60)
        const mins = minutes % 60
        if (hours <= 0)
            return mins + "m"
        if (mins === 0)
            return hours + "h"
        return hours + "h " + mins + "m"
    }

    function categoryColor(category) {
        switch (category) {
        case "Work": return "#EAF1FF"
        case "Health": return "#E6F7F4"
        case "Personal": return "#F1EBFF"
        case "Home": return "#EAF7EC"
        default: return "#F0F3F6"
        }
    }

    function categoryTextColor(category) {
        switch (category) {
        case "Work": return "#486CC6"
        case "Health": return "#3E877F"
        case "Personal": return "#7A62B2"
        case "Home": return "#4E8358"
        default: return "#65717D"
        }
    }

    function priorityColor(priority) {
        switch (priority) {
        case "High": return "#E97883"
        case "Medium": return "#E3AA55"
        default: return "#7DA1E8"
        }
    }

    function defaultTasks() {
        return [
            {
                id: Date.now() + 1,
                title: "Finish AGAZ website updates",
                date: root.todayKey,
                time: "09:00 – 11:00",
                category: "Work",
                priority: "High",
                notes: "",
                completed: true
            },
            {
                id: Date.now() + 2,
                title: "Review project documentation",
                date: root.todayKey,
                time: "11:30 – 12:30",
                category: "Work",
                priority: "Medium",
                notes: "",
                completed: false
            },
            {
                id: Date.now() + 3,
                title: "Workout",
                date: root.todayKey,
                time: "16:00 – 17:00",
                category: "Health",
                priority: "Medium",
                notes: "",
                completed: false
            },
            {
                id: Date.now() + 4,
                title: "Read a book",
                date: root.todayKey,
                time: "19:00 – 20:00",
                category: "Personal",
                priority: "Low",
                notes: "",
                completed: false
            },
            {
                id: Date.now() + 5,
                title: "Plan tomorrow's tasks",
                date: root.todayKey,
                time: "20:00 – 20:30",
                category: "Personal",
                priority: "Medium",
                notes: "",
                completed: false
            },
            {
                id: Date.now() + 6,
                title: "Learn something new",
                date: root.todayKey,
                time: "21:00 – 22:00",
                category: "Personal",
                priority: "Low",
                notes: "",
                completed: false
            },
            {
                id: Date.now() + 7,
                title: "Clean room",
                date: root.todayKey,
                time: "22:30 – 23:00",
                category: "Home",
                priority: "Low",
                notes: "",
                completed: false
            }
        ]
    }

    function normalizeTask(task, fallbackId) {
        return {
            id: Number(task.id) || fallbackId,
            title: String(task.title || "").trim(),
            date: String(task.date || root.todayKey),
            time: String(task.time || ""),
            category: String(task.category || "Personal"),
            priority: String(task.priority || "Medium"),
            notes: String(task.notes || ""),
            completed: Boolean(task.completed)
        }
    }

    function initializeState() {
        if (root.storageReady)
            return
        root.storageReady = true
        root.tasks = root.defaultTasks()
        root.completedExpanded = false
        root.widgetWidth = 1040
        root.widgetHeight = 690
        root.widgetX = -1
        root.widgetY = 54
        root.saveState()
    }

    function loadState() {
        if (root.storageReady)
            return
        try {
            const parsed = JSON.parse(storage.text())
            const loaded = Array.isArray(parsed.tasks)
                ? parsed.tasks.map((task, index) =>
                    root.normalizeTask(task, Date.now() + index))
                : []
            root.tasks = loaded.filter(task => task.title.length > 0)
            root.completedExpanded = Boolean(parsed.completedExpanded)
            root.widgetWidth = Math.max(860, Number(parsed.width) || 1040)
            root.widgetHeight = Math.max(600, Number(parsed.height) || 690)
            root.widgetX = Number.isFinite(Number(parsed.x)) ? Number(parsed.x) : -1
            root.widgetY = Number.isFinite(Number(parsed.y)) ? Number(parsed.y) : 54
            root.storageReady = true
            root.clampGeometry()
        } catch (error) {
            root.initializeState()
        }
    }

    function saveState() {
        if (!root.storageReady)
            return
        storage.setText(JSON.stringify({
            version: 3,
            tasks: root.tasks,
            completedExpanded: root.completedExpanded,
            x: root.widgetX,
            y: root.widgetY,
            width: root.widgetWidth,
            height: root.widgetHeight
        }))
    }

    function clamp(value, minimum, maximum) {
        return Math.min(maximum, Math.max(minimum, value))
    }

    function clampGeometry() {
        if (!root.modelData)
            return
        const maxWidth = Math.max(860, root.width - 24)
        const maxHeight = Math.max(600, root.height - 24)
        root.widgetWidth = Math.round(root.clamp(
            root.widgetWidth, 860, Math.min(1160, maxWidth)))
        root.widgetHeight = Math.round(root.clamp(
            root.widgetHeight, 600, Math.min(780, maxHeight)))
        if (root.widgetX < 0)
            root.widgetX = Math.max(16, root.width - root.widgetWidth - 24)
        root.widgetX = root.clamp(
            root.widgetX, 10, Math.max(10, root.width - root.widgetWidth - 10))
        root.widgetY = root.clamp(
            root.widgetY, 10, Math.max(10, root.height - root.widgetHeight - 10))
    }

    function updateTask(taskId, changes) {
        root.tasks = root.tasks.map(task =>
            task.id === taskId ? Object.assign({}, task, changes) : task)
        root.saveState()
        analyticsRing.requestPaint()
    }

    function toggleTask(taskId) {
        const found = root.tasks.find(task => task.id === taskId)
        if (!found)
            return
        root.menuTaskId = -1
        root.updateTask(taskId, { completed: !found.completed })
    }

    function deleteTask(taskId) {
        root.menuTaskId = -1
        root.tasks = root.tasks.filter(task => task.id !== taskId)
        root.saveState()
        analyticsRing.requestPaint()
    }

    function openNewTask() {
        root.optionsOpen = false
        root.menuTaskId = -1
        root.editingTaskId = -1
        root.editorCategory = "Personal"
        root.editorPriority = "Medium"
        taskTitleField.text = ""
        taskDateInput.text = root.todayKey
        taskTimeInput.text = ""
        taskNotesInput.text = ""
        root.editorOpen = true
        Qt.callLater(() => taskTitleField.inputItem.forceActiveFocus())
    }

    function openEditTask(taskId) {
        const task = root.tasks.find(item => item.id === taskId)
        if (!task)
            return
        root.optionsOpen = false
        root.menuTaskId = -1
        root.editingTaskId = taskId
        root.editorCategory = task.category || "Personal"
        root.editorPriority = task.priority || "Medium"
        taskTitleField.text = task.title
        taskDateInput.text = task.date
        taskTimeInput.text = task.time
        taskNotesInput.text = task.notes
        root.editorOpen = true
        Qt.callLater(() => taskTitleField.inputItem.forceActiveFocus())
    }

    function saveEditor() {
        const title = taskTitleField.text.trim()
        if (!title.length)
            return

        const entry = {
            id: root.editingTaskId >= 0 ? root.editingTaskId : Date.now(),
            title: title,
            date: taskDateInput.text.trim() || root.todayKey,
            time: taskTimeInput.text.trim(),
            category: root.editorCategory,
            priority: root.editorPriority,
            notes: taskNotesInput.text,
            completed: false
        }

        if (root.editingTaskId >= 0) {
            const current = root.tasks.find(task => task.id === root.editingTaskId)
            entry.completed = current ? current.completed : false
            root.tasks = root.tasks.map(task =>
                task.id === root.editingTaskId ? entry : task)
        } else {
            root.tasks = root.tasks.concat([entry])
        }

        root.saveState()
        root.editorOpen = false
        root.editingTaskId = -1
        analyticsRing.requestPaint()
    }

    function clearCompleted() {
        root.tasks = root.tasks.filter(task => !task.completed)
        root.completedExpanded = false
        root.menuTaskId = -1
        root.optionsOpen = false
        root.saveState()
        analyticsRing.requestPaint()
    }

    function resetGeometry() {
        root.widgetWidth = 1040
        root.widgetHeight = 690
        root.widgetX = -1
        root.widgetY = 54
        root.clampGeometry()
        root.optionsOpen = false
        root.saveState()
    }

    function taskCountForDate(key) {
        return root.tasks.filter(task => task.date === key).length
    }

    function previousMonth() {
        root.monthOffset--
    }

    function nextMonth() {
        root.monthOffset++
    }

    function goToday() {
        root.monthOffset = 0
    }

    Component.onCompleted: Qt.callLater(root.clampGeometry)

    // Ambient depth behind the glass surface.
    Rectangle {
        x: surface.x + 4
        y: surface.y + 16
        width: surface.width
        height: surface.height
        radius: surface.radius + 6
        color: "#98A4B4"
        opacity: 0.10
    }

    Rectangle {
        x: surface.x + 10
        y: surface.y + 24
        width: surface.width - 20
        height: surface.height - 8
        radius: surface.radius + 8
        color: "#C8D0DA"
        opacity: 0.05
    }

    // Subtle atmospheric layer behind the panels.
    Rectangle {
        x: 0
        y: Math.max(0, root.height - 320)
        width: root.width
        height: 320
        color: "transparent"
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#F0F4F8A8" }
            GradientStop { position: 0.58; color: "#E3EAF2C2" }
            GradientStop { position: 1.0; color: "#D7E0EBCF" }
        }
        opacity: 0.65
    }

    Rectangle {
        id: surface
        x: root.widgetX
        y: root.widgetY
        width: root.widgetWidth
        height: root.widgetHeight
        radius: 28
        color: root.surfaceColor
        border.width: 1
        border.color: "#FFFFFF"
        clip: true

        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        // Drag only from the top header so text inputs and task controls stay reliable.
        DragHandler {
            target: null
            enabled: !root.editorOpen
            property real startX: 0
            property real startY: 0

            onActiveChanged: {
                if (active) {
                    startX = root.widgetX
                    startY = root.widgetY
                    root.optionsOpen = false
                    root.menuTaskId = -1
                } else {
                    root.clampGeometry()
                    root.saveState()
                }
            }

            onTranslationChanged: {
                if (!active)
                    return
                root.widgetX = startX + translation.x
                root.widgetY = startY + translation.y
                root.clampGeometry()
            }
        }

        Column {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                id: topBar
                width: parent.width
                height: 86
                color: "#FFFFFFC2"
                border.width: 0
                radius: 28

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 22
                    anchors.rightMargin: 18
                    anchors.topMargin: 14
                    anchors.bottomMargin: 14
                    spacing: 16

                    Column {
                        width: 230
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Row {
                            spacing: 8

                            Image {
                                width: 20
                                height: 20
                                source: Qt.resolvedUrl("../assets/icons/lucide-clipboard.svg")
                                fillMode: Image.PreserveAspectFit
                            }

                            Text {
                                text: "My Tasks"
                                color: root.ink
                                font.pixelSize: 19
                                font.weight: Font.DemiBold
                            }
                        }

                        Text {
                            text: "Good morning, Abraham"
                            color: root.secondary
                            font.pixelSize: 9
                        }
                    }

                    Rectangle {
                        id: weatherChip
                        width: 180
                        height: 38
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 12
                        color: root.glassSoft
                        border.width: 1
                        border.color: root.borderSoft

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Image {
                                width: 16
                                height: 16
                                anchors.verticalCenter: parent.verticalCenter
                                source: Qt.resolvedUrl("../assets/icons/lucide-sun.svg")
                                fillMode: Image.PreserveAspectFit
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1

                                Text {
                                    text: "18°C · Clear"
                                    color: root.ink
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: "Addis Ababa · Today"
                                    color: root.muted
                                    font.pixelSize: 6
                                }
                            }
                        }
                    }

                    Item { width: Math.max(1, parent.width - 660); height: 1 }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: root.formatDateLabel()
                            color: root.ink
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignRight
                        }

                        Text {
                            text: root.completedCount + " of " + root.todayTotal + " completed"
                            color: root.accent
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    Rectangle {
                        width: 34
                        height: 34
                        radius: 11
                        color: root.optionsOpen ? root.accentSoft : root.glassSoft
                        border.width: 1
                        border.color: root.borderSoft

                        Image {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            source: Qt.resolvedUrl("../assets/icons/lucide-settings.svg")
                            fillMode: Image.PreserveAspectFit
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.optionsOpen = !root.optionsOpen
                        }
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 270
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 9
                    text: "Keep the important work visible. Everything else can wait."
                    color: root.muted
                    font.pixelSize: 7
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: root.borderSoft
                opacity: 0.8
            }

            Row {
                id: mainArea
                width: parent.width
                height: parent.height - topBar.height - 1
                spacing: 0

                Rectangle {
                    id: rail
                    width: 176
                    height: parent.height
                    color: "#FFFFFF88"
                    border.width: 0

                    Column {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        anchors.topMargin: 18
                        anchors.bottomMargin: 16
                        spacing: 7

                        SidebarItem {
                            active: true
                            iconSource: "../assets/icons/house.svg"
                            label: "Home"
                            onClicked: taskFlick.contentY = 0
                        }

                        SidebarItem {
                            active: false
                            iconSource: "../assets/icons/lucide-clipboard.svg"
                            label: "My Tasks"
                            onClicked: taskFlick.contentY = 0
                        }

                        SidebarItem {
                            active: root.calendarOpen
                            iconSource: "../assets/icons/lucide-app-window.svg"
                            label: "Calendar"
                            onClicked: {
                                root.calendarOpen = !root.calendarOpen
                                root.optionsOpen = false
                            }
                        }

                        SidebarItem {
                            active: false
                            iconSource: "../assets/icons/lucide-sliders-horizontal.svg"
                            label: "Analytics"
                            onClicked: taskFlick.contentY = Math.max(
                                0, taskFlick.contentHeight - taskFlick.height)
                        }

                        SidebarItem {
                            active: root.optionsOpen
                            iconSource: "../assets/icons/lucide-settings.svg"
                            label: "Settings"
                            onClicked: {
                                root.optionsOpen = !root.optionsOpen
                                root.calendarOpen = false
                            }
                        }

                        Item { width: 1; height: 1 }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: root.borderSoft
                        }

                        Text {
                            text: "FOCUS"
                            color: root.muted
                            font.pixelSize: 6
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.2
                        }

                        Rectangle {
                            width: parent.width
                            height: 76
                            radius: 14
                            color: root.glassSoft
                            border.width: 1
                            border.color: root.borderSoft

                            Column {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 6

                                Text {
                                    text: "Today"
                                    color: root.ink
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 6
                                    radius: 3
                                    color: "#E8EDF2"

                                    Rectangle {
                                        width: parent.width * root.progress
                                        height: parent.height
                                        radius: 3
                                        color: root.accent
                                    }
                                }

                                Row {
                                    width: parent.width

                                    Text {
                                        text: root.completedCount + " done"
                                        color: root.secondary
                                        font.pixelSize: 6
                                    }

                                    Item { width: Math.max(1, parent.width - 60); height: 1 }

                                    Text {
                                        text: Math.round(root.progress * 100) + "%"
                                        color: root.accent
                                        font.pixelSize: 7
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: contentArea
                    width: parent.width - rail.width
                    height: parent.height
                    color: "transparent"

                    Column {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        anchors.topMargin: 16
                        anchors.bottomMargin: 16
                        spacing: 12

                        Row {
                            width: parent.width
                            height: 42
                            spacing: 8

                            Rectangle {
                                width: parent.width - 128
                                height: parent.height
                                radius: 12
                                color: root.glassSoft
                                border.width: 1
                                border.color: root.borderSoft

                                Image {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 15
                                    height: 15
                                    source: Qt.resolvedUrl("../assets/icons/search.svg")
                                    fillMode: Image.PreserveAspectFit
                                    opacity: 0.7
                                }

                                TextInput {
                                    id: searchInput
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 34
                                    anchors.rightMargin: 10
                                    color: root.ink
                                    font.pixelSize: 8
                                    clip: true
                                    activeFocusOnPress: true
                                    cursorVisible: true
                                    onTextChanged: root.searchText = text

                                    Text {
                                        visible: searchInput.text.length === 0
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Search tasks, notes or categories..."
                                        color: root.muted
                                        font.pixelSize: 8
                                    }
                                }
                            }

                            Rectangle {
                                width: 120
                                height: parent.height
                                radius: 12
                                color: root.accent
                                border.width: 1
                                border.color: "#6A8FEC"

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 7

                                    Image {
                                        width: 14
                                        height: 14
                                        source: Qt.resolvedUrl("../assets/icons/sparkles.svg")
                                        fillMode: Image.PreserveAspectFit
                                        opacity: 0.98
                                    }

                                    Text {
                                        text: "Add Task"
                                        color: "#FFFFFF"
                                        font.pixelSize: 8
                                        font.weight: Font.DemiBold
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.openNewTask()
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            text: "Plan with intention. Finish with momentum."
                            color: root.muted
                            font.pixelSize: 7
                        }

                        Row {
                            width: parent.width
                            height: parent.height - 84
                            spacing: 12

                            Rectangle {
                                id: todayPanel
                                width: parent.width - 292
                                height: parent.height
                                radius: 18
                                color: root.glass
                                border.width: 1
                                border.color: root.borderSoft
                                clip: true

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 10

                                    Row {
                                        width: parent.width
                                        height: 34

                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 1

                                            Text {
                                                text: "Today"
                                                color: root.ink
                                                font.pixelSize: 13
                                                font.weight: Font.DemiBold
                                            }

                                            Text {
                                                text: root.todayTotal + " scheduled tasks"
                                                color: root.muted
                                                font.pixelSize: 6
                                            }
                                        }

                                        Item { width: Math.max(1, parent.width - 330); height: 1 }

                                        Rectangle {
                                            width: 95
                                            height: 26
                                            anchors.verticalCenter: parent.verticalCenter
                                            radius: 9
                                            color: root.glassSoft
                                            border.width: 1
                                            border.color: root.borderSoft

                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 5

                                                Image {
                                                    width: 13
                                                    height: 13
                                                    source: Qt.resolvedUrl("../assets/icons/lucide-sliders-horizontal.svg")
                                                    fillMode: Image.PreserveAspectFit
                                                }

                                                Text {
                                                    text: "Priority"
                                                    color: root.secondary
                                                    font.pixelSize: 6
                                                    font.weight: Font.DemiBold
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.optionsOpen = !root.optionsOpen
                                            }
                                        }

                                        Rectangle {
                                            width: 26
                                            height: 26
                                            anchors.verticalCenter: parent.verticalCenter
                                            radius: 8
                                            color: root.glassSoft
                                            border.width: 1
                                            border.color: root.borderSoft

                                            Image {
                                                anchors.centerIn: parent
                                                width: 13
                                                height: 13
                                                source: Qt.resolvedUrl("../assets/icons/lucide-settings.svg")
                                                fillMode: Image.PreserveAspectFit
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.optionsOpen = !root.optionsOpen
                                            }
                                        }
                                    }

                                    Flickable {
                                        id: taskFlick
                                        width: parent.width
                                        height: parent.height - 44
                                        clip: true
                                        contentWidth: width
                                        contentHeight: taskColumn.height
                                        boundsBehavior: Flickable.StopAtBounds

                                        Column {
                                            id: taskColumn
                                            width: taskFlick.width
                                            spacing: 0

                                            Repeater {
                                                model: root.visibleActiveTasks
                                                delegate: TaskRow {
                                                    task: modelData
                                                    completedStyle: false
                                                }
                                            }

                                            Item {
                                                visible: root.visibleActiveTasks.length === 0
                                                width: parent.width
                                                height: Math.max(190, taskFlick.height - 26)

                                                Column {
                                                    anchors.centerIn: parent
                                                    spacing: 9

                                                    Image {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        width: 34
                                                        height: 34
                                                        source: Qt.resolvedUrl("../assets/icons/lucide-clipboard.svg")
                                                        fillMode: Image.PreserveAspectFit
                                                        opacity: 0.5
                                                    }

                                                    Text {
                                                        width: 250
                                                        text: root.searchText.trim().length > 0
                                                            ? "No matching tasks"
                                                            : "No tasks for today"
                                                        color: root.ink
                                                        font.pixelSize: 12
                                                        font.weight: Font.DemiBold
                                                        horizontalAlignment: Text.AlignHCenter
                                                    }

                                                    Text {
                                                        width: 250
                                                        text: root.searchText.trim().length > 0
                                                            ? "Try another search."
                                                            : "Add a task to build your day."
                                                        color: root.muted
                                                        font.pixelSize: 8
                                                        horizontalAlignment: Text.AlignHCenter
                                                    }

                                                    Rectangle {
                                                        width: 112
                                                        height: 32
                                                        radius: 10
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        color: root.accent
                                                        border.width: 1
                                                        border.color: "#6A8FEC"

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: "Add your first task"
                                                            color: "#FFFFFF"
                                                            font.pixelSize: 7
                                                            font.weight: Font.DemiBold
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: root.openNewTask()
                                                        }
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                visible: root.completedCount > 0
                                                width: parent.width
                                                height: 38
                                                radius: 10
                                                color: root.glassSubtle
                                                border.width: 1
                                                border.color: root.borderSoft

                                                Row {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 10
                                                    anchors.rightMargin: 8
                                                    spacing: 7

                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: root.completedExpanded ? "⌄" : "›"
                                                        color: root.secondary
                                                        font.pixelSize: 12
                                                    }

                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: "Completed (" + root.completedCount + ")"
                                                        color: root.ink
                                                        font.pixelSize: 7
                                                        font.weight: Font.DemiBold
                                                    }

                                                    Item { width: Math.max(1, parent.width - 195); height: 1 }

                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: root.completedExpanded ? "Hide" : "Show"
                                                        color: root.muted
                                                        font.pixelSize: 6
                                                    }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.completedExpanded = !root.completedExpanded
                                                }
                                            }

                                            Repeater {
                                                model: root.completedExpanded ? root.completedTasks : []
                                                delegate: TaskRow {
                                                    task: modelData
                                                    completedStyle: true
                                                }
                                            }
                                        }

                                        Rectangle {
                                            visible: taskFlick.contentHeight > taskFlick.height
                                            width: 3
                                            height: Math.max(
                                                28,
                                                taskFlick.height * taskFlick.height /
                                                Math.max(taskFlick.contentHeight, 1))
                                            x: parent.width - 3
                                            y: Math.min(
                                                taskFlick.height - height,
                                                taskFlick.contentY *
                                                (taskFlick.height - height) /
                                                Math.max(taskFlick.contentHeight - taskFlick.height, 1))
                                            radius: 2
                                            color: "#9CA9B6"
                                            opacity: 0.5
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: rightColumn
                                width: 280
                                height: parent.height
                                radius: 18
                                color: root.glass
                                border.width: 1
                                border.color: root.borderSoft
                                clip: true

                                Flickable {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    clip: true
                                    contentWidth: width
                                    contentHeight: rightContent.height
                                    boundsBehavior: Flickable.StopAtBounds

                                    Column {
                                        id: rightContent
                                        width: parent.width
                                        spacing: 10

                                        Row {
                                            width: parent.width
                                            height: 30

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: root.displayedMonthTitle
                                                color: root.ink
                                                font.pixelSize: 10
                                                font.weight: Font.DemiBold
                                            }

                                            Item { width: Math.max(1, parent.width - 110); height: 1 }

                                            CalendarButton {
                                                iconText: "‹"
                                                onTriggered: root.previousMonth()
                                            }

                                            CalendarButton {
                                                iconText: "›"
                                                onTriggered: root.nextMonth()
                                            }
                                        }

                                        Row {
                                            width: parent.width
                                            height: 18
                                            spacing: 1

                                            Repeater {
                                                model: ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
                                                delegate: Text {
                                                    required property string modelData
                                                    width: (parent.width - 6) / 7
                                                    text: modelData
                                                    color: root.muted
                                                    font.pixelSize: 5
                                                    horizontalAlignment: Text.AlignHCenter
                                                }
                                            }
                                        }

                                        Grid {
                                            width: parent.width
                                            columns: 7
                                            rows: 6
                                            rowSpacing: 2
                                            columnSpacing: 1

                                            Repeater {
                                                model: root.calendarCells

                                                delegate: Rectangle {
                                                    required property var modelData
                                                    width: (parent.width - 6) / 7
                                                    height: 24
                                                    radius: 7
                                                    color: modelData.monthOffset === 0
                                                        && modelData.key === root.todayKey
                                                        ? root.accentSoft
                                                        : "transparent"
                                                    border.width: modelData.monthOffset === 0
                                                        && modelData.key === root.todayKey ? 1 : 0
                                                    border.color: "#D3DDFC"

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: modelData.day
                                                        color: modelData.monthOffset !== 0
                                                            ? "#BCC5CE"
                                                            : modelData.key === root.todayKey
                                                                ? root.accent
                                                                : root.secondary
                                                        font.pixelSize: 6
                                                        font.weight: modelData.key === root.todayKey
                                                            ? Font.DemiBold
                                                            : Font.Normal
                                                    }

                                                    Rectangle {
                                                        visible: modelData.key.length > 0
                                                            && root.taskCountForDate(modelData.key) > 0
                                                        width: 3
                                                        height: 3
                                                        radius: 1.5
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        anchors.bottom: parent.bottom
                                                        anchors.bottomMargin: 3
                                                        color: modelData.key === root.todayKey
                                                            ? root.accent
                                                            : "#A8B6C4"
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            if (modelData.monthOffset === 0)
                                                                root.calendarOpen = true
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: parent.width
                                            height: 1
                                            color: root.borderSoft
                                        }

                                        Text {
                                            text: "THIS WEEK"
                                            color: root.muted
                                            font.pixelSize: 6
                                            font.weight: Font.DemiBold
                                            font.letterSpacing: 1.2
                                        }

                                        Column {
                                            width: parent.width
                                            spacing: 0

                                            Repeater {
                                                model: root.activeTasks.slice(0, 5)
                                                delegate: TimelineItem {
                                                    task: modelData
                                                }
                                            }

                                            Item {
                                                visible: root.activeTasks.length === 0
                                                width: parent.width
                                                height: 48

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "No scheduled tasks"
                                                    color: root.muted
                                                    font.pixelSize: 7
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: parent.width
                                            height: 66
                                            radius: 13
                                            color: root.glassSoft
                                            border.width: 1
                                            border.color: root.borderSoft

                                            Row {
                                                anchors.fill: parent
                                                anchors.margins: 9
                                                spacing: 12

                                                Canvas {
                                                    id: analyticsRing
                                                    width: 48
                                                    height: 48
                                                    anchors.verticalCenter: parent.verticalCenter

                                                    onPaint: {
                                                        const ctx = getContext("2d")
                                                        ctx.reset()
                                                        const center = 24
                                                        const radius = 18
                                                        ctx.lineWidth = 5
                                                        ctx.strokeStyle = "#E6EBF0"
                                                        ctx.beginPath()
                                                        ctx.arc(center, center, radius, 0, Math.PI * 2)
                                                        ctx.stroke()

                                                        ctx.strokeStyle = root.accent
                                                        ctx.beginPath()
                                                        ctx.arc(
                                                            center,
                                                            center,
                                                            radius,
                                                            -Math.PI / 2,
                                                            -Math.PI / 2 + Math.PI * 2 * root.progress)
                                                        ctx.stroke()
                                                    }

                                                    Component.onCompleted: requestPaint()
                                                }

                                                Column {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    spacing: 2

                                                    Text {
                                                        text: "Today's focus"
                                                        color: root.secondary
                                                        font.pixelSize: 6
                                                    }

                                                    Text {
                                                        text: root.formatDuration(root.totalFocusMinutes)
                                                        color: root.ink
                                                        font.pixelSize: 13
                                                        font.weight: Font.DemiBold
                                                    }

                                                    Text {
                                                        text: Math.round(root.progress * 100) + "% complete"
                                                        color: root.accent
                                                        font.pixelSize: 6
                                                    }
                                                }
                                            }

                                        Text {
                                            text: "ANALYTICS"
                                            color: root.muted
                                            font.pixelSize: 6
                                            font.weight: Font.DemiBold
                                            font.letterSpacing: 1.2
                                        }

                                        Row {
                                            width: parent.width
                                            height: 84
                                            spacing: 7

                                            AnalyticsStat {
                                                width: (parent.width - 14) / 3
                                                label: "Focus"
                                                value: root.formatDuration(root.totalFocusMinutes)
                                                iconSource: "../assets/icons/lucide-sun.svg"
                                            }

                                            AnalyticsStat {
                                                width: (parent.width - 14) / 3
                                                label: "Done"
                                                value: String(root.weekTasksDone)
                                                iconSource: "../assets/icons/lucide-clipboard.svg"
                                            }

                                            AnalyticsStat {
                                                width: (parent.width - 14) / 3
                                                label: "Streak"
                                                value: String(root.streakDays) + "d"
                                                iconSource: "../assets/icons/sparkles.svg"
                                            }
                                        }

                                        Rectangle {
                                            width: parent.width
                                            height: 92
                                            radius: 13
                                            color: root.glassSoft
                                            border.width: 1
                                            border.color: root.borderSoft

                                            Column {
                                                anchors.fill: parent
                                                anchors.margins: 9
                                                spacing: 5

                                                Row {
                                                    width: parent.width
                                                    height: 16

                                                    Text {
                                                        text: "This Week"
                                                        color: root.ink
                                                        font.pixelSize: 7
                                                        font.weight: Font.DemiBold
                                                    }

                                                    Item { width: Math.max(1, parent.width - 85); height: 1 }

                                                    Text {
                                                        text: root.weekTasksDone + " done"
                                                        color: root.accent
                                                        font.pixelSize: 6
                                                        font.weight: Font.DemiBold
                                                    }
                                                }

                                                Row {
                                                    width: parent.width
                                                    height: 56
                                                    spacing: 5

                                                    Repeater {
                                                        model: root.weeklySample

                                                        delegate: Item {
                                                            required property int modelData
                                                            width: (parent.width - 30) / 7
                                                            height: parent.height

                                                            Rectangle {
                                                                width: 9
                                                                height: Math.max(6, parent.height * modelData / 7)
                                                                anchors.horizontalCenter: parent.horizontalCenter
                                                                anchors.bottom: parent.bottom
                                                                radius: 4
                                                                color: root.accent
                                                                opacity: 0.28 + (modelData / 10)
                                                            }

                                                            Text {
                                                                anchors.horizontalCenter: parent.horizontalCenter
                                                                anchors.bottom: parent.bottom
                                                                anchors.bottomMargin: -13
                                                                text: root.weekdayShort[index]
                                                                color: root.muted
                                                                font.pixelSize: 5
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: optionsMenu
            visible: root.optionsOpen && !root.editorOpen
            z: 150
            width: 176
            height: 116
            x: surface.width - width - 18
            y: 72
            radius: 13
            color: "#FFFFFFFF"
            border.width: 1
            border.color: root.border
            opacity: 0.98

            Column {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 2

                MenuEntry {
                    label: "Clear completed"
                    onTriggered: root.clearCompleted()
                }

                MenuEntry {
                    label: "Today"
                    onTriggered: root.goToday()
                }

                MenuEntry {
                    label: "Reset position & size"
                    onTriggered: root.resetGeometry()
                }
            }
        }

        Rectangle {
            id: editorOverlay
            anchors.fill: parent
            visible: root.editorOpen
            z: 200
            color: "#FFFFFFF7"

            Column {
                anchors.fill: parent
                anchors.margins: 26
                spacing: 12

                Row {
                    width: parent.width
                    height: 36

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: root.editingTaskId >= 0 ? "Edit task" : "Create a task"
                            color: root.ink
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.editingTaskId >= 0
                                ? "Update the details and keep your schedule clear."
                                : "Add something meaningful to your day."
                            color: root.muted
                            font.pixelSize: 7
                        }
                    }

                    Item { width: Math.max(1, parent.width - 230); height: 1 }

                    Rectangle {
                        width: 34
                        height: 34
                        radius: 11
                        color: root.glassSoft
                        border.width: 1
                        border.color: root.borderSoft

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: root.secondary
                            font.pixelSize: 18
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.editorOpen = false
                        }
                    }
                }

                Flickable {
                    width: parent.width
                    height: parent.height - 98
                    clip: true
                    contentWidth: width
                    contentHeight: formColumn.height

                    Column {
                        id: formColumn
                        width: parent.width
                        spacing: 10

                        FormLabel { text: "TASK NAME" }

                        FormField {
                            id: taskTitleField
                            height: 46
                            placeholder: "What needs to be done?"
                        }

                        Row {
                            width: parent.width
                            spacing: 10

                            Column {
                                width: (parent.width - 10) / 2
                                spacing: 8

                                FormLabel { text: "DATE" }

                                InputField {
                                    id: taskDateInput
                                }
                            }

                            Column {
                                width: (parent.width - 10) / 2
                                spacing: 8

                                FormLabel { text: "TIME" }

                                InputField {
                                    id: taskTimeInput
                                }
                            }
                        }

                        FormLabel { text: "CATEGORY" }

                        Flow {
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: ["Work", "Health", "Personal", "Home", "Other"]

                                delegate: ChoicePill {
                                    required property string modelData
                                    label: modelData
                                    selected: root.editorCategory === modelData
                                    onTriggered: root.editorCategory = modelData
                                }
                            }
                        }

                        FormLabel { text: "PRIORITY" }

                        Flow {
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: ["Low", "Medium", "High"]

                                delegate: ChoicePill {
                                    required property string modelData
                                    label: modelData
                                    selected: root.editorPriority === modelData
                                    onTriggered: root.editorPriority = modelData
                                }
                            }
                        }

                        FormLabel { text: "NOTES" }

                        Rectangle {
                            width: parent.width
                            height: 104
                            radius: 12
                            color: "#FFFFFFFF"
                            border.width: 1
                            border.color: taskNotesInput.activeFocus ? "#B9CAF8" : root.borderSoft

                            TextEdit {
                                id: taskNotesInput
                                anchors.fill: parent
                                anchors.margins: 11
                                color: root.ink
                                font.pixelSize: 8
                                wrapMode: TextEdit.Wrap
                                activeFocusOnPress: true
                                cursorVisible: true

                                Text {
                                    visible: taskNotesInput.text.length === 0
                                    text: "Optional notes..."
                                    color: root.muted
                                    font.pixelSize: 8
                                }
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    height: 42
                    spacing: 8

                    ButtonSurface {
                        width: (parent.width - 8) / 2
                        label: "Cancel"
                        active: false
                        onTriggered: root.editorOpen = false
                    }

                    ButtonSurface {
                        width: (parent.width - 8) / 2
                        label: root.editingTaskId >= 0 ? "Save changes" : "Create task"
                        active: true
                        enabled: taskTitleField.text.trim().length > 0
                        onTriggered: root.saveEditor()
                    }
                }
            }
        }

        Rectangle {
            id: resizeHandle
            z: 220
            width: 20
            height: 20
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 4
            anchors.bottomMargin: 4
            color: "transparent"

            Image {
                anchors.centerIn: parent
                width: 12
                height: 12
                source: Qt.resolvedUrl("../assets/icons/lucide-crop.svg")
                fillMode: Image.PreserveAspectFit
                opacity: 0.45
            }

            DragHandler {
                target: null
                property real startWidth: 0
                property real startHeight: 0

                onActiveChanged: {
                    if (active) {
                        startWidth = root.widgetWidth
                        startHeight = root.widgetHeight
                    } else {
                        root.clampGeometry()
                        root.saveState()
                    }
                }

                onTranslationChanged: {
                    if (!active)
                        return
                    root.widgetWidth = startWidth + translation.x
                    root.widgetHeight = startHeight + translation.y
                    root.clampGeometry()
                }
            }
        }
    }

    component SidebarItem: Rectangle {
        required property bool active
        required property string iconSource
        required property string label
        signal clicked()

        width: parent.width
        height: 42
        radius: 11
        color: active ? "#EEF3FF" : "transparent"
        border.width: active ? 1 : 0
        border.color: "#D7E1FB"

        Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 11

            Image {
                anchors.verticalCenter: parent.verticalCenter
                width: 17
                height: 17
                source: Qt.resolvedUrl(iconSource)
                fillMode: Image.PreserveAspectFit
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: label
                color: active ? root.ink : root.secondary
                font.pixelSize: 8
                font.weight: active ? Font.DemiBold : Font.Normal
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component TaskRow: Item {
        required property var task
        required property bool completedStyle

        width: taskColumn.width
        height: 74
        opacity: completedStyle ? 0.55 : 1

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: root.borderSoft
        }

        Rectangle {
            width: 4
            height: 34
            radius: 2
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: root.priorityColor(task.priority)
            opacity: completedStyle ? 0.45 : 0.95
        }

        Rectangle {
            id: checkbox
            z: 4
            width: 20
            height: 20
            radius: 7
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            color: task.completed ? root.accent : "#FFFFFFFF"
            border.width: 1
            border.color: task.completed ? root.accent : "#C3CBD4"

            Text {
                visible: task.completed
                anchors.centerIn: parent
                text: "✓"
                color: "#FFFFFF"
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleTask(task.id)
            }
        }

        Column {
            anchors.left: checkbox.right
            anchors.leftMargin: 11
            anchors.right: rowMenu.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Row {
                width: parent.width
                spacing: 7

                Text {
                    width: Math.max(80, parent.width - 96)
                    text: task.title
                    color: root.ink
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                CategoryPill {
                    category: task.category
                }
            }

            Text {
                text: task.time || "No time set"
                color: root.secondary
                font.pixelSize: 6
            }
        }

        Rectangle {
            width: 7
            height: 7
            radius: 3.5
            anchors.right: rowMenu.left
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            color: root.priorityColor(task.priority)
            opacity: 0.92
        }

        Rectangle {
            id: rowMenu
            z: 4
            width: 28
            height: 28
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            radius: 9
            color: root.glassSoft
            border.width: 1
            border.color: root.borderSoft

            Column {
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                    model: 3
                    delegate: Rectangle {
                        width: 3
                        height: 3
                        radius: 1.5
                        color: root.secondary
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.optionsOpen = false
                    root.menuTaskId = root.menuTaskId === task.id ? -1 : task.id
                }
            }

            Rectangle {
                visible: root.menuTaskId === task.id
                z: 30
                width: 118
                height: 74
                anchors.right: parent.right
                anchors.top: parent.bottom
                anchors.topMargin: 4
                radius: 11
                color: "#FFFFFFFF"
                border.width: 1
                border.color: root.border

                Column {
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 1

                    MenuEntry {
                        label: "Edit"
                        onTriggered: root.openEditTask(task.id)
                    }

                    MenuEntry {
                        label: "Delete"
                        danger: true
                        onTriggered: root.deleteTask(task.id)
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            z: 1
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openEditTask(task.id)
        }
    }

    component CategoryPill: Rectangle {
        required property string category

        height: 18
        width: categoryText.implicitWidth + 15
        radius: 8
        color: root.categoryColor(category)
        border.width: 1
        border.color: "#FFFFFF"

        Text {
            id: categoryText
            anchors.centerIn: parent
            text: category
            color: root.categoryTextColor(category)
            font.pixelSize: 5.5
            font.weight: Font.DemiBold
        }
    }

    component TimelineItem: Item {
        required property var task

        width: parent.width
        height: 43

        Rectangle {
            width: 2
            height: parent.height - 6
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 3
            radius: 1
            color: root.priorityColor(task.priority)
            opacity: 0.7
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 9
            anchors.top: parent.top
            anchors.topMargin: 3
            text: String(task.time || "—").split(" – ")[0]
            color: root.secondary
            font.pixelSize: 6
            width: 38
        }

        Rectangle {
            width: 6
            height: 6
            radius: 3
            anchors.left: parent.left
            anchors.leftMargin: 49
            anchors.top: parent.top
            anchors.topMargin: 6
            color: root.priorityColor(task.priority)
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 64
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 1
            spacing: 2

            Text {
                width: parent.width
                text: task.title
                color: root.ink
                font.pixelSize: 6.5
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                text: task.category + " · " + task.time
                color: root.muted
                font.pixelSize: 5.5
                elide: Text.ElideRight
                width: parent.width
            }
        }
    }

    component CalendarButton: Rectangle {
        required property string iconText
        signal triggered()

        width: 24
        height: 24
        radius: 8
        color: root.glassSoft
        border.width: 1
        border.color: root.borderSoft

        Text {
            anchors.centerIn: parent
            text: iconText
            color: root.secondary
            font.pixelSize: 11
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.triggered()
        }
    }

    component AnalyticsStat: Rectangle {
        required property string label
        required property string value
        required property string iconSource

        height: 78
        radius: 12
        color: root.glassSoft
        border.width: 1
        border.color: root.borderSoft

        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 7

            Image {
                width: 13
                height: 13
                source: Qt.resolvedUrl(iconSource)
                fillMode: Image.PreserveAspectFit
                opacity: 0.72
            }

            Text {
                text: value
                color: root.ink
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }

            Text {
                text: label
                color: root.muted
                font.pixelSize: 5.5
            }
        }
    }

    component MenuEntry: Rectangle {
        required property string label
        property bool danger: false
        signal triggered()

        width: parent.width
        height: 31
        radius: 8
        color: hover.containsMouse
            ? (danger ? "#FFF1F3" : "#F4F6F8")
            : "transparent"

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 8
            text: label
            color: danger ? root.danger : root.ink
            font.pixelSize: 7
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.triggered()
        }
    }

    component FormLabel: Text {
        color: root.secondary
        font.pixelSize: 6
        font.weight: Font.DemiBold
        font.letterSpacing: 0.9
    }

    component ChoicePill: Rectangle {
        required property string label
        required property bool selected
        signal triggered()

        width: label === "Medium" ? 78 : 65
        height: 30
        radius: 10
        color: selected ? root.accentSoft : "#FFFFFFFF"
        border.width: 1
        border.color: selected ? "#CAD6FA" : root.borderSoft

        Text {
            anchors.centerIn: parent
            text: label
            color: selected ? root.accent : root.secondary
            font.pixelSize: 7
            font.weight: Font.DemiBold
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.triggered()
        }
    }

    component ButtonSurface: Rectangle {
        required property string label
        required property bool active
        signal triggered()

        height: 42
        radius: 11
        color: active ? root.accent : "#FFFFFFFF"
        border.width: 1
        border.color: active ? "#6A8FEC" : root.borderSoft
        opacity: enabled ? 1 : 0.5

        Text {
            anchors.centerIn: parent
            text: label
            color: active ? "#FFFFFF" : root.secondary
            font.pixelSize: 8
            font.weight: Font.DemiBold
        }

        MouseArea {
            anchors.fill: parent
            enabled: parent.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.triggered()
        }
    }

    component FormField: Rectangle {
        property alias text: inputProxy.text
        property alias inputItem: inputProxy
        required property string placeholder

        width: parent.width
        height: 46
        radius: 12
        color: "#FFFFFFFF"
        border.width: 1
        border.color: inputProxy.activeFocus ? "#B9CAF8" : root.borderSoft

        Text {
            visible: inputProxy.text.length === 0
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 11
            text: parent.placeholder
            color: root.muted
            font.pixelSize: 8
        }

        TextInput {
            id: inputProxy
            anchors.fill: parent
            anchors.leftMargin: 11
            anchors.rightMargin: 9
            verticalAlignment: TextInput.AlignVCenter
            activeFocusOnPress: true
            cursorVisible: true
            color: root.ink
            font.pixelSize: 8
        }
    }

    component InputField: Rectangle {
        property alias text: inputProxy.text

        width: parent.width
        height: 42
        radius: 11
        color: "#FFFFFFFF"
        border.width: 1
        border.color: inputProxy.activeFocus ? "#B9CAF8" : root.borderSoft

        TextInput {
            id: inputProxy
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            verticalAlignment: TextInput.AlignVCenter
            activeFocusOnPress: true
            cursorVisible: true
            color: root.ink
            font.pixelSize: 8
        }
    }
}
