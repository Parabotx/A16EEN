import QtQuick
import Quickshell
import Quickshell.Wayland
import "WidgetCatalog.js" as WidgetCatalog

PanelWindow {
    id: root

    property bool opened: false
    property bool timeEnabled: true
    property bool pulseEnabled: false
    property bool workspaceEnabled: false
    property bool timeUse24Hour: true
    property bool timeShowSeconds: false

    signal closeRequested()
    signal widgetEnabledRequested(string widgetId, bool enabled)
    signal timeUse24HourRequested(bool enabled)
    signal timeShowSecondsRequested(bool enabled)

    readonly property int activeCount:
        (root.timeEnabled ? 1 : 0)
        + (root.pulseEnabled ? 1 : 0)
        + (root.workspaceEnabled ? 1 : 0)

    function widgetEnabled(id) {
        if (id === "time") return root.timeEnabled
        if (id === "pulse") return root.pulseEnabled
        if (id === "workspaces") return root.workspaceEnabled
        return false
    }

    function requestToggle(id) {
        root.widgetEnabledRequested(id, !root.widgetEnabled(id))
    }

    readonly property var targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    screen: root.targetScreen
    visible: root.opened && root.targetScreen !== null
    color: "transparent"
    focusable: root.opened

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-widget-manager"
    WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.opened ? 0.44 : 0
    }

    Rectangle {
        width: Math.min(820, parent.width - 64)
        height: Math.min(590, parent.height - 64)
        anchors.centerIn: parent
        radius: 24
        color: "#050505"
        border.width: 1
        border.color: "#222222"
        clip: true

        Column {
            anchors.fill: parent
            anchors.margins: 26
            spacing: 14

            Rectangle {
                width: parent.width
                height: 68
                radius: 16
                color: "#090909"
                border.width: 1
                border.color: "#191919"

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
                            color: "#505050"
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.2
                        }
                    }

                    Item { width: parent.width - 375; height: 1 }

                    Rectangle {
                        width: 175
                        height: 42
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 12
                        color: "#101010"
                        border.width: 1
                        border.color: "#242424"

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                width: 145
                                horizontalAlignment: Text.AlignHCenter
                                text: "ACTIVE"
                                color: "#4D4D4D"
                                font.pixelSize: 6
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.1
                            }

                            Text {
                                width: 145
                                horizontalAlignment: Text.AlignHCenter
                                text: root.activeCount + " / " + WidgetCatalog.definitions.length
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
                height: 408
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
                        anchors.margins: 18
                        spacing: 9

                        Text {
                            text: "WIDGET REGISTRY"
                            color: "#B5B5B5"
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.4
                        }

                        Text {
                            text: "Modules are independent and can be added without changing the shell layout."
                            color: "#414141"
                            font.pixelSize: 7
                            wrapMode: Text.WordWrap
                        }

                        Repeater {
                            model: WidgetCatalog.definitions

                            delegate: Rectangle {
                                required property var modelData
                                width: 314
                                height: 92
                                radius: 15
                                color: root.widgetEnabled(modelData.id) ? "#111111" : "#090909"
                                border.width: 1
                                border.color: root.widgetEnabled(modelData.id) ? "#303030" : "#151515"

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 13
                                    anchors.rightMargin: 12
                                    spacing: 11

                                    Rectangle {
                                        width: 40
                                        height: 40
                                        anchors.verticalCenter: parent.verticalCenter
                                        radius: 12
                                        color: root.widgetEnabled(modelData.id) ? "#202020" : "#0E0E0E"

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.id === "time" ? "T" : modelData.id === "pulse" ? "P" : "W"
                                            color: root.widgetEnabled(modelData.id) ? "#D7B56D" : "#5B5B5B"
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    Column {
                                        width: 175
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4

                                        Text {
                                            text: modelData.title
                                            color: "#FFFFFF"
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                            font.letterSpacing: 0.5
                                        }

                                        Text {
                                            text: modelData.subtitle
                                            color: "#707070"
                                            font.pixelSize: 7
                                        }

                                        Text {
                                            width: parent.width
                                            text: modelData.detail
                                            color: "#434343"
                                            font.pixelSize: 6
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Rectangle {
                                        width: 52
                                        height: 28
                                        anchors.verticalCenter: parent.verticalCenter
                                        radius: 14
                                        color: root.widgetEnabled(modelData.id) ? "#D7B56D" : "#151515"
                                        border.width: 1
                                        border.color: root.widgetEnabled(modelData.id) ? "#D7B56D" : "#292929"

                                        Rectangle {
                                            width: 20
                                            height: 20
                                            y: 3
                                            x: root.widgetEnabled(modelData.id) ? 29 : 3
                                            radius: 10
                                            color: root.widgetEnabled(modelData.id) ? "#050505" : "#6A6A6A"

                                            Behavior on x {
                                                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.requestToggle(modelData.id)
                                        }
                                    }
                                }
                            }
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
                        spacing: 14

                        Text {
                            text: "TIME & DATE"
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.1
                        }

                        Text {
                            text: "Control the desktop clock without touching the widget itself."
                            color: "#505050"
                            font.pixelSize: 7
                        }

                        Rectangle {
                            width: parent.width
                            height: 108
                            radius: 16
                            color: "#0A0A0A"
                            border.width: 1
                            border.color: "#191919"

                            Column {
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    width: 300
                                    horizontalAlignment: Text.AlignHCenter
                                    text: root.timeUse24Hour ? "14:30" : "02:30 PM"
                                    color: "#FFFFFF"
                                    font.pixelSize: 29
                                    font.weight: Font.Light
                                }

                                Text {
                                    width: 300
                                    horizontalAlignment: Text.AlignHCenter
                                    text: root.timeShowSeconds ? "SECONDS ENABLED" : "MINUTES ONLY"
                                    color: "#D7B56D"
                                    font.pixelSize: 7
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 1
                                }
                            }
                        }

                        Text {
                            text: "TIME FORMAT"
                            color: "#777777"
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1
                        }

                        Row {
                            width: parent.width
                            height: 44
                            spacing: 8

                            Rectangle {
                                width: (parent.width - 8) / 2
                                height: 44
                                radius: 12
                                color: root.timeUse24Hour ? "#181818" : "#0B0B0B"
                                border.width: 1
                                border.color: root.timeUse24Hour ? "#363636" : "#181818"

                                Text {
                                    anchors.centerIn: parent
                                    text: "24 HOUR"
                                    color: root.timeUse24Hour ? "#D7B56D" : "#6A6A6A"
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.timeUse24HourRequested(true)
                                }
                            }

                            Rectangle {
                                width: (parent.width - 8) / 2
                                height: 44
                                radius: 12
                                color: !root.timeUse24Hour ? "#181818" : "#0B0B0B"
                                border.width: 1
                                border.color: !root.timeUse24Hour ? "#363636" : "#181818"

                                Text {
                                    anchors.centerIn: parent
                                    text: "12 HOUR"
                                    color: !root.timeUse24Hour ? "#D7B56D" : "#6A6A6A"
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.timeUse24HourRequested(false)
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            height: 56

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3

                                Text {
                                    text: "SHOW SECONDS"
                                    color: "#A0A0A0"
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.8
                                }

                                Text {
                                    text: "Adds seconds to the desktop clock"
                                    color: "#454545"
                                    font.pixelSize: 7
                                }
                            }

                            Item { width: parent.width - 110; height: 1 }

                            Rectangle {
                                width: 50
                                height: 28
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 14
                                color: root.timeShowSeconds ? "#D7B56D" : "#151515"
                                border.width: 1
                                border.color: root.timeShowSeconds ? "#D7B56D" : "#292929"

                                Rectangle {
                                    width: 20
                                    height: 20
                                    y: 3
                                    x: root.timeShowSeconds ? 27 : 3
                                    radius: 10
                                    color: root.timeShowSeconds ? "#050505" : "#6A6A6A"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.timeShowSecondsRequested(!root.timeShowSeconds)
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#161616"
                        }

                        Text {
                            width: parent.width
                            text: "TIME, DAY AND DATE ARE CALCULATED FROM YOUR LOCAL SYSTEM CLOCK."
                            color: "#3D3D3D"
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            Row {
                width: parent.width
                height: 38
                spacing: 10

                Rectangle {
                    width: 40
                    height: 38
                    radius: 11
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
                        font.letterSpacing: 1
                    }

                    Text {
                        text: "Return to / commands"
                        color: "#3F3F3F"
                        font.pixelSize: 8
                    }
                }

                Item { width: parent.width - 250; height: 1 }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.activeCount + " ACTIVE"
                    color: "#3F3F3F"
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                }
            }
        }
    }

    Keys.onEscapePressed: root.closeRequested()
}
