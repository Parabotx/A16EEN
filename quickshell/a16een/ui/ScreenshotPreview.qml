import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool opened: false
    property string imagePath: ""

    signal closeRequested()

    screen: modelData
    color: "transparent"
    visible: root.opened
    focusable: false
    aboveWindows: true
    exclusiveZone: 0

    anchors {
        left: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-screenshot-preview"

    Timer {
        id: hideTimer
        interval: 2000
        repeat: false
        running: root.opened
        onTriggered: root.closeRequested()
    }

    Rectangle {
        id: card
        width: 236
        height: 142
        x: 22
        y: parent.height - height - 22
        radius: 16
        color: "#FFFFFF"
        border.width: 1
        border.color: "#DDE4EA"

        Image {
            id: previewImage
            anchors.fill: parent
            anchors.margins: 7
            source: root.imagePath
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: false
        }

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: previewMouse.containsMouse ? "#18000000" : "transparent"

            IconImage {
                anchors.centerIn: parent
                implicitWidth: 22
                implicitHeight: 22
                source: Quickshell.iconPath("image-x-generic", "image-x-generic")
                visible: previewMouse.containsMouse
            }

            MouseArea {
                id: previewMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Quickshell.execDetached(["xdg-open", root.imagePath])
                    root.closeRequested()
                }
            }
        }
    }
}
