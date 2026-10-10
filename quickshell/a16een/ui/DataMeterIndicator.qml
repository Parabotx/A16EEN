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
    width: Math.max(70, Math.min(102, speedContent.implicitWidth + 20))
    height: root.horizontalNavbar ? 30 : 34

    // On a vertical dock, match the power button's top position. The capsule
    // sits one gap inward from it rather than following the battery at the bottom.
    anchors {
        left: root.horizontalNavbar || root.navbarPosition === "left"
        right: !root.horizontalNavbar && root.navbarPosition === "right"
        top: root.navbarPosition !== "bottom"
        bottom: root.navbarPosition === "bottom"
    }
    margins {
        // Keep left/right rails exactly where they were. On horizontal rails,
        // stack the speed pill below the power button at the top or above it at the bottom.
        left: root.horizontalNavbar ? 0 : (root.navbarPosition === "left" ? 50 : 0)
        right: !root.horizontalNavbar && root.navbarPosition === "right" ? 50 : 0
        top: root.horizontalNavbar
            ? (root.navbarPosition === "top" ? 34 : 0)
            : 12
        bottom: root.horizontalNavbar && root.navbarPosition === "bottom" ? 34 : 0
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
            id: speedContent
            anchors.centerIn: parent
            spacing: 5

            Rectangle {
                id: directionBadge
                width: 22
                height: 22
                radius: 7
                anchors.verticalCenter: parent.verticalCenter
                color: root.showingDownload ? "#E9EDF2" : "#F2F4F7"
                border.width: 1
                border.color: "#E3E7EC"

                Item {
                    id: directionGlyph
                    width: 18
                    height: 18
                    anchors.centerIn: parent
                    rotation: root.showingDownload ? 180 : 0
                    Behavior on rotation {
                        NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
                    }

                    // Fine motion trails sit behind a crisp, rounded arrow.
                    Rectangle {
                        x: 1
                        y: 7
                        width: 3
                        height: 1.5
                        radius: 1
                        color: "#A6B0BC"
                    }
                    Rectangle {
                        x: 2
                        y: 11
                        width: 2
                        height: 1.5
                        radius: 1
                        color: "#C0C7D0"
                    }
                    Rectangle {
                        x: 8
                        y: 5
                        width: 2
                        height: 9
                        radius: 1
                        color: "#252B34"
                    }
                    Rectangle {
                        x: 4
                        y: 3
                        width: 2
                        height: 6
                        radius: 1
                        rotation: -45
                        color: "#252B34"
                    }
                    Rectangle {
                        x: 10
                        y: 3
                        width: 2
                        height: 6
                        radius: 1
                        rotation: 45
                        color: "#252B34"
                    }
                }
            }

            Item {
                id: speedValueGroup
                width: speedNumber.implicitWidth + speedUnit.implicitWidth + 3
                height: 22

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
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    id: speedUnit
                    anchors.left: speedNumber.right
                    anchors.leftMargin: 2
                    y: 4
                    text: {
                        const reading = root.formatRate(root.snapshot
                            ? (root.showingDownload ? root.snapshot.down_bps : root.snapshot.up_bps)
                            : 0)
                        return reading.unit
                    }
                    color: "#7D8793"
                    font.pixelSize: 7
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
