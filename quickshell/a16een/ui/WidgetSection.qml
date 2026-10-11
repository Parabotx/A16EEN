import QtQuick
import QtQuick.Layouts
import "WidgetCatalog.js" as WidgetCatalog

Item {
    id: root

    property bool editorialTimeEnabled: true
    property bool musicEnabled: false
    property bool quotesEnabled: false
    property bool timeUse24Hour: true
    property bool timeShowSeconds: false
    property string selectedWidgetId: "editorial-time"

    readonly property color textPrimary: "#111318"
    readonly property color textSecondary: "#5D6875"
    readonly property color textMuted: "#8993A0"
    readonly property color hoverBackground: "#F4F6F8"
    readonly property color selectedBackground: "#F0F2F5"
    readonly property color activeBackground: "#20262E"
    readonly property color dividerColor: "#E8EBEF"
    readonly property color controlBackground: "#F6F7F9"
    readonly property color controlBorder: "#E3E8ED"

    signal backRequested()
    signal editorialTimeWidgetEnabledRequested(bool enabled)
    signal musicWidgetEnabledRequested(bool enabled)
    signal quotesWidgetEnabledRequested(bool enabled)
    signal timeUse24HourRequested(bool enabled)
    signal timeShowSecondsRequested(bool enabled)

    readonly property int activeCount:
        (root.editorialTimeEnabled ? 1 : 0)
        + (root.musicEnabled ? 1 : 0)
        + (root.quotesEnabled ? 1 : 0)

    readonly property var selectedWidget: root.widgetDefinition(root.selectedWidgetId)

    function widgetDefinition(id) {
        for (let i = 0; i < WidgetCatalog.definitions.length; ++i) {
            if (WidgetCatalog.definitions[i].id === id)
                return WidgetCatalog.definitions[i]
        }
        return WidgetCatalog.definitions.length ? WidgetCatalog.definitions[0] : ({})
    }

    function widgetEnabled(id) {
        if (id === "editorial-time") return root.editorialTimeEnabled
        if (id === "music") return root.musicEnabled
        if (id === "quotes") return root.quotesEnabled
        return false
    }

    function widgetIcon(id) {
        if (id === "editorial-time") return "lucide-monitor.svg"
        if (id === "music") return "music.svg"
        if (id === "quotes") return "quote-mark.svg"
        return "lucide-app-window.svg"
    }

    function toggleWidget(id) {
        const next = !root.widgetEnabled(id)

        if (id === "editorial-time")
            root.editorialTimeWidgetEnabledRequested(next)
        else if (id === "music")
            root.musicWidgetEnabledRequested(next)
        else if (id === "quotes")
            root.quotesWidgetEnabledRequested(next)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            spacing: 10

            Text {
                text: "WIDGETS"
                color: root.textPrimary
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 0.4
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.activeCount + " / " + WidgetCatalog.definitions.length + " ACTIVE"
                color: root.textMuted
                font.pixelSize: 8
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            spacing: 18

            // A stable left-side index leaves room for each widget to gain
            // its own settings without turning the screen into more tabs.
            ColumnLayout {
                Layout.preferredWidth: 178
                Layout.minimumWidth: 155
                Layout.maximumWidth: 195
                Layout.fillHeight: true
                spacing: 8

                Text {
                    Layout.leftMargin: 8
                    Layout.bottomMargin: 2
                    text: "DESKTOP"
                    color: root.textMuted
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.0
                }

                Flickable {
                    id: widgetListScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 0
                    clip: true
                    contentWidth: width
                    contentHeight: widgetList.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick

                    ColumnLayout {
                        id: widgetList
                        width: widgetListScroll.width
                        spacing: 3

                        Repeater {
                            model: WidgetCatalog.definitions

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 49
                                radius: 8
                                color: root.selectedWidgetId === modelData.id
                                    ? root.selectedBackground
                                    : (itemMouse.containsMouse ? root.hoverBackground : "transparent")

                                Rectangle {
                                    width: 2
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    radius: 1
                                    color: root.activeBackground
                                    visible: root.selectedWidgetId === modelData.id
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 8
                                    spacing: 10

                                    NavbarIcon {
                                        Layout.preferredWidth: 17
                                        Layout.preferredHeight: 17
                                        iconName: root.widgetIcon(modelData.id)
                                        iconColor: root.selectedWidgetId === modelData.id
                                            ? root.textPrimary
                                            : (root.widgetEnabled(modelData.id) ? "#4E5864" : "#9AA3AE")
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.title
                                            color: root.selectedWidgetId === modelData.id
                                                ? root.textPrimary : root.textSecondary
                                            font.pixelSize: 8
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.subtitle
                                            color: root.textMuted
                                            font.pixelSize: 7
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 5
                                        Layout.preferredHeight: 5
                                        radius: 3
                                        color: root.widgetEnabled(modelData.id) ? "#333B45" : "#D6DCE3"
                                    }
                                }

                                MouseArea {
                                    id: itemMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectedWidgetId = modelData.id
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    Layout.topMargin: 2
                    text: "Choose a widget to view its details and options."
                    color: root.textMuted
                    font.pixelSize: 7
                    wrapMode: Text.WordWrap
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: root.dividerColor
            }

            // Widget-specific details and controls.
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    spacing: 10

                    NavbarIcon {
                        Layout.preferredWidth: 23
                        Layout.preferredHeight: 23
                        iconName: root.widgetIcon(root.selectedWidgetId)
                        iconColor: root.textPrimary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            Layout.fillWidth: true
                            text: root.selectedWidget.title || "WIDGET"
                            color: root.textPrimary
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.2
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.selectedWidget.subtitle || ""
                            color: root.textSecondary
                            font.pixelSize: 8
                            elide: Text.ElideRight
                        }
                    }

                    Item {
                        Layout.preferredWidth: 72
                        Layout.preferredHeight: 30

                        Row {
                            anchors.centerIn: parent
                            spacing: 7

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.widgetEnabled(root.selectedWidgetId) ? "ON" : "OFF"
                                color: root.widgetEnabled(root.selectedWidgetId) ? root.textPrimary : root.textMuted
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.5
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 34
                                height: 20
                                radius: 10
                                color: root.widgetEnabled(root.selectedWidgetId)
                                    ? root.activeBackground : "#DDE2E8"

                                Rectangle {
                                    width: 14
                                    height: 14
                                    y: 3
                                    x: root.widgetEnabled(root.selectedWidgetId) ? 17 : 3
                                    radius: 7
                                    color: "#FFFFFF"

                                    Behavior on x {
                                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleWidget(root.selectedWidgetId)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                    Layout.bottomMargin: 18
                    height: 1
                    color: root.dividerColor
                }

                Text {
                    text: "ABOUT THIS WIDGET"
                    color: root.textMuted
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.0
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    text: root.selectedWidget.detail || ""
                    color: root.textSecondary
                    font.pixelSize: 9
                    wrapMode: Text.WordWrap
                }

                Item { Layout.preferredHeight: 12 }

                // Editorial Time is the first widget with configurable options.
                // Other widgets can add their own controls to this same panel.
                ColumnLayout {
                    visible: root.selectedWidgetId === "editorial-time"
                    Layout.fillWidth: true
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: root.dividerColor
                    }

                    Text {
                        Layout.topMargin: 16
                        text: "CLOCK FORMAT"
                        color: root.textMuted
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.0
                    }

                    Text {
                        Layout.topMargin: 5
                        Layout.bottomMargin: 12
                        text: "Choose how time appears on the desktop."
                        color: root.textSecondary
                        font.pixelSize: 8
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: [
                                { value: true, label: "24 HOUR" },
                                { value: false, label: "12 HOUR" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 34
                                radius: 7
                                color: root.timeUse24Hour === modelData.value
                                    ? root.activeBackground : root.controlBackground
                                border.width: 1
                                border.color: root.timeUse24Hour === modelData.value
                                    ? root.activeBackground : root.controlBorder

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: root.timeUse24Hour === modelData.value ? "#FFFFFF" : root.textSecondary
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.timeUse24HourRequested(modelData.value)
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 12
                        height: 1
                        color: root.dividerColor
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 10
                        Layout.preferredHeight: 38
                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: "SHOW SECONDS"
                                color: root.textPrimary
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: root.timeShowSeconds ? "Seconds are visible" : "Seconds are hidden"
                                color: root.textSecondary
                                font.pixelSize: 7
                            }
                        }

                        Item {
                            Layout.preferredWidth: 38
                            Layout.preferredHeight: 24

                            Rectangle {
                                anchors.centerIn: parent
                                width: 34
                                height: 20
                                radius: 10
                                color: root.timeShowSeconds ? root.activeBackground : "#DDE2E8"

                                Rectangle {
                                    width: 14
                                    height: 14
                                    y: 3
                                    x: root.timeShowSeconds ? 17 : 3
                                    radius: 7
                                    color: "#FFFFFF"

                                    Behavior on x {
                                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.timeShowSecondsRequested(!root.timeShowSeconds)
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: 10
                        text: root.editorialTimeEnabled
                            ? "These options apply to the Editorial Time desktop widget."
                            : "Enable this widget above to show the clock options on your desktop."
                        color: root.textMuted
                        font.pixelSize: 7
                        wrapMode: Text.WordWrap
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }

    Keys.onEscapePressed: root.backRequested()
    focus: root.visible
    activeFocusOnTab: true
}
