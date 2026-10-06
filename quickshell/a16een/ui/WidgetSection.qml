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

    readonly property color pageBackground: "#FFFFFF"
    readonly property color panelBackground: "#FBFCFE"
    readonly property color tileBackground: "#F7F9FC"
    readonly property color borderColor: "#E2E8F0"
    readonly property color strongText: "#18212B"
    readonly property color secondaryText: "#617080"
    readonly property color mutedText: "#8793A1"
    readonly property color accent: "#2F80ED"

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

    focus: true
    activeFocusOnTab: true

    Rectangle {
        anchors.fill: parent
        color: root.pageBackground
    }

    Rectangle {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 22
        height: 62
        radius: 15
        color: root.panelBackground
        border.width: 1
        border.color: root.borderColor

        Row {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 12

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    text: "WIDGETS"
                    color: root.strongText
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.5
                }

                Text {
                    text: "DESKTOP MODULES"
                    color: root.mutedText
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.2
                }
            }

            Item { Layout.fillWidth: true; width: Math.max(1, parent.width - 185); height: 1 }

            Rectangle {
                width: 135
                height: 40
                anchors.verticalCenter: parent.verticalCenter
                radius: 11
                color: "#FFFFFF"
                border.width: 1
                border.color: root.borderColor

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        width: 105
                        horizontalAlignment: Text.AlignHCenter
                        text: "ACTIVE"
                        color: root.secondaryText
                        font.pixelSize: 6
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1
                    }

                    Text {
                        width: 105
                        horizontalAlignment: Text.AlignHCenter
                        text: root.activeCount
                        color: root.accent
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }

    Row {
        id: contentRow
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: footer.top
        anchors.topMargin: 14
        anchors.bottomMargin: 14
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        spacing: 12

        Rectangle {
            id: registryPanel
            width: Math.min(318, contentRow.width * 0.36)
            height: parent.height
            radius: 16
            color: root.panelBackground
            border.width: 1
            border.color: root.borderColor
            clip: true

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                Text {
                    text: "WIDGET REGISTRY"
                    color: root.strongText
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.2
                }

                Text {
                    width: parent.width
                    text: "Choose which modules live on your desktop."
                    color: root.secondaryText
                    font.pixelSize: 7
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 2
                }

                Column {
                    id: registryList
                    width: parent.width
                    spacing: 7

                    Repeater {
                        model: WidgetCatalog.definitions

                        delegate: Rectangle {
                            required property var modelData

                            width: registryList.width
                            height: Math.min(70, Math.max(58, (registryPanel.height - 190) / 4))
                            radius: 13
                            color: root.widgetEnabled(modelData.id) ? "#F0F5FB" : "#FFFFFF"
                            border.width: 1
                            border.color: root.widgetEnabled(modelData.id) ? "#C8D9EA" : root.borderColor

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 11
                                anchors.rightMargin: 10
                                spacing: 9

                                Rectangle {
                                    width: 34
                                    height: 34
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: 10
                                    color: root.widgetEnabled(modelData.id) ? "#EAF3FF" : "#F4F7FA"
                                    border.width: 1
                                    border.color: root.widgetEnabled(modelData.id) ? "#D3E5F9" : "#E6EBF0"

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.id === "editorial-time"
                                            ? "T"
                                            : modelData.id === "calendar"
                                                ? "C"
                                                : modelData.id === "pulse"
                                                    ? "P"
                                                    : "W"
                                        color: root.widgetEnabled(modelData.id) ? root.accent : root.mutedText
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Column {
                                    width: Math.max(90, parent.width - 116)
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 3

                                    Text {
                                        width: parent.width
                                        text: modelData.title
                                        color: root.strongText
                                        font.pixelSize: 8
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: modelData.subtitle
                                        color: root.secondaryText
                                        font.pixelSize: 6
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: modelData.detail
                                        color: root.mutedText
                                        font.pixelSize: 6
                                        elide: Text.ElideRight
                                    }
                                }

                                Rectangle {
                                    width: 42
                                    height: 24
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: 12
                                    color: root.widgetEnabled(modelData.id) ? root.accent : "#D9E1E9"

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        y: 3
                                        x: root.widgetEnabled(modelData.id) ? 21 : 3
                                        radius: 9
                                        color: "#FFFFFF"

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
        }

        Rectangle {
            id: settingsPanel
            width: contentRow.width - registryPanel.width - contentRow.spacing
            height: parent.height
            radius: 16
            color: root.panelBackground
            border.width: 1
            border.color: root.borderColor

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 10

                Text {
                    text: "TIME & DATE"
                    color: root.strongText
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                }

                Text {
                    width: parent.width
                    text: "Control the editorial clock without changing the wallpaper design."
                    color: root.secondaryText
                    font.pixelSize: 7
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                }

                Rectangle {
                    width: parent.width
                    height: 82
                    radius: 13
                    color: "#FFFFFF"
                    border.width: 1
                    border.color: root.borderColor

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12

                        Column {
                            width: Math.max(130, parent.width - 96)
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Text {
                                width: parent.width
                                text: root.editorialTimeEnabled ? "EDITORIAL TIME" : "TIME DISABLED"
                                color: root.strongText
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: root.editorialTimeEnabled
                                    ? "Wide, container-free clock that blends into the wallpaper."
                                    : "Enable Editorial Time from the widget registry."
                                color: root.secondaryText
                                font.pixelSize: 7
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            width: 72
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignRight
                            text: root.editorialTimeEnabled ? "DEFAULT" : "OFF"
                            color: root.editorialTimeEnabled ? root.accent : root.mutedText
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1
                        }
                    }
                }

                Text {
                    text: "CLOCK FORMAT"
                    color: root.strongText
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                }

                Row {
                    width: parent.width
                    height: 40
                    spacing: 7

                    Rectangle {
                        width: (parent.width - 7) / 2
                        height: parent.height
                        radius: 11
                        color: root.timeUse24Hour ? "#EAF3FF" : "#FFFFFF"
                        border.width: 1
                        border.color: root.timeUse24Hour ? "#BBD7F5" : root.borderColor

                        Text {
                            anchors.centerIn: parent
                            text: "24 HOUR"
                            color: root.timeUse24Hour ? root.accent : root.secondaryText
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
                        height: parent.height
                        radius: 11
                        color: !root.timeUse24Hour ? "#EAF3FF" : "#FFFFFF"
                        border.width: 1
                        border.color: !root.timeUse24Hour ? "#BBD7F5" : root.borderColor

                        Text {
                            anchors.centerIn: parent
                            text: "12 HOUR"
                            color: !root.timeUse24Hour ? root.accent : root.secondaryText
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
                    height: 50
                    radius: 12
                    color: "#FFFFFF"
                    border.width: 1
                    border.color: root.borderColor

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 13
                        anchors.rightMargin: 13
                        spacing: 10

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Text {
                                text: "SHOW SECONDS"
                                color: root.strongText
                                font.pixelSize: 7
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: root.timeShowSeconds ? "Visible" : "Hidden"
                                color: root.secondaryText
                                font.pixelSize: 6
                            }
                        }

                        Item { width: Math.max(1, parent.width - 105); height: 1 }

                        Rectangle {
                            width: 46
                            height: 24
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 12
                            color: root.timeShowSeconds ? root.accent : "#D9E1E9"

                            Rectangle {
                                width: 18
                                height: 18
                                y: 3
                                x: root.timeShowSeconds ? 25 : 3
                                radius: 9
                                color: "#FFFFFF"
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
                    height: Math.max(42, parent.height - 292)
                    radius: 12
                    color: root.tileBackground
                    border.width: 1
                    border.color: "#E7ECF2"

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 5

                        Text {
                            text: "DESKTOP BEHAVIOR"
                            color: root.strongText
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1
                        }

                        Text {
                            width: parent.width
                            text: "Editorial Time is shown on the wallpaper. Calendar, System Pulse and Workspace Matrix remain independent modules."
                            color: root.secondaryText
                            font.pixelSize: 6
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    Row {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        anchors.bottomMargin: 22
        height: 38
        spacing: 9

        Rectangle {
            width: 38
            height: 38
            radius: 11
            color: root.panelBackground
            border.width: 1
            border.color: root.borderColor

            Text {
                anchors.centerIn: parent
                text: "←"
                color: root.strongText
                font.pixelSize: 14
                font.weight: Font.DemiBold
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
                color: root.strongText
                font.pixelSize: 6
                font.weight: Font.DemiBold
                font.letterSpacing: 1
            }

            Text {
                text: "Return to command search"
                color: root.secondaryText
                font.pixelSize: 7
            }
        }

        Item { width: Math.max(1, parent.width - 215); height: 1 }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.activeCount + " ACTIVE"
            color: root.secondaryText
            font.pixelSize: 6
            font.weight: Font.DemiBold
            font.letterSpacing: 0.8
        }
    }
}
