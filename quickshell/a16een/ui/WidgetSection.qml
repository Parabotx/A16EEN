import QtQuick
import "WidgetCatalog.js" as WidgetCatalog

Item {
    id: root

    property bool editorialTimeEnabled: true
    property bool calendarEnabled: false
    property bool pulseEnabled: false
    property bool workspaceEnabled: false
    property bool timeUse24Hour: true
    property bool timeShowSeconds: false

    signal backRequested()
    signal editorialTimeWidgetEnabledRequested(bool enabled)
    signal calendarWidgetEnabledRequested(bool enabled)
    signal pulseWidgetEnabledRequested(bool enabled)
    signal workspaceWidgetEnabledRequested(bool enabled)
    signal timeUse24HourRequested(bool enabled)
    signal timeShowSecondsRequested(bool enabled)

    function widgetEnabled(id) {
        if (id === "editorial-time") return root.editorialTimeEnabled
        if (id === "calendar") return root.calendarEnabled
        if (id === "pulse") return root.pulseEnabled
        if (id === "workspaces") return root.workspaceEnabled
        return false
    }

    readonly property int activeCount:
        (root.editorialTimeEnabled ? 1 : 0)
        + (root.calendarEnabled ? 1 : 0)
        + (root.pulseEnabled ? 1 : 0)
        + (root.workspaceEnabled ? 1 : 0)

    function toggleWidget(id) {
        const next = !root.widgetEnabled(id)

        if (id === "editorial-time")
            root.editorialTimeWidgetEnabledRequested(next)
        else if (id === "calendar")
            root.calendarWidgetEnabledRequested(next)
        else if (id === "pulse")
            root.pulseWidgetEnabledRequested(next)
        else if (id === "workspaces")
            root.workspaceWidgetEnabledRequested(next)
    }

    Column {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 12

        Rectangle {
            width: parent.width
            height: 58
            radius: 15
            color: "#FFFFFF"
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
                        color: "#8A93A0"
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.2
                    }
                }

                Item { width: parent.width - 170; height: 1 }

                Rectangle {
                    width: 135
                    height: 38
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 11
                    color: "#F5F7FA"
                    border.width: 1
                    border.color: "#DDE3EA"

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
                            color: "#2F80ED"
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
                width: 310
                height: parent.height
                radius: 16
                color: "#FFFFFF"
                border.width: 1
                border.color: "#E2E7EC"

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Text {
                        text: "WIDGET REGISTRY"
                        color: "#525E6B"
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.2
                    }

                    Text {
                        width: parent.width
                        text: "Choose which independent modules live on your desktop."
                        color: "#7A8693"
                        font.pixelSize: 7
                        wrapMode: Text.WordWrap
                    }

                    Repeater {
                        model: WidgetCatalog.definitions

                        delegate: Rectangle {
                            required property var modelData

                            width: parent.width
                            height: 74
                            radius: 14
                            color: root.widgetEnabled(modelData.id) ? "#F0F4F8" : "#FFFFFF"
                            border.width: 1
                            border.color: root.widgetEnabled(modelData.id) ? "#C7D0DA" : "#D9E0E7"

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
                                    color: root.widgetEnabled(modelData.id) ? "#EEF3F8" : "#F5F7FA"

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.id === "editorial-time"
                                            ? "T"
                                            : modelData.id === "calendar"
                                                ? "C"
                                                : modelData.id === "pulse"
                                                    ? "P"
                                                    : "W"
                                        color: root.widgetEnabled(modelData.id) ? "#2F80ED" : "#8390A0"
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
                                        color: "#66717D"
                                        font.pixelSize: 6
                                    }

                                    Text {
                                        width: parent.width
                                        text: modelData.detail
                                        color: "#89929E"
                                        font.pixelSize: 6
                                        elide: Text.ElideRight
                                    }
                                }

                                Rectangle {
                                    width: 42
                                    height: 24
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: 12
                                    color: root.widgetEnabled(modelData.id) ? "#2F80ED" : "#D9E0E7"

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        y: 3
                                        x: root.widgetEnabled(modelData.id) ? 21 : 3
                                        radius: 9
                                        color: root.widgetEnabled(modelData.id) ? "#17202A" : "#7C8794"

                                        Behavior on x {
                                            NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.toggleWidget(modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width - 322
                height: parent.height
                radius: 16
                color: "#FFFFFF"
                border.width: 1
                border.color: "#E2E7EC"

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 11

                    Text {
                        text: "TIME & DATE"
                        color: "#FFFFFF"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1
                    }

                    Text {
                        text: "The calendar is optional. The editorial time widget is the default."
                        color: "#505050"
                        font.pixelSize: 7
                    }

                    Rectangle {
                        width: parent.width
                        height: 90
                        radius: 14
                        color: "#F7F9FB"
                        border.width: 1
                        border.color: "#1A1A1A"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 18
                            anchors.rightMargin: 18

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 5

                                Text {
                                    text: root.editorialTimeEnabled ? "EDITORIAL TIME" : "TIME DISABLED"
                                    color: "#FFFFFF"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    width: 300
                                    text: root.editorialTimeEnabled
                                        ? "Wide, container-free clock that blends into the wallpaper."
                                        : "Enable it from the registry."
                                    color: "#687582"
                                    font.pixelSize: 7
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Item { width: parent.width - 315; height: 1 }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.editorialTimeEnabled ? "DEFAULT" : "OFF"
                                color: root.editorialTimeEnabled ? "#2F80ED" : "#505050"
                                font.pixelSize: 7
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1
                            }
                        }
                    }

                    Text {
                        text: "CLOCK FORMAT"
                        color: "#5E6A77"
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
                            color: root.timeUse24Hour ? "#E2E7EC" : "#FFFFFF"
                            border.width: 1
                            border.color: root.timeUse24Hour ? "#B9C5D1" : "#E2E7EC"

                            Text {
                                anchors.centerIn: parent
                                text: "24 HOUR"
                                color: root.timeUse24Hour ? "#2F80ED" : "#7C8794"
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
                            color: !root.timeUse24Hour ? "#E2E7EC" : "#FFFFFF"
                            border.width: 1
                            border.color: !root.timeUse24Hour ? "#B9C5D1" : "#E2E7EC"

                            Text {
                                anchors.centerIn: parent
                                text: "12 HOUR"
                                color: !root.timeUse24Hour ? "#2F80ED" : "#7C8794"
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
                        height: 52
                        radius: 12
                        color: "#F7F9FB"
                        border.width: 1
                        border.color: "#E2E7EC"

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
                                }

                                Text {
                                    text: root.timeShowSeconds ? "Visible" : "Hidden"
                                    color: "#414141"
                                    font.pixelSize: 6
                                }
                            }

                            Item { width: parent.width - 112; height: 1 }

                            Rectangle {
                                width: 46
                                height: 24
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 12
                                color: root.timeShowSeconds ? "#2F80ED" : "#D9E0E7"

                                Rectangle {
                                    width: 18
                                    height: 18
                                    y: 3
                                    x: root.timeShowSeconds ? 25 : 3
                                    radius: 9
                                    color: root.timeShowSeconds ? "#17202A" : "#7C8794"
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
                        color: "#E5EAF0"
                    }

                    Text {
                        width: parent.width
                        text: "CALENDAR MODE IS AN INDEPENDENT WIDGET. TURN IT ON ONLY WHEN YOU WANT THE GLASS CALENDAR DESIGN."
                        color: "#7A8794"
                        font.pixelSize: 6
                        font.weight: Font.DemiBold
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        Row {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 22
            anchors.rightMargin: 22
            anchors.bottomMargin: 22
            height: 36
            spacing: 9

            Rectangle {
                width: 38
                height: 36
                radius: 11
                color: "#F7F9FB"
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
                    color: "#5F6C79"
                    font.pixelSize: 6
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                }

                Text {
                    text: "Return to command search"
                    color: "#73808D"
                    font.pixelSize: 7
                }
            }

            Item { width: parent.width - 210; height: 1 }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.activeCount + " ACTIVE"
                color: "#52606E"
                font.pixelSize: 6
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
            }
        }
    }
}
