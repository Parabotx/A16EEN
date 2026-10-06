import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool opened: false
    property bool timeWidgetEnabled: true
    property bool pulseWidgetEnabled: false
    property bool workspaceWidgetEnabled: false
    property bool timeUse24Hour: true
    property bool timeShowSeconds: false
    property real systemLoad: 0
    property int volumePercent: 0
    property bool volumeMuted: false
    property var workspaces: []
    property int focusedWorkspaceId: -1

    signal closeRequested()
    signal timeWidgetEnabledRequested(bool enabled)
    signal pulseWidgetEnabledRequested(bool enabled)
    signal workspaceWidgetEnabledRequested(bool enabled)
    signal timeUse24HourRequested(bool enabled)
    signal timeShowSecondsRequested(bool enabled)

    readonly property var widgetDefinitions: [
        {
            id: "time",
            title: "TIME & DATE",
            subtitle: "Desktop clock and calendar",
            detail: "Large local time, day, and date",
            enabled: root.timeWidgetEnabled,
            available: true
        },
        {
            id: "pulse",
            title: "SYSTEM PULSE",
            subtitle: "Lightweight system telemetry",
            detail: "Load and audio at a glance",
            enabled: root.pulseWidgetEnabled,
            available: true
        },
        {
            id: "workspaces",
            title: "WORKSPACE MATRIX",
            subtitle: "Workspace awareness",
            detail: "Current workspace and workspace map",
            enabled: root.workspaceWidgetEnabled,
            available: true
        }
    ]

    screen: modelData
    color: "transparent"
    visible: root.opened
    focusable: root.opened

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-widgets-center"
    WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.opened ? 0.38 : 0
    }

    Rectangle {
        width: Math.min(900, parent.width - 70)
        height: Math.min(620, parent.height - 70)
        anchors.centerIn: parent
        radius: 26
        color: "#050505"
        border.width: 1
        border.color: "#222222"
        clip: true

        Column {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 16

            Rectangle {
                width: parent.width
                height: 70
                radius: 17
                color: "#0A0A0A"
                border.width: 1
                border.color: "#181818"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            text: "WIDGETS"
                            color: "#FFFFFF"
                            font.pixelSize: 17
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.7
                        }

                        Text {
                            text: "A16EEN DESKTOP MODULES"
                            color: "#4D4D4D"
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.2
                        }
                    }

                    Item {
                        width: parent.width - 390
                        height: 1
                    }

                    Rectangle {
                        width: 190
                        height: 44
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 13
                        color: "#101010"
                        border.width: 1
                        border.color: "#262626"

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                width: 160
                                horizontalAlignment: Text.AlignHCenter
                                text: "ACTIVE WIDGETS"
                                color: "#4D4D4D"
                                font.pixelSize: 7
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1
                            }

                            Text {
                                width: 160
                                horizontalAlignment: Text.AlignHCenter
                                text: root.activeWidgetCount + " / " + root.widgetDefinitions.length
                                color: "#D7B56D"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }
            }

            Row {
                width: parent.width
                height: 390
                spacing: 14

                Rectangle {
                    width: 350
                    height: parent.height
                    radius: 18
                    color: "#080808"
                    border.width: 1
                    border.color: "#171717"

                    Column {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 13

                        Row {
                            width: parent.width
                            height: 20

                            Text {
                                text: "WIDGET REGISTRY"
                                color: "#B0B0B0"
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.3
                            }

                            Item {
                                width: parent.width - 130
                                height: 1
                            }

                            Text {
                                width: 130
                                horizontalAlignment: Text.AlignRight
                                text: "FOUNDATION"
                                color: "#353535"
                                font.pixelSize: 6
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1
                            }
                        }

                        Repeater {
                            model: root.widgetDefinitions

                            delegate: WidgetRow {
                                title: modelData.title
                                subtitle: modelData.subtitle
                                detail: modelData.detail
                                enabled: modelData.enabled
                                available: modelData.available
                                widgetId: modelData.id
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#161616"
                        }

                        Text {
                            width: parent.width
                            text: "New widgets can be registered here without changing the manager layout."
                            color: "#3F3F3F"
                            font.pixelSize: 7
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Rectangle {
                    width: parent.width - 364
                    height: parent.height
                    radius: 18
                    color: "#080808"
                    border.width: 1
                    border.color: "#171717"

                    Column {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 15

                        Row {
                            width: parent.width
                            height: 26

                            Column {
                                spacing: 3

                                Text {
                                    text: "TIME & DATE"
                                    color: "#FFFFFF"
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 1.1
                                }

                                Text {
                                    text: "Display controls"
                                    color: "#505050"
                                    font.pixelSize: 7
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 96
                            radius: 16
                            color: "#0A0A0A"
                            border.width: 1
                            border.color: "#181818"

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 18
                                anchors.rightMargin: 18

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 5

                                    Text {
                                        text: root.timeUse24Hour ? "24:00" : "12:00 PM"
                                        color: "#FFFFFF"
                                        font.pixelSize: 24
                                        font.weight: Font.Light
                                    }

                                    Text {
                                        text: root.timeShowSeconds ? "Seconds visible" : "Minutes only"
                                        color: "#555555"
                                        font.pixelSize: 7
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 0.8
                                    }
                                }

                                Item {
                                    width: parent.width - 190
                                    height: 1
                                }

                                Rectangle {
                                    width: 42
                                    height: 42
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: 12
                                    color: "#111111"
                                    border.width: 1
                                    border.color: "#242424"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "T"
                                        color: "#D7B56D"
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }
                        }

                        Text {
                            text: "TIME FORMAT"
                            color: "#777777"
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.0
                        }

                        Row {
                            width: parent.width
                            height: 46
                            spacing: 8

                            FormatButton {
                                label: "24 HOUR"
                                active: root.timeUse24Hour
                                onClicked: root.timeUse24HourRequested(true)
                            }

                            FormatButton {
                                label: "12 HOUR"
                                active: !root.timeUse24Hour
                                onClicked: root.timeUse24HourRequested(false)
                            }
                        }

                        Row {
                            width: parent.width
                            height: 54

                            Column {
                                spacing: 3

                                Text {
                                    text: "SHOW SECONDS"
                                    color: "#A0A0A0"
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.9
                                }

                                Text {
                                    text: "Add seconds to the desktop clock"
                                    color: "#454545"
                                    font.pixelSize: 7
                                }
                            }

                            Item {
                                width: parent.width - 104
                                height: 1
                            }

                            Toggle {
                                checked: root.timeShowSeconds
                                onClicked: root.timeShowSecondsRequested(!root.timeShowSeconds)
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#161616"
                        }

                        Row {
                            width: parent.width
                            height: 70
                            spacing: 10

                            InfoTile {
                                label: "TIME"
                                value: "LOCAL SYSTEM CLOCK"
                            }

                            InfoTile {
                                label: "DAY"
                                value: "AUTOMATIC"
                            }

                            InfoTile {
                                label: "DATE"
                                value: "AUTOMATIC"
                            }
                        }
                    }
                }
            }

            Row {
                width: parent.width
                height: 40
                spacing: 10

                Rectangle {
                    width: 40
                    height: 40
                    radius: 12
                    color: "#0A0A0A"
                    border.width: 1
                    border.color: "#1D1D1D"

                    Text {
                        anchors.centerIn: parent
                        text: "←"
                        color: "#9A9A9A"
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: "COMMAND SEARCH"
                        color: "#666666"
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.0
                    }

                    Text {
                        text: "Return to / commands"
                        color: "#3F3F3F"
                        font.pixelSize: 8
                    }
                }

                Item {
                    width: parent.width - 300
                    height: 1
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "WIDGET FOUNDATION"
                    color: "#2F2F2F"
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.0
                }
            }
        }
    }

    readonly property int activeWidgetCount: {
        let count = 0
        for (const widget of root.widgetDefinitions) {
            if (widget.enabled)
                count++
        }
        return count
    }

    component WidgetRow: Rectangle {
        required property string title
        required property string subtitle
        required property string detail
        required property bool enabled
        required property bool available
        required property string widgetId

        width: parent.width
        height: 82
        radius: 15
        color: enabled ? "#111111" : "#090909"
        border.width: 1
        border.color: enabled ? "#303030" : "#151515"

        Row {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 12
            spacing: 10

            Rectangle {
                width: 38
                height: 38
                anchors.verticalCenter: parent.verticalCenter
                radius: 11
                color: enabled ? "#202020" : "#0E0E0E"
                border.width: 1
                border.color: enabled ? "#343434" : "#191919"

                Text {
                    anchors.centerIn: parent
                    text: parent.parent.parent.widgetId === "time"
                        ? "T"
                        : parent.parent.parent.widgetId === "pulse"
                            ? "P"
                            : "W"
                    color: enabled ? "#D7B56D" : "#5E5E5E"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }

            Column {
                width: parent.width - 132
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    text: parent.parent.parent.title
                    color: "#FFFFFF"
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.6
                }

                Text {
                    text: parent.parent.parent.subtitle
                    color: "#6B6B6B"
                    font.pixelSize: 7
                }

                Text {
                    text: parent.parent.parent.detail
                    color: "#3F3F3F"
                    font.pixelSize: 6
                    elide: Text.ElideRight
                }
            }

            Toggle {
                anchors.verticalCenter: parent.verticalCenter
                checked: parent.parent.enabled
                onClicked: {
                    if (widgetId === "time")
                        root.timeWidgetEnabledRequested(!root.timeWidgetEnabled)
                    else if (widgetId === "pulse")
                        root.pulseWidgetEnabledRequested(!root.pulseWidgetEnabled)
                    else if (widgetId === "workspaces")
                        root.workspaceWidgetEnabledRequested(!root.workspaceWidgetEnabled)
                }
            }
        }
    }

    component FormatButton: Rectangle {
        required property string label
        required property bool active
        signal clicked()

        width: (parent.width - 8) / 2
        height: 46
        radius: 12
        color: active ? "#181818" : "#0B0B0B"
        border.width: 1
        border.color: active ? "#343434" : "#181818"

        Text {
            anchors.centerIn: parent
            text: parent.parent.label
            color: active ? "#D7B56D" : "#707070"
            font.pixelSize: 8
            font.weight: Font.DemiBold
            font.letterSpacing: 0.9
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component Toggle: Rectangle {
        property bool checked: false
        signal clicked()

        width: 48
        height: 26
        radius: 13
        color: checked ? "#D7B56D" : "#161616"
        border.width: 1
        border.color: checked ? "#D7B56D" : "#2A2A2A"

        Rectangle {
            width: 20
            height: 20
            anchors.verticalCenter: parent.verticalCenter
            x: parent.checked ? parent.width - width - 3 : 3
            radius: 10
            color: checked ? "#050505" : "#6A6A6A"

            Behavior on x {
                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    Keys.onEscapePressed: root.closeRequested()
}
