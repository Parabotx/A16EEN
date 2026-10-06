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
        width: 264
        height: 164
        x: 22
        y: parent.height - height - 22
        radius: 16
        color: "#FFFFFF"
        border.width: 1
        border.color: "#DDE4EA"

        Image {
            id: previewImage
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 7
            anchors.rightMargin: 7
            anchors.topMargin: 7
            height: 122
            source: root.imagePath
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: false
        }

        Text {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 11
            anchors.bottomMargin: 9
            text: "A16EEN"
            color: "#15171A"
            font.pixelSize: 7
            font.weight: Font.DemiBold
            font.letterSpacing: 1.0
        }

        Text {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 11
            anchors.bottomMargin: 9
            text: "SCREENSHOT"
            color: "#8A949F"
            font.pixelSize: 6
            font.weight: Font.DemiBold
            font.letterSpacing: 0.8
        }

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: previewMouse.containsMouse ? "#14000000" : "transparent"

            IconImage {
                anchors.centerIn: parent
                implicitWidth: 24
                implicitHeight: 24
                source: Quickshell.iconPath("image-x-generic", "image-x-generic")
                visible: previewMouse.containsMouse
            }

            MouseArea {
                id: previewMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton
                onClicked: {
                    hideTimer.stop()
                    Quickshell.execDetached(["xdg-open", root.imagePath])
                    root.closeRequested()
                }
            }
        }
    }

    onOpenedChanged: {
        if (root.opened)
            hideTimer.restart()
    }
}
