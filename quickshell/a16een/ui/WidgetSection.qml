import QtQuick
import "WidgetCatalog.js" as WidgetCatalog

Item {
    id: root

    property bool timeEnabled: true
    property bool pulseEnabled: false
    property bool workspaceEnabled: false
    property bool timeUse24Hour: true
    property bool timeShowSeconds: false

    signal backRequested()
    signal widgetEnabledRequested(string widgetId, bool enabled)
    signal timeUse24HourRequested(bool enabled)
    signal timeShowSecondsRequested(bool enabled)

    function widgetEnabled(id) {
        if (id === "time") return root.timeEnabled
        if (id === "pulse") return root.pulseEnabled
        if (id === "workspaces") return root.workspaceEnabled
        return false
    }

    readonly property int activeCount:
        (root.timeEnabled ? 1 : 0)
        + (root.pulseEnabled ? 1 : 0)
        + (root.workspaceEnabled ? 1 : 0)

    Rectangle {
        anchors.fill: parent
        radius: 22
        color: "#050505"
        border.width: 1
        border.color: "#222222"
        clip: true

        Column {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 12

            Rectangle {
                width: parent.width
                height: 58
                radius: 15
                color: "#090909"
                border.width: 1
                border.color: "#1A1A1A"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Text {
                            text: "WIDGETS"
                            color: "#FFFFFF"
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.5
                        }

                        Text {
                            text: "DESKTOP MODULES"
                            color: "#4F4F4F"
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.2
                        }
                    }

                    Item {
                        width: parent.width - 170
                        height: 1
                    }

                    Rectangle {
                        width: 135
                        height: 38
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 11
                        color: "#101010"
                        border.width: 1
                        border.color: "#252525"

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                width: 105
                                horizontalAlignment: Text.AlignHCenter
                                text: "ACTIVE"
                                color: "#4B4B4B"
                                font.pixelSize: 6
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1
                            }

                            Text {
                                width: 105
                                horizontalAlignment: Text.AlignHCenter
                                text: root.activeCount
                                color: "#D7B56D"
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }
            }

            Row {
                width: parent.width
                height: parent.height - 124
                spacing: 12

                Rectangle {
                    width: 290
                    height: parent.height
                    radius: 16
                    color: "#080808"
                    border.width: 1
                    border.color: "#181818"

                    Column {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 8

                        Text {
                            text: "REGISTRY"
                            color: "#AFAFAF"
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.2
                        }

                        Text {
                            width: parent.width
                            text: "Enable the modules you want on the desktop."
                            color: "#434343"
                            font.pixelSize: 7
                            wrapMode: Text.WordWrap
                        }

                        Repeater {
                            model: WidgetCatalog.definitions

                            delegate: Rectangle {
                                required property var modelData

                                width: parent.width
                                height: 82
                                radius: 14
                                color: root.widgetEnabled(modelData.id) ? "#111111" : "#090909"
                                border.width: 1
                                border.color: root.widgetEnabled(modelData.id) ? "#303030" : "#151515"

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 10
                                    spacing: 9

                                    Rectangle {
                                        width: 34
                                        height: 34
                                        anchors.verticalCenter: parent.verticalCenter
                                        radius: 10
                                        color: root.widgetEnabled(modelData.id) ? "#202020" : "#101010"

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.id === "time"
                                                ? "T"
                                                : modelData.id === "pulse"
                                                    ? "P"
                                                    : "W"
                                            color: root.widgetEnabled(modelData.id) ? "#D7B56D" : "#595959"
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    Column {
                                        width: parent.width - 120
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 3

                                        Text {
                                            text: modelData.title
                                            color: "#FFFFFF"
                                            font.pixelSize: 8
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: modelData.subtitle
                                            color: "#696969"
                                            font.pixelSize: 6
                                        }

                                        Text {
                                            width: parent.width
                                            text: modelData.detail
                                            color: "#404040"
                                            font.pixelSize: 6
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Rectangle {
                                        width: 42
                                        height: 24
                                        anchors.verticalCenter: parent.verticalCenter
                                        radius: 12
                                        color: root.widgetEnabled(modelData.id) ? "#D7B56D" : "#151515"

                                        Rectangle {
                                            width: 18
                                            height: 18
                                            y: 3
                                            x: root.widgetEnabled(modelData.id) ? 21 : 3
                                            radius: 9
                                            color: root.widgetEnabled(modelData.id) ? "#050505" : "#686868"

                                            Behavior on x {
                                                NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.widgetEnabledRequested(
                                                modelData.id,
                                                !root.widgetEnabled(modelData.id)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width - 302
                    height: parent.height
                    radius: 16
                    color: "#080808"
                    border.width: 1
                    border.color: "#181818"

                    Column {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 11

                        Row {
                            width: parent.width
                            height: 24

                            Column {
                                spacing: 2

                                Text {
                                    text: "TIME & DATE"
                                    color: "#FFFFFF"
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 1
                                }

                                Text {
                                    text: "Clock display preferences"
                                    color: "#4E4E4E"
                                    font.pixelSize: 7
                                }
                            }

                            Item { width: 1; height: 1 }
                        }

                        Rectangle {
                            width: parent.width
                            height: 95
                            radius: 14
                            color: "#0A0A0A"
                            border.width: 1
                            border.color: "#1A1A1A"

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    width: 280
                                    horizontalAlignment: Text.AlignHCenter
                                    text: root.timeUse24Hour ? "21:48" : "09:48 PM"
                                    color: "#FFFFFF"
                                    font.pixelSize: 27
                                    font.weight: Font.Light
                                }

                                Text {
                                    width: 280
                                    horizontalAlignment: Text.AlignHCenter
                                    text: root.timeShowSeconds ? "SECONDS" : "MINUTES"
                                    color: "#D7B56D"
                                    font.pixelSize: 6
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 1.2
                                }
                            }
                        }

                        Text {
                            text: "TIME FORMAT"
                            color: "#6F6F6F"
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1
                        }

                        Row {
                            width: parent.width
                            height: 42
                            spacing: 7

                            Rectangle {
                                width: (parent.width - 7) / 2
                                height: 42
                                radius: 11
                                color: root.timeUse24Hour ? "#181818" : "#0B0B0B"
                                border.width: 1
                                border.color: root.timeUse24Hour ? "#363636" : "#181818"

                                Text {
                                    anchors.centerIn: parent
                                    text: "24 HOUR"
                                    color: root.timeUse24Hour ? "#D7B56D" : "#686868"
                                    font.pixelSize: 7
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.timeUse24HourRequested(true)
                                }
                            }

                            Rectangle {
                                width: (parent.width - 7) / 2
                                height: 42
                                radius: 11
                                color: !root.timeUse24Hour ? "#181818" : "#0B0B0B"
                                border.width: 1
                                border.color: !root.timeUse24Hour ? "#363636" : "#181818"

                                Text {
                                    anchors.centerIn: parent
                                    text: "12 HOUR"
                                    color: !root.timeUse24Hour ? "#D7B56D" : "#686868"
                                    font.pixelSize: 7
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.timeUse24HourRequested(false)
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 53
                            radius: 12
                            color: "#0A0A0A"
                            border.width: 1
                            border.color: "#181818"

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 13
                                anchors.rightMargin: 13

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 3

                                    Text {
                                        text: "SHOW SECONDS"
                                        color: "#A6A6A6"
                                        font.pixelSize: 7
                                        font.weight: Font.DemiBold
                                        letterSpacing: 0.6
                                    }

                                    Text {
                                        text: "Add seconds to the widget clock"
                                        color: "#414141"
                                        font.pixelSize: 6
                                    }
                                }

                                Item { width: parent.width - 118; height: 1 }

                                Rectangle {
                                    width: 46
                                    height: 24
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: 12
                                    color: root.timeShowSeconds ? "#D7B56D" : "#151515"

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        y: 3
                                        x: root.timeShowSeconds ? 25 : 3
                                        radius: 9
                                        color: root.timeShowSeconds ? "#050505" : "#686868"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.timeShowSecondsRequested(!root.timeShowSeconds)
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#171717"
                        }

                        Text {
                            width: parent.width
                            text: "TIME, DAY AND DATE FOLLOW THE LOCAL SYSTEM CLOCK AUTOMATICALLY."
                            color: "#3D3D3D"
                            font.pixelSize: 6
                            font.weight: Font.DemiBold
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            Row {
                width: parent.width
                height: 36
                spacing: 9

                Rectangle {
                    width: 38
                    height: 36
                    radius: 11
                    color: "#0A0A0A"
                    border.width: 1
                    border.color: "#1D1D1D"

                    Text {
                        anchors.centerIn: parent
                        text: "←"
                        color: "#9A9A9A"
                        font.pixelSize: 14
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.backRequested()
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: "BACK"
                        color: "#666666"
                        font.pixelSize: 6
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1
                    }

                    Text {
                        text: "Return to command search"
                        color: "#3E3E3E"
                        font.pixelSize: 7
                    }
                }

                Item { width: parent.width - 210; height: 1 }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.activeCount + " ACTIVE"
                    color: "#383838"
                    font.pixelSize: 6
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.8
                }
            }
        }
    }
}
