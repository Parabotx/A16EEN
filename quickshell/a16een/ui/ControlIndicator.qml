import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    required property bool active
    required property real requestedLevel
    required property int requestRevision

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
            opacity: 0.98
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

    function showLevel(value: real) {
        root.level = Math.max(0, Math.min(1, value))
        root.mounted = true
        root.displaying = true
        removeTimer.stop()
        hideTimer.restart()
    }

    onRequestRevisionChanged: {
        if (root.active)
            root.showLevel(root.requestedLevel)
    }

    onActiveChanged: {
        if (!root.active) {
            hideTimer.stop()
            removeTimer.stop()
            root.displaying = false
            root.mounted = false
        }
    }
}
