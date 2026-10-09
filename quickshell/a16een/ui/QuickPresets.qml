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
    property var presets: []
    property var draftApps: []
    property string draftId: ""
    property string draftName: ""
    property string appSearch: ""
    property string statusMessage: ""
    property string openPresetId: ""
    property string deletePresetId: ""
    property bool editorOpen: false

    signal closeRequested()

    readonly property bool horizontalNavbar:
        root.navbarPosition === "top" || root.navbarPosition === "bottom"
    readonly property real screenWidth: root.modelData ? root.modelData.width : 1920
    readonly property real screenHeight: root.modelData ? root.modelData.height : 1080
    readonly property int popupWidth: 340
    readonly property int popupHeight: root.editorOpen ? 428 : 348
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

    readonly property var applicationCatalog: {
        return [...DesktopEntries.applications.values]
            .filter(entry => entry && !entry.noDisplay)
            .sort((a, b) => String(a.name || "").localeCompare(String(b.name || "")))
    }

    readonly property var filteredApplications: {
        const query = root.appSearch.trim().toLowerCase()
        if (!query)
            return root.applicationCatalog
        return root.applicationCatalog.filter(entry => {
            const description = [
                entry.name, entry.genericName, entry.comment,
                ...(entry.keywords || [])
            ].filter(value => value).join(" ").toLowerCase()
            return description.includes(query)
        })
    }

    readonly property bool canSave:
        root.draftName.trim().length > 0
        && root.draftApps.length > 0
        && !saveProcess.running

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

    width: root.screenWidth
    height: root.screenHeight
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-quick-presets"

    function cleanAppIds(entry) {
        const values = [
            entry.startupClass || "",
            entry.startupWmClass || "",
            String(entry.id || "").replace(/\.desktop$/i, ""),
            entry.command && entry.command.length
                ? String(entry.command[0] || "").split("/").pop()
                : ""
        ]
        return values.filter(value => value)
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
        if (!root.opened || presetReader.running)
            return
        presetReader.running = true
    }

    function parsePresets(output) {
        try {
            const data = JSON.parse(String(output || "{}"))
            root.presets = Array.isArray(data.presets) ? data.presets : []
            root.statusMessage = root.presets.length
                ? root.presets.length + " saved"
                : "No presets yet"
        } catch (error) {
            root.presets = []
            root.statusMessage = "Couldn't read presets"
        }
    }

    function beginAdd() {
        root.draftId = ""
        root.draftName = ""
        root.draftApps = []
        root.appSearch = ""
        root.editorOpen = true
        Qt.callLater(() => presetNameField.forceActiveFocus())
    }

    function cancelEditor() {
        root.editorOpen = false
        root.draftId = ""
        root.draftName = ""
        root.draftApps = []
        root.appSearch = ""
    }

    function toggleApp(entry) {
        if (!entry)
            return
        const id = String(entry.id || "")
        if (!id)
            return

        const exists = root.draftApps.some(app => app.desktopId === id)
        root.draftApps = exists
            ? root.draftApps.filter(app => app.desktopId !== id)
            : root.draftApps.concat([root.appFromEntry(entry)])
    }

    function savePayload() {
        return {
            version: 1,
            id: root.draftId,
            name: root.draftName.trim(),
            apps: root.draftApps
        }
    }

    function savePreset() {
        if (!root.canSave)
            return
        root.statusMessage = "Saving…"
        saveProcess.running = true
    }

    function openPreset(preset) {
        if (!preset || openProcess.running)
            return
        root.openPresetId = String(preset.id || "")
        if (!root.openPresetId)
            return
        root.statusMessage = "Opening " + String(preset.name || "preset")
        openProcess.running = true
    }

    function deletePreset(preset) {
        if (!preset || deleteProcess.running)
            return
        root.deletePresetId = String(preset.id || "")
        if (root.deletePresetId)
            deleteProcess.running = true
    }

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
                    root.statusMessage = "Couldn't read presets"
            }
        }
    }

    Process {
        id: saveProcess
        command: ["a16een-workspace-preset", "save", JSON.stringify(root.savePayload())]
        running: false
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length)
                    root.statusMessage = "Save failed"
            }
        }
        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.editorOpen = false
                root.draftId = ""
                root.draftName = ""
                root.draftApps = []
                root.appSearch = ""
                root.statusMessage = "Preset saved"
                Qt.callLater(() => presetReader.running = true)
            } else {
                root.statusMessage = "Save failed"
            }
        }
    }

    Process {
        id: openProcess
        command: ["a16een-workspace-preset", "open", root.openPresetId]
        running: false
        onExited: function(exitCode) {
            root.statusMessage = exitCode === 0 ? "Preset opened" : "Some apps may not have opened"
        }
    }

    Process {
        id: deleteProcess
        command: ["a16een-workspace-preset", "delete", root.deletePresetId]
        running: false
        onExited: function(exitCode) {
            root.statusMessage = exitCode === 0 ? "Preset removed" : "Remove failed"
            if (exitCode === 0)
                Qt.callLater(() => presetReader.running = true)
        }
    }

    onOpenedChanged: {
        if (opened) {
            root.editorOpen = false
            root.loadPresets()
        } else {
            root.editorOpen = false
            root.appSearch = ""
        }
    }

    MouseArea {
        id: outsideClickArea
        anchors.fill: parent
        z: 0
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: root.closeRequested()
    }

    Item {
        id: popup
        x: root.popupX
        y: root.popupY
        width: root.popupWidth
        height: root.popupHeight
        visible: root.opened && root.dockVisible
        z: 1

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: "#FFFFFF"
            border.width: 1
            border.color: "#D9DEE5"

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: 22
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
                anchors.fill: parent
                anchors.margins: 13
                spacing: 9
                z: 1

                Row {
                    width: parent.width
                    height: 30
                    spacing: 8

                    Column {
                        width: parent.width - 88
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: root.editorOpen ? "NEW PRESET" : "WORKSPACES"
                            color: "#202630"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: root.editorOpen
                                ? root.draftApps.length + " apps selected"
                                : root.statusMessage
                            color: "#8A939E"
                            font.pixelSize: 9
                        }
                    }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 9
                        color: addHover.containsMouse ? "#171B20" : "#F5F7F9"
                        border.width: addHover.containsMouse ? 0 : 1
                        border.color: "#E2E7EC"
                        Text {
                            anchors.centerIn: parent
                            text: root.editorOpen ? "‹" : "+"
                            color: addHover.containsMouse && !root.editorOpen ? "#FFFFFF" : "#343D47"
                            font.pixelSize: 19
                        }
                        MouseArea {
                            id: addHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.editorOpen)
                                    root.cancelEditor()
                                else
                                    root.beginAdd()
                            }
                        }
                    }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 9
                        color: closeHover.containsMouse ? "#FBEDEE" : "#F8F9FA"
                        border.width: 1
                        border.color: "#E7EAEE"
                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: "#6F7986"
                            font.pixelSize: 18
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
                    height: parent.height - 50
                    visible: !root.editorOpen

                    ListView {
                        id: presetList
                        anchors.fill: parent
                        clip: true
                        spacing: 6
                        model: root.presets

                        delegate: Rectangle {
                            id: presetRow
                            required property var modelData
                            width: presetList.width
                            height: 56
                            radius: 11
                            color: "#FAFBFC"
                            border.width: 1
                            border.color: "#E8ECF1"

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.right: actionRow.left
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                Text {
                                    width: parent.width
                                    text: presetRow.modelData.name || "Untitled preset"
                                    color: "#27313D"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width
                                    text: String((presetRow.modelData.apps || []).length) + " apps"
                                    color: "#8C96A2"
                                    font.pixelSize: 9
                                }
                            }

                            Row {
                                id: actionRow
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3

                                Rectangle {
                                    width: 35
                                    height: 30
                                    radius: 8
                                    color: launchHover.containsMouse ? "#20262E" : "#EDF0F3"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "▶"
                                        color: launchHover.containsMouse ? "#FFFFFF" : "#374250"
                                        font.pixelSize: 10
                                    }
                                    MouseArea {
                                        id: launchHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: !openProcess.running
                                        onClicked: root.openPreset(presetRow.modelData)
                                    }
                                }

                                Rectangle {
                                    width: 26
                                    height: 30
                                    radius: 8
                                    color: deleteHover.containsMouse ? "#FBEDEE" : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "×"
                                        color: deleteHover.containsMouse ? "#B9444A" : "#929BA7"
                                        font.pixelSize: 15
                                    }
                                    MouseArea {
                                        id: deleteHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: !deleteProcess.running
                                        onClicked: root.deletePreset(presetRow.modelData)
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.presets.length === 0
                        text: "No presets yet\nTap + to create one"
                        color: "#8A939E"
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        lineHeight: 1.35
                    }
                }

                Column {
                    width: parent.width
                    height: parent.height - 50
                    spacing: 7
                    visible: root.editorOpen

                    Rectangle {
                        width: parent.width
                        height: 31
                        radius: 9
                        color: "#FAFBFC"
                        border.width: 1
                        border.color: presetNameField.activeFocus ? "#B8C5D4" : "#E5EAF0"
                        TextInput {
                            id: presetNameField
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            color: "#202833"
                            font.pixelSize: 11
                            clip: true
                            selectByMouse: true
                            text: root.draftName
                            onTextEdited: root.draftName = text
                            Keys.onReturnPressed: root.savePreset()
                        }
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 9
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Preset name"
                            color: "#A0A9B4"
                            font.pixelSize: 11
                            visible: presetNameField.text.length === 0 && !presetNameField.activeFocus
                            enabled: false
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 30
                        radius: 9
                        color: "#FAFBFC"
                        border.width: 1
                        border.color: appSearchField.activeFocus ? "#B8C5D4" : "#E5EAF0"
                        TextInput {
                            id: appSearchField
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            color: "#35404C"
                            font.pixelSize: 10
                            clip: true
                            selectByMouse: true
                            onTextEdited: root.appSearch = text
                        }
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 9
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Search applications"
                            color: "#A0A9B4"
                            font.pixelSize: 10
                            visible: appSearchField.text.length === 0 && !appSearchField.activeFocus
                            enabled: false
                        }
                    }

                    ListView {
                        id: appList
                        width: parent.width
                        height: parent.height - 111
                        clip: true
                        spacing: 3
                        model: root.filteredApplications

                        delegate: Rectangle {
                            id: appRow
                            required property var modelData
                            width: appList.width
                            height: 29
                            radius: 8
                            readonly property bool chosen:
                                root.draftApps.some(app => app.desktopId === String(appRow.modelData.id || ""))
                            color: appRow.chosen ? "#E9EEF3"
                                : (appHover.containsMouse ? "#F2F4F6" : "transparent")

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 7

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 13
                                    height: 13
                                    radius: 4
                                    color: appRow.chosen ? "#222A34" : "#FFFFFF"
                                    border.width: 1
                                    border.color: appRow.chosen ? "#222A34" : "#CED5DD"
                                    Text {
                                        anchors.centerIn: parent
                                        text: appRow.chosen ? "✓" : ""
                                        color: "#FFFFFF"
                                        font.pixelSize: 9
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 28
                                    text: appRow.modelData.name || "Application"
                                    color: "#303A46"
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: appHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleApp(appRow.modelData)
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 30
                        spacing: 7

                        Rectangle {
                            width: (parent.width - 7) / 2
                            height: 30
                            radius: 9
                            color: cancelHover.containsMouse ? "#EEF1F4" : "#F7F8FA"
                            border.width: 1
                            border.color: "#E3E7EC"
                            Text {
                                anchors.centerIn: parent
                                text: "Cancel"
                                color: "#5F6A76"
                                font.pixelSize: 10
                            }
                            MouseArea {
                                id: cancelHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.cancelEditor()
                            }
                        }
                        Rectangle {
                            width: (parent.width - 7) / 2
                            height: 30
                            radius: 9
                            color: root.canSave ? (saveHover.containsMouse ? "#111318" : "#242A32") : "#F0F2F4"
                            Text {
                                anchors.centerIn: parent
                                text: saveProcess.running ? "Saving…" : "Save preset"
                                color: root.canSave ? "#FFFFFF" : "#A2AAB4"
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }
                            MouseArea {
                                id: saveHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: root.canSave
                                onClicked: root.savePreset()
                            }
                        }
                    }
                }
            }
        }
    }
}
