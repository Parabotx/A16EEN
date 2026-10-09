import QtQuick
import QtQuick.Dialogs
import QtMultimedia
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
    property string noteMenuNoteId: ""
    property bool noteMenuOpen: false
    property real noteMenuX: 0
    property real noteMenuY: 0

    // The passcode is hashed before it is written to disk. This is a local
    // interface lock, not encryption of the note file itself.
    property string passcodeHash: ""
    property string passcodeSalt: ""
    property bool accessGranted: false
    property string gateMode: "loading"
    property string firstPasscode: ""
    property string passcodeMessage: ""
    property string passcodeInput: ""

    property string recordingPath: ""
    property string recordingDraftPath: ""
    property bool recordingDraftReady: false
    property bool stopRequested: false
    property int recordingSeconds: 0
    property int recordingAnchorPosition: 0
    property string mediaError: ""
    property string playingAudioPath: ""
    readonly property bool isRecording:
        voiceRecorder.recorderState === MediaRecorder.RecordingState

    signal closeRequested()

    readonly property bool horizontalNavbar:
        root.navbarPosition === "top" || root.navbarPosition === "bottom"
    readonly property var selectedNote:
        root.notes.find(note => String(note.id) === root.selectedNoteId) || null
    readonly property var noteMenuNote:
        root.notes.find(note => String(note.id) === root.noteMenuNoteId) || null
    readonly property var orderedNotes: {
        const copy = root.notes.slice()
        copy.sort((a, b) => Number(Boolean(b.pinned)) - Number(Boolean(a.pinned)))
        return copy
    }
    readonly property real screenWidth: root.modelData ? root.modelData.width : 1920
    readonly property real screenHeight: root.modelData ? root.modelData.height : 1080
    readonly property int popupWidth: root.sidebarVisible ? 372 : 294
    readonly property int popupHeight: 414
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

    // A screen-sized surface gives us a reliable outside-click target while
    // the visible card remains positioned directly beside the navbar cluster.
    width: root.screenWidth
    height: root.screenHeight

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-quick-notes"

    FileView {
        id: notesStorage
        path: Quickshell.stateDir + "/quick-notes.txt"
        preload: true
        printErrors: false
        atomicWrites: true
        onLoaded: root.loadNotes()
        onLoadFailed: root.initializeNotes()
    }

    Timer {
        id: saveTimer
        interval: 1200
        repeat: false
        onTriggered: root.saveNow()
    }

    Timer {
        id: recordingClock
        interval: 1000
        repeat: true
        running: voiceRecorder.recorderState === MediaRecorder.RecordingState
        onTriggered: root.recordingSeconds++
    }

    CaptureSession {
        id: captureSession
        audioInput: AudioInput {}
        recorder: MediaRecorder {
            id: voiceRecorder
            outputLocation: root.recordingPath
            audioChannelCount: 1
            audioSampleRate: 44100

            onErrorOccurred: (error, errorString) => {
                root.mediaError = String(errorString || "Recording could not start.")
                root.recordingDraftReady = false
            }
        }
    }

    MediaPlayer {
        id: audioPlayer
        source: root.playingAudioPath
        audioOutput: AudioOutput {}
        onErrorOccurred: (error, errorString) => {
            root.mediaError = String(errorString || "Audio playback failed.")
        }
    }

    FileDialog {
        id: imagePicker
        title: "Attach an image"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.gif *.bmp)"]
        onAccepted: root.addAttachment("image", String(selectedFile), noteEditor.cursorPosition)
    }

    function hashPasscode(code, salt) {
        const source = String(salt) + "::A16EEN::" + String(code)
        let first = 2166136261
        let second = 2246822519
        for (let i = 0; i < source.length; i++) {
            const value = source.charCodeAt(i)
            first = Math.imul(first ^ value, 16777619) >>> 0
            second = Math.imul(second ^ (value + i + 17), 3266489917) >>> 0
        }
        return first.toString(16).padStart(8, "0")
            + second.toString(16).padStart(8, "0")
    }

    function escapeHtml(value) {
        return String(value)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#39;")
    }

    // Qt's rich-text editor can return a complete HTML document with its
    // own stylesheet. Persist and format only the body fragment.
    function cleanRichHtml(value) {
        let html = String(value || "")
        const bodyMatch = html.match(/<body\b[^>]*>([\s\S]*?)<\/body\s*>/i)
        if (bodyMatch) {
            html = bodyMatch[1]
        } else {
            html = html
                .replace(/<head\b[^>]*>[\s\S]*?<\/head\s*>/gi, "")
                .replace(/<style\b[^>]*>[\s\S]*?<\/style\s*>/gi, "")
        }

        html = html
            .replace(/<style\b[^>]*>[\s\S]*?<\/style\s*>/gi, "")
            .replace(/<!doctype[^>]*>/gi, "")
            .replace(/<meta\b[^>]*>/gi, "")
            .replace(/<\/?(?:html|head|body)\b[^>]*>/gi, "")
            // Remove CSS that an older selection mapper accidentally copied
            // into note content.
            .replace(/p\s*,\s*li\s*\{[\s\S]*?li\.checked::marker\s*\{[^}]*\}\s*/gi, "")
            .replace(/white-space:\s*pre-wrap;\s*\}\s*hr\s*\{[\s\S]*?li\.checked::marker\s*\{[^}]*\}\s*/gi, "")
            .replace(/pace:\s*pre-wrap;\s*\}\s*hr\s*\{[\s\S]*?li\.checked::marker\s*\{[^}]*\}\s*/gi, "")
            .replace(/<script\b[^>]*>[\s\S]*?<\/script\s*>/gi, "")
            .trim()

        // Repair basic legacy Markdown markers from the earlier formatter.
        html = html.replace(/\*\*([^*\n]+)\*\*/g, "<b>$1</b>")
            .replace(/\*([^*\n]+)\*/g, "<i>$1</i>")
        return html
    }

    function previewText(value) {
        return root.cleanRichHtml(value)
            .replace(/<a\b[^>]*href=["']a16een-audio:[^"']*["'][^>]*>([\s\S]*?)<\/a>/gi, "[Voice note]")
            .replace(/<img\b[^>]*>/gi, "[Image]")
            .replace(/<br\s*\/?\s*>/gi, " ")
            .replace(/<\/(?:p|div|li|h[1-6]|blockquote|pre)\s*>/gi, " ")
            .replace(/<[^>]*>/g, " ")
            .replace(/&nbsp;|&#160;/gi, " ")
            .replace(/&amp;/gi, "&")
            .replace(/&lt;/gi, "<")
            .replace(/&gt;/gi, ">")
            .replace(/&quot;/gi, '"')
            .replace(/&#39;/g, "'")
            .replace(/\s+/g, " ")
            .trim()
    }

    function insertMarkupAtVisibleIndex(source, position, markup) {
        const html = root.cleanRichHtml(source)
        const offset = root.htmlOffsetForVisibleIndex(html, Math.max(0, Number(position) || 0))
        return html.slice(0, offset) + markup + html.slice(offset)
    }

    function playInlineAttachment(link) {
        const match = String(link || "").match(/^a16een-audio:(.+)$/)
        if (!match || !root.selectedNote)
            return
        const item = (root.selectedNote.attachments || []).find(entry =>
            String(entry.id) === match[1] && entry.type === "audio")
        if (!item)
            return
        if (root.playingAudioPath === item.path && audioPlayer.playing) {
            audioPlayer.pause()
        } else {
            root.mediaError = ""
            root.playingAudioPath = item.path
            audioPlayer.play()
        }
    }

    function initializeNotes() {
        if (root.storageReady)
            return
        const note = {
            id: String(Date.now()),
            title: "Quick note",
            body: "",
            alignment: "left",
            attachments: [],
            pinned: false
        }
        root.notes = [note]
        root.selectedNoteId = note.id
        root.storageReady = true
        root.saved = false
        root.gateMode = "create"
        root.accessGranted = false
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
                        body: Number(parsed.version || 0) >= 3
                        ? root.cleanRichHtml(String(note.body || ""))
                        : root.escapeHtml(String(note.body || "")).replace(/\n/g, "<br>"),
                    alignment: ["left", "center", "right"].includes(note.alignment)
                            ? note.alignment : "left",
                        attachments: Array.isArray(note.attachments)
                            ? note.attachments.filter(item => item && item.path)
                                .map(item => ({
                                    id: String(item.id || Date.now()),
                                    type: item.type === "audio" ? "audio" : "image",
                                    path: String(item.path),
                                    title: String(item.title || ""),
                                    inline: Boolean(item.inline),
                                    position: Number.isFinite(Number(item.position)) ? Number(item.position) : -1
                                }))
                            : [],
                        pinned: Boolean(note.pinned)
                    }))
                root.selectedNoteId = String(parsed.selectedNoteId || "")
                root.passcodeHash = String(parsed.passcodeHash || "")
                root.passcodeSalt = String(parsed.passcodeSalt || "")
            } else {
                root.notes = []
            }
        } catch (error) {
            // Migrate a previous single plain-text note without discarding it.
            root.notes = raw.length
                ? [{
                    id: String(Date.now()),
                    title: "Quick note",
                    body: root.escapeHtml(raw).replace(/\n/g, "<br>"),
                    alignment: "left",
                    attachments: [],
                    pinned: false
                }]
                : []
            root.selectedNoteId = root.notes.length ? root.notes[0].id : ""
        }

        if (root.notes.length === 0) {
            const note = {
                id: String(Date.now()),
                title: "Quick note",
                body: "",
                alignment: "left",
                attachments: [],
                pinned: false
            }
            root.notes = [note]
            root.selectedNoteId = note.id
        } else if (!root.notes.some(note => String(note.id) === root.selectedNoteId)) {
            root.selectedNoteId = root.notes[0].id
        }

        root.storageReady = true
        root.saved = true
        root.gateMode = root.passcodeHash.length ? "unlock" : "create"
        root.accessGranted = false
        root.passcodeInput = ""
        Qt.callLater(root.syncEditor)
        saveTimer.restart()
    }

    function saveNow() {
        saveTimer.stop()
        if (!root.storageReady)
            return
        notesStorage.setText(JSON.stringify({
            version: 4,
            selectedNoteId: root.selectedNoteId,
            notes: root.notes,
            passcodeHash: root.passcodeHash,
            passcodeSalt: root.passcodeSalt
        }))
        root.saved = true
    }

    function queueSave() {
        root.saved = false
        saveTimer.restart()
    }

    function requirePasscode() {
        root.accessGranted = false
        root.gateMode = root.passcodeHash.length ? "unlock" : "create"
        root.firstPasscode = ""
        root.passcodeInput = ""
        root.passcodeMessage = ""
        Qt.callLater(() => passcodeField.forceActiveFocus())
    }

    function submitPasscode() {
        const code = String(passcodeField.text || "")
        if (code.length < 4) {
            root.passcodeMessage = "Use at least 4 characters."
            return
        }

        if (root.gateMode === "create") {
            root.firstPasscode = code
            root.gateMode = "confirm"
            root.passcodeMessage = "Enter it once more to confirm."
            passcodeField.text = ""
            Qt.callLater(() => passcodeField.forceActiveFocus())
            return
        }

        if (root.gateMode === "confirm") {
            if (code !== root.firstPasscode) {
                root.gateMode = "create"
                root.firstPasscode = ""
                root.passcodeMessage = "Those codes did not match. Try again."
                passcodeField.text = ""
                Qt.callLater(() => passcodeField.forceActiveFocus())
                return
            }
            root.passcodeSalt = String(Date.now()) + "-" + String(Math.floor(Math.random() * 1000000000))
            root.passcodeHash = root.hashPasscode(code, root.passcodeSalt)
            root.accessGranted = true
            root.passcodeMessage = ""
            root.firstPasscode = ""
            passcodeField.text = ""
            root.queueSave()
            Qt.callLater(root.syncEditor)
            Qt.callLater(() => noteEditor.forceActiveFocus())
            return
        }

        if (root.hashPasscode(code, root.passcodeSalt) !== root.passcodeHash) {
            root.passcodeMessage = "Incorrect passcode. Try again."
            passcodeField.text = ""
            Qt.callLater(() => passcodeField.forceActiveFocus())
            return
        }

        root.accessGranted = true
        root.passcodeMessage = ""
        passcodeField.text = ""
        Qt.callLater(root.syncEditor)
        Qt.callLater(() => noteEditor.forceActiveFocus())
    }

    function lockNotes() {
        root.saveNow()
        root.accessGranted = false
        root.gateMode = "unlock"
        root.passcodeMessage = "Notes locked."
        passcodeField.text = ""
        root.firstPasscode = ""
        Qt.callLater(() => passcodeField.forceActiveFocus())
    }

    function syncEditor() {
        if (!root.accessGranted || !root.selectedNote)
            return
        root.syncingEditor = true
        titleField.text = root.selectedNote.title
        noteEditor.text = root.cleanRichHtml(root.selectedNote.body)
        noteEditor.horizontalAlignment = root.selectedNote.alignment === "center"
            ? TextEdit.AlignHCenter
            : (root.selectedNote.alignment === "right"
                ? TextEdit.AlignRight : TextEdit.AlignLeft)
        root.syncingEditor = false
    }

    function selectNote(id) {
        root.noteMenuOpen = false
        root.selectedNoteId = String(id)
        root.queueSave()
        Qt.callLater(root.syncEditor)
    }

    function openNoteMenu(id, row) {
        root.noteMenuNoteId = String(id)
        const point = row.mapToItem(notePopup, Math.max(0, row.width - 118), row.height + 3)
        root.noteMenuX = Math.max(8, Math.min(root.screenWidth - 124, root.popupX + point.x))
        root.noteMenuY = Math.max(8, Math.min(root.screenHeight - 82, root.popupY + point.y))
        root.noteMenuOpen = true
    }

    function togglePinnedNote() {
        const id = root.noteMenuNoteId
        root.notes = root.notes.map(note => {
            if (String(note.id) !== id)
                return note
            return {
                id: note.id,
                title: note.title,
                body: note.body,
                alignment: note.alignment || "left",
                attachments: note.attachments || [],
                pinned: !Boolean(note.pinned)
            }
        })
        root.noteMenuOpen = false
        root.queueSave()
    }

    function deleteMenuNote() {
        const id = root.noteMenuNoteId
        root.notes = root.notes.filter(note => String(note.id) !== id)
        if (String(root.selectedNoteId) === id) {
            root.selectedNoteId = root.notes.length ? String(root.notes[0].id) : ""
            if (root.notes.length === 0)
                root.addNote()
            else
                Qt.callLater(root.syncEditor)
        }
        root.noteMenuOpen = false
        root.queueSave()
    }

    function addNote() {
        const note = {
            id: String(Date.now()),
            title: "Untitled note",
            body: "",
            alignment: "left",
            attachments: [],
            pinned: false
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
            const next = {
                id: note.id,
                title: note.title,
                body: note.body,
                alignment: note.alignment || "left",
                attachments: note.attachments || [],
                pinned: Boolean(note.pinned)
            }
            next[fieldName] = fieldName === "body"
                ? root.cleanRichHtml(value)
                : String(value)
            return next
        })
        root.queueSave()
    }

    function addAttachment(type, path, insertAt) {
        if (!root.selectedNote || !path)
            return

        const attachmentType = type === "audio" ? "audio" : "image"
        const hasInlinePosition = insertAt !== undefined && Number.isFinite(Number(insertAt))
        const item = {
            id: String(Date.now()),
            type: attachmentType,
            path: String(path),
            title: attachmentType === "audio" ? "Voice note" : "Image",
            inline: hasInlinePosition,
            position: hasInlinePosition ? Math.max(0, Number(insertAt) || 0) : -1
        }

        let nextBody = root.cleanRichHtml(root.selectedNote.body)
        if (hasInlinePosition) {
            let markup = ""
            if (attachmentType === "audio") {
                // Render voice notes as a small inline play button, not a text label.
                // Spaces after the anchor keep the next typed characters outside the link.
                markup = '&nbsp;<a href="a16een-audio:' + item.id
                    + '" style="color:#365A7D; background-color:#EAF2FA; text-decoration:none; font-weight:bold;">▶</a>&nbsp; '
            } else {
                markup = ' &nbsp;<img src="' + root.escapeHtml(String(path))
                    + '" width="144" />&nbsp; '
            }
            nextBody = root.insertMarkupAtVisibleIndex(nextBody, item.position, markup)
        }

        root.notes = root.notes.map(note => {
            if (String(note.id) !== root.selectedNoteId)
                return note
            return {
                id: note.id,
                title: note.title,
                body: nextBody,
                alignment: note.alignment || "left",
                attachments: [...(note.attachments || []), item],
                pinned: Boolean(note.pinned)
            }
        })

        if (hasInlinePosition) {
            root.syncingEditor = true
            noteEditor.text = nextBody
            root.syncingEditor = false
            Qt.callLater(() => {
                noteEditor.cursorPosition = Math.min(
                    noteEditor.length,
                    // NBSP + play glyph + NBSP + space: place the caret outside the link.
                    item.position + (attachmentType === "audio" ? 4 : 1)
                )
            })
        }
        root.queueSave()
    }

    function removeAttachment(id) {
        root.notes = root.notes.map(note => {
            if (String(note.id) !== root.selectedNoteId)
                return note
            return {
                id: note.id,
                title: note.title,
                body: note.body,
                alignment: note.alignment || "left",
                attachments: (note.attachments || []).filter(item => String(item.id) !== String(id)),
                pinned: Boolean(note.pinned)
            }
        })
        root.queueSave()
    }

    // Map a visible TextEdit selection index back into an HTML source string.
    // This keeps repeated formatting operations stable when text already has
    // <b>, <i> or <u> markup around earlier selections.
    function htmlOffsetForVisibleIndex(source, targetIndex) {
        const raw = String(source)
        let visibleIndex = 0
        let i = 0
        while (i < raw.length) {
            if (raw[i] === "<") {
                const end = raw.indexOf(">", i + 1)
                if (end >= 0) {
                    const tag = raw.slice(i, end + 1)
                    const isVisibleBreak =
                        /^<br\s*\/?\s*>$/i.test(tag)
                        || /^<\/(?:p|div|li|h[1-6]|blockquote|pre)\s*>$/i.test(tag)
                    if (isVisibleBreak) {
                        if (visibleIndex === targetIndex)
                            return i
                        visibleIndex++
                    }
                    i = end + 1
                    continue
                }
            }
            if (raw[i] === "&") {
                const end = raw.indexOf(";", i + 1)
                if (end > i && end - i < 12) {
                    if (visibleIndex === targetIndex)
                        return i
                    visibleIndex++
                    i = end + 1
                    continue
                }
            }
            if (visibleIndex === targetIndex)
                return i
            visibleIndex++
            i++
        }
        return raw.length
    }

    function formatSelection(tag) {
        const start = noteEditor.selectionStart
        const end = noteEditor.selectionEnd
        if (start < 0 || end <= start)
            return

        const current = root.cleanRichHtml(noteEditor.text)
        const selected = String(noteEditor.selectedText)
        const sourceStart = root.htmlOffsetForVisibleIndex(current, start)
        const sourceEnd = root.htmlOffsetForVisibleIndex(current, end)
        const marked = "<" + tag + ">" + root.escapeHtml(selected) + "</" + tag + ">"
        const updated = current.slice(0, sourceStart) + marked + current.slice(sourceEnd)
        root.syncingEditor = true
        noteEditor.text = updated
        root.syncingEditor = false
        root.updateSelectedField("body", updated)
        noteEditor.cursorPosition = start + selected.length
        noteEditor.deselect()
    }

    function setAlignment(alignment) {
        noteEditor.horizontalAlignment = alignment === "center"
            ? TextEdit.AlignHCenter
            : (alignment === "right" ? TextEdit.AlignRight : TextEdit.AlignLeft)
        root.updateSelectedField("alignment", alignment)
    }

    function startRecording() {
        if (voiceRecorder.recorderState === MediaRecorder.RecordingState)
            return
        root.recordingAnchorPosition = noteEditor.cursorPosition
        root.mediaError = ""
        root.recordingDraftReady = false
        root.recordingDraftPath = ""
        root.recordingSeconds = 0
        root.recordingPath = "file://" + Quickshell.stateDir
            + "/note-voice-" + String(Date.now()) + ".wav"
        voiceRecorder.outputLocation = root.recordingPath
        voiceRecorder.record()
    }

    function stopRecording() {
        if (voiceRecorder.recorderState !== MediaRecorder.RecordingState)
            return
        root.stopRequested = true
        voiceRecorder.stop()
        Qt.callLater(() => {
            root.recordingDraftPath = String(voiceRecorder.actualLocation || root.recordingPath)
            root.recordingDraftReady = root.recordingDraftPath.length > 0
            root.stopRequested = false
        })
    }

    function saveRecordingDraft() {
        if (!root.recordingDraftReady)
            return
        root.addAttachment("audio", root.recordingDraftPath, root.recordingAnchorPosition)
        root.recordingDraftPath = ""
        root.recordingDraftReady = false
        root.recordingSeconds = 0
    }

    function discardRecordingDraft() {
        root.recordingDraftPath = ""
        root.recordingDraftReady = false
        root.recordingSeconds = 0
    }

    function recordingTime(seconds) {
        const m = Math.floor(seconds / 60)
        const s = seconds % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    onOpenedChanged: {
        if (opened) {
            root.requirePasscode()
        } else {
            if (voiceRecorder.recorderState === MediaRecorder.RecordingState)
                voiceRecorder.stop()
            root.saveNow()
        }
    }

    onStorageReadyChanged: {
        if (storageReady && opened)
            root.requirePasscode()
    }

    MouseArea {
        id: outsideClickArea
        anchors.fill: parent
        z: 0
        acceptedButtons: Qt.LeftButton
        onClicked: root.closeRequested()
    }

    Item {
        id: notePopup
        visible: root.opened && root.dockVisible && root.modelData !== null
        x: root.popupX
        y: root.popupY
        width: root.popupWidth
        height: root.popupHeight
        z: 1

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

            Item {
                id: passcodeGate
                anchors.fill: parent
                anchors.margins: 20
                visible: root.storageReady && !root.accessGranted
                z: 2

                Column {
                    anchors.centerIn: parent
                    width: Math.min(240, parent.width)
                    spacing: 10

                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 28
                        height: 28
                        source: Qt.resolvedUrl("../assets/icons/quick-lock-closed.svg")
                        sourceSize.width: 56
                        sourceSize.height: 56
                    }

                    Text {
                        width: parent.width
                        text: root.gateMode === "create"
                            ? "Protect your notes"
                            : (root.gateMode === "confirm" ? "Confirm passcode" : "Unlock notes")
                        color: "#1C222A"
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        width: parent.width
                        text: root.gateMode === "create"
                            ? "Set a passcode for your private notes."
                            : (root.gateMode === "confirm"
                                ? "Enter the same passcode again."
                                : "Enter your passcode to continue.")
                        color: "#828C98"
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        width: parent.width
                        height: 36
                        radius: 10
                        color: "#FAFBFC"
                        border.width: 1
                        border.color: passcodeField.activeFocus ? "#B8C5D4" : "#E4E9EF"

                        TextInput {
                            id: passcodeField
                            anchors.fill: parent
                            anchors.leftMargin: 11
                            anchors.rightMargin: 11
                            verticalAlignment: TextInput.AlignVCenter
                            color: "#222A34"
                            font.pixelSize: 13
                            echoMode: TextInput.Password
                            passwordCharacter: "●"
                            selectByMouse: true
                            clip: true
                            onAccepted: root.submitPasscode()
                        }
                    }

                    Text {
                        width: parent.width
                        visible: root.passcodeMessage.length > 0
                        text: root.passcodeMessage
                        color: root.passcodeMessage.includes("Incorrect") || root.passcodeMessage.includes("match")
                            ? "#B74A50" : "#85909C"
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        width: parent.width
                        height: 35
                        radius: 10
                        color: unlockButtonHover.containsMouse ? "#222831" : "#171C23"

                        Text {
                            anchors.centerIn: parent
                            text: root.gateMode === "create" ? "Set passcode"
                                : (root.gateMode === "confirm" ? "Confirm" : "Unlock")
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }
                        MouseArea {
                            id: unlockButtonHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.submitPasscode()
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 32
                        height: 32
                        radius: 10
                        color: closeGateHover.containsMouse ? "#F0F2F5" : "#FAFBFC"
                        border.width: 1
                        border.color: "#E5E9EE"
                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: "#46505B"
                            font.pixelSize: 20
                        }
                        MouseArea {
                            id: closeGateHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeRequested()
                        }
                    }
                }
            }

            Column {
                id: notesWorkspace
                anchors.fill: parent
                anchors.margins: 11
                spacing: 8
                visible: root.storageReady && root.accessGranted
                z: 1

                Row {
                    width: parent.width
                    height: 29
                    spacing: 5

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 8
                        color: toggleNavHover.containsMouse ? "#EEF1F4" : "#F8F9FA"
                        border.width: 1
                        border.color: "#E4E8ED"
                        Image {
                            anchors.centerIn: parent
                            width: 15
                            height: 15
                            source: Qt.resolvedUrl("../assets/icons/quick-menu.svg")
                            sourceSize.width: 30
                            sourceSize.height: 30
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
                        width: parent.width - 99
                        height: 28
                        radius: 8
                        color: "#FAFBFC"
                        border.width: 1
                        border.color: titleField.activeFocus ? "#BECAD7" : "#E5EAF0"

                        TextInput {
                            id: titleField
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 6
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
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Note name"
                            color: "#A0A9B4"
                            font.pixelSize: 11
                            visible: titleField.text.length === 0 && !titleField.activeFocus
                            enabled: false
                        }
                    }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 8
                        color: lockHover.containsMouse ? "#E8EEF4" : "#F8F9FA"
                        border.width: 1
                        border.color: "#E4E8ED"
                        Image {
                            anchors.centerIn: parent
                            width: 15
                            height: 15
                            source: Qt.resolvedUrl("../assets/icons/quick-lock-open.svg")
                            sourceSize.width: 30
                            sourceSize.height: 30
                        }
                        MouseArea {
                            id: lockHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.lockNotes()
                        }
                    }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 8
                        color: closeHover.containsMouse ? "#FBEDEE" : "#F8F9FA"
                        border.width: 1
                        border.color: "#E5E9EE"
                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: closeHover.containsMouse ? "#B9444A" : "#77818D"
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

                Row {
                    id: notesContent
                    width: parent.width
                    height: parent.height - 37
                    spacing: root.sidebarVisible ? 8 : 0

                    Rectangle {
                        id: notesSidebar
                        visible: root.sidebarVisible
                        width: root.sidebarVisible ? 104 : 0
                        height: parent.height
                        radius: 11
                        color: "#F7F8FA"
                        border.width: 1
                        border.color: "#E6EAF0"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 7
                            spacing: 7

                            Row {
                                width: parent.width
                                height: 24
                                spacing: 3
                                Text {
                                    width: parent.width - 25
                                    text: "NOTES"
                                    color: "#818B98"
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.7
                                    verticalAlignment: Text.AlignVCenter
                                }
                                Rectangle {
                                    width: 22
                                    height: 22
                                    radius: 7
                                    color: addNoteHover.containsMouse ? "#E6EAF0" : "#FFFFFF"
                                    border.width: 1
                                    border.color: "#E0E5EB"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "+"
                                        color: "#252C35"
                                        font.pixelSize: 16
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
                                height: parent.height - 31
                                clip: true
                                spacing: 4
                                model: root.orderedNotes
                                delegate: Rectangle {
                                    id: noteRow
                                    required property var modelData
                                    width: notesList.width
                                    height: 42
                                    radius: 8
                                    color: String(noteRow.modelData.id) === root.selectedNoteId
                                        ? "#E7EBF0" : (noteHover.containsMouse ? "#EEF1F4" : "transparent")
                                    Column {
                                        anchors.fill: parent
                                        anchors.leftMargin: 7
                                        anchors.rightMargin: 4
                                        anchors.topMargin: 6
                                        spacing: 3
                                        Text {
                                            width: parent.width
                                            text: (noteRow.modelData.pinned ? "★ " : "")
                                                + (noteRow.modelData.title || "Untitled note")
                                            color: "#252C35"
                                            font.pixelSize: 10
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            width: parent.width
                                            text: root.previewText(noteRow.modelData.body)
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
                                        onClicked: {
                                            root.noteMenuOpen = false
                                            root.selectNote(noteRow.modelData.id)
                                        }
                                        onDoubleClicked: {
                                            root.selectNote(noteRow.modelData.id)
                                            root.openNoteMenu(noteRow.modelData.id, noteRow)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        id: editorColumn
                        width: parent.width - (root.sidebarVisible ? 112 : 0)
                        height: parent.height
                        spacing: 6

                        Row {
                            width: parent.width
                            height: 26
                            spacing: 5

                            Rectangle {
                                width: (parent.width - 5) / 2
                                height: 26
                                radius: 8
                                color: micHover.containsMouse ? "#FCEDEF" : "#F8F9FA"
                                border.width: 1
                                border.color: root.isRecording ? "#E8ADB2" : "#E4E9EE"

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Image {
                                        width: 13
                                        height: 13
                                        source: Qt.resolvedUrl("../assets/icons/quick-mic.svg")
                                        sourceSize.width: 26
                                        sourceSize.height: 26
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: root.isRecording ? "Stop" : "Voice"
                                        color: root.isRecording ? "#B6434C" : "#4B5663"
                                        font.pixelSize: 10
                                        font.weight: Font.Medium
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                                MouseArea {
                                    id: micHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.isRecording ? root.stopRecording() : root.startRecording()
                                }
                            }

                            Rectangle {
                                width: (parent.width - 5) / 2
                                height: 26
                                radius: 8
                                color: imageHover.containsMouse ? "#E9EEF4" : "#F8F9FA"
                                border.width: 1
                                border.color: "#E4E9EE"
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Image {
                                        width: 13
                                        height: 13
                                        source: Qt.resolvedUrl("../assets/icons/quick-image.svg")
                                        sourceSize.width: 26
                                        sourceSize.height: 26
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: "Image"
                                        color: "#4B5663"
                                        font.pixelSize: 10
                                        font.weight: Font.Medium
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                                MouseArea {
                                    id: imageHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: imagePicker.open()
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            height: 20
                            visible: noteEditor.selectedText.length > 0
                            spacing: 4

                            Repeater {
                                model: [
                                    { id: "bold", text: "B", tag: "b" },
                                    { id: "italic", text: "I", tag: "i" },
                                    { id: "underline", text: "U", tag: "u" }
                                ]
                                delegate: Rectangle {
                                    required property var modelData
                                    width: 25
                                    height: 20
                                    radius: 6
                                    color: formatHover.containsMouse ? "#E9EEF4" : "#F7F8FA"
                                    border.width: 1
                                    border.color: "#E2E7ED"
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.text
                                        color: "#44505C"
                                        font.pixelSize: 10
                                        font.weight: modelData.id === "bold" ? Font.Bold : Font.Medium
                                        font.italic: modelData.id === "italic"
                                        font.underline: modelData.id === "underline"
                                    }
                                    MouseArea {
                                        id: formatHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.formatSelection(modelData.tag)
                                    }
                                }
                            }

                            Rectangle {
                                width: 22
                                height: 20
                                radius: 6
                                color: alignLeftHover.containsMouse ? "#E9EEF4" : "#F7F8FA"
                                border.width: 1
                                border.color: "#E2E7ED"
                                Text { anchors.centerIn: parent; text: "≡"; color: "#44505C"; font.pixelSize: 12 }
                                MouseArea {
                                    id: alignLeftHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setAlignment("left")
                                }
                            }
                            Rectangle {
                                width: 22
                                height: 20
                                radius: 6
                                color: alignCenterHover.containsMouse ? "#E9EEF4" : "#F7F8FA"
                                border.width: 1
                                border.color: "#E2E7ED"
                                Text { anchors.centerIn: parent; text: "≡"; color: "#44505C"; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter }
                                MouseArea {
                                    id: alignCenterHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setAlignment("center")
                                }
                            }
                            Rectangle {
                                width: 22
                                height: 20
                                radius: 6
                                color: alignRightHover.containsMouse ? "#E9EEF4" : "#F7F8FA"
                                border.width: 1
                                border.color: "#E2E7ED"
                                Text { anchors.centerIn: parent; text: "≡"; color: "#44505C"; font.pixelSize: 12; horizontalAlignment: Text.AlignRight }
                                MouseArea {
                                    id: alignRightHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setAlignment("right")
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: Math.max(86, parent.height - 58
                                - (noteEditor.selectedText.length > 0 ? 26 : 0)
                                - (root.recordingDraftReady || root.isRecording ? 42 : 0)
                                - (root.selectedNote && root.selectedNote.attachments.length > 0 ? 58 : 0)
                                - (root.mediaError.length > 0 ? 24 : 0))
                            radius: 11
                            color: "#FAFBFC"
                            border.width: 1
                            border.color: noteEditor.activeFocus ? "#BECAD7" : "#E5EAF0"

                            TextEdit {
                                id: noteEditor
                                anchors.fill: parent
                                anchors.margins: 9
                                text: ""
                                textFormat: TextEdit.RichText
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
                                        root.updateSelectedField("body", root.cleanRichHtml(text))
                                }
                                onLinkActivated: link => root.playInlineAttachment(link)
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

                        Rectangle {
                            id: recordingDraft
                            width: parent.width
                            height: 36
                            radius: 9
                            color: "#FFF8F8"
                            border.width: 1
                            border.color: "#F0D6D9"
                            visible: root.recordingDraftReady || root.isRecording
                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 6
                                spacing: 5

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 7
                                    height: 7
                                    radius: 4
                                    color: root.isRecording ? "#D8434D" : "#7DA58A"
                                    visible: true
                                    SequentialAnimation on scale {
                                        running: root.isRecording
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 1.55; duration: 420 }
                                        NumberAnimation { to: 1; duration: 420 }
                                    }
                                }
                                Text {
                                    width: parent.width - 102
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.isRecording
                                        ? "Recording " + root.recordingTime(root.recordingSeconds)
                                        : "Voice note ready"
                                    color: root.isRecording ? "#B6434C" : "#526D5B"
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }
                                Rectangle {
                                    visible: root.recordingDraftReady
                                    width: 38
                                    height: 24
                                    radius: 7
                                    color: saveVoiceHover.containsMouse ? "#171C23" : "#272E37"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Save"
                                        color: "#FFFFFF"
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                    }
                                    MouseArea {
                                        id: saveVoiceHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.saveRecordingDraft()
                                    }
                                }
                                Rectangle {
                                    visible: root.recordingDraftReady
                                    width: 22
                                    height: 24
                                    radius: 7
                                    color: discardVoiceHover.containsMouse ? "#FBEDEE" : "#F9F3F4"
                                    Text { anchors.centerIn: parent; text: "×"; color: "#B6434C"; font.pixelSize: 15 }
                                    MouseArea {
                                        id: discardVoiceHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.discardRecordingDraft()
                                    }
                                }
                            }
                        }

                        Text {
                            visible: root.mediaError.length > 0
                            width: parent.width
                            text: root.mediaError
                            color: "#B6434C"
                            font.pixelSize: 9
                            wrapMode: Text.WordWrap
                        }

                        ListView {
                            id: attachmentsList
                            width: parent.width
                            height: root.selectedNote && root.selectedNote.attachments.length > 0 ? 52 : 0
                            visible: height > 0
                            orientation: ListView.Horizontal
                            spacing: 6
                            clip: true
                            model: root.selectedNote
                                ? root.selectedNote.attachments.filter(item => !item.inline)
                                : []

                            delegate: Rectangle {
                                id: attachmentCard
                                required property var modelData
                                width: attachmentCard.modelData.type === "audio" ? 126 : 50
                                height: 48
                                radius: 9
                                color: "#F5F7F9"
                                border.width: 1
                                border.color: "#E2E7EC"

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    visible: attachmentCard.modelData.type === "image"
                                    source: attachmentCard.modelData.path
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    clip: true
                                }

                                Row {
                                    visible: attachmentCard.modelData.type === "audio"
                                    anchors.fill: parent
                                    anchors.leftMargin: 6
                                    anchors.rightMargin: 5
                                    spacing: 5

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 25
                                        height: 25
                                        radius: 8
                                        color: "#FFFFFF"
                                        border.width: 1
                                        border.color: "#E1E6EC"
                                        Text {
                                            anchors.centerIn: parent
                                            text: audioPlayer.source.toString() === attachmentCard.modelData.path && audioPlayer.playing ? "Ⅱ" : "▶"
                                            color: "#3F4A56"
                                            font.pixelSize: 11
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (root.playingAudioPath === attachmentCard.modelData.path && audioPlayer.playing)
                                                    audioPlayer.pause()
                                                else {
                                                    root.playingAudioPath = attachmentCard.modelData.path
                                                    audioPlayer.play()
                                                }
                                            }
                                        }
                                    }
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 42
                                        spacing: 2
                                        Text {
                                            width: parent.width
                                            text: audioPlayer.source.toString() === attachmentCard.modelData.path && audioPlayer.playing
                                                ? "Playing" : "Voice note"
                                            color: "#4D5967"
                                            font.pixelSize: 9
                                            font.weight: Font.Medium
                                        }
                                        Text {
                                            width: parent.width
                                            text: "Tap to play"
                                            color: "#929BA7"
                                            font.pixelSize: 8
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    width: 16
                                    height: 16
                                    radius: 6
                                    color: removeAttachmentHover.containsMouse ? "#FFFFFF" : "#F7F8FA"
                                    border.width: 1
                                    border.color: "#E2E7EC"
                                    Text { anchors.centerIn: parent; text: "×"; color: "#67727F"; font.pixelSize: 11 }
                                    MouseArea {
                                        id: removeAttachmentHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.removeAttachment(attachmentCard.modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Pin/delete menu for a sidebar note, opened by double-clicking its row.
    Item {
        id: noteContextMenu
        x: root.noteMenuX
        y: root.noteMenuY
        width: 116
        height: 78
        z: 10
        visible: root.noteMenuOpen && root.opened && root.accessGranted && !!root.noteMenuNote

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: "#FFFFFF"
            border.width: 1
            border.color: "#D9DEE5"

            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: 15
                color: "#16000000"
                z: -1
            }

            Column {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 3

                Rectangle {
                    width: parent.width
                    height: 30
                    radius: 8
                    color: pinNoteHover.containsMouse ? "#F0F3F6" : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        spacing: 7
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.noteMenuNote && root.noteMenuNote.pinned ? "★" : "☆"
                            color: "#4B5968"
                            font.pixelSize: 14
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.noteMenuNote && root.noteMenuNote.pinned ? "Unpin" : "Pin"
                            color: "#303A46"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }
                    }
                    MouseArea {
                        id: pinNoteHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.togglePinnedNote()
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 30
                    radius: 8
                    color: deleteNoteHover.containsMouse ? "#FBEDEE" : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        spacing: 7
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "×"
                            color: "#B9444A"
                            font.pixelSize: 16
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Delete"
                            color: "#B9444A"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }
                    }
                    MouseArea {
                        id: deleteNoteHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.deleteMenuNote()
                    }
                }
            }
        }
    }

}
