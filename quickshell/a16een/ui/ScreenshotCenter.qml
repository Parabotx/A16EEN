import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool opened: false

    property int phase: 0 // 0 menu, 1 preparing area, 2 selecting area, 3 capturing
    property string snapshotPath: ""
    property real selectionX: 0
    property real selectionY: 0
    property real selectionWidth: 0
    property real selectionHeight: 0
    property real dragStartX: 0
    property real dragStartY: 0
    property bool dragging: false
    property real screenOriginX: modelData ? modelData.geometry.x : 0
    property real screenOriginY: modelData ? modelData.geometry.y : 0

    signal closeRequested()

    readonly property string monitorIcon: Qt.resolvedUrl("../assets/icons/lucide-monitor.svg")
    readonly property string cropIcon: Qt.resolvedUrl("../assets/icons/lucide-crop.svg")
    readonly property string windowIcon: Qt.resolvedUrl("../assets/icons/lucide-app-window.svg")

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

    function resetSelection() {
        root.selectionX = 0
        root.selectionY = 0
        root.selectionWidth = 0
        root.selectionHeight = 0
        root.dragging = false
    }

    function beginMode(mode) {
        root.resetSelection()
        root.phase = mode === 1 ? 1 : 3
        if (mode === 1) {
            areaPrepareProcess.running = false
            areaPrepareProcess.running = true
        } else {
            captureProcess.command = [
                "a16een-screenshot",
                mode === 0 ? "screen" : "window"
            ]
            captureProcess.running = false
            captureProcess.running = true
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

    Process {
        id: captureProcess
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
                    console.warn("A16EEN screenshot:", text.trim())
            }
        }
    }

    Process {
        id: areaPrepareProcess
        command: ["a16een-screenshot", "prepare-area"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim()
                if (!path.length) {
                    root.phase = 0
                    root.closeRequested()
                    return
                }

                root.snapshotPath = path
                root.phase = 2
                root.resetSelection()
                root.forceActiveFocus()
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
        anchors.fill: parent
        visible: root.phase === 2
        z: 1

        Image {
            id: snapshot
            anchors.fill: parent
            source: root.snapshotPath
            fillMode: Image.Stretch
            asynchronous: true
            opacity: 0.0
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

    Row {
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

    Keys.onEscapePressed: root.closeRequested()

    onOpenedChanged: {
        if (root.opened) {
            root.phase = 0
            root.resetSelection()
            root.snapshotPath = ""
            root.forceActiveFocus()
        } else if (!root.areaPrepareProcess.running && !root.areaCaptureProcess.running
                   && !root.captureProcess.running) {
            root.phase = 0
        }
    }
}
