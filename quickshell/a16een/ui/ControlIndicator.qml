import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData

    readonly property string eventPath: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
        + "/a16een/control-indicator"
    property bool eventWatcherReady: false

    property string mode: ""
    property real level: 0
    property bool mounted: false
    property bool displaying: false

    screen: modelData
    visible: root.mounted
    color: "transparent"
    aboveWindows: true
    exclusiveZone: 0
    implicitHeight: 34

    anchors {
        left: true
        right: true
        bottom: true
    }

    margins {
        bottom: 52
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-control-indicator"

    mask: Region {
        x: Math.round((root.width - 182) / 2)
        y: 11
        width: 182
        height: 12
    }

    Item {
        id: capsule
        width: 180
        height: 10
        anchors.centerIn: parent
        opacity: root.displaying ? 1 : 0
        scale: root.displaying ? 1 : 0.94

        Behavior on opacity {
            NumberAnimation {
                duration: 105
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 135
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 5
            color: "#FFFFFF"
        }

        Rectangle {
            x: 2
            y: 2
            width: Math.max(2, (parent.width - 4) * Math.max(0, Math.min(1, root.level)))
            height: parent.height - 4
            radius: 3
            color: "#000000"

            Behavior on width {
                NumberAnimation {
                    duration: 90
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    FileView {
        id: controlEvent

        path: root.eventPath
        watchChanges: true

        onFileChanged: reload()

        onTextChanged: {
            if (!root.eventWatcherReady)
                return

            const payload = String(text).trim()
            if (!payload.length)
                return

            const parts = payload.split("|")
            const kind = parts[0]

            if (kind === "volume")
                root.showVolume()
            else if (kind === "brightness")
                root.showBrightness()
        }
    }

    Timer {
        interval: 250
        running: true
        repeat: false

        onTriggered: root.eventWatcherReady = true
    }

    Process {
        id: volumeRead

        command: ["a16een-control", "audio", "status"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const output = String(text).trim()
                const match = output.match(/^([0-9]+)/)

                if (!match)
                    return

                const value = Number(match[1])
                if (Number.isFinite(value))
                    root.reveal("volume", value / 100)
            }
        }
    }

    Process {
        id: brightnessRead

        command: ["a16een-control", "brightness", "status"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const value = Number(String(text).trim())
                if (Number.isFinite(value))
                    root.reveal("brightness", value / 100)
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 850
        repeat: false

        onTriggered: {
            root.displaying = false
            removeTimer.restart()
        }
    }

    Timer {
        id: removeTimer
        interval: 140
        repeat: false

        onTriggered: root.mounted = false
    }

    function reveal(kind, value) {
        if (root.mode !== kind)
            return

        root.level = Math.max(0, Math.min(1, value))
        root.mounted = true
        root.displaying = true
        removeTimer.stop()
        hideTimer.restart()
    }

    function showVolume() {
        root.mode = "volume"
        volumeRead.running = false
        volumeRead.running = true
    }

    function showBrightness() {
        root.mode = "brightness"
        brightnessRead.running = false
        brightnessRead.running = true
    }
}
