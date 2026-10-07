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

    property int widgetWidth: 860
    property int widgetHeight: 580
    property real widgetX: -1
    property real widgetY: 84

    readonly property color glass: "#FFFFFFFF"
    readonly property color glassStrong: "#FFFFFFFF"
    readonly property color glassSoft: "#FFFFFFFF"
    readonly property color glassPanel: "#FFFFFFFF"
    readonly property color border: "#D7DEE6"
    readonly property color borderSoft: "#E3E8ED"
    readonly property color ink: "#18212B"
    readonly property color secondary: "#637181"
    readonly property color muted: "#8D99A7"
    readonly property color accent: "#3E8BEA"
    readonly property color accentSoft: "#F3F5F7"
    readonly property color canvas: "#FFFFFF"
    readonly property color danger: "#B86161"

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

    readonly property var calendarCells: {
        const first = new Date(root.now.getFullYear(), root.now.getMonth(), 1)
        const startIndex = (first.getDay() + 6) % 7
        const daysInMonth = new Date(root.now.getFullYear(), root.now.getMonth() + 1, 0).getDate()
        const daysInPrevious = new Date(root.now.getFullYear(), root.now.getMonth(), 0).getDate()
        const cells = []

        for (let i = 0; i < 35; i++) {
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
                cells.push({
                    day: day,
                    monthOffset: 0,
                    key: root.rootDateKey(day)
                })
            }
        }

        return cells
    }

    readonly property string monthTitle:
        root.monthNames[root.now.getMonth()] + " " + root.now.getFullYear()

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]

    readonly property var weekdayNames: ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]

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

    function rootDateKey(day) {
        return root.now.getFullYear()
            + "-" + root.pad(root.now.getMonth() + 1)
            + "-" + root.pad(day)
    }

    function formatDateLabel() {
        const dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return dayNames[root.now.getDay()]
            + ", "
            + root.monthNames[root.now.getMonth()].slice(0, 3)
            + " "
            + root.now.getDate()
    }

    function sortedTasks(source) {
        const copy = source.slice()
        copy.sort((a, b) => {
            const at = String(a.time || "99:99").slice(0, 5)
            const bt = String(b.time || "99:99").slice(0, 5)
            if (at !== bt) return at.localeCompare(bt)
            return String(a.title || "").localeCompare(String(b.title || ""))
        })
        return copy
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
        if (root.storageReady) return

        root.storageReady = true
        root.tasks = root.defaultTasks()
        root.completedExpanded = false
        root.widgetWidth = 860
        root.widgetHeight = 580
        root.widgetX = -1
        root.widgetY = 84
        root.saveState()
    }

    function loadState() {
        if (root.storageReady) return

        try {
            const parsed = JSON.parse(storage.text())
            const loaded = Array.isArray(parsed.tasks)
                ? parsed.tasks.map((task, index) =>
                    root.normalizeTask(task, Date.now() + index))
                : []

            root.tasks = loaded.filter(task => task.title.length > 0)
            root.completedExpanded = Boolean(parsed.completedExpanded)
            root.widgetWidth = Math.max(660, Number(parsed.width) || 860)
            root.widgetHeight = Math.max(480, Number(parsed.height) || 580)
            root.widgetX = Number.isFinite(Number(parsed.x)) ? Number(parsed.x) : -1
            root.widgetY = Number.isFinite(Number(parsed.y)) ? Number(parsed.y) : 84
            root.storageReady = true
            root.clampGeometry()
        } catch (error) {
            root.initializeState()
        }
    }

    function saveState() {
        if (!root.storageReady) return

        storage.setText(JSON.stringify({
            version: 2,
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
        if (!root.modelData) return

        const maxWidth = Math.max(660, root.width - 24)
        const maxHeight = Math.max(480, root.height - 24)

        root.widgetWidth = Math.round(root.clamp(
            root.widgetWidth, 660, Math.min(1080, maxWidth)))
        root.widgetHeight = Math.round(root.clamp(
            root.widgetHeight, 480, Math.min(760, maxHeight)))

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
    }

    function toggleTask(taskId) {
        const found = root.tasks.find(task => task.id === taskId)
        if (!found) return
        root.menuTaskId = -1
        root.updateTask(taskId, { completed: !found.completed })
    }

    function deleteTask(taskId) {
        root.menuTaskId = -1
        root.tasks = root.tasks.filter(task => task.id !== taskId)
        root.saveState()
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
        Qt.callLater(() => taskTitleInput.forceActiveFocus())
    }

    function openEditTask(taskId) {
        const task = root.tasks.find(item => item.id === taskId)
        if (!task) return

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
        Qt.callLater(() => taskTitleInput.forceActiveFocus())
    }

    function saveEditor() {
        const title = taskTitleField.text.trim()
        if (!title.length) return

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
    }

    function clearCompleted() {
        root.tasks = root.tasks.filter(task => !task.completed)
        root.completedExpanded = false
        root.menuTaskId = -1
        root.optionsOpen = false
        root.saveState()
    }

    function resetGeometry() {
        root.widgetWidth = 860
        root.widgetHeight = 580
        root.widgetX = -1
        root.widgetY = 84
        root.clampGeometry()
        root.optionsOpen = false
        root.saveState()
    }

    function taskCountForDate(key) {
        return root.tasks.filter(task => task.date === key).length
    }

    Component.onCompleted: Qt.callLater(root.clampGeometry)

    Rectangle {
        id: shadow
        x: surface.x + 3
        y: surface.y + 12
        width: surface.width
        height: surface.height
        radius: surface.radius + 3
        color: "#24303D"
        opacity: 0.08
    }

    Rectangle {
        id: surface
        x: root.widgetX
        y: root.widgetY
        width: root.widgetWidth
        height: root.widgetHeight
        radius: 24
        color: root.glass
        border.width: 1
        border.color: root.border
        clip: true

        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

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
                if (!active) return
                root.widgetX = startX + translation.x
                root.widgetY = startY + translation.y
                root.clampGeometry()
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#FFFFFF"
            opacity: 0.18
        }

        Row {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                id: rail
                width: 148
                height: parent.height
                color: "#FFFFFFFF"
                border.width: 1
                border.color: "#FFFFFFFF"

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    Item {
                        width: parent.width
                        height: 74

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10

                            Rectangle {
                                width: 34
                                height: 34
                                radius: 11
                                color: root.accentSoft
                                border.width: 1
                                border.color: "#D5E7FA"

                                Text {
                                    anchors.centerIn: parent
                                    text: "✓"
                                    color: root.accent
                                    font.pixelSize: 18
                                    font.weight: Font.DemiBold
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: "My Tasks"
                                    color: root.ink
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: "Plan. Focus. Get it done."
                                    color: root.secondary
                                    font.pixelSize: 6
                                }
                            }
                        }
                    }

                    NavItem {
                        active: true
                        icon: "⌂"
                        label: "Home"
                        onClicked: taskFlick.contentY = 0
                    }

                    NavItem {
                        active: false
                        icon: "✓"
                        label: "My Tasks"
                        onClicked: taskFlick.contentY = 0
                    }

                    NavItem {
                        active: root.calendarOpen
                        icon: "▦"
                        label: "Calendar"
                        onClicked: {
                            root.calendarOpen = !root.calendarOpen
                            root.optionsOpen = false
                        }
                    }

                    NavItem {
                        active: false
                        icon: "⚙"
                        label: "Settings"
                        onClicked: {
                            root.optionsOpen = !root.optionsOpen
                            root.calendarOpen = false
                        }
                    }

                    Item { width: 1; height: 1 }
                }
            }

            Rectangle {
                id: workspace
                width: parent.width - rail.width
                height: parent.height
                color: "#FFFFFFFF"

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 10

                    Row {
                        width: parent.width
                        height: 58

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: "Good morning,"
                                color: root.secondary
                                font.pixelSize: 8
                            }

                            Text {
                                text: "My Tasks"
                                color: root.ink
                                font.pixelSize: 21
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "You have " + root.todayTotal + " tasks today."
                                color: root.secondary
                                font.pixelSize: 7
                            }
                        }

                        Item { width: Math.max(1, parent.width - 285); height: 1 }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Text {
                                text: root.formatDateLabel()
                                color: root.secondary
                                font.pixelSize: 7
                                horizontalAlignment: Text.AlignRight
                            }

                            Text {
                                text: root.completedCount + " completed"
                                color: root.accent
                                font.pixelSize: 7
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 38
                        spacing: 7

                        Rectangle {
                            width: parent.width - 124
                            height: parent.height
                            radius: 12
                            color: root.glassSoft
                            border.width: 1
                            border.color: root.borderSoft

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 11
                                text: "⌕"
                                color: root.muted
                                font.pixelSize: 13
                            }

                            TextInput {
                                id: searchInput
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 30
                                anchors.rightMargin: 10
                                color: root.ink
                                font.pixelSize: 8
                                clip: true
                                onTextChanged: root.searchText = text

                                Text {
                                    visible: searchInput.text.length === 0
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Search tasks..."
                                    color: "#A3ADB8"
                                    font.pixelSize: 8
                                }
                            }
                        }

                        Rectangle {
                            width: 117
                            height: parent.height
                            radius: 12
                            color: root.accentSoft
                            border.width: 1
                            border.color: "#CADFF7"

                            Row {
                                anchors.centerIn: parent
                                spacing: 7

                                Text {
                                    text: "+"
                                    color: root.accent
                                    font.pixelSize: 17
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: "Add Task"
                                    color: root.accent
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

                    Row {
                        width: parent.width
                        height: parent.height - 106
                        spacing: 10

                        Rectangle {
                            id: todayPanel
                            width: parent.width - 214
                            height: parent.height
                            radius: 16
                            color: root.glassPanel
                            border.width: 1
                            border.color: root.borderSoft
                            clip: true

                            Column {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                Row {
                                    width: parent.width
                                    height: 34

                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 8

                                        Rectangle {
                                            width: 28
                                            height: 28
                                            radius: 9
                                            color: "#FFFFFFFF"
                                            border.width: 1
                                            border.color: root.borderSoft

                                            Text {
                                                anchors.centerIn: parent
                                                text: "▦"
                                                color: root.accent
                                                font.pixelSize: 12
                                            }
                                        }

                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 1

                                            Text {
                                                text: "Today"
                                                color: root.ink
                                                font.pixelSize: 11
                                                font.weight: Font.DemiBold
                                            }

                                            Text {
                                                text: root.todayTotal + " tasks"
                                                color: root.muted
                                                font.pixelSize: 6
                                            }
                                        }
                                    }

                                    Item {
                                        width: Math.max(1, parent.width - 160)
                                        height: 1
                                    }

                                    Rectangle {
                                        width: 94
                                        height: 27
                                        anchors.verticalCenter: parent.verticalCenter
                                        radius: 9
                                        color: "#FFFFFFFF"
                                        border.width: 1
                                        border.color: root.borderSoft

                                        Text {
                                            anchors.centerIn: parent
                                            text: "PRIORITY  ˅"
                                            color: root.secondary
                                            font.pixelSize: 6
                                            font.weight: Font.DemiBold
                                            font.letterSpacing: 0.5
                                        }
                                    }

                                    Rectangle {
                                        width: 27
                                        height: 27
                                        anchors.verticalCenter: parent.verticalCenter
                                        radius: 9
                                        color: "#FFFFFFFF"
                                        border.width: 1
                                        border.color: root.borderSoft

                                        Text {
                                            anchors.centerIn: parent
                                            text: "☷"
                                            color: root.secondary
                                            font.pixelSize: 11
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
                                    height: parent.height - 42
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

                                        Rectangle {
                                            visible: root.completedCount > 0
                                            width: parent.width
                                            height: 36
                                            radius: 10
                                            color: "#FFFFFFFF"
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
                                                    font.pixelSize: 13
                                                }

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: "Completed (" + root.completedCount + ")"
                                                    color: root.ink
                                                    font.pixelSize: 7
                                                    font.weight: Font.DemiBold
                                                }

                                                Item { width: Math.max(1, parent.width - 190); height: 1 }

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: root.completedExpanded ? "Hide" : "Show"
                                                    color: root.secondary
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
                                            24,
                                            taskFlick.height * taskFlick.height /
                                            Math.max(taskFlick.contentHeight, 1))
                                        x: parent.width - 3
                                        y: Math.min(
                                            taskFlick.height - height,
                                            taskFlick.contentY *
                                            (taskFlick.height - height) /
                                            Math.max(taskFlick.contentHeight - taskFlick.height, 1))
                                        radius: 2
                                        color: "#A8B3BE"
                                        opacity: 0.55
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: sidePanel
                            width: 204
                            height: parent.height
                            radius: 16
                            color: "#FFFFFFFF"
                            border.width: 1
                            border.color: root.borderSoft
                            clip: true

                            Column {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                Row {
                                    width: parent.width
                                    height: 28

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.monthTitle
                                        color: root.ink
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                    }

                                    Item { width: Math.max(1, parent.width - 105); height: 1 }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "‹   ›"
                                        color: root.secondary
                                        font.pixelSize: 10
                                    }
                                }

                                Row {
                                    width: parent.width
                                    height: 16
                                    spacing: 1

                                    Repeater {
                                        model: root.weekdayNames
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
                                    rows: 5
                                    rowSpacing: 4
                                    columnSpacing: 1

                                    Repeater {
                                        model: root.calendarCells
                                        delegate: Rectangle {
                                            required property var modelData
                                            width: (parent.width - 6) / 7
                                            height: 29
                                            radius: 8
                                            color: modelData.monthOffset === 0
                                                && modelData.key === root.todayKey
                                                ? root.accentSoft
                                                : "transparent"
                                            border.width: modelData.monthOffset === 0
                                                && modelData.key === root.todayKey ? 1 : 0
                                            border.color: "#CFE1F5"

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.top: parent.top
                                                anchors.topMargin: 5
                                                text: modelData.day
                                                color: modelData.monthOffset !== 0
                                                    ? "#B6C0CB"
                                                    : modelData.key === root.todayKey
                                                        ? root.accent
                                                        : root.secondary
                                                font.pixelSize: 7
                                                font.weight: modelData.key === root.todayKey
                                                    ? Font.DemiBold
                                                    : Font.Normal
                                            }

                                            Rectangle {
                                                visible: modelData.key.length > 0
                                                    && root.taskCountForDate(modelData.key) > 0
                                                width: 4
                                                height: 4
                                                radius: 2
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.bottom: parent.bottom
                                                anchors.bottomMargin: 4
                                                color: modelData.key === root.todayKey
                                                    ? root.accent
                                                    : "#AAB8C7"
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
                                    text: "TODAY"
                                    color: root.muted
                                    font.pixelSize: 6
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 1.2
                                }

                                Repeater {
                                    model: root.activeTasks.slice(0, 4)
                                    delegate: TimelineItem {
                                        task: modelData
                                    }
                                }

                                Item { width: 1; height: Math.max(1, parent.height - 344) }

                                Rectangle {
                                    width: parent.width
                                    height: 58
                                    radius: 12
                                    color: "#FFFFFFFF"
                                    border.width: 1
                                    border.color: root.borderSoft

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 9
                                        spacing: 6

                                        Row {
                                            width: parent.width
                                            spacing: 5

                                            Text {
                                                text: "Task progress"
                                                color: root.secondary
                                                font.pixelSize: 6
                                            }

                                            Item { width: Math.max(1, parent.width - 70); height: 1 }

                                            Text {
                                                text: root.completedCount + " / " + root.todayTotal
                                                color: root.ink
                                                font.pixelSize: 8
                                                font.weight: Font.DemiBold
                                            }
                                        }

                                        Rectangle {
                                            width: parent.width
                                            height: 4
                                            radius: 2
                                            color: "#E2E8EE"

                                            Rectangle {
                                                width: parent.width * root.progress
                                                height: parent.height
                                                radius: 2
                                                color: root.accent

                                                Behavior on width {
                                                    NumberAnimation {
                                                        duration: 180
                                                        easing.type: Easing.OutCubic
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 34
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.completedCount + " of " + root.todayTotal + " completed"
                            color: root.secondary
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                        }

                        Rectangle {
                            width: parent.width - 210
                            height: 5
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 3
                            color: "#E0E6EC"

                            Rectangle {
                                width: parent.width * root.progress
                                height: parent.height
                                radius: 3
                                color: root.accent

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "TODAY"
                            color: root.muted
                            font.pixelSize: 6
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.1
                        }
                    }
                }
            }
        }

        Rectangle {
            id: optionsMenu
            visible: root.optionsOpen && !root.editorOpen
            z: 80
            width: 166
            height: 82
            x: surface.width - width - 64
            y: 58
            radius: 12
            color: root.glassStrong
            border.width: 1
            border.color: root.border

            Column {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 1

                MenuEntry {
                    label: "Clear completed"
                    onTriggered: root.clearCompleted()
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
            z: 100
            color: "#F8FAFCEB"

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 10

                Row {
                    width: parent.width
                    height: 32

                    Text {
                        text: root.editingTaskId >= 0 ? "Edit task" : "New task"
                        color: root.ink
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                    }

                    Item { width: Math.max(1, parent.width - 140); height: 1 }

                    Rectangle {
                        width: 30
                        height: 30
                        radius: 10
                        color: "#FFFFFF"
                        border.width: 1
                        border.color: root.borderSoft

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: root.secondary
                            font.pixelSize: 16
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
                    height: parent.height - 88
                    clip: true
                    contentWidth: width
                    contentHeight: formColumn.height

                    Column {
                        id: formColumn
                        width: parent.width
                        spacing: 9

                        FormLabel { text: "TASK NAME" }

                        FormField {
                            id: taskTitleField
                            height: 38
                            placeholder: "What needs to be done?"
                        }

                        FormLabel { text: "DATE" }

                        Rectangle {
                            width: parent.width
                            height: 34
                            radius: 10
                            color: "#FFFFFFFF"
                            border.width: 1
                            border.color: taskDateInput.activeFocus ? "#BBD4F2" : root.borderSoft

                            TextInput {
                                id: taskDateInput
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 8
                                verticalAlignment: TextInput.AlignVCenter
                                color: root.ink
                                font.pixelSize: 8
                            }
                        }

                        FormLabel { text: "TIME" }

                        Rectangle {
                            width: parent.width
                            height: 34
                            radius: 10
                            color: "#FFFFFFFF"
                            border.width: 1
                            border.color: taskTimeInput.activeFocus ? "#BBD4F2" : root.borderSoft

                            TextInput {
                                id: taskTimeInput
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 8
                                verticalAlignment: TextInput.AlignVCenter
                                color: root.ink
                                font.pixelSize: 8
                            }
                        }

                        FormLabel { text: "CATEGORY" }

                        Flow {
                            width: parent.width
                            spacing: 5

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
                            spacing: 5

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
                            height: 76
                            radius: 10
                            color: "#FFFFFFFF"
                            border.width: 1
                            border.color: taskNotesInput.activeFocus ? "#BBD4F2" : root.borderSoft

                            TextEdit {
                                id: taskNotesInput
                                anchors.fill: parent
                                anchors.margins: 9
                                color: root.ink
                                font.pixelSize: 8
                                wrapMode: TextEdit.Wrap
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    height: 38
                    spacing: 7

                    ButtonSurface {
                        width: (parent.width - 7) / 2
                        label: "Cancel"
                        active: false
                        onTriggered: root.editorOpen = false
                    }

                    ButtonSurface {
                        width: (parent.width - 7) / 2
                        label: root.editingTaskId >= 0 ? "Save changes" : "Save task"
                        active: true
                        enabled: taskTitleField.text.trim().length > 0
                        onTriggered: root.saveEditor()
                    }
                }
            }
        }

        Rectangle {
            id: resizeHandle
            z: 120
            width: 18
            height: 18
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 3
            anchors.bottomMargin: 3
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: "⌟"
                color: "#9DA8B4"
                font.pixelSize: 10
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
                    if (!active) return
                    root.widgetWidth = startWidth + translation.x
                    root.widgetHeight = startHeight + translation.y
                    root.clampGeometry()
                }
            }
        }
    }

    component NavItem: Rectangle {
        required property bool active
        required property string icon
        required property string label
        signal clicked()

        width: parent.width
        height: 38
        radius: 10
        color: active ? root.accentSoft : "transparent"
        border.width: active ? 1 : 0
        border.color: "#CFE2F7"

        Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            spacing: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: icon
                color: active ? root.accent : root.secondary
                font.pixelSize: 12
                width: 15
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: label
                color: active ? root.accent : root.secondary
                font.pixelSize: 8
                font.weight: active ? Font.DemiBold : Font.Normal
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component TaskRow: Item {
        required property var task
        required property bool completedStyle

        width: taskColumn.width
        height: 64
        opacity: completedStyle ? 0.58 : 1

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            Rectangle {
                width: 1
                height: parent.height
                anchors.left: parent.left
                color: root.borderSoft
            }

            Rectangle {
                width: 3
                height: 31
                radius: 2
                anchors.left: parent.left
                anchors.leftMargin: 0
                anchors.verticalCenter: parent.verticalCenter
                color: task.priority === "High"
                    ? "#6C7784"
                    : task.priority === "Medium"
                        ? "#9BA7B3"
                        : "#C0C8D1"
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.top: parent.top
                anchors.topMargin: 10
                text: String(task.time || "—").split(" – ")[0]
                color: root.secondary
                font.pixelSize: 6
                width: 54
            }

            Rectangle {
                id: connector
                width: 7
                height: 7
                radius: 3.5
                anchors.left: parent.left
                anchors.leftMargin: 61
                anchors.top: parent.top
                anchors.topMargin: 13
                color: task.completed ? root.accent : "#A8B4C1"
                border.width: task.completed ? 0 : 1
                border.color: "#C4CDD6"
            }

            Rectangle {
                width: 1
                height: parent.height - 25
                anchors.left: parent.left
                anchors.leftMargin: 64
                anchors.top: parent.top
                anchors.topMargin: 21
                color: root.borderSoft
            }

            Rectangle {
                id: checkbox
                z: 3
                width: 18
                height: 18
                anchors.left: parent.left
                anchors.leftMargin: 79
                anchors.top: parent.top
                anchors.topMargin: 9
                radius: 6
                color: task.completed ? root.accent : "#FFFFFFFF"
                border.width: 1
                border.color: task.completed ? root.accent : "#B9C4CF"

                Text {
                    anchors.centerIn: parent
                    visible: task.completed
                    text: "✓"
                    color: "#FFFFFF"
                    font.pixelSize: 10
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
                anchors.leftMargin: 10
                anchors.right: rowMenu.left
                anchors.rightMargin: 8
                anchors.top: parent.top
                anchors.topMargin: 8
                spacing: 4

                Row {
                    width: parent.width
                    spacing: 6

                    Text {
                        text: task.title
                        color: root.ink
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        width: Math.max(60, parent.width - 70)
                    }

                    Rectangle {
                        height: 19
                        width: categoryText.implicitWidth + 14
                        radius: 9
                        color: "#FFFFFFFF"
                        border.width: 1
                        border.color: root.borderSoft

                        Text {
                            id: categoryText
                            anchors.centerIn: parent
                            text: task.category
                            color: root.secondary
                            font.pixelSize: 6
                        }
                    }
                }

                Row {
                    spacing: 7

                    Text {
                        text: task.time
                        color: root.secondary
                        font.pixelSize: 6
                    }

                    Text {
                        text: "·"
                        color: root.muted
                        font.pixelSize: 6
                    }

                    Text {
                        text: task.priority
                        color: root.muted
                        font.pixelSize: 6
                    }
                }
            }

            Text {
                visible: task.completed
                anchors.right: rowMenu.left
                anchors.rightMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                text: "DONE"
                color: root.accent
                font.pixelSize: 5
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
            }

            Rectangle {
                id: rowMenu
                z: 3
                width: 25
                height: 25
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                radius: 8
                color: root.menuTaskId === task.id ? "#EEF3F8" : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "⋮"
                    color: root.secondary
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
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
                    width: 108
                    height: 72
                    anchors.right: parent.right
                    anchors.top: parent.bottom
                    anchors.topMargin: 4
                    radius: 10
                    color: root.glassStrong
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

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: root.borderSoft
            }
        }
    }

    component TimelineItem: Item {
        required property var task
        width: parent.width
        height: 39

        Row {
            anchors.fill: parent
            spacing: 7

            Text {
                text: String(task.time || "—").split(" – ")[0]
                color: root.secondary
                font.pixelSize: 6
                width: 32
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 5
                height: 5
                radius: 2.5
                color: root.accent
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                width: parent.width - 52

                Text {
                    width: parent.width
                    text: task.title
                    color: root.ink
                    font.pixelSize: 6
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    text: task.category
                    color: root.muted
                    font.pixelSize: 5
                }
            }
        }
    }

    component MenuEntry: Rectangle {
        required property string label
        property bool danger: false
        signal triggered()

        width: parent.width
        height: 31
        radius: 7
        color: hover.containsMouse
            ? (danger ? "#FAF0F0" : "#F1F4F7")
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
        font.letterSpacing: 0.8
    }

    component ChoicePill: Rectangle {
        required property string label
        required property bool selected
        signal triggered()

        width: label === "Medium" ? 72 : 62
        height: 28
        radius: 9
        color: selected ? root.accentSoft : "#FFFFFFFF"
        border.width: 1
        border.color: selected ? "#C9DDF6" : root.borderSoft

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

        height: 38
        radius: 10
        color: active ? root.accentSoft : "#FFFFFFFF"
        border.width: 1
        border.color: active ? "#C9DDF6" : root.borderSoft
        opacity: enabled ? 1 : 0.55

        Text {
            anchors.centerIn: parent
            text: label
            color: active ? root.accent : root.secondary
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
        required property string placeholder

        width: parent.width
        height: 38
        radius: 10
        color: "#FFFFFFFF"
        border.width: 1
        border.color: inputProxy.activeFocus ? "#BBD4F2" : root.borderSoft

        Text {
            visible: inputProxy.text.length === 0
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 10
            text: parent.placeholder
            color: "#A6B0BA"
            font.pixelSize: 8
        }

        TextInput {
            id: inputProxy
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            verticalAlignment: TextInput.AlignVCenter
            color: root.ink
            font.pixelSize: 8
        }
    }
}
