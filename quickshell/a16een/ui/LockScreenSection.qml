import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool active: false
    property bool idleEnabled: true
    property int idleMinutes: 5
    property bool sleepLockEnabled: true

    property int currentTab: 0
    property bool timePasswordEnabled: false
    property int timeOffsetMinutes: -20
    property var temporaryCodes: []
    property string newCodeLabel: ""
    property string newCodePassword: ""
    property int newCodeUses: 1
    property string pendingCodePayload: ""
    property string pendingRemoveId: ""
    property string authMessage: ""
    property bool authBusy: false

    signal backRequested()
    signal settingsRequested(bool idleEnabled, int idleMinutes, bool sleepLockEnabled)
    signal lockNowRequested()

    readonly property color page: "#FFFFFF"
    readonly property color tile: "#F7F8FA"
    readonly property color tileRaised: "#FFFFFF"
    readonly property color border: "#E2E6EB"
    readonly property color textPrimary: "#171A1F"
    readonly property color textSecondary: "#687280"
    readonly property color textMuted: "#9099A5"
    readonly property color accent: "#B18B3F"
    readonly property color accentSoft: "#F3EBD9"
    readonly property color green: "#23845B"
    readonly property real contentWidth: Math.max(0, root.width - 52)

    focus: true

    Keys.onEscapePressed: root.backRequested()

    onActiveChanged: {
        if (root.active) {
            root.currentTab = 0
            root.authMessage = ""
            forceActiveFocus()
            root.refreshAuthSettings()
        }
    }

    function refreshAuthSettings() {
        if (authLoader.running)
            return
        root.authBusy = true
        authLoader.running = true
    }

    function acceptAuthState(rawText) {
        try {
            const state = JSON.parse(String(rawText || "{}"))
            root.timePasswordEnabled = state.timeEnabled === true
            const offset = Number(state.timeOffsetMinutes)
            root.timeOffsetMinutes = Number.isInteger(offset) && offset >= -720 && offset <= 720
                ? offset : -20
            root.temporaryCodes = Array.isArray(state.temporaryCodes) ? state.temporaryCodes : []
            root.authBusy = false
        } catch (error) {
            root.authBusy = false
            root.authMessage = "Could not read the saved authentication settings."
        }
    }

    function saveTimePassword() {
        if (timeWriter.running)
            return
        root.authBusy = true
        root.authMessage = "Saving dynamic password settings…"
        timeWriter.command = [
            "a16een-lockscreen-auth",
            "set-time",
            root.timePasswordEnabled ? "true" : "false",
            String(root.timeOffsetMinutes)
        ]
        timeWriter.running = true
    }

    function addTemporaryCode() {
        const label = root.newCodeLabel.trim()
        const secret = root.newCodePassword
        if (!label.length || secret.length < 6 || secret.length > 64) {
            root.authMessage = "Add a name and a password between 6 and 64 characters."
            return
        }
        if (!Number.isInteger(root.newCodeUses) || root.newCodeUses < 1 || root.newCodeUses > 100) {
            root.authMessage = "Choose between 1 and 100 successful uses."
            return
        }
        if (addCodeProcess.running) {
            root.authMessage = "A temporary password is already being saved."
            return
        }

        root.pendingCodePayload = JSON.stringify({
            label: label,
            password: secret,
            uses: root.newCodeUses
        })
        root.newCodePassword = ""
        root.authMessage = "Creating protected temporary password…"
        root.authBusy = true
        addCodeProcess.running = true
    }

    function removeTemporaryCode(codeId) {
        if (!codeId || removeCodeProcess.running)
            return
        root.pendingRemoveId = String(codeId)
        removeCodeProcess.command = ["a16een-lockscreen-auth", "remove", root.pendingRemoveId]
        root.authMessage = "Removing temporary password…"
        root.authBusy = true
        removeCodeProcess.running = true
    }

    function authCommandSucceeded(rawText, message) {
        root.acceptAuthState(rawText)
        if (!root.authMessage.startsWith("Could not"))
            root.authMessage = message
    }

    Rectangle {
        anchors.fill: parent
        color: root.page
    }

    Column {
        anchors.fill: parent
        anchors.margins: 26
        spacing: 13

        Row {
            id: header
            width: parent.width
            height: 42
            spacing: 12

            Rectangle {
                width: 36
                height: 36
                radius: 11
                anchors.verticalCenter: parent.verticalCenter
                color: backMouse.containsMouse ? "#E8EBEF" : "#F2F4F6"
                border.width: 1
                border.color: root.border

                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    color: root.textPrimary
                    font.pixelSize: 26
                    y: -1
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backRequested()
                }

                Behavior on color {
                    ColorAnimation { duration: 130 }
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    text: "LOCK SCREEN"
                    color: root.textPrimary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.2
                }

                Text {
                    text: "Protection, sign-in methods and automatic locking"
                    color: root.textSecondary
                    font.pixelSize: 10
                }
            }

            Item { width: 1; height: 1 }
        }

        Rectangle {
            id: tabBar
            width: parent.width
            height: 48
            radius: 14
            color: "#F1F3F6"
            border.width: 1
            border.color: "#E9ECF0"

            Rectangle {
                id: activeTabPill
                x: root.currentTab * (tabBar.width / 3) + 4
                y: 4
                width: tabBar.width / 3 - 8
                height: tabBar.height - 8
                radius: 11
                color: "#FFFFFF"
                border.width: 1
                border.color: "#E3E7EC"

                Behavior on x {
                    NumberAnimation { duration: 230; easing.type: Easing.OutCubic }
                }
            }

            Row {
                anchors.fill: parent
                anchors.margins: 4

                Repeater {
                    model: [
                        { title: "Behavior", icon: "◷" },
                        { title: "Dynamic key", icon: "⌁" },
                        { title: "Temporary", icon: "⌑" }
                    ]

                    delegate: Item {
                        required property var modelData
                        required property int index
                        width: tabBar.width / 3 - 2.7
                        height: parent.height

                        Row {
                            anchors.centerIn: parent
                            spacing: 7

                            Text {
                                text: modelData.icon
                                color: root.currentTab === index ? root.accent : root.textMuted
                                font.pixelSize: 15
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: modelData.title
                                color: root.currentTab === index ? root.textPrimary : root.textSecondary
                                font.pixelSize: 10
                                font.weight: root.currentTab === index ? Font.DemiBold : Font.Medium
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.currentTab = index
                                if (index !== 0)
                                    root.refreshAuthSettings()
                            }
                        }
                    }
                }
            }
        }

        Flickable {
            id: contentFlickable
            width: parent.width
            height: Math.max(0, parent.height - header.height - tabBar.height - 26)
            contentWidth: width
            contentHeight: pageLoader.item ? pageLoader.item.implicitHeight : 0
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Loader {
                id: pageLoader
                width: contentFlickable.width
                sourceComponent: root.currentTab === 0
                    ? behaviorPage
                    : root.currentTab === 1 ? dynamicPage : temporaryPage
            }
        }
    }

    Process {
        id: authLoader
        command: ["a16een-lockscreen-auth", "get"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.acceptAuthState(text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(text || "").trim()
                if (message.length) {
                    root.authBusy = false
                    root.authMessage = message
                }
            }
        }
    }

    Process {
        id: timeWriter
        command: ["a16een-lockscreen-auth", "set-time", "false", "-20"]
        running: false

        onExited: (exitCode, exitStatus) => {
            root.authBusy = false
            if (exitCode === 0) {
                root.authMessage = "Dynamic password settings saved."
                root.refreshAuthSettings()
            } else {
                root.authMessage = "Could not save dynamic password settings. Your normal password still works."
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(text || "").trim()
                if (message.length)
                    root.authMessage = message
            }
        }
    }

    Process {
        id: addCodeProcess
        command: ["a16een-lockscreen-auth", "add"]
        stdinEnabled: true
        running: false

        onStarted: {
            const payload = root.pendingCodePayload
            root.pendingCodePayload = ""
            write(payload + "\n")
        }

        stdout: StdioCollector {
            onStreamFinished: {
                root.authBusy = false
                if (String(text || "").trim().length) {
                    root.authCommandSucceeded(text, "Temporary password created.")
                    root.newCodeLabel = ""
                    root.newCodePassword = ""
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(text || "").trim()
                if (message.length) {
                    root.authBusy = false
                    root.authMessage = message
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.authBusy = false
            else
                root.refreshAuthSettings()
        }
    }

    Process {
        id: removeCodeProcess
        command: ["a16een-lockscreen-auth", "remove", ""]
        running: false

        onExited: (exitCode, exitStatus) => {
            root.authBusy = false
            if (exitCode === 0) {
                root.authMessage = "Temporary password removed."
                root.refreshAuthSettings()
            } else {
                root.authMessage = "Could not remove that password."
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(text || "").trim()
                if (message.length)
                    root.authMessage = message
            }
        }
    }

    Component {
        id: behaviorPage

        Column {
            width: contentFlickable.width
            spacing: 12

            Rectangle {
                width: parent.width
                height: 144
                radius: 16
                color: root.tile
                border.width: 1
                border.color: root.border

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    Row {
                        width: parent.width
                        height: 38
                        spacing: 12

                        Column {
                            width: parent.width - 58
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 5

                            Text {
                                text: "Lock after inactivity"
                                color: root.textPrimary
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }

                            Text {
                                width: parent.width
                                text: root.idleEnabled
                                    ? "Secure the session when the keyboard and pointer have been idle."
                                    : "Automatic idle locking is turned off."
                                color: root.textSecondary
                                font.pixelSize: 10
                                wrapMode: Text.WordWrap
                            }
                        }

                        Rectangle {
                            width: 44
                            height: 25
                            radius: 13
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.idleEnabled ? root.accent : "#D4DAE1"

                            Rectangle {
                                width: 19
                                height: 19
                                radius: 10
                                y: 3
                                x: root.idleEnabled ? 22 : 3
                                color: "#FFFFFF"
                                Behavior on x {
                                    NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.settingsRequested(!root.idleEnabled, root.idleMinutes, root.sleepLockEnabled)
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 33
                        spacing: 6
                        opacity: root.idleEnabled ? 1.0 : 0.45

                        Text {
                            width: 76
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            text: "LOCK AFTER"
                            color: root.textMuted
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.5
                        }

                        Repeater {
                            model: [
                                { value: 1, label: "1m" },
                                { value: 3, label: "3m" },
                                { value: 5, label: "5m" },
                                { value: 10, label: "10m" },
                                { value: 15, label: "15m" },
                                { value: 30, label: "30m" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                width: 57
                                height: 31
                                radius: 8
                                color: root.idleEnabled && root.idleMinutes === modelData.value ? root.accentSoft : "#FFFFFF"
                                border.width: 1
                                border.color: root.idleEnabled && root.idleMinutes === modelData.value ? root.accent : root.border

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: root.idleEnabled && root.idleMinutes === modelData.value ? "#71511C" : root.textSecondary
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: root.idleEnabled
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: root.settingsRequested(root.idleEnabled, modelData.value, root.sleepLockEnabled)
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 105
                radius: 16
                color: root.tile
                border.width: 1
                border.color: root.border

                Row {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Column {
                        width: parent.width - 60
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Text {
                            text: "Lock when the laptop sleeps"
                            color: root.textPrimary
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        Text {
                            width: parent.width
                            text: root.sleepLockEnabled
                                ? "Lock before suspend and keep the session protected when the laptop wakes."
                                : "Automatic locking during suspend and resume is turned off."
                            color: root.textSecondary
                            font.pixelSize: 10
                            wrapMode: Text.WordWrap
                        }
                    }

                    Rectangle {
                        width: 44
                        height: 25
                        radius: 13
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.sleepLockEnabled ? root.accent : "#D4DAE1"

                        Rectangle {
                            width: 19
                            height: 19
                            radius: 10
                            y: 3
                            x: root.sleepLockEnabled ? 22 : 3
                            color: "#FFFFFF"
                            Behavior on x {
                                NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.settingsRequested(root.idleEnabled, root.idleMinutes, !root.sleepLockEnabled)
                        }
                    }
                }
            }

            Row {
                width: parent.width
                height: 48
                spacing: 12

                Rectangle {
                    width: 122
                    height: 40
                    radius: 11
                    anchors.verticalCenter: parent.verticalCenter
                    color: lockNowMouse.containsMouse ? "#D8C094" : root.accent

                    Text {
                        anchors.centerIn: parent
                        text: "LOCK NOW"
                        color: "#FFFFFF"
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.8
                    }

                    MouseArea {
                        id: lockNowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.lockNowRequested()
                    }
                }

                Column {
                    width: parent.width - 136
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        text: "Your regular Linux password stays active."
                        color: root.textPrimary
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }

                    Text {
                        text: "These settings apply to A16EEN's GTKLock screen."
                        color: root.textMuted
                        font.pixelSize: 9
                    }
                }
            }
        }
    }

    Component {
        id: dynamicPage

        Column {
            width: contentFlickable.width
            spacing: 12

            Rectangle {
                width: parent.width
                height: 122
                radius: 16
                color: root.tile
                border.width: 1
                border.color: root.border

                Row {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    Column {
                        width: parent.width - 60
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Text {
                            text: "Dynamic time password"
                            color: root.textPrimary
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        Text {
                            width: parent.width
                            text: "Generate a new four-digit sign-in code from your local 12-hour clock. It changes every minute and never uses AM or PM."
                            color: root.textSecondary
                            font.pixelSize: 10
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            text: "DISABLED BY DEFAULT"
                            color: root.textMuted
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                        }
                    }

                    Rectangle {
                        width: 44
                        height: 25
                        radius: 13
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.timePasswordEnabled ? root.accent : "#D4DAE1"

                        Rectangle {
                            width: 19
                            height: 19
                            radius: 10
                            y: 3
                            x: root.timePasswordEnabled ? 22 : 3
                            color: "#FFFFFF"
                            Behavior on x {
                                NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.timePasswordEnabled = !root.timePasswordEnabled
                                root.saveTimePassword()
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 160
                radius: 16
                color: "#FFFFFF"
                border.width: 1
                border.color: root.border

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 11

                    Text {
                        text: "HIDE THE CLOCK PATTERN"
                        color: root.textMuted
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.8
                    }

                    Row {
                        width: parent.width
                        height: 40
                        spacing: 8

                        Repeater {
                            model: [
                                { value: -1, label: "SUBTRACT" },
                                { value: 1, label: "ADD" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                width: (parent.width - 8) / 2
                                height: 38
                                radius: 9
                                color: Math.sign(root.timeOffsetMinutes) === modelData.value
                                    ? root.accentSoft : root.tile
                                border.width: 1
                                border.color: Math.sign(root.timeOffsetMinutes) === modelData.value
                                    ? root.accent : root.border

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: Math.sign(root.timeOffsetMinutes) === modelData.value
                                        ? "#71511C" : root.textSecondary
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.5
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const amount = Math.abs(root.timeOffsetMinutes)
                                        root.timeOffsetMinutes = modelData.value * amount
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 39
                        spacing: 8

                        Text {
                            width: parent.width - 158
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            text: "TIME ADJUSTMENT"
                            color: root.textSecondary
                            font.pixelSize: 9
                            font.weight: Font.Medium
                        }

                        Rectangle {
                            width: 62
                            height: 36
                            radius: 9
                            color: root.tile
                            border.width: 1
                            border.color: root.border

                            TextInput {
                                id: offsetInput
                                anchors.fill: parent
                                anchors.margins: 5
                                verticalAlignment: TextInput.AlignVCenter
                                horizontalAlignment: TextInput.AlignHCenter
                                text: String(Math.abs(root.timeOffsetMinutes))
                                color: root.textPrimary
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                maximumLength: 3
                                inputMethodHints: Qt.ImhDigitsOnly
                                validator: IntValidator { bottom: 0; top: 720 }
                                onEditingFinished: {
                                    const n = Math.max(0, Math.min(720, Number(text || 0)))
                                    root.timeOffsetMinutes = (root.timeOffsetMinutes < 0 ? -1 : 1) * n
                                }
                            }
                        }

                        Text {
                            width: 75
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            text: "MINUTES"
                            color: root.textMuted
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 96
                radius: 16
                color: "#F8F6F1"
                border.width: 1
                border.color: "#E8DDC9"

                Row {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 12

                    Text {
                        text: "↻"
                        color: root.accent
                        font.pixelSize: 23
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        width: parent.width - 38
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        Text {
                            text: "Example — subtract 20 minutes"
                            color: "#57452A"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }

                        Text {
                            width: parent.width
                            text: "11:53 becomes 11:33 → enter 1133. At 11:13 it becomes 10:53 → enter 1053. The actual current code is never shown here."
                            color: "#75664F"
                            font.pixelSize: 9
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            Row {
                width: parent.width
                height: 42
                spacing: 10

                Rectangle {
                    width: 126
                    height: 38
                    radius: 10
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.authBusy ? "#D8DCE2" : root.accent

                    Text {
                        anchors.centerIn: parent
                        text: root.authBusy ? "SAVING…" : "SAVE SETTINGS"
                        color: root.authBusy ? root.textSecondary : "#FFFFFF"
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.authBusy
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.saveTimePassword()
                    }
                }

                Text {
                    width: parent.width - 140
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    text: root.authMessage
                    color: root.authMessage.indexOf("Could not") === 0 ? "#B34B4B" : root.textMuted
                    font.pixelSize: 9
                    wrapMode: Text.WordWrap
                }
            }

            Text {
                width: parent.width
                text: "Security note: this is a convenient secondary sign-in method, not a replacement for a strong Linux account password. Your normal password continues to work."
                color: root.textMuted
                font.pixelSize: 9
                wrapMode: Text.WordWrap
            }
        }
    }

    Component {
        id: temporaryPage

        Column {
            width: contentFlickable.width
            spacing: 12

            Rectangle {
                width: parent.width
                height: 214
                radius: 16
                color: root.tile
                border.width: 1
                border.color: root.border

                Column {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 9

                    Row {
                        width: parent.width
                        height: 25

                        Text {
                            text: "CREATE A TEMPORARY PASSWORD"
                            color: root.textMuted
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.7
                        }

                        Item { width: 1; height: 1 }
                    }

                    Row {
                        width: parent.width
                        height: 38
                        spacing: 9

                        Rectangle {
                            width: parent.width
                            height: 36
                            radius: 9
                            color: "#FFFFFF"
                            border.width: 1
                            border.color: root.border

                            TextInput {
                                anchors.fill: parent
                                anchors.leftMargin: 11
                                anchors.rightMargin: 11
                                verticalAlignment: TextInput.AlignVCenter
                                text: root.newCodeLabel
                                color: root.textPrimary
                                font.pixelSize: 10
                                maximumLength: 28
                                onTextChanged: root.newCodeLabel = text
                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: "Name this code (e.g. Guest access)"
                                    color: root.textMuted
                                    font.pixelSize: 10
                                    visible: parent.text.length === 0
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 38
                        spacing: 9

                        Rectangle {
                            width: parent.width
                            height: 36
                            radius: 9
                            color: "#FFFFFF"
                            border.width: 1
                            border.color: root.border

                            TextInput {
                                anchors.fill: parent
                                anchors.leftMargin: 11
                                anchors.rightMargin: 11
                                verticalAlignment: TextInput.AlignVCenter
                                text: root.newCodePassword
                                color: root.textPrimary
                                font.pixelSize: 10
                                echoMode: TextInput.Password
                                maximumLength: 64
                                inputMethodHints: Qt.ImhSensitiveData
                                onTextChanged: root.newCodePassword = text
                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: "Password (6–64 characters)"
                                    color: root.textMuted
                                    font.pixelSize: 10
                                    visible: parent.text.length === 0
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 32
                        spacing: 8

                        Text {
                            width: 108
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            text: "SUCCESSFUL USES"
                            color: root.textSecondary
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.3
                        }

                        Repeater {
                            model: [1, 3, 5, 10]

                            delegate: Rectangle {
                                required property int modelData
                                width: 49
                                height: 30
                                radius: 8
                                color: root.newCodeUses === modelData ? root.accentSoft : "#FFFFFF"
                                border.width: 1
                                border.color: root.newCodeUses === modelData ? root.accent : root.border

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData === 1 ? "ONCE" : String(modelData) + "×"
                                    color: root.newCodeUses === modelData ? "#71511C" : root.textSecondary
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.newCodeUses = modelData
                                }
                            }
                        }

                        Rectangle {
                            width: 64
                            height: 30
                            radius: 8
                            color: "#FFFFFF"
                            border.width: 1
                            border.color: root.newCodeUses > 10 ? root.accent : root.border

                            TextInput {
                                anchors.fill: parent
                                anchors.margins: 4
                                verticalAlignment: TextInput.AlignVCenter
                                horizontalAlignment: TextInput.AlignHCenter
                                text: String(root.newCodeUses)
                                color: root.textPrimary
                                font.pixelSize: 9
                                maximumLength: 3
                                inputMethodHints: Qt.ImhDigitsOnly
                                validator: IntValidator { bottom: 1; top: 100 }
                                onEditingFinished: {
                                    const value = Number(text)
                                    if (Number.isInteger(value) && value >= 1 && value <= 100)
                                        root.newCodeUses = value
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 34
                        spacing: 9

                        Rectangle {
                            width: 126
                            height: 34
                            radius: 9
                            color: root.authBusy ? "#D8DCE2" : root.accent

                            Text {
                                anchors.centerIn: parent
                                text: root.authBusy ? "PLEASE WAIT…" : "CREATE CODE"
                                color: root.authBusy ? root.textSecondary : "#FFFFFF"
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: !root.authBusy
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: root.addTemporaryCode()
                            }
                        }

                        Text {
                            width: parent.width - 135
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            text: root.authMessage
                            color: root.authMessage.indexOf("Could not") === 0 ? "#B34B4B" : root.textMuted
                            font.pixelSize: 8
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            Row {
                width: parent.width
                height: 24
                spacing: 8

                Text {
                    text: "YOUR TEMPORARY CODES"
                    color: root.textPrimary
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.8
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: String(root.temporaryCodes.length) + " / 10"
                    color: root.textMuted
                    font.pixelSize: 8
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item { width: 1; height: 1 }
            }

            Repeater {
                model: root.temporaryCodes

                delegate: Rectangle {
                    required property var modelData
                    width: parent.width
                    height: 66
                    radius: 13
                    color: "#FFFFFF"
                    border.width: 1
                    border.color: root.border

                    Row {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Rectangle {
                            width: 34
                            height: 34
                            radius: 10
                            color: "#F4F0E8"
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: "⌑"
                                color: root.accent
                                font.pixelSize: 17
                            }
                        }

                        Column {
                            width: parent.width - 112
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Text {
                                text: modelData.label
                                color: root.textPrimary
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: modelData.usesLeft > 0
                                    ? String(modelData.usesLeft) + " of " + String(modelData.usesTotal) + " uses remaining"
                                    : "Expired · no uses remaining"
                                color: modelData.usesLeft > 0 ? root.textSecondary : root.textMuted
                                font.pixelSize: 8
                            }
                        }

                        Rectangle {
                            width: 56
                            height: 29
                            radius: 8
                            anchors.verticalCenter: parent.verticalCenter
                            color: "#FAF1F0"
                            border.width: 1
                            border.color: "#F0DEDC"

                            Text {
                                anchors.centerIn: parent
                                text: "REMOVE"
                                color: "#A6534E"
                                font.pixelSize: 7
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                enabled: !root.authBusy
                                onClicked: root.removeTemporaryCode(modelData.id)
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 60
                radius: 12
                color: "#F8F6F1"
                border.width: 1
                border.color: "#E8DDC9"

                Text {
                    anchors.fill: parent
                    anchors.margins: 12
                    verticalAlignment: Text.AlignVCenter
                    text: "Temporary passwords are stored as salted hashes. Their remaining-use count decreases only after a successful unlock. Your normal Linux password is always available."
                    color: "#75664F"
                    font.pixelSize: 8
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
