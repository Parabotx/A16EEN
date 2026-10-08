import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool active: false
    property string stateDir: ""
    property string position: "right"
    signal backRequested()

    readonly property var positions: [
        { id: "left", title: "LEFT", subtitle: "Vertical • left edge", icon: "panel-left.svg" },
        { id: "right", title: "RIGHT", subtitle: "Vertical • right edge", icon: "panel-right.svg" },
        { id: "top", title: "TOP", subtitle: "Horizontal • top edge", icon: "panel-top.svg" },
        { id: "bottom", title: "BOTTOM", subtitle: "Horizontal • bottom edge", icon: "panel-bottom.svg" }
    ]

    readonly property string statePath: root.stateDir + "/navbar-layout.json"

    function loadState(raw) {
        try {
            const parsed = JSON.parse(String(raw || ""))
            if (parsed && parsed.position)
                root.position = parsed.position
        } catch (error) {}
    }

    function choosePosition(value) {
        if (root.position === value || saveProcess.running)
            return
        root.pendingPosition = value
        saveProcess.running = true
    }

    property string pendingPosition: "right"

    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true
        printErrors: false
        onLoaded: root.loadState(this.text())
        onFileChanged: root.loadState(this.text())
    }

    Process {
        id: saveProcess
        command: ["/usr/local/bin/a16een-navbar-layout", "set", root.pendingPosition]
        running: false
        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.position = root.pendingPosition
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 2
        spacing: 14

        Text {
            text: "LAYOUT & POSITION"
            color: "#111318"
            font.pixelSize: 16
            font.weight: Font.DemiBold
            font.letterSpacing: 1
        }

        Text {
            text: "Choose where A16EEN places the navbar. Changes apply immediately."
            color: "#64748B"
            font.pixelSize: 9
        }

        Grid {
            width: parent.width
            columns: 2
            rowSpacing: 10
            columnSpacing: 10

            Repeater {
                model: root.positions

                delegate: Rectangle {
                    required property var modelData
                    width: (parent.width - 10) / 2
                    height: 132
                    radius: 16
                    color: root.position === modelData.id ? "#111318" : "#F4F6F8"
                    border.width: 1
                    border.color: root.position === modelData.id ? "#111318" : "#CBD3DB"

                    Column {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        Row {
                            spacing: 10

                            Rectangle {
                                width: 42
                                height: 42
                                radius: 12
                                color: root.position === modelData.id ? "#25282E" : "#FFFFFF"
                                border.width: 1
                                border.color: root.position === modelData.id ? "#383D46" : "#CBD3DB"

                                Image {
                                    anchors.centerIn: parent
                                    width: 20
                                    height: 20
                                    sourceSize.width: width
                                    sourceSize.height: height
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    source: Qt.resolvedUrl("../assets/icons/" + modelData.icon)
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3

                                Text {
                                    text: modelData.title
                                    color: root.position === modelData.id ? "#FFFFFF" : "#111318"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: modelData.subtitle
                                    color: root.position === modelData.id ? "#AAB2BC" : "#64748B"
                                    font.pixelSize: 7
                                }
                            }
                        }

                        Item { width: 1; height: 2 }

                        Text {
                            text: root.position === modelData.id ? "ACTIVE" : "USE THIS POSITION"
                            color: root.position === modelData.id ? "#D7B56D" : "#64748B"
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.9
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.active && !saveProcess.running
                        onClicked: root.choosePosition(modelData.id)
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 70
            radius: 14
            color: "#FBFCFD"
            border.width: 1
            border.color: "#CBD3DB"

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 3

                Text {
                    text: "CURRENT POSITION"
                    color: "#64748B"
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                }

                Text {
                    text: root.position.toUpperCase()
                    color: "#111318"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
