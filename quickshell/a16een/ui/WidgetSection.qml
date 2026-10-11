import QtQuick
import QtQuick.Layouts
import "WidgetCatalog.js" as WidgetCatalog

Item {
    id: root

    property bool editorialTimeEnabled: true
    property bool calendarEnabled: false
    property bool pulseEnabled: false
    property bool workspaceEnabled: false
    property bool tasksEnabled: false
    property bool musicEnabled: false
    property bool quotesEnabled: false
    property bool timeUse24Hour: true
    property bool timeShowSeconds: false
    property string currentSection: "widgets"

    readonly property color textPrimary: "#111318"
    readonly property color textSecondary: "#5D6875"
    readonly property color textMuted: "#8993A0"
    readonly property color hoverBackground: "#F4F6F8"
    readonly property color selectedBackground: "#20262E"
    readonly property color dividerColor: "#E8EBEF"
    readonly property color controlBackground: "#F6F7F9"
    readonly property color controlBorder: "#E3E8ED"

    signal backRequested()
    signal editorialTimeWidgetEnabledRequested(bool enabled)
    signal calendarWidgetEnabledRequested(bool enabled)
    signal pulseWidgetEnabledRequested(bool enabled)
    signal workspaceWidgetEnabledRequested(bool enabled)
    signal tasksWidgetEnabledRequested(bool enabled)
    signal musicWidgetEnabledRequested(bool enabled)
    signal quotesWidgetEnabledRequested(bool enabled)
    signal timeUse24HourRequested(bool enabled)
    signal timeShowSecondsRequested(bool enabled)

    readonly property int activeCount:
        (root.editorialTimeEnabled ? 1 : 0)
        + (root.calendarEnabled ? 1 : 0)
        + (root.pulseEnabled ? 1 : 0)
        + (root.workspaceEnabled ? 1 : 0)
        + (root.tasksEnabled ? 1 : 0)
        + (root.musicEnabled ? 1 : 0)
        + (root.quotesEnabled ? 1 : 0)

    function widgetEnabled(id) {
        if (id === "editorial-time") return root.editorialTimeEnabled
        if (id === "calendar") return root.calendarEnabled
        if (id === "pulse") return root.pulseEnabled
        if (id === "workspaces") return root.workspaceEnabled
        if (id === "tasks") return root.tasksEnabled
        if (id === "music") return root.musicEnabled
        if (id === "quotes") return root.quotesEnabled
        return false
    }

    function widgetIcon(id) {
        if (id === "editorial-time") return "lucide-monitor.svg"
        if (id === "calendar") return "quick-calendar.svg"
        if (id === "pulse") return "lucide-activity.svg"
        if (id === "workspaces") return "layers.svg"
        if (id === "tasks") return "quick-tasks.svg"
        if (id === "music") return "music.svg"
        if (id === "quotes") return "quote-mark.svg"
        return "lucide-app-window.svg"
    }

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
        else if (id === "tasks")
            root.tasksWidgetEnabledRequested(next)
        else if (id === "music")
            root.musicWidgetEnabledRequested(next)
        else if (id === "quotes")
            root.quotesWidgetEnabledRequested(next)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            Layout.minimumHeight: 32
            Layout.maximumHeight: 32
            spacing: 6

            Repeater {
                model: [
                    { id: "widgets", label: "Widgets" },
                    { id: "clock", label: "Clock" }
                ]

                delegate: Rectangle {
                    required property var modelData
                    Layout.preferredWidth: 104
                    Layout.preferredHeight: 32
                    radius: 9
                    color: root.currentSection === modelData.id
                        ? root.selectedBackground
                        : (tabMouse.containsMouse ? "#EEF1F4" : root.controlBackground)
                    border.width: 1
                    border.color: root.currentSection === modelData.id
                        ? root.selectedBackground : root.controlBorder

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: root.currentSection === modelData.id ? "#FFFFFF" : root.textSecondary
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentSection = modelData.id
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.activeCount + " / " + WidgetCatalog.definitions.length + " ACTIVE"
                color: root.textMuted
                font.pixelSize: 8
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
                verticalAlignment: Text.AlignVCenter
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            clip: true

            StackLayout {
                anchors.fill: parent
                currentIndex: root.currentSection === "clock" ? 1 : 0

                Item {
                    id: widgetsPage

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            Layout.bottomMargin: 8
                            text: "DESKTOP WIDGETS"
                            color: root.textMuted
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.0
                        }

                        Flickable {
                            id: widgetsScroll
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 0
                            clip: true
                            contentWidth: width
                            contentHeight: widgetRows.implicitHeight
                            boundsBehavior: Flickable.StopAtBounds
                            flickableDirection: Flickable.VerticalFlick

                            ColumnLayout {
                                id: widgetRows
                                width: widgetsScroll.width
                                spacing: 0

                                Repeater {
                                    model: WidgetCatalog.definitions

                                    delegate: Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 58
                                        color: rowMouse.containsMouse ? root.hoverBackground : "transparent"
                                        radius: 8

                                        Behavior on color {
                                            ColorAnimation { duration: 100 }
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            spacing: 12

                                            NavbarIcon {
                                                Layout.preferredWidth: 20
                                                Layout.preferredHeight: 20
                                                iconName: root.widgetIcon(modelData.id)
                                                iconColor: root.widgetEnabled(modelData.id) ? root.textPrimary : "#8B95A2"
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 3

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData.title
                                                    color: root.textPrimary
                                                    font.pixelSize: 9
                                                    font.weight: Font.DemiBold
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData.subtitle
                                                    color: root.textSecondary
                                                    font.pixelSize: 8
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Text {
                                                text: root.widgetEnabled(modelData.id) ? "ON" : "OFF"
                                                color: root.widgetEnabled(modelData.id) ? root.textPrimary : root.textMuted
                                                font.pixelSize: 7
                                                font.weight: Font.DemiBold
                                                font.letterSpacing: 0.6
                                            }

                                            Rectangle {
                                                Layout.preferredWidth: 38
                                                Layout.preferredHeight: 22
                                                radius: 11
                                                color: root.widgetEnabled(modelData.id) ? root.selectedBackground : "#DDE2E8"

                                                Rectangle {
                                                    width: 16
                                                    height: 16
                                                    y: 3
                                                    x: root.widgetEnabled(modelData.id) ? 19 : 3
                                                    radius: 8
                                                    color: "#FFFFFF"

                                                    Behavior on x {
                                                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                                    }
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: rowMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.toggleWidget(modelData.id)
                                        }

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.bottom: parent.bottom
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            height: 1
                                            color: root.dividerColor
                                            visible: modelData.id !== "quotes"
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.topMargin: 7
                            text: "Editorial Time and Calendar share the same desktop position."
                            color: root.textMuted
                            font.pixelSize: 7
                            elide: Text.ElideRight
                        }
                    }
                }

                Item {
                    id: clockPage

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: 12
                        spacing: 0

                        Text {
                            text: "CLOCK FORMAT"
                            color: root.textMuted
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.0
                        }

                        Text {
                            Layout.topMargin: 5
                            Layout.bottomMargin: 18
                            text: "Choose how time appears on the desktop."
                            color: root.textSecondary
                            font.pixelSize: 9
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
                                    Layout.preferredHeight: 38
                                    radius: 8
                                    color: root.timeUse24Hour === modelData.value
                                        ? root.selectedBackground : root.controlBackground
                                    border.width: 1
                                    border.color: root.timeUse24Hour === modelData.value
                                        ? root.selectedBackground : root.controlBorder

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: root.timeUse24Hour === modelData.value ? "#FFFFFF" : root.textSecondary
                                        font.pixelSize: 9
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
                            Layout.topMargin: 14
                            Layout.bottomMargin: 14
                            height: 1
                            color: root.dividerColor
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            spacing: 10

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                Text {
                                    text: "SHOW SECONDS"
                                    color: root.textPrimary
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: root.timeShowSeconds ? "Seconds are visible" : "Seconds are hidden"
                                    color: root.textSecondary
                                    font.pixelSize: 8
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 38
                                Layout.preferredHeight: 22
                                radius: 11
                                color: root.timeShowSeconds ? root.selectedBackground : "#DDE2E8"

                                Rectangle {
                                    width: 16
                                    height: 16
                                    y: 3
                                    x: root.timeShowSeconds ? 19 : 3
                                    radius: 8
                                    color: "#FFFFFF"

                                    Behavior on x {
                                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.timeShowSecondsRequested(!root.timeShowSeconds)
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.topMargin: 14
                            height: 1
                            color: root.dividerColor
                        }

                        Text {
                            Layout.topMargin: 14
                            text: root.editorialTimeEnabled
                                ? "These options apply to Editorial Time."
                                : "Enable Editorial Time in the Widgets tab to use these options."
                            color: root.textMuted
                            font.pixelSize: 8
                            wrapMode: Text.WordWrap
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }

    Keys.onEscapePressed: root.backRequested()
    focus: root.visible
    activeFocusOnTab: true
}
