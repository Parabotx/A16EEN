import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool active: false
    property string stateDir: ""

    readonly property string statePath: root.stateDir + "/navbar-content.json"
    property var contentState: ({
        workspaces: true,
        time: false,
        date: false,
        battery: false,
        volume: false,
        network: false
    })

    readonly property var items: [
        { id: "workspaces", title: "WORKSPACES", subtitle: "Workspace and launcher icons", icon: "layers.svg" },
        { id: "time", title: "CLOCK", subtitle: "Current time", icon: "clock.svg" },
        { id: "date", title: "DATE", subtitle: "Current date", icon: "calendar.svg" },
        { id: "battery", title: "BATTERY", subtitle: "Battery percentage", icon: "zap.svg" },
        { id: "volume", title: "VOLUME", subtitle: "Current audio level", icon: "volume-2.svg" },
        { id: "network", title: "NETWORK", subtitle: "Network connection state", icon: "wifi.svg" }
    ]

    function loadState(raw) {
        try {
            const parsed = JSON.parse(String(raw || ""))
            if (parsed && typeof parsed === "object")
                root.contentState = parsed
        } catch (error) {}
    }

    function isEnabled(id) {
        return root.contentState[id] === true
    }

    function toggle(id) {
        if (saveProcess.running)
            return
        pendingItem = id
        pendingValue = enabled(id) ? "off" : "on"
        saveProcess.running = true
    }

    property string pendingItem: ""
    property string pendingValue: "off"

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
        command: ["/usr/local/bin/a16een-navbar-content", "set", root.pendingItem, root.pendingValue]
        running: false
        onExited: function(exitCode) {
            if (exitCode === 0)
                stateFile.reload()
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 2
        spacing: 12

        Text {
            text: "NAVBAR CONTENT"
            color: "#111318"
            font.pixelSize: 16
            font.weight: Font.DemiBold
            font.letterSpacing: 1
        }

        Text {
            text: "Choose which information appears alongside the workspace icons."
            color: "#64748B"
            font.pixelSize: 9
        }

        Grid {
            width: parent.width
            columns: 2
            rowSpacing: 9
            columnSpacing: 9

            Repeater {
                model: root.items

                delegate: Rectangle {
                    required property var modelData
                    width: (parent.width - 9) / 2
                    height: 88
                    radius: 14
                    color: isEnabled(modelData.id) ? "#111318" : "#F4F6F8"
                    border.width: 1
                    border.color: isEnabled(modelData.id) ? "#111318" : "#CBD3DB"

                    Row {
                        anchors.fill: parent
                        anchors.margins: 13
                        spacing: 10

                        Rectangle {
                            width: 40
                            height: 40
                            radius: 11
                            anchors.verticalCenter: parent.verticalCenter
                            color: isEnabled(modelData.id) ? "#25282E" : "#FFFFFF"
                            border.width: 1
                            border.color: isEnabled(modelData.id) ? "#383D46" : "#CBD3DB"

                            Image {
                                anchors.centerIn: parent
                                width: 19
                                height: 19
                                sourceSize.width: width
                                sourceSize.height: height
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                source: Qt.resolvedUrl("../assets/icons/" + modelData.icon)
                            }
                        }

                        Column {
                            width: parent.width - 108
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Text {
                                text: modelData.title
                                color: isEnabled(modelData.id) ? "#FFFFFF" : "#111318"
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            Text {
                                width: parent.width
                                text: modelData.subtitle
                                color: isEnabled(modelData.id) ? "#AAB2BC" : "#64748B"
                                font.pixelSize: 7
                                wrapMode: Text.WordWrap
                            }
                        }

                        Rectangle {
                            width: 42
                            height: 24
                            radius: 8
                            anchors.verticalCenter: parent.verticalCenter
                            color: isEnabled(modelData.id) ? "#D7B56D" : "#E5E7EB"

                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                anchors.verticalCenter: parent.verticalCenter
                                x: isEnabled(modelData.id) ? parent.width - width - 3 : 3
                                color: isEnabled(modelData.id) ? "#111318" : "#FFFFFF"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                enabled: root.active && !saveProcess.running
                                onClicked: root.toggle(modelData.id)
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 54
            radius: 13
            color: "#FBFCFD"
            border.width: 1
            border.color: "#CBD3DB"

            Text {
                anchors.centerIn: parent
                text: "Only enabled content is added to the live navbar."
                color: "#64748B"
                font.pixelSize: 8
            }
        }
    }
}
