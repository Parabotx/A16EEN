import QtQuick

Item {
    id: root

    property bool active: false
    property bool idleEnabled: true
    property int idleMinutes: 5
    property bool sleepLockEnabled: true

    signal backRequested()
    signal settingsRequested(bool idleEnabled, int idleMinutes, bool sleepLockEnabled)
    signal lockNowRequested()

    readonly property color page: "#FFFFFF"
    readonly property color tile: "#F7F8FA"
    readonly property color border: "#E1E5EA"
    readonly property color textPrimary: "#15171A"
    readonly property color textSecondary: "#687280"
    readonly property color textMuted: "#8993A0"
    readonly property color accent: "#B18B3F"

    focus: true

    Keys.onEscapePressed: root.backRequested()

    onActiveChanged: {
        if (root.active)
            forceActiveFocus()
    }

    Rectangle {
        anchors.fill: parent
        color: root.page
    }

    Column {
        anchors.fill: parent
        anchors.margins: 26
        spacing: 16

        Row {
            width: parent.width
            height: 38
            spacing: 12

            Rectangle {
                width: 34
                height: 34
                radius: 10
                color: "#F1F3F6"
                border.width: 1
                border.color: root.border

                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    color: root.textPrimary
                    font.pixelSize: 25
                    y: -1
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backRequested()
                }
            }

            Column {
                width: parent.width - 48
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    text: "LOCK SCREEN"
                    color: root.textPrimary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.1
                }

                Text {
                    text: "Automatic locking, inactivity and sleep behavior"
                    color: root.textSecondary
                    font.pixelSize: 10
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 140
            radius: 16
            color: root.tile
            border.width: 1
            border.color: root.border

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Row {
                    width: parent.width
                    height: 43
                    spacing: 12

                    Column {
                        width: parent.width - 58
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        Text {
                            text: "Lock after inactivity"
                            color: root.textPrimary
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        Text {
                            width: parent.width
                            text: root.idleEnabled
                                ? "Lock the session when there is no keyboard or pointer activity."
                                : "Automatic idle locking is turned off."
                            color: root.textSecondary
                            font.pixelSize: 10
                            wrapMode: Text.WordWrap
                        }
                    }

                    Rectangle {
                        width: 44
                        height: 25
                        radius: 13
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.idleEnabled ? root.accent : "#D4DAE1"

                        Rectangle {
                            width: 19
                            height: 19
                            radius: 10
                            y: 3
                            x: root.idleEnabled ? 22 : 3
                            color: "#FFFFFF"

                            Behavior on x {
                                NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.settingsRequested(!root.idleEnabled, root.idleMinutes, root.sleepLockEnabled)
                        }
                    }
                }

                Row {
                    width: parent.width
                    height: 30
                    spacing: 7
                    opacity: root.idleEnabled ? 1.0 : 0.45

                    Text {
                        width: 78
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        text: "LOCK AFTER"
                        color: root.textMuted
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.6
                    }

                    Repeater {
                        model: [
                            { value: 1, label: "1 MIN" },
                            { value: 3, label: "3 MIN" },
                            { value: 5, label: "5 MIN" },
                            { value: 10, label: "10 MIN" },
                            { value: 15, label: "15 MIN" },
                            { value: 30, label: "30 MIN" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            width: 66
                            height: 29
                            radius: 8
                            color: root.idleEnabled && root.idleMinutes === modelData.value ? "#EFE5D2" : "#FFFFFF"
                            border.width: 1
                            border.color: root.idleEnabled && root.idleMinutes === modelData.value ? root.accent : root.border

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: root.idleEnabled && root.idleMinutes === modelData.value ? "#71511C" : root.textSecondary
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: root.idleEnabled
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: root.settingsRequested(root.idleEnabled, modelData.value, root.sleepLockEnabled)
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 94
            radius: 16
            color: root.tile
            border.width: 1
            border.color: root.border

            Row {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Column {
                    width: parent.width - 58
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Text {
                        text: "Lock when the laptop sleeps"
                        color: root.textPrimary
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        text: root.sleepLockEnabled
                            ? "Lock before suspend and verify the screen is secured before sleep continues. It will stay locked after wake."
                            : "The session will not automatically lock when the system suspends or resumes."
                        color: root.textSecondary
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                    }
                }

                Rectangle {
                    width: 44
                    height: 25
                    radius: 13
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.sleepLockEnabled ? root.accent : "#D4DAE1"

                    Rectangle {
                        width: 19
                        height: 19
                        radius: 10
                        y: 3
                        x: root.sleepLockEnabled ? 22 : 3
                        color: "#FFFFFF"

                        Behavior on x {
                            NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.settingsRequested(root.idleEnabled, root.idleMinutes, !root.sleepLockEnabled)
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: 42

            Row {
                anchors.fill: parent
                spacing: 10

                Rectangle {
                    width: 114
                    height: 38
                    radius: 10
                    color: lockNowMouse.containsMouse ? "#D8C094" : root.accent
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "LOCK NOW"
                        color: "#FFFFFF"
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.8
                    }

                    MouseArea {
                        id: lockNowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.lockNowRequested()
                    }
                }

                Text {
                    width: parent.width - 126
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    text: "Changes apply immediately and are saved for your next session."
                    color: root.textMuted
                    font.pixelSize: 9
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
