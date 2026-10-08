import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData

    property real level: 0
    property bool displaying: false

    screen: modelData
    visible: root.displaying
    color: "transparent"
    aboveWindows: true
    exclusiveZone: 0

    implicitWidth: 180
    implicitHeight: 10

    anchors {
        bottom: true
    }

    margins {
        bottom: 52
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-control-indicator"

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

    opacity: root.displaying ? 1 : 0
    transform: Scale {
        origin.x: root.width / 2
        origin.y: root.height / 2
        xScale: root.displaying ? 1 : 0.92
        yScale: root.displaying ? 1 : 0.92
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 105
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: hideTimer
        interval: 850
        repeat: false

        onTriggered: root.displaying = false
    }

    function showLevel(value: real) {
        root.level = Math.max(0, Math.min(1, value))
        root.displaying = true
        hideTimer.restart()
    }
}
