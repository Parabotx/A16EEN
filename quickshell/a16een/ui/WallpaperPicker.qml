import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool opened: false
    property var wallpapers: []

    signal closeRequested()

    readonly property int columns: 3
    readonly property int tileWidth: 204
    readonly property int tileHeight: 146
    readonly property int tileGap: 10
    readonly property int gridWidth: columns * tileWidth + (columns - 1) * tileGap
    readonly property int gridHeight: wallpapers.length > 0
        ? Math.ceil(wallpapers.length / columns) * (tileHeight + tileGap) - tileGap
        : 0

    screen: modelData
    color: "transparent"
    visible: root.opened
    focusable: root.opened

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-wallpaper-picker"
    WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    Process {
        id: catalogProcess
        command: ["a16een-wallpaper", "catalog"]

        stdout: StdioCollector {
            onStreamFinished: {
                const next = []
                const lines = text.trim().split("
")

                for (const line of lines) {
                    if (!line.length)
                        continue

                    const fields = line.split("	")
                    if (fields.length < 4)
                        continue

                    next.push({
                        source: fields[0],
                        name: fields[1],
                        path: fields[2],
                        selected: fields[3] === "1"
                    })
                }

                root.wallpapers = next
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.opened ? 0.28 : 0
    }

    Rectangle {
        id: card
        z: 2
        width: Math.min(720, parent.width - 64)
        height: Math.min(500, parent.height - 72)
        anchors.centerIn: parent
        radius: 22
        color: "#FFFFFF"
        border.width: 1
        border.color: "#E7E7E7"

        Rectangle {
            anchors.fill: parent
            anchors.margins: -5
            radius: 27
            color: "#28000000"
            z: -1
        }

        Item {
            id: pickerViewport
            anchors.fill: parent
            anchors.margins: 22
            clip: true

            Flickable {
                id: wallpaperScroll
                anchors.fill: parent
                contentWidth: root.gridWidth
                contentHeight: Math.max(
                    root.gridHeight,
                    height
                )
                boundsBehavior: Flickable.StopAtBounds

                Grid {
                    id: wallpaperGrid
                    x: Math.max(0, (parent.width - width) / 2)
                    y: 0
                    width: root.gridWidth
                    columns: root.columns
                    columnSpacing: root.tileGap
                    rowSpacing: root.tileGap

                    Repeater {
                        model: root.wallpapers

                        delegate: Rectangle {
                            required property var modelData

                            width: root.tileWidth
                            height: root.tileHeight
                            radius: 13
                            color: "#FFFFFF"
                            border.width: modelData.selected ? 2 : 1
                            border.color: modelData.selected
                                ? "#111111"
                                : "#E8E8E8"

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: 12
                                color: "#F7F7F7"
                                clip: true

                                Image {
                                    id: preview
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 5
                                    height: 104
                                    source: modelData.path
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    mipmap: true
                                    smooth: true
                                    visible: status === Image.Ready
                                }

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 5
                                    height: 104
                                    radius: 8
                                    color: "#EEEEEE"
                                    visible: preview.status !== Image.Ready

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Preview unavailable"
                                        color: "#A0A0A0"
                                        font.pixelSize: 9
                                    }
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    anchors.bottomMargin: 8
                                    height: 18
                                    text: modelData.name
                                    color: "#161616"
                                    font.pixelSize: 10
                                    font.weight: modelData.selected
                                        ? Font.DemiBold
                                        : Font.Medium
                                    elide: Text.ElideMiddle
                                    verticalAlignment: Text.AlignVCenter
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        root.closeRequested()
                                        Quickshell.execDetached([
                                            "a16een-wallpaper",
                                            "set",
                                            modelData.source,
                                            modelData.name
                                        ])
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.wallpapers.length === 0
                    text: "No wallpapers"
                    color: "#8A8A8A"
                    font.pixelSize: 11
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: 1
        onClicked: root.closeRequested()
    }

    Keys.onEscapePressed: root.closeRequested()

    onOpenedChanged: {
        if (opened) {
            root.wallpapers = []
            catalogProcess.running = false
            catalogProcess.running = true
        }
    }
}
