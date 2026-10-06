import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool opened: false
    property var windows: []
    property int captureMode: 0 // 0 = screen, 1 = area, 2 = window
    property int delaySeconds: 0
    property bool includePointer: true
    property bool saveToDisk: true
    property string statusText: "LIVE DESKTOP • READY"

    signal closeRequested()

    readonly property color textPrimary: "#15171A"
    readonly property color textSecondary: "#65717E"
    readonly property color textMuted: "#8C97A3"
    readonly property color accent: "#2F80ED"
    readonly property color surface: "#FFFFFF"
    readonly property color softSurface: "#F7F9FB"
    readonly property color border: "#E1E6EB"

    readonly property string screenIcon:
        Quickshell.iconPath("display", "video-display")
    readonly property string areaIcon:
        Quickshell.iconPath("select-rectangle", "edit-select")
    readonly property string windowIcon:
        Quickshell.iconPath("window", "application-x-executable")
    readonly property string pointerIcon:
        Quickshell.iconPath("input-mouse", "input-mouse")
    readonly property string saveIcon:
        Quickshell.iconPath("document-save", "document-save-as")
    readonly property string clipboardIcon:
        Quickshell.iconPath("edit-copy", "edit-copy")
    readonly property string closeIcon:
        Quickshell.iconPath("window-close", "dialog-close")
    readonly property string cameraIcon:
        Quickshell.iconPath("camera-photo", "camera-photo")

    screen: modelData
    color: "transparent"
    visible: root.opened
    focusable: root.opened
    aboveWindows: true
    exclusiveZone: 0

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-screenshot"
    WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    function setMode(mode) {
        root.captureMode = mode
        if (mode === 1)
            root.delaySeconds = 0
    }

    function modeTitle() {
        if (root.captureMode === 1)
            return "SELECT AREA"
        if (root.captureMode === 2)
            return "WINDOW"
        return "FULL SCREEN"
    }

    function runCaptureAction(kind, id) {
        const args = ["niri", "msg", "action"]

        if (kind === "screen")
            args.push("screenshot-screen")
        else if (kind === "area")
            args.push("screenshot")
        else {
            args.push("screenshot-window", "--id", String(id))
        }

        if (!root.saveToDisk)
            args.push("--write-to-disk=false")

        if (!root.includePointer)
            args.push("--show-pointer=false")

        root.statusText = "CAPTURED • " + root.modeTitle()
        Quickshell.execDetached(args)
    }

    function scheduleCapture(kind, id) {
        root.pendingKind = kind
        root.pendingWindowId = id || 0
        root.pendingDelay = root.delaySeconds

        if (root.pendingDelay > 0) {
            root.statusText = "CAPTURING IN " + root.pendingDelay + "S • MOVE AWAY FROM CONTROLS"
            captureTimer.restart()
        } else {
            root.statusText = "CAPTURING • " + root.modeTitle()
            captureTimer.interval = 110
            captureTimer.restart()
        }
    }

    function beginCapture() {
        root.closeRequested()

        if (root.captureMode === 2) {
            root.pendingKind = "window-pick"
            root.pendingDelay = 0
            pickerTimer.restart()
            return
        }

        root.scheduleCapture(root.captureMode === 1 ? "area" : "screen", 0)
    }

    function buildDelayStatus() {
        if (root.captureMode === 1)
            return "LIVE SELECTION"
        if (root.delaySeconds === 0)
            return "INSTANT"
        return root.delaySeconds + " SEC"
    }

    property string pendingKind: ""
    property int pendingWindowId: 0
    property int pendingDelay: 0

    Timer {
        id: pickerTimer
        interval: 120
        repeat: false
        onTriggered: {
            windowPickerProcess.running = false
            windowPickerProcess.running = true
        }
    }

    Timer {
        id: captureTimer
        interval: 110
        repeat: false
        onTriggered: {
            if (root.pendingDelay > 0) {
                root.pendingDelay -= 1
                if (root.pendingDelay > 0) {
                    root.statusText = "CAPTURING IN " + root.pendingDelay + "S • " + root.modeTitle()
                    captureTimer.interval = 1000
                    captureTimer.restart()
                    return
                }
            }

            if (root.pendingKind === "screen")
                root.runCaptureAction("screen", 0)
            else if (root.pendingKind === "area")
                root.runCaptureAction("area", 0)
            else if (root.pendingKind === "window")
                root.runCaptureAction("window", root.pendingWindowId)

            root.pendingKind = ""
        }
    }

    Process {
        id: windowPickerProcess
        command: ["niri", "msg", "--json", "pick-window"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const output = String(text || "").trim()
                const match = output.match(/"id"\\s*:\\s*(\\d+)/)

                if (!match) {
                    root.statusText = "WINDOW PICK CANCELED"
                    return
                }

                root.pendingWindowId = Number(match[1])
                root.pendingKind = "window"
                root.pendingDelay = root.delaySeconds
                root.statusText = root.delaySeconds > 0
                    ? "WINDOW SELECTED • CAPTURING IN " + root.delaySeconds + "S"
                    : "WINDOW SELECTED • CAPTURING"

                captureTimer.interval = root.delaySeconds > 0 ? 1000 : 110
                captureTimer.restart()
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

    MouseArea {
        anchors.fill: parent
        z: 0
        onClicked: root.closeRequested()
    }

    Rectangle {
        id: topBar
        z: 2
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 18
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        height: 64
        radius: 18
        color: root.surface
        opacity: 0.96
        border.width: 1
        border.color: root.border

        Row {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 13

            Rectangle {
                width: 34
                height: 34
                anchors.verticalCenter: parent.verticalCenter
                radius: 10
                color: "#EEF5FF"

                IconImage {
                    anchors.centerIn: parent
                    implicitWidth: 18
                    implicitHeight: 18
                    source: root.cameraIcon
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    text: "SCREENSHOT MODE"
                    color: root.textPrimary
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.3
                }

                Text {
                    text: "THE DESKTOP STAYS VISIBLE UNTIL YOU CAPTURE OR CANCEL"
                    color: root.textMuted
                    font.pixelSize: 6
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.7
                }
            }

            Item {
                width: Math.max(1, parent.width - 420)
                height: 1
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.statusText
                color: root.accent
                font.pixelSize: 7
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
                elide: Text.ElideRight
            }

            Rectangle {
                width: 34
                height: 34
                anchors.verticalCenter: parent.verticalCenter
                radius: 10
                color: closeMouse.containsMouse ? "#F0F2F4" : "transparent"

                IconImage {
                    anchors.centerIn: parent
                    implicitWidth: 17
                    implicitHeight: 17
                    source: root.closeIcon
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }
    }

    Rectangle {
        id: modeBar
        z: 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: topBar.bottom
        anchors.topMargin: 18
        width: Math.min(760, parent.width - 48)
        height: 132
        radius: 20
        color: root.surface
        opacity: 0.97
        border.width: 1
        border.color: root.border

        Row {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Repeater {
                model: [
                    {
                        mode: 0,
                        title: "FULL SCREEN",
                        subtitle: "Capture the entire focused display",
                        icon: root.screenIcon
                    },
                    {
                        mode: 1,
                        title: "SELECT AREA",
                        subtitle: "Draw exactly the region you need",
                        icon: root.areaIcon
                    },
                    {
                        mode: 2,
                        title: "SPECIFIC WINDOW",
                        subtitle: "Pick a window without guessing its size",
                        icon: root.windowIcon
                    }
                ]

                delegate: Rectangle {
                    required property var modelData

                    width: (parent.width - 20) / 3
                    height: parent.height
                    radius: 16
                    color: root.captureMode === modelData.mode
                        ? "#EEF5FF"
                        : (modeMouse.containsMouse ? "#F8FAFC" : "#FFFFFF")
                    border.width: 1
                    border.color: root.captureMode === modelData.mode
                        ? "#B9D8FA"
                        : root.border

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 9

                        Rectangle {
                            width: 38
                            height: 38
                            radius: 11
                            color: root.captureMode === modelData.mode
                                ? "#FFFFFF"
                                : "#F4F7FA"

                            IconImage {
                                anchors.centerIn: parent
                                implicitWidth: 19
                                implicitHeight: 19
                                source: modelData.icon
                            }
                        }

                        Text {
                            width: parent.width
                            text: modelData.title
                            color: root.textPrimary
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.7
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: modelData.subtitle
                            color: root.textSecondary
                            font.pixelSize: 6
                            lineHeight: 1.15
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        visible: root.captureMode === modelData.mode
                        width: 7
                        height: 7
                        radius: 4
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.rightMargin: 10
                        anchors.topMargin: 10
                        color: root.accent
                    }

                    MouseArea {
                        id: modeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setMode(modelData.mode)
                    }
                }
            }
        }
    }

    Rectangle {
        id: bottomBar
        z: 2
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        anchors.bottomMargin: 18
        height: 72
        radius: 18
        color: root.surface
        opacity: 0.97
        border.width: 1
        border.color: root.border

        Row {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 8

            Rectangle {
                width: 148
                height: 44
                anchors.verticalCenter: parent.verticalCenter
                radius: 12
                color: root.softSurface
                border.width: 1
                border.color: root.border

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 11
                    anchors.rightMargin: 11
                    spacing: 8

                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 16
                        implicitHeight: 16
                        source: root.pointerIcon
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: "POINTER"
                            color: root.textPrimary
                            font.pixelSize: 6
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                        }

                        Text {
                            text: root.includePointer ? "Included" : "Hidden"
                            color: root.textSecondary
                            font.pixelSize: 6
                        }
                    }

                    Item { width: 1; height: 1 }

                    Rectangle {
                        width: 38
                        height: 22
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 11
                        color: root.includePointer ? root.accent : "#D7DEE6"

                        Rectangle {
                            width: 16
                            height: 16
                            y: 3
                            x: root.includePointer ? 19 : 3
                            radius: 8
                            color: "#FFFFFF"

                            Behavior on x {
                                NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.includePointer = !root.includePointer
                        }
                    }
                }
            }

            Rectangle {
                width: 170
                height: 44
                anchors.verticalCenter: parent.verticalCenter
                radius: 12
                color: root.softSurface
                border.width: 1
                border.color: root.border

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 11
                    anchors.rightMargin: 11
                    spacing: 8

                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 16
                        implicitHeight: 16
                        source: root.saveIcon
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: "SAVE TO DISK"
                            color: root.textPrimary
                            font.pixelSize: 6
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                        }

                        Text {
                            text: root.saveToDisk ? "File + clipboard" : "Clipboard only"
                            color: root.textSecondary
                            font.pixelSize: 6
                        }
                    }

                    Rectangle {
                        width: 38
                        height: 22
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 11
                        color: root.saveToDisk ? root.accent : "#D7DEE6"

                        Rectangle {
                            width: 16
                            height: 16
                            y: 3
                            x: root.saveToDisk ? 19 : 3
                            radius: 8
                            color: "#FFFFFF"

                            Behavior on x {
                                NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.saveToDisk = !root.saveToDisk
                        }
                    }
                }
            }

            Rectangle {
                width: 190
                height: 44
                anchors.verticalCenter: parent.verticalCenter
                radius: 12
                color: root.softSurface
                border.width: 1
                border.color: root.border

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 11
                    anchors.rightMargin: 11
                    spacing: 6

                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 16
                        implicitHeight: 16
                        source: root.clipboardIcon
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: "CLIPBOARD"
                            color: root.textPrimary
                            font.pixelSize: 6
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                        }

                        Text {
                            text: "Always copied by Niri"
                            color: root.textSecondary
                            font.pixelSize: 6
                        }
                    }

                    Item { width: 1; height: 1 }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "ON"
                        color: root.accent
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.8
                    }
                }
            }

            Rectangle {
                width: 184
                height: 44
                anchors.verticalCenter: parent.verticalCenter
                radius: 12
                color: root.softSurface
                border.width: 1
                border.color: root.border

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 11
                    anchors.rightMargin: 11
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "DELAY"
                        color: root.textPrimary
                        font.pixelSize: 6
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.8
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        Repeater {
                            model: [0, 3, 5]

                            delegate: Rectangle {
                                required property int modelData

                                width: 38
                                height: 24
                                radius: 9
                                color: root.delaySeconds === modelData
                                    ? "#EAF3FF"
                                    : "#FFFFFF"
                                border.width: 1
                                border.color: root.delaySeconds === modelData
                                    ? "#BBD7F5"
                                    : root.border

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData === 0 ? "NOW" : modelData + "S"
                                    color: root.delaySeconds === modelData
                                        ? root.accent
                                        : root.textSecondary
                                    font.pixelSize: 6
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: root.captureMode !== 1
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.delaySeconds = modelData
                                }
                            }
                        }
                    }
                }
            }

            Item {
                width: Math.max(1, parent.width - 790)
                height: 1
            }

            Rectangle {
                width: 106
                height: 44
                anchors.verticalCenter: parent.verticalCenter
                radius: 12
                color: "#F4F6F8"
                border.width: 1
                border.color: root.border

                Text {
                    anchors.centerIn: parent
                    text: "CANCEL"
                    color: root.textSecondary
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }

            Rectangle {
                width: 150
                height: 44
                anchors.verticalCenter: parent.verticalCenter
                radius: 12
                color: root.accent

                IconImage {
                    id: captureIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 17
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 17
                    implicitHeight: 17
                    source: root.captureMode === 2 ? root.windowIcon : root.cameraIcon
                }

                Text {
                    anchors.left: captureIcon.right
                    anchors.leftMargin: 9
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.captureMode === 2 ? "CHOOSE WINDOW" : "CAPTURE"
                    color: "#FFFFFF"
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.7
                    elide: Text.ElideRight
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.beginCapture()
                }
            }
        }
    }

    Keys.onEscapePressed: root.closeRequested()

    Keys.onReturnPressed: root.beginCapture()

    Keys.onLeftPressed: {
        if (root.captureMode > 0)
            root.captureMode -= 1
    }

    Keys.onRightPressed: {
        if (root.captureMode < 2)
            root.captureMode += 1
    }

    onOpenedChanged: {
        if (root.opened) {
            root.captureMode = 0
            root.delaySeconds = 0
            root.includePointer = true
            root.saveToDisk = true
            root.statusText = "LIVE DESKTOP • READY"
            root.forceActiveFocus()
        } else {
            if (windowPickerProcess.running)
                windowPickerProcess.running = false
            pickerTimer.stop()
            captureTimer.stop()
        }
    }
}
