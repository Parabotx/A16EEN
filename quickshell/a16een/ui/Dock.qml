import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: root

    required property var modelData
    property var workspaces: []
    property int focusedWorkspaceId: -1

    readonly property int activeWorkspaceIndex: {
        const active = root.workspaces.find(workspace => workspace.id === root.focusedWorkspaceId)
        return active ? Number(active.idx || -1) : -1
    }

    signal launcherRequested()
    signal dashboardRequested()

    screen: modelData
    color: "transparent"
    aboveWindows: true
    exclusiveZone: 0
    implicitWidth: 92

    anchors {
        left: true
        top: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-dock"

    function findApplication(keywords) {
        const apps = DesktopEntries.applications.values || []

        return apps.find(entry => {
            const haystack = [
                entry.name,
                entry.genericName,
                entry.comment,
                ...(entry.keywords || [])
            ].filter(value => value).join(" ").toLowerCase()

            return keywords.some(keyword => haystack.includes(keyword))
        }) || null
    }

    function launch(entry, fallbackCommand) {
        try {
            if (entry) {
                entry.execute()
            } else if (fallbackCommand) {
                Quickshell.execDetached(fallbackCommand)
            }
        } catch (error) {
            console.error("A16EEN dock launch failed:", error)
        }
    }

    Rectangle {
        id: dock
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 14
        width: 62
        height: Math.min(560, parent.height - 44)
        radius: 30
        color: "#090B10D9"
        border.width: 1
        border.color: "#FFFFFF16"

        // A soft floating shadow is kept entirely inside the shell item.
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: 33
            color: "#00000040"
            z: -1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            spacing: 7

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 40
                height: 40
                radius: 14
                color: "#D7B56D18"
                border.width: 1
                border.color: "#D7B56D46"

                Text {
                    anchors.centerIn: parent
                    text: "A"
                    color: "#D7B56D"
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.8
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 28
                height: 1
                color: "#FFFFFF14"
            }

            DockButton {
                tooltip: "Application launcher"
                icon: "⌕"
                accent: true
                onClicked: root.launcherRequested()
            }

            DockButton {
                tooltip: "Terminal"
                icon: ">"
                onClicked: root.launch(null, ["foot"])
            }

            DockButton {
                tooltip: "Web browser"
                icon: "◉"
                property var app: root.findApplication([
                    "firefox",
                    "mozilla firefox",
                    "chromium",
                    "brave",
                    "google chrome",
                    "microsoft edge"
                ])
                enabled: !!app
                opacity: enabled ? 1 : 0.28
                onClicked: root.launch(app)
            }

            DockButton {
                tooltip: "File manager"
                icon: "▣"
                property var app: root.findApplication([
                    "thunar",
                    "nautilus",
                    "dolphin",
                    "pcmanfm",
                    "file manager"
                ])
                enabled: !!app
                opacity: enabled ? 1 : 0.28
                onClicked: root.launch(app)
            }

            DockButton {
                tooltip: "Code editor"
                icon: "⌘"
                property var app: root.findApplication([
                    "visual studio code",
                    "code",
                    "vscodium",
                    "zed",
                    "codium"
                ])
                enabled: !!app
                opacity: enabled ? 1 : 0.28
                onClicked: root.launch(app)
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 2
                width: 28
                height: 1
                color: "#FFFFFF14"
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "WS"
                color: "#6B7280"
                font.pixelSize: 7
                font.weight: Font.DemiBold
                font.letterSpacing: 1.1
            }

            Repeater {
                model: [1, 2, 3, 4, 5]

                delegate: Rectangle {
                    required property int modelData
                    Layout.alignment: Qt.AlignHCenter
                    width: 34
                    height: 30
                    radius: 10
                    property bool active: modelData === root.activeWorkspaceIndex

                    color: active ? "#D7B56D1F" : "#FFFFFF05"
                    border.width: active ? 1 : 0
                    border.color: "#D7B56D55"

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: parent.active ? "#D7B56D" : "#737B88"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Quickshell.execDetached([
                            "niri", "msg", "action", "focus-workspace",
                            String(modelData)
                        ])
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            DockButton {
                tooltip: "Control center"
                icon: "⚙"
                onClicked: root.dashboardRequested()
            }
        }
    }

    component DockButton: Rectangle {
        property string tooltip: ""
        property string icon: "•"
        property bool accent: false

        signal clicked()

        Layout.alignment: Qt.AlignHCenter
        width: 44
        height: 44
        radius: 15
        color: mouse.containsMouse
            ? (accent ? "#D7B56D2A" : "#FFFFFF10")
            : (accent ? "#D7B56D14" : "#FFFFFF06")
        border.width: accent || mouse.containsMouse ? 1 : 0
        border.color: accent ? "#D7B56D55" : "#FFFFFF18"

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        Text {
            anchors.centerIn: parent
            text: parent.icon
            color: parent.accent || mouse.containsMouse ? "#D7B56D" : "#E1E4E9"
            font.pixelSize: parent.icon === "⌕" ? 24 : 18
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.clicked()
        }

        Rectangle {
            visible: mouse.containsMouse && root.width > 0
            x: parent.width + 8
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(170, tooltipText.implicitWidth + 20)
            height: 30
            radius: 10
            color: "#0B0D12F5"
            border.width: 1
            border.color: "#FFFFFF16"
            z: 10

            Text {
                id: tooltipText
                anchors.centerIn: parent
                text: parent.parent.tooltip
                color: "#F5F2EA"
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }
        }
    }
}
