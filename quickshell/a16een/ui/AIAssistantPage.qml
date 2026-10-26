import QtQuick
import Quickshell
import Quickshell.Io
import qs.ui

Item {
    id: root

    property var palette: null
    property bool hasApiKey: false
    property bool connected: false
    property bool busy: false
    property bool awaitingApproval: false
    property string pageMode: "chat"
    property string keyDraft: ""
    property string inputText: ""
    property string assistantMode: "normal"
    readonly property var assistantModes: [
        { id: "normal", label: "Normal", icon: "sparkles.svg" },
        { id: "explain", label: "Explain", icon: "book-open.svg" },
        { id: "diagnose", label: "Diagnose", icon: "bug.svg" }
    ]
    property string statusLine: "Ready when you are"
    property int progressIndex: 0
    property var progressPhrases: [
        "Understanding your request",
        "Planning the next step",
        "Checking A16EEN",
        "Choosing a safe action",
        "Applying your changes",
        "Verifying the result"
    ]
    property var history: []
    property string activeConversationId: ""
    property string activeConversationTitle: "New chat"
    property var savedConversations: []
    property bool historyMenuOpen: false
    property bool loadingSavedHistory: false
    property bool persistEmptyConversation: false
    property string pendingHistoryPayload: ""
    property var historySaveQueue: []
    property var pendingCalls: []
    property int pendingCallIndex: 0
    property var toolResponses: []
    property var activeCall: ({})
    property var executionRequest: ({})
    property string lastError: ""
    property bool executionApproved: false

    readonly property color textColor: root.palette ? root.palette.textColor : "#17191D"
    readonly property color secondaryTextColor: root.palette ? root.palette.secondaryTextColor : "#555B65"
    readonly property color mutedTextColor: root.palette ? root.palette.mutedTextColor : "#7A818B"
    readonly property color fieldColor: root.palette ? root.palette.fieldColor : "#F5F6F8"
    readonly property color subtleColor: root.palette ? root.palette.subtleSurfaceColor : "#ECEFF2"
    readonly property color borderColor: root.palette ? root.palette.fieldBorderColor : "#D9DEE4"
    readonly property color accentColor: root.palette ? root.palette.actionColor : "#D8B46A"
    readonly property color accentTextColor: root.palette ? root.palette.actionTextColor : "#171717"
    readonly property color dangerColor: root.palette ? root.palette.dangerColor : "#B74646"
    readonly property color successColor: root.palette ? root.palette.successColor : "#2D9466"

    width: parent ? parent.width : 400
    height: parent ? parent.height : 520

    onHistoryChanged: root.scheduleHistorySave()
    onAssistantModeChanged: root.scheduleHistorySave()

    function refreshStatus() {
        if (!statusProcess.running)
            statusProcess.running = true
    }

    function snapshotMessages() {
        const result = []
        for (let i = 0; i < messageModel.count; i++) {
            const item = messageModel.get(i)
            result.push({ speaker: String(item.speaker || "assistant"), body: String(item.body || "") })
        }
        return result.slice(-80)
    }

    function scheduleHistorySave() {
        if (root.loadingSavedHistory || !root.activeConversationId)
            return
        if (root.history.length === 0 && !root.persistEmptyConversation)
            return
        historySaveTimer.restart()
    }

    function saveCurrentConversation(force) {
        if (root.loadingSavedHistory || !root.activeConversationId)
            return
        if (root.history.length === 0 && !root.persistEmptyConversation && force !== true)
            return

        const payload = JSON.stringify({
            id: root.activeConversationId,
            title: root.activeConversationTitle,
            mode: root.assistantMode,
            history: root.history,
            messages: root.snapshotMessages(),
            updated_at: Math.floor(Date.now() / 1000)
        })
        const queue = root.historySaveQueue.slice()
        let replaced = false
        const firstPending = historySaveProcess.running ? 1 : 0
        if (queue.length > firstPending) {
            const lastIndex = queue.length - 1
            try {
                if (JSON.parse(queue[lastIndex]).id === root.activeConversationId) {
                    queue[lastIndex] = payload
                    replaced = true
                }
            } catch (error) {
                // Replace malformed pending data rather than letting it block later saves.
            }
        }
        if (!replaced)
            queue.push(payload)
        root.historySaveQueue = queue.slice(-10)
        root.startNextHistorySave()
    }

    function startNextHistorySave() {
        if (historySaveProcess.running || root.historySaveQueue.length === 0)
            return
        root.pendingHistoryPayload = String(root.historySaveQueue[0] || "")
        if (root.pendingHistoryPayload.length)
            historySaveProcess.running = true
        else
            root.historySaveQueue = root.historySaveQueue.slice(1)
    }

    function handleHistorySaveResponse(raw) {
        try {
            const response = JSON.parse(String(raw || "{}"))
            if (response.ok === true && Array.isArray(response.conversations))
                root.savedConversations = response.conversations
            else if (response.error)
                root.lastError = String(response.error)
        } catch (error) {
            root.lastError = "Could not update local chat history."
        }
    }

    function restoreSavedConversations(raw) {
        try {
            const response = JSON.parse(String(raw || "{}"))
            if (response.ok !== true || !Array.isArray(response.conversations))
                throw new Error(String(response.error || "Invalid saved history"))
            root.savedConversations = response.conversations
            const activeId = String(response.active_id || "")
            const active = root.savedConversations.find(item => String(item.id || "") === activeId)
            if (active)
                root.openConversation(active.id, false)
            else
                root.startNewConversation(false)
        } catch (error) {
            root.lastError = "Saved chat history could not be loaded. " + String(error)
            root.startNewConversation(false)
        }
    }

    function openConversation(conversationId, markActive) {
        if (root.busy || root.awaitingApproval)
            return
        const selected = root.savedConversations.find(item => String(item.id || "") === String(conversationId || ""))
        if (!selected)
            return
        if (root.history.length > 0 || root.persistEmptyConversation)
            root.saveCurrentConversation(true)

        root.loadingSavedHistory = true
        root.historyMenuOpen = false
        root.activeConversationId = String(selected.id)
        root.activeConversationTitle = String(selected.title || "New chat")
        root.assistantMode = root.assistantModes.some(item => item.id === selected.mode)
            ? String(selected.mode) : "normal"
        root.history = Array.isArray(selected.history) ? selected.history : []
        root.persistEmptyConversation = true
        root.inputText = ""
        root.lastError = ""
        messageModel.clear()
        const messages = Array.isArray(selected.messages) ? selected.messages : []
        for (let i = 0; i < messages.length; i++) {
            const item = messages[i]
            if (item && (item.speaker === "user" || item.speaker === "assistant"))
                messageModel.append({ speaker: item.speaker, body: String(item.body || "") })
        }
        root.pageMode = root.hasApiKey ? "chat" : "settings"
        root.loadingSavedHistory = false
        Qt.callLater(() => messageList.positionViewAtEnd())
        if (markActive !== false)
            root.scheduleHistorySave()
    }

    function toggleHistoryMenu() {
        if (root.busy || root.awaitingApproval)
            return
        root.historyMenuOpen = !root.historyMenuOpen
    }

    function startNewConversation(persistBlank) {
        if (root.busy || root.awaitingApproval)
            return
        if (root.history.length > 0 || root.persistEmptyConversation)
            root.saveCurrentConversation(true)

        root.loadingSavedHistory = true
        root.activeConversationId = Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 9)
        root.activeConversationTitle = "New chat"
        root.assistantMode = "normal"
        root.history = []
        root.inputText = ""
        root.lastError = ""
        root.historyMenuOpen = false
        root.persistEmptyConversation = persistBlank === true
        messageModel.clear()
        messageModel.append({
            speaker: "assistant",
            body: "I'm A16EEN's desktop assistant. I can change wallpapers, open apps, adjust settings, diagnose your system, and perform approved power actions."
        })
        root.pageMode = root.hasApiKey ? "chat" : "settings"
        root.loadingSavedHistory = false
        if (root.persistEmptyConversation)
            root.saveCurrentConversation(true)
    }

    function appendMessage(speaker, body) {
        const text = String(body || "").trim()
        if (!text.length)
            return
        messageModel.append({ speaker: speaker, body: text })
        while (messageModel.count > 80)
            messageModel.remove(0)
        root.scheduleHistorySave()
        Qt.callLater(() => messageList.positionViewAtEnd())
    }

    function sendMessage() {
        const text = String(root.inputText || "").trim()
        if (!text.length || root.busy || root.awaitingApproval || !root.hasApiKey)
            return
        root.lastError = ""
        if (!root.activeConversationId)
            root.startNewConversation(false)
        if (root.history.length === 0) {
            root.activeConversationTitle = text.replace(/\s+/g, " ").slice(0, 64)
            root.persistEmptyConversation = true
        }
        root.inputText = ""
        root.appendMessage("user", text)
        root.history = root.history.concat([{ role: "user", parts: [{ text: text }] }])
        root.busy = true
        root.progressIndex = 0
        root.statusLine = "Understanding your request"
        root.requestGemini()
    }

    function selectAssistantMode(mode) {
        if (root.busy || root.awaitingApproval)
            return
        const normalized = String(mode || "").toLowerCase()
        if (!root.assistantModes.some(item => item.id === normalized))
            return
        root.assistantMode = normalized
        const status = {
            normal: "Ready when you are",
            explain: "Explain mode · focus on how and why",
            diagnose: "Diagnose mode · gather evidence first"
        }
        root.statusLine = status[normalized]
    }

    function requestGemini() {
        if (aiAskProcess.running)
            return
        aiAskProcess.running = true
    }

    function handleGeminiResponse(raw) {
        let response = null
        try {
            response = JSON.parse(String(raw || "{}"))
        } catch (error) {
            root.busy = false
            root.lastError = "A16EEN received an unreadable response from the AI service."
            root.statusLine = "Something went wrong"
            return
        }
        if (!response || response.ok !== true) {
            root.busy = false
            root.connected = false
            root.lastError = String(response && response.error || "Gemini did not return a response.")
            root.statusLine = "Connection needs attention"
            root.appendMessage("assistant", root.lastError)
            return
        }

        root.connected = true
        const content = response.content
        if (!content || !Array.isArray(content.parts)) {
            root.busy = false
            root.lastError = "Gemini returned an empty response."
            root.statusLine = "No response"
            root.appendMessage("assistant", root.lastError)
            return
        }

        root.history = root.history.concat([content])
        const calls = Array.isArray(response.calls) ? response.calls : []
        const responseText = String(response.text || "").trim()
        if (calls.length === 0) {
            root.busy = false
            root.statusLine = "Ready when you are"
            root.appendMessage("assistant", responseText || "I'm ready. Tell me what you'd like to do.")
            return
        }

        if (responseText.length)
            root.appendMessage("assistant", responseText)
        root.pendingCalls = calls
        root.pendingCallIndex = 0
        root.toolResponses = []
        root.runNextTool()
    }

    function actionNeedsApproval(name) {
        return [
            "close_active_window",
            "logout_session",
            "suspend_system",
            "reboot_system",
            "power_off_system"
        ].includes(String(name || ""))
    }

    function actionTitle(call) {
        const name = String(call && call.name || "")
        const titles = {
            close_active_window: "Close the active window",
            logout_session: "Log out of A16EEN",
            suspend_system: "Put the computer to sleep",
            reboot_system: "Restart the computer",
            power_off_system: "Shut down the computer"
        }
        return titles[name] || "Run system action"
    }

    function actionExplanation(call) {
        const name = String(call && call.name || "")
        const explanations = {
            close_active_window: "This will close whichever window is focused right now. Unsaved work in that app could be lost.",
            logout_session: "This will end your A16EEN desktop session. Open applications may close, and unsaved work could be lost.",
            suspend_system: "This will put the computer to sleep. Your session should resume when you wake it, but unsaved work is safer if saved first.",
            reboot_system: "This will restart the entire computer and close running applications. Save your work before continuing.",
            power_off_system: "This will power off the entire computer and close running applications. Save your work before continuing."
        }
        return explanations[name] || "This action changes your desktop session."
    }

    function confirmationLabel(call) {
        const name = String(call && call.name || "")
        if (name === "power_off_system") return "Shut down"
        if (name === "reboot_system") return "Restart"
        if (name === "suspend_system") return "Sleep"
        if (name === "logout_session") return "Log out"
        return "Close window"
    }

    function runNextTool() {
        if (root.pendingCallIndex >= root.pendingCalls.length) {
            root.awaitingApproval = false
            root.activeCall = ({})
            if (root.toolResponses.length) {
                root.history = root.history.concat([{ role: "user", parts: root.toolResponses }])
            }
            root.pendingCalls = []
            root.pendingCallIndex = 0
            root.toolResponses = []
            root.busy = true
            root.progressIndex = 1
            root.statusLine = "Checking the result"
            root.requestGemini()
            return
        }

        const call = root.pendingCalls[root.pendingCallIndex]
        root.activeCall = call
        if (root.actionNeedsApproval(call.name)) {
            root.awaitingApproval = true
            root.busy = false
            root.statusLine = "Waiting for your approval"
            return
        }
        root.executeTool(call, false)
    }

    function executeTool(call, approved) {
        root.activeCall = call
        root.executionApproved = approved
        root.executionRequest = {
            name: String(call && call.name || ""),
            args: call && call.args && typeof call.args === "object" ? call.args : ({}),
            approved: approved === true
        }
        root.awaitingApproval = false
        root.busy = true
        root.lastError = ""
        root.statusLine = approved ? "Running the approved action" : "Applying your request"
        if (!aiExecuteProcess.running)
            aiExecuteProcess.running = true
    }

    function makeFunctionResponse(call, response) {
        const value = {
            name: String(call && call.name || "unknown_action"),
            response: response
        }
        if (call && call.id)
            value.id = String(call.id)
        return { functionResponse: value }
    }

    function handleToolResult(raw) {
        let result = null
        try {
            result = JSON.parse(String(raw || "{}"))
        } catch (error) {
            result = { ok: false, error: "The system tool returned an unreadable response." }
        }
        if (!result || typeof result !== "object")
            result = { ok: false, error: "The system tool returned an empty response." }

        const call = root.activeCall || ({})
        if (!result.ok) {
            const reason = String(result.error || "The action failed.")
            root.lastError = reason
            root.appendMessage("assistant", "I couldn't complete " + root.actionTitle(call).toLowerCase() + ": " + reason)
        }
        root.toolResponses = root.toolResponses.concat([root.makeFunctionResponse(call, result)])
        root.pendingCallIndex++
        root.runNextTool()
    }

    function approveAction() {
        if (!root.awaitingApproval || !root.activeCall || !root.activeCall.name)
            return
        root.executeTool(root.activeCall, true)
    }

    function cancelAction() {
        if (!root.awaitingApproval)
            return
        const call = root.activeCall
        root.toolResponses = root.toolResponses.concat([root.makeFunctionResponse(call, {
            ok: false, cancelled: true, error: "The user declined this action."
        })])
        for (let i = root.pendingCallIndex + 1; i < root.pendingCalls.length; i++) {
            const skipped = root.pendingCalls[i]
            root.toolResponses = root.toolResponses.concat([root.makeFunctionResponse(skipped, {
                ok: false, skipped: true, error: "Not run because the user declined a previous action."
            })])
        }
        root.pendingCalls = []
        root.pendingCallIndex = 0
        root.awaitingApproval = false
        root.activeCall = ({})
        root.busy = true
        root.statusLine = "Updating the plan"
        root.history = root.history.concat([{ role: "user", parts: root.toolResponses }])
        root.toolResponses = []
        root.requestGemini()
    }

    function clearConversation() {
        root.startNewConversation(true)
    }

    function saveKey() {
        const key = String(root.keyDraft || "").trim()
        if (key.length < 10) {
            root.lastError = "Paste the API key you created in Google AI Studio."
            return
        }
        root.lastError = ""
        root.busy = true
        root.progressIndex = 0
        root.statusLine = "Saving your Gemini key securely"
        if (!keySetProcess.running)
            keySetProcess.running = true
    }

    function handleKeySaved(code) {
        root.keyDraft = ""
        if (code !== 0) {
            root.busy = false
            root.lastError = "The API key could not be saved. Make sure it is valid text without spaces."
            root.statusLine = "Key not saved"
            return
        }
        root.hasApiKey = true
        root.statusLine = "Testing Gemini connection"
        connectionTestProcess.running = true
    }

    function handleConnectionTest(raw) {
        let result = null
        try { result = JSON.parse(String(raw || "{}")) } catch (error) { result = null }
        root.busy = false
        if (result && result.ok === true) {
            root.hasApiKey = true
            root.connected = true
            root.lastError = ""
            root.pageMode = "chat"
            root.statusLine = "Connected to Gemini"
            if (messageModel.count === 0)
                root.appendMessage("assistant", "Gemini is connected. Tell me what you want done, and I'll use A16EEN's available system tools to help.")
        } else {
            root.connected = false
            root.hasApiKey = true
            root.pageMode = "settings"
            root.lastError = String(result && result.error || "Gemini connection failed. Check your key and internet connection.")
            root.statusLine = "Connection failed"
        }
    }

    function removeKey() {
        if (root.busy)
            return
        keyRemoveProcess.running = true
    }

    Component.onCompleted: {
        root.refreshStatus()
        historyLoadProcess.running = true
    }

    Timer {
        id: historySaveTimer
        interval: 350
        repeat: false
        onTriggered: root.saveCurrentConversation(false)
    }

    Process {
        id: historyLoadProcess
        command: ["a16een-ai", "history", "list"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.restoreSavedConversations(String(text || "{}"))
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const value = String(text || "").trim()
                if (value.length)
                    console.warn("A16EEN local chat history:", value)
            }
        }
    }

    Process {
        id: historySaveProcess
        command: ["a16een-ai", "history", "save-stdin"]
        stdinEnabled: true
        running: false
        onStarted: write(root.pendingHistoryPayload + "\n")
        onExited: (exitCode, exitStatus) => {
            root.historySaveQueue = root.historySaveQueue.slice(1)
            Qt.callLater(() => root.startNextHistorySave())
        }
        stdout: StdioCollector {
            onStreamFinished: root.handleHistorySaveResponse(String(text || "{}"))
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const value = String(text || "").trim()
                if (value.length)
                    console.warn("A16EEN chat save:", value)
            }
        }
    }

    Process {
        id: statusProcess
        command: ["a16een-ai", "status"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const value = JSON.parse(String(text || "{}"))
                    root.hasApiKey = value.ok === true && value.configured === true
                } catch (error) {
                    root.hasApiKey = false
                }
                if (!root.hasApiKey)
                    root.pageMode = "settings"
                else if (root.activeConversationId.length && root.pageMode === "settings")
                    root.pageMode = "chat"
            }
        }
    }

    Process {
        id: keySetProcess
        command: ["a16een-ai", "key", "set-stdin"]
        stdinEnabled: true
        running: false
        onStarted: write(String(root.keyDraft || "").trim() + "\n")
        onExited: (exitCode, exitStatus) => root.handleKeySaved(exitCode)
        stderr: StdioCollector {
            onStreamFinished: {
                const value = String(text || "").trim()
                if (value.length)
                    console.warn("A16EEN AI key storage:", value)
            }
        }
    }

    Process {
        id: keyRemoveProcess
        command: ["a16een-ai", "key", "remove"]
        running: false
        onExited: (exitCode, exitStatus) => {
            root.hasApiKey = false
            root.connected = false
            root.pageMode = "settings"
            root.history = []
            messageModel.clear()
            root.refreshStatus()
        }
    }

    Process {
        id: connectionTestProcess
        command: ["a16een-ai", "test"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.handleConnectionTest(String(text || "{}"))
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const value = String(text || "").trim()
                if (value.length)
                    console.warn("A16EEN Gemini connection test:", value)
            }
        }
    }

    Process {
        id: aiAskProcess
        command: ["a16een-ai", "ask"]
        stdinEnabled: true
        running: false
        onStarted: write(JSON.stringify({ history: root.history, mode: root.assistantMode }) + "\n")
        stdout: StdioCollector {
            onStreamFinished: root.handleGeminiResponse(String(text || "{}"))
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const value = String(text || "").trim()
                if (value.length)
                    console.warn("A16EEN Gemini request:", value)
            }
        }
    }

    Process {
        id: aiExecuteProcess
        command: ["a16een-ai", "execute"]
        stdinEnabled: true
        running: false
        onStarted: write(JSON.stringify(root.executionRequest) + "\n")
        stdout: StdioCollector {
            onStreamFinished: root.handleToolResult(String(text || "{}"))
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const value = String(text || "").trim()
                if (value.length)
                    console.warn("A16EEN AI action:", value)
            }
        }
    }

    ListModel {
        id: messageModel
    }

    Column {
        anchors.fill: parent
        spacing: 0

        Column {
            visible: root.pageMode === "settings" || !root.hasApiKey
            width: parent.width
            height: visible ? parent.height : 0
            spacing: 8

            Text {
                width: parent.width
                text: root.hasApiKey ? "GEMINI CONNECTION" : "CONNECT YOUR GEMINI KEY"
                color: root.textColor
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 0.55
            }

            Text {
                width: parent.width
                text: "Create or copy a Gemini API key in Google AI Studio. A16EEN stores it locally with owner-only permissions; prompts and any system details needed for your request are sent to Google Gemini."
                color: root.secondaryTextColor
                font.pixelSize: 9
                wrapMode: Text.WordWrap
                lineHeight: 1.2
            }

            Rectangle {
                width: parent.width
                height: 36
                radius: 10
                color: root.fieldColor
                border.width: 1
                border.color: root.borderColor

                Text {
                    anchors.centerIn: parent
                    text: "OPEN GOOGLE AI STUDIO  ↗"
                    color: root.textColor
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.4
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["xdg-open", "https://aistudio.google.com/apikeys"])
                }
            }

            Text {
                width: parent.width
                text: "Paste API key"
                color: root.secondaryTextColor
                font.pixelSize: 8
                font.weight: Font.DemiBold
            }

            Rectangle {
                width: parent.width
                height: 39
                radius: 10
                color: root.fieldColor
                border.width: 1
                border.color: keyInput.activeFocus ? root.accentColor : root.borderColor

                TextInput {
                    id: keyInput
                    anchors.fill: parent
                    anchors.leftMargin: 11
                    anchors.rightMargin: 11
                    verticalAlignment: TextInput.AlignVCenter
                    color: root.textColor
                    selectedTextColor: "#FFFFFF"
                    selectionColor: "#6F7E92"
                    font.pixelSize: 10
                    font.family: "monospace"
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    selectByMouse: true
                    clip: true
                    text: root.keyDraft
                    onTextEdited: root.keyDraft = text
                    onAccepted: root.saveKey()
                }
            }

            Row {
                width: parent.width
                spacing: 7

                Rectangle {
                    width: parent.width * 0.64
                    height: 37
                    radius: 10
                    color: root.busy ? root.subtleColor : root.accentColor
                    border.width: 1
                    border.color: root.borderColor

                    Text {
                        anchors.centerIn: parent
                        text: root.busy ? "CONNECTING…" : (root.hasApiKey ? "SAVE & TEST KEY" : "SAVE & CONNECT")
                        color: root.busy ? root.secondaryTextColor : root.accentTextColor
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        font.letterSpacing: 0.25
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.busy
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.saveKey()
                    }
                }

                Rectangle {
                    width: parent.width - parent.children[0].width - parent.spacing
                    height: 37
                    radius: 10
                    color: secondaryMouse.containsMouse ? root.subtleColor : "transparent"
                    border.width: 1
                    border.color: root.borderColor
                    visible: root.hasApiKey

                    Text {
                        anchors.centerIn: parent
                        text: "REMOVE"
                        color: root.secondaryTextColor
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: secondaryMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.removeKey()
                    }
                }
            }

            Text {
                width: parent.width
                visible: root.lastError.length > 0
                text: root.lastError
                color: root.dangerColor
                font.pixelSize: 8
                wrapMode: Text.WordWrap
            }

            Text {
                width: parent.width
                visible: root.hasApiKey
                text: "Your saved key stays on this computer until you remove it. Keep it private."
                color: root.mutedTextColor
                font.pixelSize: 8
                wrapMode: Text.WordWrap
            }

            Rectangle {
                visible: root.hasApiKey
                width: parent.width
                height: 30
                radius: 9
                color: "transparent"
                border.width: 1
                border.color: root.borderColor

                Text {
                    anchors.centerIn: parent
                    text: "BACK TO ASSISTANT"
                    color: root.secondaryTextColor
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.35
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pageMode = "chat"
                }
            }
        }

        Column {
            id: chatPanel
            visible: root.pageMode === "chat" && root.hasApiKey
            width: parent.width
            height: visible ? parent.height : 0
            spacing: 7

            Row {
                id: modeSelector
                width: parent.width
                height: 29
                spacing: 6

                Repeater {
                    model: root.assistantModes

                    delegate: Rectangle {
                        id: modeChip
                        required property var modelData
                        width: Math.floor((modeSelector.width - 12) / 3)
                        height: 29
                        radius: 9
                        color: root.assistantMode === modelData.id ? root.subtleColor : "transparent"
                        border.width: 1
                        border.color: root.assistantMode === modelData.id ? root.accentColor : root.borderColor

                        Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        Behavior on border.color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 5

                            NavbarIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 12
                                height: 12
                                iconName: modeChip.modelData.icon
                                iconColor: root.assistantMode === modeChip.modelData.id ? root.textColor : root.mutedTextColor
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modeChip.modelData.label
                                color: root.assistantMode === modeChip.modelData.id ? root.textColor : root.mutedTextColor
                                font.pixelSize: 8
                                font.weight: root.assistantMode === modeChip.modelData.id ? Font.DemiBold : Font.Medium
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: !root.busy && !root.awaitingApproval
                            onClicked: root.selectAssistantMode(modeChip.modelData.id)
                        }

                        Accessible.name: modeChip.modelData.label + " response mode"
                    }
                }
            }

            ListView {
                id: messageList
                width: parent.width
                height: Math.max(80, chatPanel.height - modeSelector.height
                    - chatComposerRow.height - approvalCard.height - errorMessage.height - chatPanel.spacing * 4)
                clip: true
                spacing: 7
                model: messageModel
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                delegate: Item {
                    id: messageRow
                    required property string speaker
                    required property string body
                    width: messageList.width
                    height: bubble.height + 10

                    Rectangle {
                        id: bubble
                        readonly property bool fromUser: messageRow.speaker === "user"
                        width: fromUser ? messageRow.width * 0.84 : messageRow.width - 6
                        height: Math.max(fromUser ? 43 : 49,
                            messageBody.implicitHeight + messageMetaRow.height + 22)
                        anchors.left: fromUser ? undefined : parent.left
                        anchors.right: fromUser ? parent.right : undefined
                        radius: 14
                        border.width: 1
                        border.color: fromUser ? "#3B4A63" : root.borderColor

                        gradient: Gradient {
                            GradientStop {
                                position: 0.0
                                color: bubble.fromUser ? "#2A3951" : Qt.lighter(root.fieldColor, 1.015)
                            }
                            GradientStop {
                                position: 1.0
                                color: bubble.fromUser ? "#172131" : root.fieldColor
                            }
                        }

                        Rectangle {
                            visible: !bubble.fromUser
                            anchors.left: parent.left
                            anchors.leftMargin: 0
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            height: Math.max(18, parent.height - 24)
                            radius: 2
                            color: "#D6AD60"
                        }

                        Column {
                            id: messageContent
                            anchors.fill: parent
                            anchors.leftMargin: bubble.fromUser ? 11 : 14
                            anchors.rightMargin: 11
                            anchors.topMargin: 8
                            anchors.bottomMargin: 9
                            spacing: 5

                            Row {
                                id: messageMetaRow
                                width: parent.width
                                height: 10
                                spacing: 5

                                Rectangle {
                                    width: 5
                                    height: 5
                                    radius: 2.5
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: bubble.fromUser ? "#A5B4FC" : "#D6AD60"
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: bubble.fromUser ? "YOU" : "A16EEN AI"
                                    color: bubble.fromUser ? "#D4DCE8" : root.mutedTextColor
                                    font.pixelSize: 7
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.65
                                }
                            }

                            Text {
                                id: messageBody
                                width: parent.width
                                text: messageRow.body
                                color: bubble.fromUser ? "#F8FAFC" : root.textColor
                                font.pixelSize: 10
                                wrapMode: Text.WordWrap
                                textFormat: Text.PlainText
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: approvalCard
                visible: root.awaitingApproval
                width: parent.width
                height: root.awaitingApproval ? 108 : 0
                radius: 11
                color: root.fieldColor
                border.width: 1
                border.color: root.accentColor

                Column {
                    anchors.fill: parent
                    anchors.margins: 9
                    spacing: 5

                    Text {
                        width: parent.width
                        text: "REVIEW THIS ACTION"
                        color: root.accentColor
                        font.pixelSize: 7
                        font.weight: Font.Bold
                        font.letterSpacing: 0.8
                    }

                    Text {
                        width: parent.width
                        text: root.actionTitle(root.activeCall)
                        color: root.textColor
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        text: root.actionExplanation(root.activeCall)
                        color: root.secondaryTextColor
                        font.pixelSize: 8
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }

                    Row {
                        width: parent.width
                        spacing: 7

                        Rectangle {
                            width: (parent.width - parent.spacing) * 0.62
                            height: 27
                            radius: 8
                            color: root.accentColor

                            Text {
                                anchors.centerIn: parent
                                text: "CONFIRM " + root.confirmationLabel(root.activeCall).toUpperCase()
                                color: root.accentTextColor
                                font.pixelSize: 7
                                font.weight: Font.Bold
                                font.letterSpacing: 0.25
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: root.awaitingApproval
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.approveAction()
                            }
                        }

                        Rectangle {
                            width: parent.width - parent.children[0].width - parent.spacing
                            height: 27
                            radius: 8
                            color: cancelMouse.containsMouse ? root.subtleColor : "transparent"
                            border.width: 1
                            border.color: root.borderColor

                            Text {
                                anchors.centerIn: parent
                                text: "CANCEL"
                                color: root.secondaryTextColor
                                font.pixelSize: 7
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                id: cancelMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.cancelAction()
                            }
                        }
                    }
                }
            }

            Text {
                id: errorMessage
                width: parent.width
                height: visible ? 22 : 0
                visible: root.lastError.length > 0 && !root.awaitingApproval
                text: root.lastError
                color: root.dangerColor
                font.pixelSize: 8
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            Row {
                id: chatComposerRow
                width: parent.width
                height: 43
                spacing: 7

                Rectangle {
                    width: parent.width - 49
                    height: 43
                    radius: 10
                    color: root.fieldColor
                    border.width: 1
                    border.color: composerInput.activeFocus ? root.accentColor : root.borderColor

                    TextInput {
                        id: composerInput
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        color: root.textColor
                        selectedTextColor: "#FFFFFF"
                        selectionColor: "#6F7E92"
                        font.pixelSize: 10
                        clip: true
                        selectByMouse: true
                        text: root.inputText
                        onTextEdited: root.inputText = text
                        onAccepted: root.sendMessage()
                        enabled: !root.busy && !root.awaitingApproval
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.inputText.length === 0 && !composerInput.activeFocus
                        text: "Ask your desktop…"
                        color: root.mutedTextColor
                        font.pixelSize: 9
                    }
                }

                Rectangle {
                    id: composerSendButton
                    width: 42
                    height: 43
                    radius: 12
                    color: root.busy || root.awaitingApproval || !root.inputText.trim().length
                        ? root.subtleColor : root.accentColor
                    border.width: 1
                    border.color: root.busy || root.awaitingApproval || !root.inputText.trim().length
                        ? root.borderColor : root.accentColor
                    opacity: root.busy ? 0.72 : 1.0

                    Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                    NavbarIcon {
                        anchors.centerIn: parent
                        width: 17
                        height: 17
                        rotation: 90
                        iconName: "lucide-arrow-left.svg"
                        iconColor: root.busy || root.awaitingApproval || !root.inputText.trim().length
                            ? root.mutedTextColor : root.accentTextColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.busy && !root.awaitingApproval && root.inputText.trim().length > 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.sendMessage()
                    }

                    Accessible.name: root.busy ? "Assistant is working" : "Send message"
                }
            }


        }
    }

    Item {
        id: historyOverlay
        anchors.fill: parent
        visible: root.historyMenuOpen
        z: 50

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: root.fieldColor
            border.width: 1
            border.color: root.borderColor
        }

        Column {
            anchors.fill: parent
            anchors.margins: 11
            spacing: 9

            Row {
                width: parent.width
                height: 25
                spacing: 8

                Text {
                    width: parent.width - 30
                    anchors.verticalCenter: parent.verticalCenter
                    text: "CHAT HISTORY"
                    color: root.textColor
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.7
                }

                Rectangle {
                    width: 24
                    height: 24
                    radius: 7
                    color: historyCloseMouse.containsMouse ? root.subtleColor : "transparent"

                    Item {
                        anchors.centerIn: parent
                        width: 12
                        height: 12
                        Rectangle {
                            anchors.centerIn: parent
                            width: 13
                            height: 1.5
                            radius: 1
                            color: root.secondaryTextColor
                            rotation: 45
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: 13
                            height: 1.5
                            radius: 1
                            color: root.secondaryTextColor
                            rotation: -45
                        }
                    }

                    MouseArea {
                        id: historyCloseMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.historyMenuOpen = false
                    }

                    Accessible.name: "Close chat history"
                }
            }

            Text {
                width: parent.width
                visible: root.savedConversations.length === 0
                text: "Your conversations will appear here as you chat."
                color: root.mutedTextColor
                font.pixelSize: 9
                wrapMode: Text.WordWrap
            }

            ListView {
                id: conversationList
                width: parent.width
                height: Math.max(60, parent.height - 38)
                clip: true
                spacing: 5
                model: root.savedConversations
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: conversationRow
                    required property var modelData
                    width: conversationList.width
                    height: 52
                    radius: 9
                    color: String(conversationRow.modelData.id || "") === root.activeConversationId
                        ? root.subtleColor : "transparent"
                    border.width: 1
                    border.color: String(conversationRow.modelData.id || "") === root.activeConversationId
                        ? root.accentColor : root.borderColor

                    Column {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        anchors.topMargin: 7
                        anchors.bottomMargin: 6
                        spacing: 3

                        Text {
                            width: parent.width
                            text: String(conversationRow.modelData.title || "New chat")
                            color: root.textColor
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: String(conversationRow.modelData.mode || "normal").toUpperCase()
                                + "  ·  "
                                + (Number(conversationRow.modelData.updated_at) > 0
                                    ? new Date(Number(conversationRow.modelData.updated_at) * 1000).toLocaleString()
                                    : "Saved locally")
                            color: root.mutedTextColor
                            font.pixelSize: 7
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !root.busy && !root.awaitingApproval
                        onClicked: root.openConversation(conversationRow.modelData.id, true)
                    }

                    Accessible.name: String(conversationRow.modelData.title || "New chat")
                }
            }
        }
    }
}
