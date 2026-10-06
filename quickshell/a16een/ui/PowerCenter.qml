import QtQuick
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool opened: false

    signal closeRequested()

    screen: modelData
    color: "#000000"
    visible: root.opened
    focusable: root.opened

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-power-center"
    WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    Rectangle {
        width: Math.min(880, parent.width - 80)
        height: Math.min(500, parent.height - 100)
        anchors.centerIn: parent
        radius: 24
        color: "#050505"
        border.width: 1
        border.color: "#1A1A1A"

        Column {
            anchors.fill: parent
            anchors.margins: 34
            spacing: 24

            Row {
                width: parent.width
                height: 48

                Column {
                    spacing: 3

                    Text {
                        text: "POWER MODE"
                        color: "#FFFFFF"
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        font.letterSpacing: 2.2
                    }

                    Text {
                        text: "SYSTEM PERFORMANCE & BATTERY"
                        color: "#505050"
                        font.pixelSize: 8
                        font.letterSpacing: 1.4
                    }
                }

                Item { width: parent.width - 210; height: 1 }

                Column {
                    width: 160
                    spacing: 3

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        text: PowerProfile.toString(PowerProfiles.profile)
                        color: "#D7B56D"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        text: UPower.onBattery
                            ? (UPower.displayDevice.ready && UPower.displayDevice.isLaptopBattery
                                ? Math.round(UPower.displayDevice.percentage) + "% BATTERY"
                                : "BATTERY POWER")
                            : "AC POWER"
                        color: "#5A5A5A"
                        font.pixelSize: 8
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#151515"
            }

            Row {
                width: parent.width
                height: 250
                spacing: 12

                ProfileCard {
                    title: "PERFORMANCE"
                    subtitle: "Maximum responsiveness"
                    detail: "Full animation"
                    profile: PowerProfile.Performance
                    available: PowerProfiles.hasPerformanceProfile
                }

                ProfileCard {
                    title: "BALANCED"
                    subtitle: "Everyday efficiency"
                    detail: "Adaptive animation"
                    profile: PowerProfile.Balanced
                    available: true
                }

                ProfileCard {
                    title: "ECO"
                    subtitle: "Maximum power saving"
                    detail: "Animations paused"
                    profile: PowerProfile.PowerSaver
                    available: true
                }
            }

            Row {
                width: parent.width
                height: 36

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "ESC"
                    color: "#3F3F3F"
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.2
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 34
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Return to command center"
                    color: "#444444"
                    font.pixelSize: 9
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.closeRequested()
    }

    Keys.onEscapePressed: root.closeRequested()

    component ProfileCard: Rectangle {
        required property string title
        required property string subtitle
        required property string detail
        required property int profile
        required property bool available

        width: (parent.width - 24) / 3
        height: 250
        radius: 18
        color: PowerProfiles.profile === profile ? "#111111" : "#080808"
        border.width: PowerProfiles.profile === profile ? 1 : 0
        border.color: "#303030"
        opacity: available ? 1 : 0.35

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            Rectangle {
                width: 42
                height: 42
                radius: 12
                color: PowerProfiles.profile === profile ? "#222222" : "#101010"

                Text {
                    anchors.centerIn: parent
                    text: title.charAt(0)
                    color: "#FFFFFF"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }

            Text {
                text: parent.parent.title
                color: "#FFFFFF"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                font.letterSpacing: 0.9
            }

            Text {
                width: parent.width
                text: parent.parent.subtitle
                color: "#666666"
                font.pixelSize: 9
                wrapMode: Text.WordWrap
            }

            Text {
                width: parent.width
                text: parent.parent.detail
                color: "#3F3F3F"
                font.pixelSize: 8
                wrapMode: Text.WordWrap
            }

            Item { height: 1; width: 1 }

            Text {
                text: PowerProfiles.profile === profile ? "ACTIVE" : "SELECT"
                color: PowerProfiles.profile === profile ? "#D7B56D" : "#555555"
                font.pixelSize: 8
                font.weight: Font.DemiBold
                font.letterSpacing: 1.2
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: parent.available
            cursorShape: Qt.PointingHandCursor
            onClicked: PowerProfiles.profile = parent.profile
        }
    }
}
