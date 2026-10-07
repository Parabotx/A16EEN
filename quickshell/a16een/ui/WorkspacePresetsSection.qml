import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

Item {
    id: root

    property bool active: false

    signal backRequested()

    property var presets: []
    property var draftApps: []
    property string draftId: ""
    property string draftName: ""
    property string statusMessage: "READY"
    property string appSearch: ""
    property bool editorOpen: false
    property bool appPickerOpen: false
    property int workspacePickerIndex: -1
    property int deleteIndex: -1
    property string openPresetId: ""

    readonly property color page: "#FFFFFF"
    readonly property color card: "#F7F8FA"
    readonly property color cardHover: "#EEF1F4"
    readonly property color border: "#E1E5EA"
    readonly property color borderStrong: "#CDD3DA"
    readonly property color textPrimary: "#111318"
    readonly property color textSecondary: "#66707C"
    readonly property color textMuted: "#8A939E"
    readonly property color accent: "#B18B3F"

    readonly property var workspaceCatalog: [
        { id: "home", name: "HOME", number: "01" },
        { id: "code", name: "CODE", number: "02" },
        { id: "web", name: "WEB", number: "03" },
        { id: "comms", name: "COMMS", number: "04" },
        { id: "studio", name: "STUDIO", number: "05" },
        { id: "music", name: "MUSIC", number: "06" }
    ]

    readonly property var applicationCatalog: {
        return [...DesktopEntries.applications.values]
            .filter(entry => entry && !entry.noDisplay)
            .sort((a, b) => (a.name || "").localeCompare(b.name || ""))
    }

    readonly property var filteredApplications: {
        const q = root.appSearch.trim().toLowerCase()
        if (!q)
            return root.applicationCatalog

        return root.applicationCatalog.filter(entry => {
            const text = [
                entry.name,
                entry.genericName,
                entry.comment,
                ...(entry.keywords || [])
            ].filter(value => value).join(" ").toLowerCase()

            return text.includes(q)
        })
    }

    function iconSource(name) {
        return Qt.resolvedUrl("../assets/icons/" + name + ".svg")
    }

    function workspaceLabel(id) {
        const item = root.workspaceCatalog.find(ws => ws.id === id)
        return item ? item.name : "HOME"
    }

    function workspaceNumber(id) {
        const item = root.workspaceCatalog.find(ws => ws.id === id)
        return item ? item.number : "01"
    }

    function cleanAppIds(entry) {
        const values = [
            entry.startupClass || "",
            entry.startupWmClass || "",
            String(entry.id || "").replace(/\.desktop$/i, ""),
            entry.command && entry.command.length
                ? String(entry.command[0] || "").split("/").pop()
                : ""
        ]

        return values
            .filter(value => value)
            .filter((value, index, all) => all.indexOf(value) === index)
    }

    function appFromEntry(entry) {
        return {
            desktopId: String(entry.id || ""),
            name: String(entry.name || "Application"),
            icon: String(entry.icon || ""),
            startupClass: String(entry.startupClass || ""),
            appIds: root.cleanAppIds(entry),
            command: [...(entry.command || [])],
            workingDirectory: String(entry.workingDirectory || ""),
            workspace: "home"
        }
    }

    function loadPresets() {
        if (!root.active || presetReader.running)
            return

        presetReader.running = true
    }

    function parsePresets(output) {
        try {
            const data = JSON.parse(String(output || "{}"))
            root.presets = Array.isArray(data.presets) ? data.presets : []
            root.statusMessage = root.presets.length
                ? root.presets.length + " PRESET" + (root.presets.length === 1 ? "" : "S") + " READY"
                : "NO PRESETS YET"
        } catch (error) {
            root.presets = []
            root.statusMessage = "PRESET STORE UNAVAILABLE"
        }
    }

    function beginAdd() {
        if (root.openProcess.running || root.saveProcess.running)
            return

        root.editorOpen = false
        root.appPickerOpen = false
        root.workspacePickerIndex = -1
        root.deleteIndex = -1
        root.draftId = ""
        root.draftName = ""
        root.draftApps = []
        root.appSearch = ""

        root.editorOpen = true
        root.appPickerOpen = false
        root.workspacePickerIndex = -1
        root.deleteIndex = -1
        root.draftId = ""
        root.draftName = ""
        root.draftApps = []
        root.appSearch = ""
        root.statusMessage = "BUILD A WORKSPACE SETUP"
        Qt.callLater(() => presetName.forceActiveFocus())
    }

    function beginEdit(preset) {
        if (!preset)
            return

        root.editorOpen = true
        root.appPickerOpen = false
        root.workspacePickerIndex = -1
        root.deleteIndex = -1
        root.draftId = String(preset.id || "")
        root.draftName = String(preset.name || "")
        root.draftApps = JSON.parse(JSON.stringify(preset.apps || []))
        root.statusMessage = "EDITING " + root.draftName.toUpperCase()
        Qt.callLater(() => presetName.forceActiveFocus())
    }

    function cancelEditor() {
        root.editorOpen = false
        root.appPickerOpen = false
        root.workspacePickerIndex = -1
        root.draftId = ""
        root.draftName = ""
        root.draftApps = []
        root.statusMessage = root.presets.length
            ? root.presets.length + " PRESET" + (root.presets.length === 1 ? "" : "S") + " READY"
            : "NO PRESETS YET"
    }

    function addApplication(entry) {
        if (!entry)
            return

        const desktopId = String(entry.id || "")
        if (root.draftApps.some(app => app.desktopId === desktopId)) {
            root.appPickerOpen = false
            root.statusMessage = "APP ALREADY ADDED"
            return
        }

        const apps = root.draftApps.concat([root.appFromEntry(entry)])
        root.draftApps = apps
        root.appPickerOpen = false
        root.workspacePickerIndex = apps.length - 1
        root.statusMessage = "CHOOSE A WORKSPACE"
    }

    function chooseWorkspace(workspaceId) {
        const index = root.workspacePickerIndex
        if (index < 0 || index >= root.draftApps.length)
            return

        root.draftApps = root.draftApps.map((app, appIndex) =>
            appIndex === index
                ? Object.assign({}, app, { workspace: workspaceId })
                : app
        )

        root.workspacePickerIndex = -1
        root.statusMessage = "APP PLACED ON " + root.workspaceLabel(workspaceId)
    }

    function removeApp(index) {
        root.draftApps = root.draftApps.filter((_, appIndex) => appIndex !== index)

        if (root.workspacePickerIndex === index)
            root.workspacePickerIndex = -1
        else if (root.workspacePickerIndex > index)
            root.workspacePickerIndex -= 1

        root.statusMessage = "APPLICATION REMOVED"
    }

    function savePayload() {
        return {
            version: 1,
            id: root.draftId,
            name: root.draftName.trim(),
            apps: root.draftApps
        }
    }

    function saveEditor() {
        if (root.saveProcess.running)
            return

        const name = root.draftName.trim()
        if (!name.length || root.draftApps.length === 0) {
            root.statusMessage = "ADD A NAME AND AT LEAST ONE APP"
            return
        }

        root.statusMessage = "SAVING PRESET"
        root.saveProcess.running = true
    }

    function openPreset(preset) {
        if (!preset || root.openProcess.running)
            return

        root.openPresetId = String(preset.id || "")
        if (!root.openPresetId.length)
            return

        root.statusMessage = "OPENING " + String(preset.name || root.openPresetId).toUpperCase()
        root.openProcess.running = true
    }

    function askDelete(index) {
        if (index < 0 || index >= root.presets.length)
            return

        root.deleteIndex = index
    }

    function confirmDelete() {
        if (root.deleteIndex < 0 || root.deleteProcess.running)
            return

        const preset = root.presets[root.deleteIndex]
        if (!preset)
            return

        root.deletePresetId = String(preset.id || "")
        root.deleteIndex = -1
        root.deleteProcess.running = true
        root.statusMessage = "REMOVING PRESET"
    }

    property string deletePresetId: ""

    Process {
        id: presetReader
        command: ["a16een-workspace-preset", "list"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.parsePresets(text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length)
                    root.statusMessage = "PRESET STORE UNAVAILABLE"
            }
        }
    }

    Process {
        id: saveProcess
        command: [
            "a16een-workspace-preset",
            "save",
            JSON.stringify(root.savePayload())
        ]
        running: false

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length)
                    root.statusMessage = "SAVE FAILED"
            }
        }

        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.editorOpen = false
                root.appPickerOpen = false
                root.workspacePickerIndex = -1
                root.statusMessage = "PRESET SAVED"
                root.draftApps = []
                root.draftId = ""
                root.draftName = ""
                root.presetReader.running = true
            } else {
                root.statusMessage = "SAVE FAILED"
            }
        }
    }

    Process {
        id: openProcess
        command: ["a16een-workspace-preset", "open", root.openPresetId]
        running: false

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length)
                    root.statusMessage = "OPEN FINISHED WITH WARNINGS"
            }
        }

        onExited: function(exitCode) {
            root.statusMessage = exitCode === 0
                ? "PRESET OPENED"
                : "PRESET OPENED WITH WARNINGS"
        }
    }

    Process {
        id: deleteProcess
        command: ["a16een-workspace-preset", "delete", root.deletePresetId]
        running: false

        onExited: function(exitCode) {
            root.statusMessage = exitCode === 0 ? "PRESET REMOVED" : "REMOVE FAILED"
            if (exitCode === 0)
                root.presetReader.running = true
        }
    }

    Component.onCompleted: root.loadPresets()

    onActiveChanged: {
        if (root.active) {
            root.statusMessage = "READING WORKSPACE PRESETS"
            root.loadPresets()
        }
    }

    Keys.onEscapePressed: {
        if (root.workspacePickerIndex >= 0) {
            root.workspacePickerIndex = -1
            return
        }

        if (root.appPickerOpen) {
            root.appPickerOpen = false
            return
        }

        if (root.deleteIndex >= 0) {
            root.deleteIndex = -1
            return
        }

        if (root.editorOpen) {
            root.cancelEditor()
            return
        }

        root.backRequested()
    }

    focus: root.active

    Item {
        anchors.fill: parent
        anchors.margins: 26

        RowLayout {
            id: header
            width: parent.width
            height: 54
            spacing: 14
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                width: 38
                height: 38
                radius: 11
                color: root.card
                border.width: 1
                border.color: root.border
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    color: root.textPrimary
                    font.pixelSize: 25
                    font.weight: Font.Light
                    y: -2
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backRequested()
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    text: root.editorOpen ? "CREATE WORKSPACE PRESET" : "WORKSPACE PRESETS"
                    color: root.textPrimary
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.0
                }

                Text {
                    text: root.editorOpen
                        ? "CHOOSE APPS • ASSIGN WORKSPACES • SAVE THE SETUP"
                        : "ONE CLICK TO OPEN A COMPLETE WORKSPACE SETUP  •  " + root.statusMessage
                    color: root.textMuted
                    font.pixelSize: 8
                    font.weight: Font.Medium
                    font.letterSpacing: 0.65
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
            }

            Rectangle {
                visible: !root.editorOpen
                width: 112
                height: 34
                radius: 10
                color: addMouse.containsMouse ? "#111318" : "#F7F8FA"
                border.width: addMouse.containsMouse ? 0 : 1
                border.color: root.borderStrong
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "+  ADD PRESET"
                    color: addMouse.containsMouse ? "#FFFFFF" : root.textPrimary
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.8
                }

                MouseArea {
                    id: addMouse
                    anchors.fill: parent
                    z: 10
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.beginAdd()
                    }
                }
            }

            Rectangle {
                visible: root.editorOpen
                width: 110
                height: 34
                radius: 10
                color: root.canSave ? (saveMouse.containsMouse ? "#111318" : "#EDE7DA") : "#F1F2F4"
                border.width: root.canSave ? 0 : 1
                border.color: root.border
                anchors.verticalCenter: parent.verticalCenter

                property bool enabled: root.canSave

                Text {
                    anchors.centerIn: parent
                    text: root.saveProcess.running ? "SAVING…" : "SAVE PRESET"
                    color: root.canSave ? (saveMouse.containsMouse ? "#FFFFFF" : root.textPrimary) : root.textMuted
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.8
                }

                MouseArea {
                    id: saveMouse
                    anchors.fill: parent
                    enabled: root.canSave
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.saveEditor()
                }
            }
        }

        Flickable {
            visible: !root.editorOpen
            anchors.top: header.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true
            contentHeight: presetColumn.height

            Column {
                id: presetColumn
                width: parent.width
                spacing: 10

                Rectangle {
                    width: parent.width
                    height: 92
                    radius: 18
                    color: "#FBFCFD"
                    border.width: 1
                    border.color: root.border

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        Text {
                            text: "WORKSPACE PRESETS"
                            color: root.textPrimary
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.1
                        }

                        Text {
                            width: parent.parent.width - 36
                            text: "Save a personal setup of applications and where each one belongs."
                            color: root.textSecondary
                            font.pixelSize: 10
                        }

                        Text {
                            text: "NO STARTUP AUTOLAUNCH • MANUAL WHEN YOU CHOOSE"
                            color: root.textMuted
                            font.pixelSize: 6
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.7
                        }
                    }
                }

                Text {
                    visible: root.presets.length === 0
                    width: parent.width
                    height: 130
                    text: "NO PRESETS SAVED\n\nChoose  + ADD PRESET  to build one."
                    color: root.textMuted
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Repeater {
                    model: root.presets

                    delegate: Rectangle {
                        width: presetColumn.width
                        height: 86
                        radius: 16
                        color: presetMouse.containsMouse ? root.cardHover : root.card
                        border.width: 1
                        border.color: root.border

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 17
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            width: parent.width - 330

                            Text {
                                text: modelData.name
                                color: root.textPrimary
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: String(modelData.apps ? modelData.apps.length : 0)
                                    + " APPS  •  "
                                    + (modelData.apps || []).map(app =>
                                        workspaceLabel(app.workspace)
                                    ).filter((value, index, values) =>
                                        values.indexOf(value) === index
                                    ).join("  /  ")
                                color: root.textSecondary
                                font.pixelSize: 7
                                font.weight: Font.Medium
                                font.letterSpacing: 0.35
                            }

                            Text {
                                text: "SAVED WORKSPACE SETUP"
                                color: root.textMuted
                                font.pixelSize: 6
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.8
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 7

                            Rectangle {
                                width: 82
                                height: 32
                                radius: 10
                                color: openMouse.containsMouse ? "#111318" : "#FFFFFF"
                                border.width: openMouse.containsMouse ? 0 : 1
                                border.color: root.borderStrong

                                Text {
                                    anchors.centerIn: parent
                                    text: openProcess.running && root.openPresetId === modelData.id
                                        ? "OPENING…"
                                        : "OPEN"
                                    color: openMouse.containsMouse ? "#FFFFFF" : root.textPrimary
                                    font.pixelSize: 7
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.7
                                }

                                MouseArea {
                                    id: openMouse
                                    anchors.fill: parent
                                    enabled: !root.openProcess.running
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.openPreset(modelData)
                                }
                            }

                            Rectangle {
                                width: 52
                                height: 32
                                radius: 10
                                color: "#FFFFFF"
                                border.width: 1
                                border.color: root.borderStrong

                                Text {
                                    anchors.centerIn: parent
                                    text: "EDIT"
                                    color: root.textPrimary
                                    font.pixelSize: 7
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.7
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !root.openProcess.running
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.beginEdit(modelData)
                                }
                            }

                            Rectangle {
                                width: 62
                                height: 32
                                radius: 10
                                color: "#FFFFFF"
                                border.width: 1
                                border.color: root.borderStrong

                                Text {
                                    anchors.centerIn: parent
                                    text: "REMOVE"
                                    color: "#8A3939"
                                    font.pixelSize: 7
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.7
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !root.openProcess.running
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.askDelete(index)
                                }
                            }
                        }

                        MouseArea {
                            id: presetMouse
                            anchors.fill: parent
                            anchors.rightMargin: 225
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }
                    }
                }
            }
        }

        Column {
            visible: root.editorOpen
            anchors.top: header.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 10

            Rectangle {
                width: parent.width
                height: 76
                radius: 17
                color: "#FBFCFD"
                border.width: 1
                border.color: root.border

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 17
                    anchors.right: parent.right
                    anchors.rightMargin: 17
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    Text {
                        text: "PRESET NAME"
                        color: root.textMuted
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.9
                    }

                    Rectangle {
                        width: parent.width
                        height: 34
                        radius: 10
                        color: "#FFFFFF"
                        border.width: presetName.activeFocus ? 1.4 : 1
                        border.color: presetName.activeFocus ? root.borderStrong : root.border

                        TextInput {
                            id: presetName
                            anchors.fill: parent
                            anchors.leftMargin: 11
                            anchors.rightMargin: 11
                            verticalAlignment: Text.AlignVCenter
                            color: root.textPrimary
                            font.pixelSize: 10
                            maximumLength: 42
                            text: root.draftName
                            selectByMouse: true

                            onTextChanged: root.draftName = text
                            Keys.onReturnPressed: root.saveEditor()
                        }
                    }
                }
            }

            Row {
                width: parent.width
                height: 38
                spacing: 8

                Rectangle {
                    width: parent.width - 118
                    height: 38
                    radius: 11
                    color: "#FBFCFD"
                    border.width: 1
                    border.color: root.border

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.draftApps.length === 0
                            ? "NO APPLICATIONS SELECTED"
                            : root.draftApps.length + " APPLICATION" + (root.draftApps.length === 1 ? "" : "S") + " SELECTED"
                        color: root.textSecondary
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.6
                    }
                }

                Rectangle {
                    width: 110
                    height: 38
                    radius: 11
                    color: addAppMouse.containsMouse ? "#111318" : "#EDE7DA"

                    Text {
                        anchors.centerIn: parent
                        text: "+  ADD APP"
                        color: addAppMouse.containsMouse ? "#FFFFFF" : root.textPrimary
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.8
                    }

                    MouseArea {
                        id: addAppMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.appSearch = ""
                            root.appPickerOpen = true
                            root.workspacePickerIndex = -1
                            Qt.callLater(() => appSearchInput.forceActiveFocus())
                        }
                    }
                }
            }

            Flickable {
                width: parent.width
                height: parent.height - 130
                clip: true
                contentHeight: appColumn.height

                Column {
                    id: appColumn
                    width: parent.width
                    spacing: 8

                    Text {
                        visible: root.draftApps.length === 0
                        width: parent.width
                        height: 120
                        text: "YOUR PRESET IS EMPTY\n\nClick  + ADD APP  to choose the applications\nyou want to launch together."
                        color: root.textMuted
                        font.pixelSize: 9
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Repeater {
                        model: root.draftApps

                        delegate: Rectangle {
                            width: appColumn.width
                            height: 68
                            radius: 14
                            color: root.card
                            border.width: 1
                            border.color: root.border

                            IconImage {
                                anchors.left: parent.left
                                anchors.leftMargin: 15
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: 30
                                implicitHeight: 30
                                source: modelData.icon
                                    ? Quickshell.iconPath(modelData.icon, "application-x-executable")
                                    : Quickshell.iconPath("application-x-executable", "application-x-executable")
                            }

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 58
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                Text {
                                    text: modelData.name
                                    color: root.textPrimary
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: "WORKSPACE  " + workspaceNumber(modelData.workspace) + "  /  " + workspaceLabel(modelData.workspace)
                                    color: root.textSecondary
                                    font.pixelSize: 6
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.55
                                }
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 55
                                anchors.verticalCenter: parent.verticalCenter
                                width: 118
                                height: 30
                                radius: 9
                                color: "#FFFFFF"
                                border.width: 1
                                border.color: root.borderStrong

                                Text {
                                    anchors.centerIn: parent
                                    text: "CHANGE WORKSPACE"
                                    color: root.textPrimary
                                    font.pixelSize: 6
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.55
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.workspacePickerIndex = index
                                        root.statusMessage = "CHOOSE A WORKSPACE"
                                    }
                                }
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                width: 32
                                height: 30
                                radius: 9
                                color: "#FFFFFF"
                                border.width: 1
                                border.color: root.borderStrong

                                Text {
                                    anchors.centerIn: parent
                                    text: "×"
                                    color: "#8A3939"
                                    font.pixelSize: 16
                                    font.weight: Font.Light
                                    y: -1
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.removeApp(index)
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            visible: root.appPickerOpen
            anchors.fill: parent
            z: 20
            color: "#52000000"

            MouseArea {
                anchors.fill: parent
                onClicked: root.appPickerOpen = false
            }

            Rectangle {
                anchors.centerIn: parent
                width: Math.min(700, parent.width - 34)
                height: Math.min(520, parent.height - 48)
                radius: 21
                color: "#FFFFFF"
                border.width: 1
                border.color: root.borderStrong

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                }

                Row {
                    x: 20
                    y: 18
                    width: parent.width - 40
                    height: 42

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 250
                        spacing: 3

                        Text {
                            text: "CHOOSE APPLICATION"
                            color: root.textPrimary
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "Click an app to add it to this workspace preset."
                            color: root.textMuted
                            font.pixelSize: 7
                            font.weight: Font.Medium
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        width: 190
                        height: 34
                        radius: 10
                        color: "#F7F8FA"
                        border.width: 1
                        border.color: root.border

                        TextInput {
                            id: appSearchInput
                            anchors.fill: parent
                            anchors.leftMargin: 11
                            anchors.rightMargin: 11
                            color: root.textPrimary
                            font.pixelSize: 9
                            verticalAlignment: Text.AlignVCenter
                            text: root.appSearch
                            selectByMouse: true
                            clip: true

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Search apps"
                                color: root.textMuted
                                font.pixelSize: 9
                                visible: !appSearchInput.text.length && !appSearchInput.activeFocus
                            }

                            onTextChanged: root.appSearch = text

                            Keys.onEscapePressed: root.appPickerOpen = false
                        }
                    }
                }

                Flickable {
                    anchors.top: parent.top
                    anchors.topMargin: 72
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 18
                    clip: true
                    contentHeight: appPickerColumn.height

                    Column {
                        id: appPickerColumn
                        width: parent.width - 40
                        x: 20
                        spacing: 8

                        Repeater {
                            model: root.filteredApplications

                            delegate: Rectangle {
                                width: appPickerColumn.width
                                height: 62
                                radius: 13
                                color: appPickerMouse.containsMouse ? root.cardHover : root.card
                                border.width: 1
                                border.color: root.border

                                IconImage {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    implicitWidth: 31
                                    implicitHeight: 31
                                    source: modelData.icon
                                        ? Quickshell.iconPath(modelData.icon, "application-x-executable")
                                        : Quickshell.iconPath("application-x-executable", "application-x-executable")
                                }

                                Column {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 58
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 3

                                    Text {
                                        text: modelData.name
                                        color: root.textPrimary
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: modelData.genericName || modelData.comment || modelData.id
                                        color: root.textMuted
                                        font.pixelSize: 7
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 15
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "ADD"
                                    color: root.textPrimary
                                    font.pixelSize: 7
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.7
                                }

                                MouseArea {
                                    id: appPickerMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.addApplication(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            visible: root.workspacePickerIndex >= 0
            anchors.fill: parent
            z: 30
            color: "#52000000"

            MouseArea {
                anchors.fill: parent
                onClicked: root.workspacePickerIndex = -1
            }

            Rectangle {
                anchors.centerIn: parent
                width: Math.min(460, parent.width - 50)
                height: 330
                radius: 20
                color: "#FFFFFF"
                border.width: 1
                border.color: root.borderStrong

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 10

                    Column {
                        width: parent.width
                        spacing: 3

                        Text {
                            text: "CHOOSE WORKSPACE"
                            color: root.textPrimary
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.workspacePickerIndex >= 0
                                ? "PLACE  " + root.draftApps[root.workspacePickerIndex].name.toUpperCase()
                                : "PLACE APPLICATION"
                            color: root.textMuted
                            font.pixelSize: 7
                            font.weight: Font.Medium
                        }
                    }

                    Grid {
                        width: parent.width
                        columns: 2
                        rowSpacing: 8
                        columnSpacing: 8

                        Repeater {
                            model: root.workspaceCatalog

                            delegate: Rectangle {
                                width: (parent.width - 8) / 2
                                height: 76
                                radius: 13
                                color: workspaceMouse.containsMouse ? root.cardHover : root.card
                                border.width: 1
                                border.color: root.border

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 14
                                    anchors.top: parent.top
                                    anchors.topMargin: 12
                                    text: modelData.number
                                    color: root.textMuted
                                    font.pixelSize: 7
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 14
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 12
                                    text: modelData.name
                                    color: root.textPrimary
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.7
                                }

                                MouseArea {
                                    id: workspaceMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.chooseWorkspace(modelData.id)
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            visible: root.deleteIndex >= 0
            anchors.fill: parent
            z: 40
            color: "#52000000"

            MouseArea {
                anchors.fill: parent
                onClicked: root.deleteIndex = -1
            }

            Rectangle {
                anchors.centerIn: parent
                width: 390
                height: 210
                radius: 18
                color: "#FFFFFF"
                border.width: 1
                border.color: root.borderStrong

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 22
                    spacing: 9

                    Text {
                        text: "REMOVE PRESET?"
                        color: root.textPrimary
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        text: root.deleteIndex >= 0
                            ? "Remove  \"" + root.presets[root.deleteIndex].name + "\"  from A16EEN?"
                            : "Remove this preset?"
                        color: root.textSecondary
                        font.pixelSize: 9
                        wrapMode: Text.WordWrap
                    }

                    Item {
                        width: 1
                        height: 4
                    }

                    Row {
                        width: parent.width
                        spacing: 8

                        Rectangle {
                            width: 125
                            height: 34
                            radius: 10
                            color: "#F7F8FA"
                            border.width: 1
                            border.color: root.borderStrong

                            Text {
                                anchors.centerIn: parent
                                text: "CANCEL"
                                color: root.textPrimary
                                font.pixelSize: 7
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.deleteIndex = -1
                            }
                        }

                        Rectangle {
                            width: 125
                            height: 34
                            radius: 10
                            color: "#111318"

                            Text {
                                anchors.centerIn: parent
                                text: "REMOVE"
                                color: "#FFFFFF"
                                font.pixelSize: 7
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.confirmDelete()
                            }
                        }
                    }
                }
            }
        }
    }

    readonly property bool canSave:
        root.editorOpen &&
        !root.saveProcess.running &&
        root.draftName.trim().length > 0 &&
        root.draftApps.length > 0
}
