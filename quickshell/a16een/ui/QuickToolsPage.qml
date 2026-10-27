import QtQuick
import Quickshell
import Quickshell.Io
import qs.ui

Item {
    id: root

    property string page: "updates"
    property var palette: null
    property var updateData: ({})
    property string updateMessage: "Checking update status…"
    property var lockerApps: []
    property string lockerMessage: ""
    property string appSearch: ""
    property string passwordMode: ""
    property string selectedAppId: ""
    property string selectedAppName: ""
    property string pendingInput: ""
    property string sessionMessage: ""
    property var sessionSnapshots: []
    property bool actionBusy: false

    readonly property color textColor: root.palette && root.palette.textColor ? root.palette.textColor : "#171717"
    readonly property color secondaryColor: root.palette && root.palette.secondaryTextColor ? root.palette.secondaryTextColor : "#393939"
    readonly property color mutedColor: root.palette && root.palette.mutedTextColor ? root.palette.mutedTextColor : "#777777"
    readonly property color iconColor: root.palette && root.palette.iconColor ? root.palette.iconColor : "#1B1B1B"
    readonly property color borderColor: root.palette && root.palette.fieldBorderColor ? root.palette.fieldBorderColor : "#DADADA"
    readonly property color surfaceColor: root.palette && root.palette.fieldColor ? root.palette.fieldColor : "#F7F7F7"
    readonly property color subtleColor: root.palette && root.palette.subtleSurfaceColor ? root.palette.subtleSurfaceColor : "#F0F0F0"
    readonly property color hoverColor: root.palette && root.palette.hoverSurfaceColor ? root.palette.hoverSurfaceColor : "#EAEAEA"
    readonly property color accentColor: "#C69A50"
    readonly property var systemPackages: root.updateData && root.updateData.system && Array.isArray(root.updateData.system.packages)
        ? root.updateData.system.packages : []
    readonly property var filteredApps: root.lockerApps.filter(app => {
        const query = root.appSearch.trim().toLowerCase()
        return !query || String(app.name || "").toLowerCase().includes(query)
            || String(app.desktop_id || "").toLowerCase().includes(query)
    })

    function parseJson(raw, fallback) {
        try {
            const parsed = JSON.parse(String(raw || "{}"))
            return parsed && typeof parsed === "object" ? parsed : fallback
        } catch (error) {
            return fallback
        }
    }

    function refreshUpdates(force) {
        if (updateProcess.running)
            return
        root.updateMessage = force ? "Checking for updates…" : "Loading update status…"
        updateProcess.command = force
            ? ["a16een-quick-tools", "updates", "--force"]
            : ["a16een-quick-tools", "updates"]
        updateProcess.running = true
    }

    function refreshLocker() {
        if (!lockerListProcess.running)
            lockerListProcess.running = true
    }

    function openPasswordDialog(mode, app) {
        root.passwordMode = mode
        root.selectedAppId = String(app.desktop_id || "")
        root.selectedAppName = String(app.name || "Application")
        root.lockerMessage = mode === "protect"
            ? "Choose a password for " + root.selectedAppName + "."
            : (mode === "remove"
                ? "Enter the password to remove this app's launch lock."
                : "Enter the password to unlock and launch this app.")
        if (mode === "protect")
            confirmPasswordInput.text = ""
        passwordInput.text = ""
        Qt.callLater(() => passwordInput.forceActiveFocus())
    }

    function clearPasswordDialog() {
        root.passwordMode = ""
        root.selectedAppId = ""
        root.selectedAppName = ""
        root.pendingInput = ""
        passwordInput.text = ""
        confirmPasswordInput.text = ""
    }

    function submitLockerAction() {
        if (lockerActionProcess.running || !root.passwordMode)
            return
        const password = String(passwordInput.text || "")
        if (!password.length) {
            root.lockerMessage = "Enter your password first."
            return
        }
        let action = "launch"
        let input = password + "\n"
        if (root.passwordMode === "protect") {
            if (password.length < 6) {
                root.lockerMessage = "Use at least 6 characters."
                return
            }
            if (password !== String(confirmPasswordInput.text || "")) {
                root.lockerMessage = "The passwords do not match."
                return
            }
            action = "protect"
            input += String(confirmPasswordInput.text || "") + "\n"
        } else if (root.passwordMode === "remove") {
            action = "unprotect"
        }
        root.pendingInput = input
        root.lockerMessage = action === "protect" ? "Saving the password securely…" : "Checking password…"
        lockerActionProcess.command = action === "protect"
            ? ["a16een-quick-tools", "app-locker", "protect", root.selectedAppId, root.selectedAppName]
            : ["a16een-quick-tools", "app-locker", action, root.selectedAppId]
        passwordInput.text = ""
        confirmPasswordInput.text = ""
        lockerActionProcess.running = true
    }

    function handleLockerAction(raw) {
        const result = root.parseJson(raw, ({ok:false, message:"App Locker could not read the result."}))
        root.lockerMessage = String(result.message || (result.ok ? "Done." : "App Locker action failed."))
        if (result.ok) {
            root.clearPasswordDialog()
            Qt.callLater(() => root.refreshLocker())
        }
    }

    function refreshSessions() {
        if (!sessionListProcess.running)
            sessionListProcess.running = true
    }

    function runSessionAction(args) {
        if (sessionActionProcess.running)
            return
        sessionActionProcess.command = ["a16een-quick-tools", "snapshot", ...args]
        sessionActionProcess.running = true
    }

    function showSessionResult(raw) {
        const result = root.parseJson(raw, ({ok:false, message:"Session Snapshots could not read the result."}))
        root.sessionMessage = String(result.message || (result.ok ? "Done." : "Session snapshot action failed."))
        if (result.ok || root.page === "sessions")
            Qt.callLater(() => root.refreshSessions())
    }

    onPageChanged: {
        if (root.page === "updates") {
            root.refreshUpdates(false)
        } else if (root.page === "app-locker") {
            root.refreshLocker()
        } else if (root.page === "sessions") {
            root.runSessionAction(["auto"])
        }
    }

    Component.onCompleted: {
        if (root.page === "updates")
            Qt.callLater(() => root.refreshUpdates(false))
        else if (root.page === "app-locker")
            Qt.callLater(() => root.refreshLocker())
        else if (root.page === "sessions")
            Qt.callLater(() => root.runSessionAction(["auto"]))
    }

    Process {
        id: updateProcess
        command: ["a16een-quick-tools", "updates"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const parsed = root.parseJson(String(text || "{}"), ({}))
                if (parsed.version === 1) {
                    root.updateData = parsed
                    root.updateMessage = parsed.cached
                        ? "Daily check · cached result"
                        : "Update check complete"
                } else {
                    root.updateMessage = String(parsed.message || "Update status is unavailable.")
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(text || "").trim()
                if (message.length)
                    console.warn("A16EEN update checker:", message)
            }
        }
    }

    Process {
        id: lockerListProcess
        command: ["a16een-quick-tools", "app-locker", "apps"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const result = root.parseJson(String(text || "{}"), ({}))
                root.lockerApps = Array.isArray(result.apps) ? result.apps : []
                if (result.message)
                    root.lockerMessage = String(result.message)
            }
        }
    }

    Process {
        id: lockerActionProcess
        command: ["a16een-quick-tools", "app-locker", "apps"]
        stdinEnabled: true
        running: false

        onStarted: {
            if (root.pendingInput.length) {
                write(root.pendingInput)
                root.pendingInput = ""
            }
        }

        stdout: StdioCollector {
            onStreamFinished: root.handleLockerAction(String(text || "{}"))
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(text || "").trim()
                if (message.length)
                    console.warn("A16EEN App Locker:", message)
            }
        }
    }

    Process {
        id: sessionListProcess
        command: ["a16een-quick-tools", "snapshot", "list"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const result = root.parseJson(String(text || "{}"), ({}))
                root.sessionSnapshots = Array.isArray(result.snapshots) ? result.snapshots : []
            }
        }
    }

    Process {
        id: sessionActionProcess
        command: ["a16een-quick-tools", "snapshot", "list"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.showSessionResult(String(text || "{}"))
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(text || "").trim()
                if (message.length)
                    console.warn("A16EEN Session Snapshots:", message)
            }
        }
    }

    Flickable {
        id: pageFlick
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: root.page === "updates" ? updatesContent.implicitHeight
            : (root.page === "app-locker" ? lockerContent.implicitHeight : sessionsContent.implicitHeight)

        Column {
            id: updatesContent
            visible: root.page === "updates"
            width: pageFlick.width
            spacing: 8

            Rectangle {
                width: parent.width
                height: 94
                radius: 12
                color: root.subtleColor
                border.width: 1
                border.color: root.borderColor

                Column {
                    anchors.fill: parent
                    anchors.margins: 11
                    spacing: 5

                    Row {
                        width: parent.width
                        spacing: 8

                        Rectangle {
                            width: 29
                            height: 29
                            radius: 9
                            color: root.surfaceColor
                            anchors.verticalCenter: parent.verticalCenter
                            NavbarIcon {
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                iconName: "lucide-github.svg"
                                iconColor: root.iconColor
                            }
                        }

                        Column {
                            width: parent.width - 110
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            Text {
                                text: "A16EEN"
                                color: root.textColor
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                            Text {
                                width: parent.width
                                text: root.updateData.a16een ? String(root.updateData.a16een.message || "Waiting for status…") : "Checking GitHub for a newer revision"
                                color: root.mutedColor
                                font.pixelSize: 8
                                elide: Text.ElideRight
                            }
                        }

                        Item { width: 1; height: 1 }

                        Rectangle {
                            width: 60
                            height: 27
                            radius: 8
                            color: root.accentColor
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                anchors.centerIn: parent
                                text: updateProcess.running ? "CHECKING" : "CHECK NOW"
                                color: "#FFFFFF"
                                font.pixelSize: 7
                                font.weight: Font.DemiBold
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: !updateProcess.running
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.refreshUpdates(true)
                            }
                        }
                    }

                    Row {
                        spacing: 5
                        Text {
                            text: root.updateData.a16een && root.updateData.a16een.available
                                ? String(root.updateData.a16een.commit_count || 0) + " newer commits"
                                : "Read-only check"
                            color: root.secondaryColor
                            font.pixelSize: 8
                        }
                        Text { text: "·"; color: root.mutedColor; font.pixelSize: 8 }
                        Text {
                            text: root.updateData.a16een && Number(root.updateData.a16een.changed_files) > 0
                                ? String(root.updateData.a16een.changed_files) + " changed files"
                                : "No files pending"
                            color: root.mutedColor
                            font.pixelSize: 8
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 103
                radius: 12
                color: root.subtleColor
                border.width: 1
                border.color: root.borderColor

                Column {
                    anchors.fill: parent
                    anchors.margins: 11
                    spacing: 5

                    Row {
                        width: parent.width
                        spacing: 8

                        Rectangle {
                            width: 29
                            height: 29
                            radius: 9
                            color: root.surfaceColor
                            anchors.verticalCenter: parent.verticalCenter
                            NavbarIcon {
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                iconName: "lucide-package-check.svg"
                                iconColor: root.iconColor
                            }
                        }

                        Column {
                            width: parent.width - 46
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            Text {
                                text: "SYSTEM PACKAGES"
                                color: root.textColor
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.3
                            }
                            Text {
                                width: parent.width
                                text: root.updateData.system ? String(root.updateData.system.message || "Waiting for a package check…") : "Safe read-only Arch Linux check"
                                color: root.mutedColor
                                font.pixelSize: 8
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 7

                        Rectangle {
                            width: (parent.width - 14) / 3
                            height: 36
                            radius: 8
                            color: root.surfaceColor
                            Column {
                                anchors.centerIn: parent
                                spacing: 2
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.updateData.system ? String(root.updateData.system.count || 0) : "—"
                                    color: root.textColor
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "UPDATES"
                                    color: root.mutedColor
                                    font.pixelSize: 7
                                    font.letterSpacing: 0.4
                                }
                            }
                        }

                        Rectangle {
                            width: (parent.width - 14) / 3
                            height: 36
                            radius: 8
                            color: root.surfaceColor
                            Column {
                                anchors.centerIn: parent
                                spacing: 2
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.updateData.system ? String(root.updateData.system.estimated_size || "—") : "—"
                                    color: root.textColor
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "EST. DOWNLOAD"
                                    color: root.mutedColor
                                    font.pixelSize: 7
                                    font.letterSpacing: 0.2
                                }
                            }
                        }

                        Rectangle {
                            width: (parent.width - 14) / 3
                            height: 36
                            radius: 8
                            color: root.surfaceColor
                            Column {
                                anchors.centerIn: parent
                                spacing: 2
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.updateData.system && root.updateData.system.available ? "READY" : "CLEAR"
                                    color: root.updateData.system && root.updateData.system.available ? root.accentColor : root.textColor
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "STATUS"
                                    color: root.mutedColor
                                    font.pixelSize: 7
                                    font.letterSpacing: 0.4
                                }
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 4
                visible: root.systemPackages.length > 0

                Text {
                    text: "PACKAGE DETAILS"
                    color: root.mutedColor
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.7
                }

                Repeater {
                    model: root.systemPackages.slice(0, 5)
                    delegate: Rectangle {
                        required property var modelData
                        width: updatesContent.width
                        height: 31
                        radius: 7
                        color: "transparent"

                        Column {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text {
                                width: parent.width
                                text: String(modelData.name || "Package")
                                color: root.textColor
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                text: String(modelData.current || "?") + "  →  " + String(modelData.latest || "?")
                                color: root.mutedColor
                                font.pixelSize: 8
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.size_bytes === null || modelData.size_bytes === undefined ? "" : (Number(modelData.size_bytes) / 1048576).toFixed(1) + " MB"
                            color: root.mutedColor
                            font.pixelSize: 8
                        }
                    }
                }

                Text {
                    visible: root.systemPackages.length > 5
                    text: "+" + String(root.systemPackages.length - 5) + " more packages"
                    color: root.mutedColor
                    font.pixelSize: 8
                }
            }

            Text {
                width: parent.width
                text: root.updateMessage + (root.updateData.checked_at ? "  ·  " + String(root.updateData.checked_at).replace("T", " ").replace("Z", " UTC") : "")
                color: root.mutedColor
                font.pixelSize: 8
                wrapMode: Text.Wrap
            }

            Text {
                width: parent.width
                text: "Checks run at most once per day automatically. Nothing is installed until you choose an update command."
                color: root.mutedColor
                font.pixelSize: 8
                wrapMode: Text.Wrap
            }
        }

        Column {
            id: lockerContent
            visible: root.page === "app-locker"
            width: pageFlick.width
            spacing: 7

            Rectangle {
                width: parent.width
                height: root.passwordMode ? 142 : 61
                radius: 11
                color: root.subtleColor
                border.width: 1
                border.color: root.borderColor

                Column {
                    anchors.fill: parent
                    anchors.margins: 9
                    spacing: 5

                    Row {
                        width: parent.width
                        spacing: 6
                        Text {
                            width: parent.width - 34
                            text: root.passwordMode === "protect"
                                ? "SET APP PASSWORD"
                                : (root.passwordMode === "remove" ? "REMOVE APP LOCK" : (root.passwordMode === "launch" ? "UNLOCK APP" : "APP LOCKER"))
                            color: root.textColor
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.4
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                        }
                        Rectangle {
                            width: 25
                            height: 23
                            radius: 7
                            color: root.hoverColor
                            visible: root.passwordMode.length > 0
                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                color: root.iconColor
                                font.pixelSize: 15
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.clearPasswordDialog()
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        visible: root.passwordMode.length > 0
                        text: root.selectedAppName
                        color: root.mutedColor
                        font.pixelSize: 8
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        width: parent.width
                        height: 32
                        radius: 8
                        visible: root.passwordMode.length > 0
                        color: root.surfaceColor
                        border.width: 1
                        border.color: root.borderColor
                        TextInput {
                            id: passwordInput
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            anchors.rightMargin: 9
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            color: root.textColor
                            font.pixelSize: 10
                            clip: true
                            selectByMouse: true
                            focus: root.passwordMode.length > 0
                            onAccepted: {
                                if (root.passwordMode !== "protect")
                                    root.submitLockerAction()
                                else
                                    confirmPasswordInput.forceActiveFocus()
                            }
                        }
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 9
                            anchors.verticalCenter: parent.verticalCenter
                            visible: passwordInput.text.length === 0 && !passwordInput.activeFocus
                            text: root.passwordMode === "protect" ? "New password · 6+ characters" : "Password"
                            color: root.mutedColor
                            font.pixelSize: 8
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 30
                        radius: 8
                        visible: root.passwordMode === "protect"
                        color: root.surfaceColor
                        border.width: 1
                        border.color: root.borderColor
                        TextInput {
                            id: confirmPasswordInput
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            anchors.rightMargin: 9
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            color: root.textColor
                            font.pixelSize: 10
                            clip: true
                            selectByMouse: true
                            onAccepted: root.submitLockerAction()
                        }
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 9
                            anchors.verticalCenter: parent.verticalCenter
                            visible: confirmPasswordInput.text.length === 0 && !confirmPasswordInput.activeFocus
                            text: "Confirm password"
                            color: root.mutedColor
                            font.pixelSize: 8
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 27
                        radius: 8
                        visible: root.passwordMode.length > 0
                        color: root.accentColor
                        Text {
                            anchors.centerIn: parent
                            text: lockerActionProcess.running
                                ? "PLEASE WAIT"
                                : (root.passwordMode === "protect" ? "SAVE PASSWORD" : (root.passwordMode === "remove" ? "REMOVE LOCK" : "UNLOCK & OPEN"))
                            color: "#FFFFFF"
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.2
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: !lockerActionProcess.running
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.submitLockerAction()
                        }
                    }

                    Text {
                        width: parent.width
                        text: root.lockerMessage.length ? root.lockerMessage : "Protect selected app launches with a password."
                        color: root.mutedColor
                        font.pixelSize: 8
                        wrapMode: Text.Wrap
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 31
                radius: 8
                color: root.surfaceColor
                border.width: 1
                border.color: root.borderColor
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 9
                    anchors.rightMargin: 8
                    spacing: 6
                    NavbarIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14
                        height: 14
                        iconName: "lucide-search.svg"
                        iconColor: root.mutedColor
                    }
                    TextInput {
                        id: appSearchInput
                        width: parent.width - 25
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.appSearch
                        onTextChanged: root.appSearch = text
                        color: root.textColor
                        font.pixelSize: 9
                        clip: true
                        selectByMouse: true
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.appSearch.length === 0 && !appSearchInput.activeFocus
                        text: "Search apps"
                        color: root.mutedColor
                        font.pixelSize: 9
                    }
                }
            }

            Text {
                text: String(root.filteredApps.length) + " applications · " + String(root.lockerApps.filter(app => app.locked).length) + " protected"
                color: root.mutedColor
                font.pixelSize: 8
            }

            Flickable {
                id: appListFlick
                width: parent.width
                height: 194
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: appRows.implicitHeight
                interactive: contentHeight > height

                Column {
                    id: appRows
                    width: appListFlick.width
                    spacing: 4

                    Repeater {
                        model: root.filteredApps.slice(0, 80)
                        delegate: Rectangle {
                            required property var modelData
                            width: appRows.width
                            height: 34
                            radius: 8
                            color: root.surfaceColor
                            border.width: 1
                            border.color: root.borderColor

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 5
                                spacing: 6

                                Column {
                                    width: Math.max(50, parent.width - (modelData.locked ? 100 : 74))
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    Text {
                                        width: parent.width
                                        text: String(modelData.name || modelData.desktop_id)
                                        color: root.textColor
                                        font.pixelSize: 8
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        width: parent.width
                                        text: modelData.locked ? "PASSWORD REQUIRED" : "UNPROTECTED"
                                        color: modelData.locked ? root.accentColor : root.mutedColor
                                        font.pixelSize: 6
                                        font.letterSpacing: 0.4
                                        elide: Text.ElideRight
                                    }
                                }

                                Rectangle {
                                    width: 59
                                    height: 24
                                    radius: 7
                                    color: root.hoverColor
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.locked ? "OPEN" : "PROTECT"
                                        color: root.textColor
                                        font.pixelSize: 7
                                        font.weight: Font.DemiBold
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.openPasswordDialog(modelData.locked ? "launch" : "protect", modelData)
                                    }
                                }

                                Rectangle {
                                    width: 25
                                    height: 24
                                    radius: 7
                                    visible: modelData.locked
                                    color: "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "⋯"
                                        color: root.mutedColor
                                        font.pixelSize: 13
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.openPasswordDialog("remove", modelData)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                width: parent.width
                text: "Security note: this password gate protects launches made through A16EEN App Locker. It does not block the same app from being started via a terminal or another launcher."
                color: root.mutedColor
                font.pixelSize: 7
                wrapMode: Text.Wrap
            }
        }

        Column {
            id: sessionsContent
            visible: root.page === "sessions"
            width: pageFlick.width
            spacing: 7

            Rectangle {
                width: parent.width
                height: 94
                radius: 11
                color: root.subtleColor
                border.width: 1
                border.color: root.borderColor

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 5

                    Row {
                        width: parent.width
                        spacing: 7
                        Rectangle {
                            width: 30
                            height: 30
                            radius: 9
                            color: root.surfaceColor
                            anchors.verticalCenter: parent.verticalCenter
                            NavbarIcon {
                                anchors.centerIn: parent
                                width: 17
                                height: 17
                                iconName: "lucide-panels-top-left.svg"
                                iconColor: root.iconColor
                            }
                        }
                        Column {
                            width: parent.width - 40
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            Text {
                                text: "SESSION SNAPSHOTS"
                                color: root.textColor
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }
                            Text {
                                width: parent.width
                                text: "A restore point for the apps you had open"
                                color: root.mutedColor
                                font.pixelSize: 8
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 6
                        Rectangle {
                            width: parent.width - 84
                            height: 30
                            radius: 7
                            color: root.surfaceColor
                            border.width: 1
                            border.color: root.borderColor
                            TextInput {
                                id: snapshotNameInput
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                verticalAlignment: TextInput.AlignVCenter
                                color: root.textColor
                                font.pixelSize: 9
                                clip: true
                                selectByMouse: true
                                onAccepted: {
                                    const name = String(text || "").trim()
                                    if (name.length) {
                                        root.runSessionAction(["save", name])
                                        text = ""
                                    }
                                }
                            }
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                visible: snapshotNameInput.text.length === 0 && !snapshotNameInput.activeFocus
                                text: "Snapshot name"
                                color: root.mutedColor
                                font.pixelSize: 8
                            }
                        }
                        Rectangle {
                            width: 72
                            height: 30
                            radius: 7
                            color: root.accentColor
                            Text {
                                anchors.centerIn: parent
                                text: sessionActionProcess.running ? "SAVING…" : "SAVE NOW"
                                color: "#FFFFFF"
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: !sessionActionProcess.running && snapshotNameInput.text.trim().length > 0
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const name = String(snapshotNameInput.text || "").trim()
                                    if (name.length) {
                                        root.runSessionAction(["save", name])
                                        snapshotNameInput.text = ""
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                width: parent.width
                text: root.sessionMessage.length ? root.sessionMessage : "Automatic snapshots refresh every 30 minutes; named snapshots stay until you delete them."
                color: root.mutedColor
                font.pixelSize: 8
                wrapMode: Text.Wrap
            }

            Text {
                text: "SAVED SESSIONS"
                color: root.mutedColor
                font.pixelSize: 8
                font.weight: Font.DemiBold
                font.letterSpacing: 0.7
            }

            Flickable {
                id: sessionsFlick
                width: parent.width
                height: 249
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: sessionRows.implicitHeight
                interactive: contentHeight > height

                Column {
                    id: sessionRows
                    width: sessionsFlick.width
                    spacing: 5

                    Repeater {
                        model: root.sessionSnapshots
                        delegate: Rectangle {
                            required property var modelData
                            width: sessionRows.width
                            height: 65
                            radius: 9
                            color: root.surfaceColor
                            border.width: 1
                            border.color: root.borderColor

                            Row {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 7

                                Column {
                                    width: parent.width - 93
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4
                                    Text {
                                        width: parent.width
                                        text: String(modelData.name || "Saved session")
                                        color: root.textColor
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        width: parent.width
                                        text: String(modelData.app_count || (modelData.apps ? modelData.apps.length : 0)) + " apps · " + String(modelData.created_at || "").replace("T", " ").replace("Z", " UTC")
                                        color: root.mutedColor
                                        font.pixelSize: 7
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        width: parent.width
                                        text: modelData.id === "auto" ? "AUTOMATIC · EVERY 30 MIN" : "NAMED SNAPSHOT"
                                        color: modelData.id === "auto" ? root.accentColor : root.mutedColor
                                        font.pixelSize: 6
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 0.4
                                    }
                                }

                                Column {
                                    width: 82
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4
                                    Rectangle {
                                        width: parent.width
                                        height: 23
                                        radius: 7
                                        color: root.accentColor
                                        Text {
                                            anchors.centerIn: parent
                                            text: sessionActionProcess.running ? "WORKING…" : "RESTORE"
                                            color: "#FFFFFF"
                                            font.pixelSize: 7
                                            font.weight: Font.DemiBold
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: !sessionActionProcess.running
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.runSessionAction(["restore", String(modelData.id || "")])
                                        }
                                    }
                                    Rectangle {
                                        width: parent.width
                                        height: 21
                                        radius: 7
                                        visible: modelData.id !== "auto"
                                        color: "transparent"
                                        border.width: 1
                                        border.color: root.borderColor
                                        Text {
                                            anchors.centerIn: parent
                                            text: "DELETE"
                                            color: root.mutedColor
                                            font.pixelSize: 7
                                            font.weight: Font.DemiBold
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            enabled: !sessionActionProcess.running
                                            onClicked: root.runSessionAction(["delete", String(modelData.id || "")])
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.sessionSnapshots.length === 0
                        text: "No snapshots yet. A16EEN will create one as soon as it sees restorable apps."
                        width: sessionRows.width
                        color: root.mutedColor
                        font.pixelSize: 8
                        wrapMode: Text.Wrap
                    }
                }
            }

            Text {
                width: parent.width
                text: "Restoration reopens available applications and attempts to return new windows to their saved workspaces. It cannot restore unsaved document contents."
                color: root.mutedColor
                font.pixelSize: 7
                wrapMode: Text.Wrap
            }
        }
    }
}