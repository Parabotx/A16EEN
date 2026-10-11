import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import "WindowGeometry.js" as WindowGeometry

PanelWindow {
    id: root

    required property var modelData
    property bool opened: false
    property bool preparingCapture: false
    property string prepareCommand: ""

    property int phase: 0 // 0 menu, 1 preparing area, 2 selecting area, 3 capturing, 4 preparing window picker, 5 picking window
    property string snapshotPath: ""
    property real selectionX: 0
    property real selectionY: 0
    property real selectionWidth: 0
    property real selectionHeight: 0
    property real dragStartX: 0
    property real dragStartY: 0
    property bool dragging: false
    property real screenOriginX: modelData ? modelData.x : 0
    property real screenOriginY: modelData ? modelData.y : 0
    property var windowItems: []
    property var workspaceItems: []
    property int focusedWorkspaceId: -1
    property int focusedWindowId: -1
    property int hoveredWindowId: -1
    property var hoveredWindowRect: null
    property string hoveredWindowName: ""
    readonly property var windowCandidates: WindowGeometry.buildCandidates(
        root.width, root.height, root.windowItems, root.workspaceItems,
        root.focusedWorkspaceId, root.focusedWindowId
    )

    signal closeRequested()

    readonly property string monitorIcon: Qt.resolvedUrl("../assets/icons/lucide-monitor.svg")
    readonly property string cropIcon: Qt.resolvedUrl("../assets/icons/lucide-crop.svg")
    readonly property string windowIcon: Qt.resolvedUrl("../assets/icons/lucide-app-window.svg")
    readonly property string cancelIcon: Qt.resolvedUrl("../assets/icons/lucide-x.svg")

    screen: modelData
    color: "transparent"
    visible: root.opened && !root.preparingCapture
    focusable: root.opened && !root.preparingCapture
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
    WlrLayershell.keyboardFocus: root.opened && !root.preparingCapture
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    // This picker owns hover/click selection itself. Do not restrict the
    // full-screen surface with a Region mask: the old native-picker pass-through
    // mask swallowed pointer transitions in both area and window modes.

    function cancelCapture() {
        root.dragging = false
        root.preparingCapture = false
        prepareCaptureTimer.stop()
        root.resetSelection()
        if (areaPrepareProcess.running)
            areaPrepareProcess.running = false
        if (areaCaptureProcess.running)
            areaCaptureProcess.running = false
        if (captureProcess.running)
            captureProcess.running = false
        if (root.snapshotPath.length)
            Quickshell.execDetached(["rm", "-f", root.snapshotPath])
        root.snapshotPath = ""
        root.phase = 0
        root.closeRequested()
    }

    function resetSelection() {
        root.selectionX = 0
        root.selectionY = 0
        root.selectionWidth = 0
        root.selectionHeight = 0
        root.dragging = false
    }

    // Window bounds are derived by the helper module so QML stays easy to
    // parse and the hit-test math remains independently testable.

    function updateHoveredWindow(x, y) {
        const candidates = root.windowCandidates
        let hit = null
        // Floating windows appear above tiled windows.
        for (let i = candidates.length - 1; i >= 0; i--) {
            const item = candidates[i]
            const rect = item.rect
            if (x >= rect.x && y >= rect.y
                    && x < rect.x + rect.width && y < rect.y + rect.height) {
                hit = item
                break
            }
        }
        root.hoveredWindowId = hit ? hit.id : -1
        root.hoveredWindowRect = hit ? hit.rect : null
        root.hoveredWindowName = hit ? hit.title : ""
    }

    function captureHoveredWindow() {
        if (root.phase !== 5 || root.hoveredWindowId < 0)
            return

        root.phase = 3
        captureProcess.command = [
            "a16een-screenshot",
            "window-id",
            String(root.hoveredWindowId),
            root.snapshotPath
        ]
        captureProcess.running = false
        captureProcess.running = true
    }

    function beginMode(mode) {
        root.resetSelection()
        root.snapshotPath = ""

        if (mode === 1) {
            root.phase = 1
            root.prepareCommand = "prepare-area"
            root.preparingCapture = true
            prepareCaptureTimer.restart()
        } else if (mode === 2) {
            // Hide the panel before taking the frozen background so the image
            // contains the desktop rather than the menu/layer-shell itself.
            root.phase = 4
            root.hoveredWindowId = -1
            root.hoveredWindowRect = null
            root.hoveredWindowName = ""
            root.prepareCommand = "prepare-window"
            root.preparingCapture = true
            prepareCaptureTimer.restart()
        } else {
            root.phase = 3
            root.preparingCapture = true
            prepareCaptureTimer.restart()
        }
    }

    function normalizeSelection() {
        const x1 = Math.max(0, Math.min(root.dragStartX, mouseArea.mouseX))
        const y1 = Math.max(0, Math.min(root.dragStartY, mouseArea.mouseY))
        const x2 = Math.min(root.width, Math.max(root.dragStartX, mouseArea.mouseX))
        const y2 = Math.min(root.height, Math.max(root.dragStartY, mouseArea.mouseY))

        root.selectionX = x1
        root.selectionY = y1
        root.selectionWidth = Math.max(0, x2 - x1)
        root.selectionHeight = Math.max(0, y2 - y1)
    }

    function finishAreaSelection() {
        root.dragging = false

        if (root.selectionWidth < 8 || root.selectionHeight < 8) {
            root.resetSelection()
            return
        }

        root.phase = 3

        areaCaptureProcess.command = [
            "a16een-screenshot",
            "area",
            root.snapshotPath,
            String(Math.round(root.selectionX + root.screenOriginX)),
            String(Math.round(root.selectionY + root.screenOriginY)),
            String(Math.round(root.selectionWidth)),
            String(Math.round(root.selectionHeight))
        ]
        areaCaptureProcess.running = false
        areaCaptureProcess.running = true
    }

    Timer {
        id: prepareCaptureTimer
        interval: 160
        repeat: false
        onTriggered: {
            if (!root.opened)
                return
            if (root.phase === 3) {
                captureProcess.command = ["/usr/local/bin/a16een-screenshot", "screen"]
                captureProcess.running = false
                captureProcess.running = true
            } else {
                areaPrepareProcess.command = ["/usr/local/bin/a16een-screenshot", root.prepareCommand]
                areaPrepareProcess.running = false
                areaPrepareProcess.running = true
            }
        }
    }

    Process {
        id: captureProcess
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.preparingCapture = false
                root.phase = 0
                root.closeRequested()
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length)
                    console.warn("A16EEN screenshot:", text.trim())
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && root.opened) {
                root.preparingCapture = false
                root.phase = 0
                console.warn("A16EEN screenshot capture process exited with code", exitCode)
                root.forceActiveFocus()
            }
        }
    }

    Process {
        id: areaPrepareProcess
        command: ["a16een-screenshot", "prepare-area"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const path = String(text || "").trim()
                if (!path.length) {
                    // Recover to the menu instead of leaving an invisible
                    // full-screen overlay catching every click.
                    root.preparingCapture = false
                    root.phase = 0
                    Qt.callLater(root.forceActiveFocus)
                    console.warn("A16EEN screenshot selection could not prepare its background.")
                    return
                }

                root.snapshotPath = path
                root.resetSelection()
                if (root.prepareCommand === "prepare-window")
                    root.phase = 5
                else
                    root.phase = 2
                root.preparingCapture = false
                Qt.callLater(root.forceActiveFocus)
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && root.opened) {
                root.preparingCapture = false
                root.phase = 0
                Qt.callLater(root.forceActiveFocus)
                console.warn("A16EEN screenshot background process exited with code", exitCode)
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length)
                    console.warn("A16EEN area prepare:", text.trim())
            }
        }
    }

    Process {
        id: areaCaptureProcess
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.phase = 0
                root.closeRequested()
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length)
                    console.warn("A16EEN area capture:", text.trim())
            }
        }
    }

    Item {
        id: areaSelectionOverlay
        anchors.fill: parent
        visible: root.phase === 2
        z: 1

        Image {
            id: snapshot
            anchors.fill: parent
            source: root.snapshotPath
            fillMode: Image.Stretch
            asynchronous: true
            cache: false
        }

        MultiEffect {
            anchors.fill: parent
            source: snapshot
            visible: snapshot.status === Image.Ready
            blurEnabled: true
            blurMax: 28
            blur: 0.8
            brightness: -0.18
            autoPaddingEnabled: false
        }

        Rectangle {
            anchors.fill: parent
            color: "#66000000"
            visible: snapshot.status === Image.Ready
        }

        Item {
            x: root.selectionX
            y: root.selectionY
            width: root.selectionWidth
            height: root.selectionHeight
            clip: true
            visible: root.selectionWidth > 0 && root.selectionHeight > 0

            Image {
                x: -root.selectionX
                y: -root.selectionY
                width: root.width
                height: root.height
                source: root.snapshotPath
                fillMode: Image.Stretch
                asynchronous: true
                cache: false
            }
        }

        Rectangle {
            x: root.selectionX
            y: root.selectionY
            width: root.selectionWidth
            height: root.selectionHeight
            visible: root.selectionWidth > 0 && root.selectionHeight > 0
            color: "transparent"
            border.width: 2
            border.color: "#FFFFFF"

            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                color: "transparent"
                border.width: 1
                border.color: "#2F80ED"
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 28
            text: root.selectionWidth > 0
                ? Math.round(root.selectionWidth) + " × " + Math.round(root.selectionHeight)
                : "DRAG TO SELECT"
            color: "#FFFFFF"
            font.pixelSize: 10
            font.weight: Font.DemiBold
            visible: snapshot.status === Image.Ready
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.CrossCursor

            onPressed: {
                root.dragging = true
                root.dragStartX = mouseX
                root.dragStartY = mouseY
                root.selectionX = mouseX
                root.selectionY = mouseY
                root.selectionWidth = 0
                root.selectionHeight = 0
            }

            onPositionChanged: {
                if (root.dragging)
                    root.normalizeSelection()
            }

            onReleased: root.finishAreaSelection()

            onCanceled: {
                root.dragging = false
                root.resetSelection()
            }
        }
    }

    Item {
        id: windowSelectionOverlay
        anchors.fill: parent
        visible: root.phase === 5
        z: 1
        clip: true

        Image {
            id: windowSnapshot
            anchors.fill: parent
            source: root.snapshotPath
            fillMode: Image.Stretch
            asynchronous: true
            cache: false
        }

        MultiEffect {
            anchors.fill: parent
            source: windowSnapshot
            visible: windowSnapshot.status === Image.Ready
            blurEnabled: true
            blurMax: 28
            blur: 0.62
            brightness: -0.12
            autoPaddingEnabled: false
        }

        Rectangle {
            anchors.fill: parent
            color: "#36000000"
            visible: windowSnapshot.status === Image.Ready
        }

        Item {
            x: root.hoveredWindowRect ? root.hoveredWindowRect.x : 0
            y: root.hoveredWindowRect ? root.hoveredWindowRect.y : 0
            width: root.hoveredWindowRect ? root.hoveredWindowRect.width : 0
            height: root.hoveredWindowRect ? root.hoveredWindowRect.height : 0
            clip: true
            visible: root.hoveredWindowId >= 0 && windowSnapshot.status === Image.Ready

            Image {
                x: root.hoveredWindowRect ? -root.hoveredWindowRect.x : 0
                y: root.hoveredWindowRect ? -root.hoveredWindowRect.y : 0
                width: root.width
                height: root.height
                source: root.snapshotPath
                fillMode: Image.Stretch
                asynchronous: true
                cache: false
            }
        }

        Rectangle {
            x: root.hoveredWindowRect ? root.hoveredWindowRect.x : 0
            y: root.hoveredWindowRect ? root.hoveredWindowRect.y : 0
            width: root.hoveredWindowRect ? root.hoveredWindowRect.width : 0
            height: root.hoveredWindowRect ? root.hoveredWindowRect.height : 0
            color: "transparent"
            border.width: 2
            border.color: "#FFFFFF"
            visible: root.hoveredWindowId >= 0
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 35
            spacing: 7
            z: 3

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "SELECT A WINDOW"
                color: "#FFFFFF"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 1.2
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.hoveredWindowId >= 0
                    ? root.hoveredWindowName
                    : "Hover a window to highlight it"
                color: "#E5EAF0"
                font.pixelSize: 9
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 26
            text: root.hoveredWindowId >= 0
                ? "CLICK TO CAPTURE  ·  ESC TO CANCEL"
                : "HOVER A WINDOW  ·  ESC TO CANCEL"
            color: "#FFFFFF"
            font.pixelSize: 8
            font.weight: Font.DemiBold
            font.letterSpacing: 1.0
            z: 3
        }

        MouseArea {
            id: windowPickerMouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: root.hoveredWindowId >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
            z: 4

            onPositionChanged: root.updateHoveredWindow(mouseX, mouseY)
            onEntered: root.updateHoveredWindow(mouseX, mouseY)
            onExited: {
                root.hoveredWindowId = -1
                root.hoveredWindowRect = null
                root.hoveredWindowName = ""
            }
            onClicked: {
                root.updateHoveredWindow(mouseX, mouseY)
                Qt.callLater(root.captureHoveredWindow)
            }
        }
    }

    Row {
        id: screenshotModeRow
        visible: root.phase === 0
        z: 2
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 36
        spacing: 12

        Repeater {
            model: [
                { icon: root.monitorIcon, mode: 0, label: "Full desktop" },
                { icon: root.cropIcon, mode: 1, label: "Selected place" },
                { icon: root.windowIcon, mode: 2, label: "Specific window" }
            ]

            delegate: Rectangle {
                required property var modelData

                width: 56
                height: 56
                radius: 16
                color: buttonMouse.containsMouse ? "#FFFFFF" : "#F7F9FB"
                border.width: 1
                border.color: "#DDE4EA"

                scale: buttonMouse.containsMouse ? 1.04 : 1.0

                Behavior on color {
                    ColorAnimation { duration: 110 }
                }

                Behavior on scale {
                    NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
                }

                IconImage {
                    anchors.centerIn: parent
                    implicitWidth: 24
                    implicitHeight: 24
                    source: modelData.icon
                }

                MouseArea {
                    id: buttonMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.beginMode(modelData.mode)
                }
            }
        }
    }

    Rectangle {
        id: cancelButton
        visible: root.opened && (root.phase === 0 || root.phase === 2 || root.phase === 5)
        z: 10
        width: 36
        height: 36
        anchors.right: screenshotModeRow.left
        anchors.rightMargin: 12
        anchors.verticalCenter: screenshotModeRow.verticalCenter
        radius: 18
        color: cancelMouse.containsMouse ? "#FFFFFF" : "#F7F9FB"
        border.width: 1
        border.color: "#DDE4EA"

        IconImage {
            anchors.centerIn: parent
            implicitWidth: 17
            implicitHeight: 17
            source: root.cancelIcon
        }

        MouseArea {
            id: cancelMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.cancelCapture()
        }
    }

    Keys.onEscapePressed: root.cancelCapture()

    onOpenedChanged: {
        if (root.opened) {
            prepareCaptureTimer.stop()
            root.preparingCapture = false
            root.phase = 0
            root.resetSelection()
            root.snapshotPath = ""
            root.hoveredWindowId = -1
            root.hoveredWindowRect = null
            root.hoveredWindowName = ""
            root.forceActiveFocus()
        } else if (!root.areaPrepareProcess.running && !root.areaCaptureProcess.running
                   && !root.captureProcess.running) {
            root.phase = 0
        }
    }
}
