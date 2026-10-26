import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.ui

PanelWindow {
    id: root

    required property var modelData
    required property string navbarPosition
    required property bool dockVisible
    required property bool opened
    required property int selectedDay
    required property int selectedMonth
    required property int selectedYear

    signal closeRequested()
    signal hoveringChanged(bool hovering)

    PopupCardStyle {
        id: popupCardStyle
        containerId: "time"
    }

    CalendarCommemorations {
        id: calendarData
    }

    readonly property bool horizontalNavbar:
        root.navbarPosition === "top" || root.navbarPosition === "bottom"
    readonly property var months: [
        "መስከረም", "ጥቅምት", "ሕዳር", "ታህሳስ",
        "ጥር", "የካቲት", "መጋቢት", "ሚያዝያ",
        "ግንቦት", "ሰኔ", "ሐምሌ", "ነሐሴ", "ጳጉሜ"
    ]
    readonly property var dayInfo: calendarData.forDay(root.selectedDay)
    property bool surfaceVisible: false

    screen: root.modelData
    visible: root.surfaceVisible && root.dockVisible && root.modelData !== null
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    width: 324
    height: 326

    anchors {
        left: root.navbarPosition !== "right"
        right: root.navbarPosition === "right"
        top: root.navbarPosition !== "bottom"
        bottom: root.navbarPosition === "bottom"
    }

    margins {
        // Match the calendar's screen edge and sit 12px beside it.
        left: root.horizontalNavbar ? 312
            : (root.navbarPosition === "left" ? 366 : 12)
        right: root.horizontalNavbar ? 12
            : (root.navbarPosition === "right" ? 368 : 12)
        top: root.navbarPosition === "bottom" ? 12
            : (root.horizontalNavbar ? 56 : 12)
        bottom: root.navbarPosition === "bottom" ? 56 : 12
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-calendar-day-details"

    onOpenedChanged: {
        if (root.opened) {
            hideTimer.stop()
            root.surfaceVisible = true
        } else {
            hideTimer.restart()
        }
    }

    onDockVisibleChanged: {
        if (!root.dockVisible) {
            hideTimer.stop()
            root.surfaceVisible = false
        }
    }

    Component.onCompleted: {
        if (root.opened)
            root.surfaceVisible = true
    }

    Timer {
        id: hideTimer
        interval: 210
        repeat: false
        onTriggered: {
            if (!root.opened)
                root.surfaceVisible = false
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 22
        color: popupCardStyle.backgroundColor
        border.width: 1
        border.color: popupCardStyle.borderColor
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.955
        transformOrigin: root.navbarPosition === "right"
            ? Item.TopRight
            : (root.navbarPosition === "bottom" ? Item.BottomLeft : Item.TopLeft)

        Behavior on color {
            ColorAnimation { duration: 145; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 175; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 205; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: 26
            color: "#16000000"
            z: -1
        }

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 6

            Row {
                width: parent.width
                height: 24
                spacing: 7

                Rectangle {
                    width: Math.min(202, parent.width - 34)
                    height: 23
                    radius: 9
                    color: popupCardStyle.subtleSurfaceColor
                    border.width: 1
                    border.color: popupCardStyle.fieldBorderColor

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        text: root.dayInfo.category
                        color: popupCardStyle.secondaryTextColor
                        font.family: "Noto Sans Ethiopic"
                        font.pixelSize: 9
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Item { width: Math.max(0, parent.width - 202 - 24 - 14); height: 1 }

                Rectangle {
                    width: 24
                    height: 24
                    radius: 8
                    color: closeHover.containsMouse
                        ? popupCardStyle.hoverSurfaceColor
                        : popupCardStyle.subtleSurfaceColor
                    border.width: 1
                    border.color: popupCardStyle.fieldBorderColor

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: popupCardStyle.secondaryTextColor
                        font.pixelSize: 17
                        font.weight: Font.Light
                    }

                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 2

                Text {
                    width: parent.width
                    text: root.dayInfo.title
                    color: popupCardStyle.textColor
                    font.family: "Noto Sans Ethiopic"
                    font.pixelSize: 19
                    font.weight: Font.DemiBold
                    maximumLineCount: 1
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.months[root.selectedMonth - 1] + " " + root.selectedDay
                        + " · " + root.selectedYear + " ዓ.ም."
                    color: popupCardStyle.mutedTextColor
                    font.family: "Noto Sans Ethiopic"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }
            }

            Text {
                width: parent.width
                height: 43
                text: root.dayInfo.description
                color: popupCardStyle.secondaryTextColor
                font.family: "Noto Sans Ethiopic"
                font.pixelSize: 10
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }

            Rectangle {
                width: parent.width
                height: 1
                color: popupCardStyle.fieldBorderColor
                opacity: 0.8
            }

            Rectangle {
                width: parent.width
                height: 126
                radius: 15
                color: popupCardStyle.subtleSurfaceColor
                border.width: 1
                border.color: popupCardStyle.fieldBorderColor

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 5

                    Row {
                        width: parent.width
                        height: 15
                        spacing: 5

                        Text {
                            text: "✧"
                            color: popupCardStyle.actionColor
                            font.pixelSize: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "የመጽሐፍ ቅዱስ ጥቅስ"
                            color: popupCardStyle.secondaryTextColor
                            font.family: "Noto Sans Ethiopic"
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        width: parent.width
                        height: 55
                        text: "“" + root.dayInfo.verse + "”"
                        color: popupCardStyle.textColor
                        font.family: "Noto Sans Ethiopic"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        lineHeight: 1.15
                        wrapMode: Text.WordWrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.dayInfo.reference
                        color: popupCardStyle.actionColor
                        font.family: "Noto Sans Ethiopic"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            Text {
                width: parent.width
                height: 25
                text: root.dayInfo.reflection
                color: popupCardStyle.mutedTextColor
                font.family: "Noto Sans Ethiopic"
                font.pixelSize: 9
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }

        // A HoverHandler tracks the card without intercepting the close button.
        HoverHandler {
            onHoveredChanged: root.hoveringChanged(hovered)
        }
    }
}
