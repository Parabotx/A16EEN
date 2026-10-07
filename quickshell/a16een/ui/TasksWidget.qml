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
    property bool completedExpanded: false
    property int menuTaskId: -1

    property bool editorOpen: false
    property int editingTaskId: -1
    property string editorCategory: "Personal"
    property string editorPriority: "Medium"

    property bool optionsOpen: false
    property bool storageReady: false

    property int widgetWidth: 370
    property int widgetHeight: 510
    property real widgetX: -1
    property real widgetY: 84

    readonly property color surfaceColor: "#F7FAFCEA"
    readonly property color surfaceBorder: "#D8E0E8"
    readonly property color textColor: "#18212B"
    readonly property color secondaryColor: "#687585"
    readonly property color mutedColor: "#99A4B0"
    readonly property color accentColor: "#4A8FE7"
    readonly property color fieldColor: "#FDFEFF"

    readonly property string todayKey: root.dateKey(root.now)
    readonly property var activeTasks: root.sortedTasks(root.tasks.filter(task =>
        task.date === root.todayKey && !task.completed))
    readonly property var completedTasks: root.sortedTasks(root.tasks.filter(task =>
        task.date === root.todayKey && task.completed))
    readonly property int todayTotal: root.activeTasks.length + root.completedTasks.length
    readonly property int completedCount: root.completedTasks.length
    readonly property real progress:
        root.todayTotal > 0 ? root.completedCount / root.todayTotal : 0

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

    function sortTasks(source) {
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
                completed: false
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
        root.widgetX = -1
        root.widgetY = 84
        root.widgetWidth = 370
        root.widgetHeight = 510
        root.saveState()
    }

    function loadState() {
        if (root.storageReady)
            return

        try {
            const parsed = JSON.parse(storage.text())
            const loadedTasks = Array.isArray(parsed.tasks)
                ? parsed.tasks.map((task, index) =>
                    root.normalizeTask(task, Date.now() + index))
                : []

            root.tasks = loadedTasks.filter(task => task.title.length > 0)
            root.completedExpanded = Boolean(parsed.completedExpanded)
            root.widgetX = Number.isFinite(Number(parsed.x)) ? Number(parsed.x) : -1
            root.widgetY = Number.isFinite(Number(parsed.y)) ? Number(parsed.y) : 84
            root.widgetWidth = Math.max(320, Number(parsed.width) || 370)
            root.widgetHeight = Math.max(420, Number(parsed.height) || 510)
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
            version: 1,
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

        const maxWidth = Math.max(320, root.width - 24)
        const maxHeight = Math.max(420, root.height - 24)

        root.widgetWidth = Math.round(root.clamp(root.widgetWidth, 320, Math.min(520, maxWidth)))
        root.widgetHeight = Math.round(root.clamp(root.widgetHeight, 420, Math.min(700, maxHeight)))

        const fallbackX = Math.max(12, root.width - root.widgetWidth - 22)
        if (root.widgetX < 0)
            root.widgetX = fallbackX

        root.widgetX = root.clamp(root.widgetX, 8, Math.max(8, root.width - root.widgetWidth - 8))
        root.widgetY = root.clamp(root.widgetY, 8, Math.max(8, root.height - root.widgetHeight - 8))
    }

    function updateTask(taskId, changes) {
        const next = root.tasks.map(task => {
            if (task.id !== taskId)
                return task
            return Object.assign({}, task, changes)
        })
        root.tasks = next
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
        taskTitleInput.text = ""
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

        taskTitleInput.text = task.title
        taskDateInput.text = task.date
        taskTimeInput.text = task.time
        taskNotesInput.text = task.notes

        root.editorOpen = true
        Qt.callLater(() => taskTitleInput.forceActiveFocus())
    }

    function saveEditor() {
        const title = taskTitleInput.text.trim()
        if (!title.length)
            return

        const entry = {
            title: title,
            date: taskDateInput.text.trim() || root.todayKey,
            time: taskTimeInput.text.trim(),
            category: root.editorCategory,
            priority: root.editorPriority,
            notes: taskNotesInput.text,
            completed: false
        }

        if (root.editingTaskId >= 0) {
            const existing = root.tasks.find(task => task.id === root.editingTaskId)
            entry.id = root.editingTaskId
            entry.completed = existing ? existing.completed : false
            root.tasks = root.tasks.map(task =>
                task.id === root.editingTaskId ? entry : task)
        } else {
            entry.id = Date.now()
            root.tasks = root.tasks.concat([entry])
        }

        root.saveState()
        root.editorOpen = false
        root.editingTaskId = -1
    }

    function clearCompleted() {
        root.tasks = root.tasks.filter(task => !task.completed)
        root.menuTaskId = -1
        root.completedExpanded = false
        root.optionsOpen = false
        root.saveState()
    }

    function resetGeometry() {
        root.widgetWidth = 370
        root.widgetHeight = 510
        root.widgetX = -1
        root.widgetY = 84
        root.clampGeometry()
        root.optionsOpen = false
        root.saveState()
    }

    Component.onCompleted: Qt.callLater(root.clampGeometry)

    Rectangle {
        id: widgetShadow

        x: surface.x + 2
        y: surface.y + 10
        width: surface.width
        height: surface.height
        radius: surface.radius + 2
        color: "#152231"
        opacity: 0.10
    }

    Rectangle {
        id: surface

        x: root.widgetX
        y: root.widgetY
        width: root.widgetWidth
        height: root.widgetHeight
        radius: 22
        color: root.surfaceColor
        border.width: 1
        border.color: root.surfaceBorder
        clip: true

        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        DragHandler {
            id: moveHandler
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
            opacity: 0.12
        }

        Column {
            anchors.fill: parent
            spacing: 0

            Item {
                id: header
                width: parent.width
                height: 68

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        text: "Tasks"
                        color: root.textColor
                        font.pixelSize: 19
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: "Stay on track"
                        color: root.secondaryColor
                        font.pixelSize: 9
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Rectangle {
                        width: 30
                        height: 30
                        radius: 10
                        color: root.optionsOpen ? "#EAF3FF" : "#FFFFFFB8"
                        border.width: 1
                        border.color: root.optionsOpen ? "#C8DCF5" : "#E2E8EE"

                        Text {
                            anchors.centerIn: parent
                            text: "⋯"
                            color: root.optionsOpen ? root.accentColor : root.secondaryColor
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.optionsOpen = !root.optionsOpen
                                root.menuTaskId = -1
                            }
                        }
                    }

                    Rectangle {
                        width: 30
                        height: 30
                        radius: 10
                        color: "#EAF3FF"
                        border.width: 1
                        border.color: "#C9DDF6"

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            color: root.accentColor
                            font.pixelSize: 18
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
                width: parent.width - 36
                height: 1
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#DDE4EA"
            }

            Item {
                width: parent.width
                height: parent.height - header.height - footer.height - 1

                Flickable {
                    id: taskFlick
                    anchors.fill: parent
                    anchors.topMargin: 6
                    anchors.bottomMargin: 8
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    clip: true
                    contentWidth: width
                    contentHeight: taskColumn.height + 8
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: taskColumn
                        width: taskFlick.width
                        spacing: 4

                        Rectangle {
                            visible: root.todayTotal === 0
                            width: parent.width
                            height: 120
                            radius: 14
                            color: "#FFFFFF90"
                            border.width: 1
                            border.color: "#E2E8EE"

                            Column {
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Nothing planned for today"
                                    color: root.textColor
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Use + to add your first task."
                                    color: root.secondaryColor
                                    font.pixelSize: 8
                                }
                            }
                        }

                        Repeater {
                            model: root.activeTasks
                            delegate: TaskRow {
                                task: modelData
                                completedStyle: false
                            }
                        }

                        Item {
                            width: parent.width
                            height: 9
                        }

                        Rectangle {
                            width: parent.width
                            height: 34
                            radius: 10
                            color: "#FFFFFF70"
                            border.width: 1
                            border.color: "#E0E7ED"

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 11
                                anchors.rightMargin: 9
                                spacing: 7

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.completedExpanded ? "⌄" : "›"
                                    color: root.secondaryColor
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Completed"
                                    color: root.textColor
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.completedCount
                                    color: root.mutedColor
                                    font.pixelSize: 8
                                }

                                Item { width: Math.max(1, parent.width - 160); height: 1 }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.completedExpanded ? "Hide" : "Show"
                                    color: root.secondaryColor
                                    font.pixelSize: 7
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.completedExpanded = !root.completedExpanded
                                    root.saveState()
                                }
                            }
                        }

                        Repeater {
                            model: root.completedExpanded ? root.completedTasks : []
                            delegate: TaskRow {
                                task: modelData
                                completedStyle: true
                            }
                        }

                        Item {
                            width: parent.width
                            height: 6
                        }
                    }

                    Rectangle {
                        visible: taskFlick.contentHeight > taskFlick.height
                        width: 3
                        height: Math.max(26,
                            taskFlick.height * taskFlick.height
                            / Math.max(taskFlick.contentHeight, 1))
                        x: parent.width - 4
                        y: Math.min(taskFlick.height - height,
                            taskFlick.contentY
                            * (taskFlick.height - height)
                            / Math.max(taskFlick.contentHeight - taskFlick.height, 1))
                        radius: 2
                        color: "#C9D2DC"
                        opacity: 0.75
                    }
                }
            }

            Rectangle {
                id: footer
                width: parent.width
                height: 74
                color: "#FFFFFF55"
                border.width: 1
                border.color: "#E3E9EF"
                clip: true

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16
                    spacing: 7

                    Row {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: root.completedCount + " of " + root.todayTotal + " completed"
                            color: root.secondaryColor
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                        }

                        Item { width: Math.max(1, parent.width - 145); height: 1 }

                        Text {
                            text: root.todayTotal === 0 ? "TODAY" : "TODAY"
                            color: root.mutedColor
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1
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
                            color: root.accentColor

                            Behavior on width {
                                NumberAnimation {
                                    duration: 180
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: resizeHandle
                    width: 18
                    height: 18
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 3
                    anchors.bottomMargin: 3
                    radius: 5
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "⌟"
                        color: "#9BA7B4"
                        font.pixelSize: 10
                    }

                    DragHandler {
                        id: resizeHandler
                        target: null
                        property real startWidth: 0
                        property real startHeight: 0

                        onActiveChanged: {
                            if (active) {
                                startWidth = root.widgetWidth
                                startHeight = root.widgetHeight
                                root.optionsOpen = false
                                root.menuTaskId = -1
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
        }

        Rectangle {
            id: optionsMenu
            visible: root.optionsOpen && !root.editorOpen
            z: 20
            width: 196
            height: 92
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 49
            anchors.rightMargin: 12
            radius: 13
            color: "#FFFFFFF7"
            border.width: 1
            border.color: "#D8E0E8"

            Column {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 2

                Rectangle {
                    width: parent.width
                    height: 38
                    radius: 9
                    color: clearCompletedMouse.containsMouse ? "#F0F4F8" : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 9
                        text: "Clear completed"
                        color: root.textColor
                        font.pixelSize: 8
                    }

                    MouseArea {
                        id: clearCompletedMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clearCompleted()
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 38
                    radius: 9
                    color: resetGeometryMouse.containsMouse ? "#F0F4F8" : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 9
                        text: "Reset position & size"
                        color: root.textColor
                        font.pixelSize: 8
                    }

                    MouseArea {
                        id: resetGeometryMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.resetGeometry()
                    }
                }
            }
        }

        Rectangle {
            id: editorOverlay
            anchors.fill: parent
            visible: root.editorOpen
            z: 40
            color: "#F7FAFCF7"

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: parent.radius
                color: "#FFFFFF"
                opacity: 0.75
            }

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Row {
                    width: parent.width
                    height: 30

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.editingTaskId >= 0 ? "Edit task" : "New task"
                        color: root.textColor
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }

                    Item { width: Math.max(1, parent.width - 112); height: 1 }

                    Rectangle {
                        width: 30
                        height: 30
                        radius: 10
                        color: "#F1F4F7"

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: root.secondaryColor
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
                    id: formFlick
                    width: parent.width
                    height: parent.height - 86
                    clip: true
                    contentWidth: width
                    contentHeight: formColumn.height + 8

                    Column {
                        id: formColumn
                        width: formFlick.width
                        spacing: 8

                        Text {
                            text: "Task name"
                            color: root.secondaryColor
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                        }

                        Rectangle {
                            width: parent.width
                            height: 38
                            radius: 11
                            color: root.fieldColor
                            border.width: 1
                            border.color: taskTitleInput.activeFocus ? "#BBD4F2" : "#DEE5EB"

                            Text {
                                visible: taskTitleInput.text.length === 0
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 11
                                text: "What needs to be done?"
                                color: "#A9B2BC"
                                font.pixelSize: 8
                            }

                            TextInput {
                                id: taskTitleInput
                                anchors.fill: parent
                                anchors.leftMargin: 11
                                anchors.rightMargin: 9
                                verticalAlignment: TextInput.AlignVCenter
                                color: root.textColor
                                font.pixelSize: 9
                                clip: true
                            }
                        }

                        Text {
                            text: "Date"
                            color: root.secondaryColor
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                        }

                        Rectangle {
                            width: parent.width
                            height: 34
                            radius: 10
                            color: root.fieldColor
                            border.width: 1
                            border.color: taskDateInput.activeFocus ? "#BBD4F2" : "#DEE5EB"

                            Text {
                                visible: taskDateInput.text.length === 0
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 10
                                text: "YYYY-MM-DD"
                                color: "#A9B2BC"
                                font.pixelSize: 8
                            }

                            TextInput {
                                id: taskDateInput
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 9
                                verticalAlignment: TextInput.AlignVCenter
                                color: root.textColor
                                font.pixelSize: 8
                            }
                        }

                        Text {
                            text: "Time"
                            color: root.secondaryColor
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                        }

                        Rectangle {
                            width: parent.width
                            height: 34
                            radius: 10
                            color: root.fieldColor
                            border.width: 1
                            border.color: taskTimeInput.activeFocus ? "#BBD4F2" : "#DEE5EB"

                            Text {
                                visible: taskTimeInput.text.length === 0
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 10
                                text: "09:00 or 09:00 – 11:00"
                                color: "#A9B2BC"
                                font.pixelSize: 8
                            }

                            TextInput {
                                id: taskTimeInput
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 9
                                verticalAlignment: TextInput.AlignVCenter
                                color: root.textColor
                                font.pixelSize: 8
                            }
                        }

                        Text {
                            text: "Category"
                            color: root.secondaryColor
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                        }

                        Flow {
                            width: parent.width
                            spacing: 5

                            Repeater {
                                model: ["Work", "Health", "Personal", "Other"]
                                delegate: Rectangle {
                                    required property string modelData
                                    width: 66
                                    height: 28
                                    radius: 9
                                    color: root.editorCategory === modelData ? "#EAF3FF" : "#F7F9FB"
                                    border.width: 1
                                    border.color: root.editorCategory === modelData ? "#C9DDF6" : "#E0E6EC"

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: root.editorCategory === modelData ? root.accentColor : root.secondaryColor
                                        font.pixelSize: 7
                                        font.weight: Font.DemiBold
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.editorCategory = modelData
                                    }
                                }
                            }
                        }

                        Text {
                            text: "Priority"
                            color: root.secondaryColor
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                        }

                        Flow {
                            width: parent.width
                            spacing: 5

                            Repeater {
                                model: ["Low", "Medium", "High"]
                                delegate: Rectangle {
                                    required property string modelData
                                    width: 74
                                    height: 28
                                    radius: 9
                                    color: root.editorPriority === modelData ? "#EAF3FF" : "#F7F9FB"
                                    border.width: 1
                                    border.color: root.editorPriority === modelData ? "#C9DDF6" : "#E0E6EC"

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: root.editorPriority === modelData ? root.accentColor : root.secondaryColor
                                        font.pixelSize: 7
                                        font.weight: Font.DemiBold
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.editorPriority = modelData
                                    }
                                }
                            }
                        }

                        Text {
                            text: "Notes"
                            color: root.secondaryColor
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                        }

                        Rectangle {
                            width: parent.width
                            height: 72
                            radius: 10
                            color: root.fieldColor
                            border.width: 1
                            border.color: taskNotesInput.activeFocus ? "#BBD4F2" : "#DEE5EB"

                            Text {
                                visible: taskNotesInput.text.length === 0
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.leftMargin: 10
                                anchors.topMargin: 9
                                text: "Optional notes"
                                color: "#A9B2BC"
                                font.pixelSize: 8
                            }

                            TextEdit {
                                id: taskNotesInput
                                anchors.fill: parent
                                anchors.margins: 9
                                color: root.textColor
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

                    Rectangle {
                        width: (parent.width - 7) / 2
                        height: parent.height
                        radius: 11
                        color: "#F2F5F7"
                        border.width: 1
                        border.color: "#E0E6EC"

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: root.secondaryColor
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.editorOpen = false
                        }
                    }

                    Rectangle {
                        width: (parent.width - 7) / 2
                        height: parent.height
                        radius: 11
                        color: "#EAF3FF"
                        border.width: 1
                        border.color: "#C9DDF6"
                        opacity: taskTitleInput.text.trim().length > 0 ? 1 : 0.55

                        Text {
                            anchors.centerIn: parent
                            text: root.editingTaskId >= 0 ? "Save changes" : "Save task"
                            color: root.accentColor
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: taskTitleInput.text.trim().length > 0
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.saveEditor()
                        }
                    }
                }
            }
        }
    }

    component TaskRow: Item {
        required property var task
        required property bool completedStyle

        width: taskColumn.width
        height: 58
        opacity: completedStyle ? 0.68 : 1

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: rowMouse.containsMouse ? "#FFFFFFD0" : "#FFFFFF94"
            border.width: 1
            border.color: "#E0E7ED"

            Behavior on color {
                ColorAnimation { duration: 110 }
            }

            Rectangle {
                width: 3
                height: parent.height - 20
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                radius: 2
                color: task.priority === "High"
                    ? "#D76A6A"
                    : task.priority === "Low"
                        ? "#AAB5C0"
                        : root.accentColor
                opacity: completedStyle ? 0.45 : 0.85
            }

            Rectangle {
                id: checkBox
                width: 18
                height: 18
                anchors.left: parent.left
                anchors.leftMargin: 11
                anchors.verticalCenter: parent.verticalCenter
                radius: 6
                color: task.completed ? root.accentColor : "#FFFFFF"
                border.width: 1
                border.color: task.completed ? root.accentColor : "#C8D2DC"

                Text {
                    anchors.centerIn: parent
                    visible: task.completed
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
                anchors.left: checkBox.right
                anchors.leftMargin: 10
                anchors.right: menuButton.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Row {
                    width: parent.width
                    spacing: 5

                    Text {
                        text: task.title
                        color: root.textColor
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        width: parent.width - 50
                    }

                    Text {
                        text: task.category
                        color: root.secondaryColor
                        font.pixelSize: 6
                        elide: Text.ElideRight
                        width: Math.min(50, parent.width)
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Row {
                    width: parent.width
                    spacing: 7

                    Text {
                        visible: String(task.time || "").length > 0
                        text: task.time
                        color: root.secondaryColor
                        font.pixelSize: 6
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: String(task.time || "").length > 0
                        text: "·"
                        color: root.mutedColor
                        font.pixelSize: 6
                    }

                    Text {
                        text: task.priority + " priority"
                        color: task.priority === "High" ? "#A15C5C" : root.mutedColor
                        font.pixelSize: 6
                    }
                }
            }

            Rectangle {
                id: menuButton
                width: 26
                height: 26
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                radius: 8
                color: root.menuTaskId === task.id ? "#EEF3F8" : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "⋮"
                    color: root.secondaryColor
                    font.pixelSize: 14
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
                    width: 112
                    height: 76
                    anchors.right: parent.right
                    anchors.top: parent.bottom
                    anchors.topMargin: 4
                    radius: 10
                    color: "#FFFFFFF7"
                    border.width: 1
                    border.color: "#D8E0E8"

                    Column {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 1

                        Rectangle {
                            width: parent.width
                            height: 31
                            radius: 7
                            color: editTaskMouse.containsMouse ? "#F0F4F8" : "transparent"

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 8
                                text: "Edit"
                                color: root.textColor
                                font.pixelSize: 7
                            }

                            MouseArea {
                                id: editTaskMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openEditTask(task.id)
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 31
                            radius: 7
                            color: deleteTaskMouse.containsMouse ? "#F8EEEE" : "transparent"

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 8
                                text: "Delete"
                                color: "#A45D5D"
                                font.pixelSize: 7
                            }

                            MouseArea {
                                id: deleteTaskMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.deleteTask(task.id)
                            }
                        }
                    }
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                z: -1
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openEditTask(task.id)
            }
        }

        Rectangle {
            visible: completedStyle
            anchors.left: checkBox.left
            anchors.right: menuButton.left
            anchors.verticalCenter: parent.verticalCenter
            height: 1
            color: "#B8C2CC"
            opacity: 0.7
        }
    }
}
