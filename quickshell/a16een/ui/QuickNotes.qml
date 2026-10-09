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
    property bool sidebarVisible: true
    property bool storageReady: false
    property bool saved: true
    property bool syncingEditor: false
    property var notes: []
    property string selectedNoteId: ""

    signal closeRequested()

    readonly property bool horizontalNavbar:
        root.navbarPosition === "top" || root.navbarPosition === "bottom"
    readonly property var selectedNote:
        root.notes.find(note => String(note.id) === root.selectedNoteId) || null

    screen: root.modelData
    visible: root.opened && root.dockVisible && root.modelData !== null
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    focusable: false
    readonly property real screenWidth: root.modelData ? root.modelData.width : 1920
    readonly property real screenHeight: root.modelData ? root.modelData.height : 1080
    readonly property int popupWidth: root.sidebarVisible ? 360 : 280
    readonly property int popupHeight: 320

    // Explicit output dimensions are important: this overlay must retain a
    // screen-sized input surface, or its card coordinates can collapse to (0, 0).
    width: root.screenWidth
    height: root.screenHeight

    // A transparent screen surface catches clicks outside the actual card.
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-quick-notes"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    FileView {
        id: notesStorage
        // Keep the existing filename so plain-text notes from the first
        // iteration are migrated into the new multi-note format.
        path: Quickshell.stateDir + "/quick-notes.txt"
        preload: true
        printErrors: false
        atomicWrites: true
        onLoaded: root.loadNotes()
        onLoadFailed: root.initializeNotes()
    }

    Timer {
        id: saveTimer
        interval: 950
        repeat: false
        onTriggered: root.saveNow()
    }

    function initializeNotes() {
        if (root.storageReady)
            return
        const note = { id: String(Date.now()), title: "Quick note", body: "" }
        root.notes = [note]
        root.selectedNoteId = note.id
        root.storageReady = true
        root.saved = false
        Qt.callLater(root.syncEditor)
        saveTimer.restart()
    }

    function loadNotes() {
        if (root.storageReady)
            return

        const raw = String(notesStorage.text() || "")
        try {
            const parsed = JSON.parse(raw)
            if (parsed && Array.isArray(parsed.notes)) {
                root.notes = parsed.notes
                    .filter(note => note && String(note.id || "").length)
                    .map(note => ({
                        id: String(note.id),
                        title: String(note.title || "Untitled note"),
                        body: String(note.body || "")
                    }))
            } else {
                root.notes = []
            }
            root.selectedNoteId = String(parsed.selectedNoteId || "")
        } catch (error) {
            // Migrate the previous single plain-text note without losing it.
            root.notes = raw.length
                ? [{ id: String(Date.now()), title: "Quick note", body: raw }]
                : []
            root.selectedNoteId = root.notes.length ? root.notes[0].id : ""
        }

        if (root.notes.length === 0) {
            const note = { id: String(Date.now()), title: "Quick note", body: "" }
            root.notes = [note]
            root.selectedNoteId = note.id
        } else if (!root.notes.some(note => String(note.id) === root.selectedNoteId)) {
            root.selectedNoteId = root.notes[0].id
        }

        root.storageReady = true
        root.saved = true
        Qt.callLater(root.syncEditor)
        saveTimer.restart()
    }

    function saveNow() {
        saveTimer.stop()
        if (!root.storageReady)
            return
        notesStorage.setText(JSON.stringify({
            version: 2,
            selectedNoteId: root.selectedNoteId,
            notes: root.notes
        }))
        root.saved = true
    }

    function syncEditor() {
        root.syncingEditor = true
        titleField.text = root.selectedNote ? root.selectedNote.title : ""
        noteEditor.text = root.selectedNote ? root.selectedNote.body : ""
        root.syncingEditor = false
    }

    function queueSave() {
        root.saved = false
        saveTimer.restart()
    }

    function selectNote(id) {
        root.selectedNoteId = String(id)
        Qt.callLater(root.syncEditor)
    }

    function addNote() {
        const note = {
            id: String(Date.now()),
            title: "Untitled note",
            body: ""
        }
        root.notes = [note, ...root.notes]
        root.selectedNoteId = note.id
        root.queueSave()
        Qt.callLater(root.syncEditor)
        Qt.callLater(() => titleField.forceActiveFocus())
    }

    function updateSelectedField(fieldName, value) {
        if (root.syncingEditor || !root.selectedNoteId)
            return

        root.notes = root.notes.map(note => {
            if (String(note.id) !== root.selectedNoteId)
                return note
            return {
                id: note.id,
                title: fieldName === "title" ? String(value) : note.title,
                body: fieldName === "body" ? String(value) : note.body
            }
        })
        root.queueSave()
    }

    function deleteSelectedNote() {
        if (!root.selectedNote)
            return
        const removedId = root.selectedNoteId
        root.notes = root.notes.filter(note => String(note.id) !== removedId)
        if (root.notes.length === 0) {
            const note = { id: String(Date.now()), title: "Quick note", body: "" }
            root.notes = [note]
        }
        root.selectedNoteId = root.notes[0].id
        root.queueSave()
        Qt.callLater(root.syncEditor)
    }

    onOpenedChanged: {
        if (opened) {
            Qt.callLater(() => {
                root.syncEditor()
                Qt.callLater(() => noteEditor.forceActiveFocus())
            })
        } else {
            root.saveNow()
        }
    }

    onStorageReadyChanged: {
        if (storageReady && opened) {
            Qt.callLater(() => {
                root.syncEditor()
                noteEditor.forceActiveFocus()
            })
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
        id: notePopup
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
        WlrLayershell.namespace: "a16een-quick-notes-popup"
        WlrLayershell.keyboardFocus: root.opened
            ? WlrKeyboardFocus.OnDemand
            : WlrKeyboardFocus.None

        Rectangle {
            id: noteCard
            anchors.fill: parent
            radius: 19
        color: "#FFFFFF"
        border.width: 1
        border.color: "#D9DEE5"

        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: 23
            color: "#16000000"
            z: -1
        }

        MouseArea {
            anchors.fill: parent
            z: 0
            acceptedButtons: Qt.AllButtons
            onClicked: mouse.accepted = true
        }

        Row {
            z: 1
            anchors.fill: parent
            anchors.margins: 12
            spacing: root.sidebarVisible ? 10 : 0

            Rectangle {
                id: notesSidebar
                visible: root.sidebarVisible
                width: root.sidebarVisible ? 112 : 0
                height: parent.height
                radius: 13
                color: "#F7F8FA"
                border.width: 1
                border.color: "#E6EAF0"

                Column {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Row {
                        width: parent.width
                        height: 26
                        spacing: 4

                        Text {
                            width: parent.width - 30
                            text: "NOTES"
                            color: "#818B98"
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                            verticalAlignment: Text.AlignVCenter
                        }

                        Rectangle {
                            width: 26
                            height: 26
                            radius: 8
                            color: addNoteHover.containsMouse ? "#E6EAF0" : "#FFFFFF"
                            border.width: 1
                            border.color: "#E0E5EB"

                            Text {
                                anchors.centerIn: parent
                                text: "+"
                                color: "#252C35"
                                font.pixelSize: 18
                            }
                            MouseArea {
                                id: addNoteHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.addNote()
                            }
                        }
                    }

                    ListView {
                        id: notesList
                        width: parent.width
                        height: parent.height - 34
                        clip: true
                        spacing: 5
                        model: root.notes

                        delegate: Rectangle {
                            id: noteRow
                            required property var modelData
                            width: notesList.width
                            height: 46
                            radius: 9
                            color: String(noteRow.modelData.id) === root.selectedNoteId
                                ? "#E7EBF0" : (noteHover.containsMouse ? "#EEF1F4" : "transparent")

                            Column {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 4
                                anchors.topMargin: 7
                                spacing: 3

                                Text {
                                    width: parent.width
                                    text: noteRow.modelData.title || "Untitled note"
                                    color: "#252C35"
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width
                                    text: String(noteRow.modelData.body || "").replace(/\s+/g, " ").trim()
                                    color: "#8C96A2"
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: noteHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectNote(noteRow.modelData.id)
                            }
                        }
                    }
                }
            }

            Column {
                id: editorColumn
                width: parent.width - (root.sidebarVisible ? 122 : 0)
                height: parent.height
                spacing: 9

                Row {
                    width: parent.width
                    height: 30
                    spacing: 6

                    Rectangle {
                        width: 29
                        height: 29
                        radius: 9
                        color: toggleNavHover.containsMouse ? "#EEF1F4" : "#F8F9FA"
                        border.width: 1
                        border.color: "#E4E8ED"

                        Text {
                            anchors.centerIn: parent
                            text: "☰"
                            color: "#46515E"
                            font.pixelSize: 13
                        }
                        MouseArea {
                            id: toggleNavHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.sidebarVisible = !root.sidebarVisible
                        }
                    }

                    Rectangle {
                        width: parent.width - 70
                        height: 29
                        radius: 9
                        color: "#FAFBFC"
                        border.width: 1
                        border.color: titleField.activeFocus ? "#BECAD7" : "#E5EAF0"

                        TextInput {
                            id: titleField
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            anchors.rightMargin: 7
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            selectByMouse: true
                            color: "#222A34"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            onTextEdited: root.updateSelectedField("title", text)
                            Keys.onEscapePressed: root.closeRequested()
                        }
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 9
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Note name"
                            color: "#A0A9B4"
                            font.pixelSize: 11
                            visible: titleField.text.length === 0 && !titleField.activeFocus
                            enabled: false
                        }
                    }

                    Rectangle {
                        width: 29
                        height: 29
                        radius: 9
                        color: deleteNoteHover.containsMouse ? "#FBEDEE" : "#F8F9FA"
                        border.width: 1
                        border.color: "#E5E9EE"
                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: deleteNoteHover.containsMouse ? "#B9444A" : "#77818D"
                            font.pixelSize: 17
                        }
                        MouseArea {
                            id: deleteNoteHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.deleteSelectedNote()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: Math.max(110, parent.height - 84)
                    radius: 12
                    color: "#FAFBFC"
                    border.width: 1
                    border.color: noteEditor.activeFocus ? "#BECAD7" : "#E5EAF0"

                    TextEdit {
                        id: noteEditor
                        anchors.fill: parent
                        anchors.margins: 11
                        text: ""
                        color: "#303945"
                        selectedTextColor: "#FFFFFF"
                        selectionColor: "#6E8FB9"
                        font.family: "Noto Sans"
                        font.pixelSize: 12
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        persistentSelection: true
                        clip: true
                        activeFocusOnPress: true
                        verticalAlignment: TextEdit.AlignTop

                        onTextChanged: {
                            if (!root.syncingEditor)
                                root.updateSelectedField("body", text)
                        }
                        Keys.onEscapePressed: root.closeRequested()
                    }

                    Text {
                        anchors.left: noteEditor.left
                        anchors.top: noteEditor.top
                        text: "Write anything…"
                        color: "#A0A9B4"
                        font.family: "Noto Sans"
                        font.pixelSize: 12
                        visible: noteEditor.text.length === 0 && !noteEditor.activeFocus
                        enabled: false
                    }
                }

                Row {
                    width: parent.width
                    height: 18
                    spacing: 5
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 5
                        height: 5
                        radius: 3
                        color: root.saved ? "#2F9B67" : "#C38A31"
                    }
                    Text {
                        text: root.saved ? "Saved locally" : "Saving…"
                        color: "#929BA7"
                        font.pixelSize: 9
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
    }
}
