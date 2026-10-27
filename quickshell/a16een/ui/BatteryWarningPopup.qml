import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool opened: false
    property int percent: 0
    property string severity: "warning"

    signal closeRequested()

    screen: modelData
    visible: opened && !!modelData
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    width: modelData ? modelData.width : 1
    height: modelData ? modelData.height : 1

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-battery-warning"

    readonly property color accentColor: severity === "emergency"
        ? "#FF4D5E"
        : (severity === "critical" ? "#FF9B42" : "#E8C66A")
    readonly property string heading: severity === "emergency"
        ? "CRITICAL BATTERY"
        : (severity === "critical" ? "BATTERY VERY LOW" : "BATTERY LOW")
    readonly property string detail: severity === "emergency"
        ? "Your laptop may power off at any moment. Connect the charger immediately."
        : (severity === "critical"
            ? "Only a little power remains. Connect your charger now and save your work."
            : "Your battery is running low. Connect your charger soon to avoid losing work.")

    Rectangle {
        anchors.fill: parent
        color: "#B90A0D14"

        // The backdrop deliberately does not dismiss the warning: accidental
        // clicks must not make a safety alert disappear.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: mouse => mouse.accepted = true
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: Math.max(280, Math.min(parent.width - 36, 520))
            height: 348
            radius: 26
            color: "#F0141924"
            border.width: 1
            border.color: root.accentColor
            antialiasing: true

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 4
                radius: 2
                color: root.accentColor
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 13

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 76
                    Layout.preferredHeight: 76
                    radius: 24
                    color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12)
                    border.width: 1
                    border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.53)

                    Text {
                        anchors.centerIn: parent
                        text: "!"
                        color: root.accentColor
                        font.pixelSize: 48
                        font.weight: Font.Black
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.heading
                    color: root.accentColor
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    font.letterSpacing: 2
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    Layout.fillWidth: true
                    text: root.percent + "%"
                    color: "#F5F7FC"
                    font.pixelSize: 54
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 5
                    radius: 3
                    color: "#29303C"

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(100, root.percent)) / 100
                        height: parent.height
                        radius: 3
                        color: root.accentColor
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.detail
                    color: "#D2D8E3"
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.25
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    radius: 14
                    color: root.accentColor

                    Text {
                        anchors.centerIn: parent
                        text: "I UNDERSTAND"
                        color: "#171A21"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        font.letterSpacing: 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "This warning will become more urgent if your battery drops further."
                    color: "#8F99AA"
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    onSeverityChanged: {
        if (!opened)
            return
        // Play a standard desktop warning sound when a sound-theme player is
        // installed. The visual alert remains fully functional without it.
        Quickshell.execDetached([
            "sh", "-c",
            "if command -v canberra-gtk-play >/dev/null 2>&1; then canberra-gtk-play -i dialog-warning >/dev/null 2>&1; fi"
        ])
    }

    onOpenedChanged: {
        if (opened) {
            Quickshell.execDetached([
                "sh", "-c",
                "if command -v canberra-gtk-play >/dev/null 2>&1; then canberra-gtk-play -i dialog-warning >/dev/null 2>&1; fi"
            ])
        }
    }
}
