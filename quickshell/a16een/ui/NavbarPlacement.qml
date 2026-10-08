import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool active: false
    property string position: "right"
    property string pendingPosition: ""
    property string statusText: "READY"

    signal positionChanged(string position)

    readonly property string stateDir: {
        const stateHome = Quickshell.env("XDG_STATE_HOME")
        const home = Quickshell.env("HOME") || ""
        return (stateHome && stateHome.length ? stateHome : home + "/.local/state") + "/a16een"
    }

    readonly property string layoutPath: root.stateDir + "/navbar-layout.json"

    readonly property color panel: "#F4F6F8"
    readonly property color border: "#46515E"
    readonly property color borderStrong: "#667384"
    readonly property color text: "#F4F6F9"
    readonly property color muted: "#98A4B2"
    readonly property color hover: "#3B434E"
    readonly property color selected: "#515D6A"

    function loadPosition(raw) {
        try {
            const parsed = JSON.parse(String(raw || ""))
            if (parsed && ["left", "right", "top", "bottom"].includes(parsed.position))
                root.position = parsed.position
        } catch (error) {
            root.position = "right"
        }
    }

    function applyPosition(nextPosition) {
        if (!["left", "right", "top", "bottom"].includes(nextPosition)
            || nextPosition === root.position
            || positionProcess.running)
            return

        root.pendingPosition = nextPosition
        root.statusText = "MOVING"
        positionProcess.running = true
    }

    FileView {
        id: layoutFile
        path: root.layoutPath
        watchChanges: true
        printErrors: false
        onLoaded: root.loadPosition(this.text())
        onFileChanged: root.loadPosition(this.text())
    }

    Process {
        id: positionProcess
        command: ["a16een-navbar-layout", "set", root.pendingPosition]
        running: false

        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.position = root.pendingPosition
                root.statusText = "READY"
                layoutFile.reload()
                root.positionChanged(root.position)
            } else {
                root.statusText = "MOVE FAILED"
                layoutFile.reload()
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: "#262C34"
        border.width: 1
        border.color: root.border

        Row {
            anchors.fill: parent
            anchors.margins: 7
            spacing: 7

            Text {
                width: 88
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                text: "NAVBAR PLACEMENT"
                color: root.muted
                font.pixelSize: 7
                font.weight: Font.DemiBold
                font.letterSpacing: 1
            }

            Repeater {
                model: [
                    { id: "left", name: "LEFT", glyph: "←" },
                    { id: "right", name: "RIGHT", glyph: "→" },
                    { id: "top", name: "TOP", glyph: "↑" },
                    { id: "bottom", name: "BOTTOM", glyph: "↓" }
                ]

                delegate: Rectangle {
                    width: (parent.width - 109) / 4
                    height: 32
                    radius: 9
                    color: root.position === modelData.id ? "#F4F6F9"
                        : (placementMouse.containsMouse ? root.hover : "#323943")
                    border.width: 1
                    border.color: root.position === modelData.id
                        ? root.text : root.border

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: modelData.glyph
                            color: root.position === modelData.id ? "#1A1E23" : root.text
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: modelData.name
                            color: root.position === modelData.id ? "#1A1E23" : root.text
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                        }
                    }

                    MouseArea {
                        id: placementMouse
                        anchors.fill: parent
                        enabled: root.active && !positionProcess.running
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.applyPosition(modelData.id)
                    }
                }
            }

            Text {
                width: 58
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                text: root.statusText
                color: root.muted
                font.pixelSize: 7
                font.weight: Font.DemiBold
            }
        }
    }

    onActiveChanged: {
        if (root.active)
            layoutFile.reload()
    }
}
