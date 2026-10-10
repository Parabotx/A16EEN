import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    required property var modelData
    required property string navbarPosition
    required property bool dockVisible
    required property bool enabled
    required property var snapshot
    signal openRequested()

    readonly property bool horizontalNavbar: root.navbarPosition === "top" || root.navbarPosition === "bottom"

    function formatRate(value) {
        const rate = Math.max(0, Number(value) || 0)
        if (rate < 1024) return Math.round(rate) + " B/s"
        if (rate < 1024 * 1024) return (rate / 1024).toFixed(rate < 10240 ? 1 : 0) + " KB/s"
        return (rate / (1024 * 1024)).toFixed(1) + " MB/s"
    }

    screen: root.modelData
    visible: root.enabled && root.dockVisible && root.modelData !== null
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    width: 150
    height: 28

    anchors {
        left: root.horizontalNavbar || root.navbarPosition === "left"
        right: !root.horizontalNavbar && root.navbarPosition === "right"
        top: root.navbarPosition === "top"
        bottom: root.navbarPosition === "bottom" || !root.horizontalNavbar
    }
    margins {
        // Offset inward from the power button; this is a separate capsule,
        // not another item inside the notifications/tools tray.
        left: root.horizontalNavbar ? 34 : (root.navbarPosition === "left" ? 50 : 0)
        right: !root.horizontalNavbar && root.navbarPosition === "right" ? 50 : 0
        top: 0
        bottom: !root.horizontalNavbar && root.navbarPosition !== "bottom" ? 12 : 0
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-data-meter-indicator"

    Rectangle {
        anchors.fill: parent
        radius: 11
        color: speedMouse.containsMouse ? "#F4F6F8" : "#FFFFFF"
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
            anchors.fill: parent
            anchors.leftMargin: 9
            anchors.rightMargin: 7
            spacing: 5
            Image {
                anchors.verticalCenter: parent.verticalCenter
                width: 15
                height: 15
                source: Qt.resolvedUrl("../assets/icons/lucide-activity.svg")
                sourceSize.width: 48
                sourceSize.height: 48
                smooth: true
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Row {
                    spacing: 7
                    Text {
                        text: "↓ " + root.formatRate(root.snapshot ? root.snapshot.down_bps : 0)
                        color: "#252B34"
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: "↑ " + root.formatRate(root.snapshot ? root.snapshot.up_bps : 0)
                        color: "#65707D"
                        font.pixelSize: 8
                    }
                }
                Text {
                    text: root.snapshot && root.snapshot.active_interface ? String(root.snapshot.active_interface) : "Data Meter"
                    color: "#929BA6"
                    font.pixelSize: 7
                    elide: Text.ElideRight
                }
            }
        }
        MouseArea {
            id: speedMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openRequested()
        }
    }
}
