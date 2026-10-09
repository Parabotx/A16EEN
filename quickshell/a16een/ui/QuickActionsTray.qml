import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    required property string navbarPosition
    required property bool dockVisible

    signal notesRequested()
    signal tasksRequested()
    signal presetsRequested()
    signal calendarRequested()

    readonly property bool horizontalNavbar:
        root.navbarPosition === "top" || root.navbarPosition === "bottom"

    readonly property var actions: [
        { id: "notes", icon: "quick-notes.svg", label: "Notes" },
        { id: "tasks", icon: "quick-tasks.svg", label: "Tasks" },
        { id: "presets", icon: "quick-presets.svg", label: "Presets" },
        { id: "calendar", icon: "quick-calendar.svg", label: "Ethiopian calendar" }
    ]

    screen: root.modelData
    visible: root.dockVisible && root.modelData !== null
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    width: root.horizontalNavbar ? 176 : 50
    height: root.horizontalNavbar ? 46 : 124

    anchors {
        left: !root.horizontalNavbar && root.navbarPosition === "left"
        right: root.horizontalNavbar || root.navbarPosition === "right"
        top: root.navbarPosition === "top"
        bottom: root.navbarPosition !== "top"
    }

    // Vertically, the tray sits between the workspace rail and battery pill,
    // just eight pixels above the battery panel. Horizontally, it sits just
    // before the battery capsule, away from the centered workspace navbar.
    margins {
        left: root.horizontalNavbar ? 12 : 28
        right: root.horizontalNavbar ? 118 : 28
        top: 12
        bottom: root.horizontalNavbar ? 12 : 72
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-quick-actions"

    Rectangle {
        anchors.fill: parent
        radius: root.horizontalNavbar ? 17 : 17
        color: "#FFFFFF"
        border.width: 1
        border.color: "#D9DEE5"

        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: 20
            color: "#10000000"
            z: -1
        }

        Row {
            visible: root.horizontalNavbar
            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: root.actions

                delegate: Rectangle {
                    id: actionButton
                    required property var modelData

                    width: 32
                    height: 32
                    radius: 10
                    color: actionHover.containsMouse ? "#F1F3F6" : "transparent"
                    border.width: actionHover.containsMouse ? 1 : 0
                    border.color: "#E2E6EB"

                    Image {
                        anchors.centerIn: parent
                        width: 17
                        height: 17
                        source: Qt.resolvedUrl("../assets/icons/" + actionButton.modelData.icon)
                        sourceSize.width: 34
                        sourceSize.height: 34
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    MouseArea {
                        id: actionHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activateAction(actionButton.modelData.id)
                    }
                }
            }
        }

        Column {
            visible: !root.horizontalNavbar
            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: root.actions

                delegate: Rectangle {
                    id: actionButton
                    required property var modelData

                    width: 26
                    height: 26
                    radius: 9
                    color: actionHover.containsMouse ? "#F1F3F6" : "transparent"
                    border.width: actionHover.containsMouse ? 1 : 0
                    border.color: "#E2E6EB"

                    Image {
                        anchors.centerIn: parent
                        width: 15
                        height: 15
                        source: Qt.resolvedUrl("../assets/icons/" + actionButton.modelData.icon)
                        sourceSize.width: 32
                        sourceSize.height: 32
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    MouseArea {
                        id: actionHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activateAction(actionButton.modelData.id)
                    }
                }
            }
        }
    }

    function activateAction(actionId) {
        switch (actionId) {
        case "notes":
            root.notesRequested()
            break
        case "tasks":
            root.tasksRequested()
            break
        case "presets":
            root.presetsRequested()
            break
        case "calendar":
            root.calendarRequested()
            break
        }
    }
}
