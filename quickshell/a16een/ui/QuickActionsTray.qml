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

    readonly property bool horizontalNavbar:
        root.navbarPosition === "top" || root.navbarPosition === "bottom"

    readonly property var actions: [
        { id: "notes", icon: "quick-notes.svg", label: "Notes" },
        { id: "tasks", icon: "quick-tasks.svg", label: "Tasks" },
        { id: "presets", icon: "quick-presets.svg", label: "Presets" }
    ]

    screen: root.modelData
    visible: root.dockVisible && root.modelData !== null
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    // Size the shell surface to the three compact buttons, with minimal padding.
    width: root.horizontalNavbar ? 76 : 36
    height: root.horizontalNavbar ? 28 : 76

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
        // Vertical trays sit just outside the navbar's visible 44px rail.
        // Horizontal trays share the battery capsule's 12px edge alignment.
        // Align the vertical tray exactly with the visible 44px navbar rail.
        // Horizontally it sits directly beside the battery capsule.
        // Keep the holder flush against the active screen side just like
        // the workspace rail. Horizontal layouts keep the small battery gap.
        left: root.horizontalNavbar ? 0 : 10
        right: root.horizontalNavbar ? 102 : 10
        top: 0
        bottom: root.horizontalNavbar ? 0 : 72
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-quick-actions"

    Rectangle {
        anchors.fill: parent
        radius: 11
        color: "#FFFFFF"
        border.width: 1
        border.color: "#D9DEE5"

        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: 14
            color: "#10000000"
            z: -1
        }

        Row {
            visible: root.horizontalNavbar
            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: root.actions

                delegate: Rectangle {
                    id: actionButton
                    required property var modelData

                    width: 22
                    height: 22
                    radius: 7
                    color: actionHover.containsMouse ? "#F1F3F6" : "transparent"
                    border.width: actionHover.containsMouse ? 1 : 0
                    border.color: "#E2E6EB"

                    Image {
                        anchors.centerIn: parent
                        width: 13
                        height: 13
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
            spacing: 2

            Repeater {
                model: root.actions

                delegate: Rectangle {
                    id: actionButton
                    required property var modelData

                    width: 22
                    height: 22
                    radius: 7
                    color: actionHover.containsMouse ? "#F1F3F6" : "transparent"
                    border.width: actionHover.containsMouse ? 1 : 0
                    border.color: "#E2E6EB"

                    Image {
                        anchors.centerIn: parent
                        width: 13
                        height: 13
                        source: Qt.resolvedUrl("../assets/icons/" + actionButton.modelData.icon)
                        sourceSize.width: 30
                        sourceSize.height: 30
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
        }
    }
}
