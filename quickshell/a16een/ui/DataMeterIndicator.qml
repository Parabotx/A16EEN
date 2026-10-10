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
    property bool showingDownload: false

    // Kept as a shell entry point; opening the Data Meter is available from Tools.
    signal openRequested()

    readonly property bool horizontalNavbar: root.navbarPosition === "top" || root.navbarPosition === "bottom"

    function formatRate(value) {
        const rate = Math.max(0, Number(value) || 0)
        if (rate < 1024)
            return { value: String(Math.round(rate)), unit: "B" }
        if (rate < 1024 * 1024)
            return { value: (rate / 1024).toFixed(rate < 10240 ? 1 : 0), unit: "K" }
        if (rate < 1024 * 1024 * 1024)
            return { value: (rate / (1024 * 1024)).toFixed(1), unit: "M" }
        return { value: (rate / (1024 * 1024 * 1024)).toFixed(1), unit: "G" }
    }

    screen: root.modelData
    visible: root.enabled && root.dockVisible && root.modelData !== null
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    width: root.horizontalNavbar ? 112 : 112
    height: root.horizontalNavbar ? 30 : 36

    // On a vertical dock, match the power button's top position. The capsule
    // sits one gap inward from it rather than following the battery at the bottom.
    anchors {
        left: root.horizontalNavbar || root.navbarPosition === "left"
        right: !root.horizontalNavbar && root.navbarPosition === "right"
        top: root.navbarPosition !== "bottom"
        bottom: root.navbarPosition === "bottom"
    }
    margins {
        left: root.horizontalNavbar ? 34 : (root.navbarPosition === "left" ? 50 : 0)
        right: !root.horizontalNavbar && root.navbarPosition === "right" ? 50 : 0
        top: root.horizontalNavbar ? 0 : 12
        bottom: 0
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-data-meter-indicator"

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: speedMouse.containsMouse ? "#F2F4F7" : "#FFFFFF"
        border.width: 1
        border.color: "#D9DEE5"

        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: 15
            color: "#10000000"
            z: -1
        }

        Row {
            anchors.centerIn: parent
            spacing: 7

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.showingDownload ? "↓" : "↑"
                color: root.showingDownload ? "#252B34" : "#687381"
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }

            Item {
                id: speedValueGroup
                width: speedNumber.implicitWidth + speedUnit.implicitWidth + 4
                height: 24

                Text {
                    id: speedNumber
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        const reading = root.formatRate(root.snapshot
                            ? (root.showingDownload ? root.snapshot.down_bps : root.snapshot.up_bps)
                            : 0)
                        return reading.value
                    }
                    color: "#171B21"
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }

                Text {
                    id: speedUnit
                    anchors.left: speedNumber.right
                    anchors.leftMargin: 3
                    y: 3
                    text: {
                        const reading = root.formatRate(root.snapshot
                            ? (root.showingDownload ? root.snapshot.down_bps : root.snapshot.up_bps)
                            : 0)
                        return reading.unit
                    }
                    color: "#7D8793"
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                }
            }
        }

        MouseArea {
            id: speedMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.showingDownload = !root.showingDownload
        }
    }
}
