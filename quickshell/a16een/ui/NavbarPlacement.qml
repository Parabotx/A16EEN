import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool active: false
    property string position: "right"
    property string pendingPosition: ""
    property string statusText: "READY"

    signal positionApplied(string position)

    readonly property string stateDir: {
        const stateHome = Quickshell.env("XDG_STATE_HOME")
        const home = Quickshell.env("HOME") || ""
        return (stateHome && stateHome.length ? stateHome : home + "/.local/state") + "/a16een"
    }

    readonly property string layoutPath: root.stateDir + "/navbar-layout.json"

    readonly property color panel: "#FFFFFF"
    readonly property color border: "#D9DEE5"
    readonly property color borderStrong: "#B8C1CC"
    readonly property color text: "#111318"
    readonly property color muted: "#66707C"
    readonly property color hover: "#F5F6F7"
    readonly property color selected: "#ECEEF1"

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
                root.positionApplied(root.position)
            } else {
                root.statusText = "MOVE FAILED"
                layoutFile.reload()
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 0
        color: "transparent"
        border.width: 0
        border.color: "transparent"

        Row {
            anchors.fill: parent
            anchors.margins: 0
            spacing: 6

            Repeater {
                model: [
                    { id: "left", name: "LEFT", glyph: "←" },
                    { id: "right", name: "RIGHT", glyph: "→" },
                    { id: "top", name: "TOP", glyph: "↑" },
                    { id: "bottom", name: "BOTTOM", glyph: "↓" }
                ]

                delegate: Rectangle {
                    width: (parent.width - 69) / 4
                    height: 34
                    radius: 7
                    color: root.position === modelData.id ? root.selected
                        : (placementMouse.containsMouse ? root.hover : "transparent")
                    border.width: 0
                    border.color: "transparent"

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: modelData.glyph
                            color: root.position === modelData.id ? "#111318" : root.text
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: modelData.name
                            color: root.position === modelData.id ? "#1A1E23" : root.text
                            font.pixelSize: 9
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
                width: 45
                height: parent.height
                visible: root.statusText !== "READY"
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                text: root.statusText
                color: root.muted
                font.pixelSize: 8
                font.weight: Font.DemiBold
            }
        }
    }

    onActiveChanged: {
        if (root.active)
            layoutFile.reload()
    }
}
