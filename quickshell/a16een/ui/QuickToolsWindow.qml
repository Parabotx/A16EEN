import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.ui

PanelWindow {
    id: root

    required property var modelData
    property bool opened: false
    property string page: "updates"
    property string requestedAppId: ""

    signal closeRequested()
    signal backRequested()

    PopupCardStyle {
        id: palette
        containerId: "quick-hub"
    }

    readonly property real screenWidth: root.modelData ? root.modelData.width : 1280
    readonly property real screenHeight: root.modelData ? root.modelData.height : 800
    readonly property real cardWidth: Math.min(820, root.screenWidth - 32)
    readonly property real cardHeight: Math.min(740, root.screenHeight - 32)
    readonly property color textColor: palette.textColor
    readonly property color mutedColor: palette.mutedTextColor
    readonly property color borderColor: palette.borderColor

    screen: root.modelData
    visible: root.opened && root.modelData !== null
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    focusable: root.opened
    width: root.screenWidth
    height: root.screenHeight

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-quick-tool-screen"
    WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: "#4D080B10"
        opacity: root.opened ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: overlayFocus
        anchors.fill: parent
        z: 0
        focus: true
        acceptedButtons: Qt.AllButtons
        onClicked: mouse => {
            const x = mouse.x
            const y = mouse.y
            if (x < screenCard.x || x > screenCard.x + screenCard.width
                    || y < screenCard.y || y > screenCard.y + screenCard.height)
                root.backRequested()
            else
                mouse.accepted = true
        }
        Keys.onEscapePressed: root.backRequested()
    }

    Item {
        id: screenCard
        x: Math.max(8, Math.round((root.screenWidth - width) / 2))
        y: Math.max(8, Math.round((root.screenHeight - height) / 2))
        width: Math.min(root.cardWidth, root.screenWidth - 16)
        height: Math.min(root.cardHeight, root.screenHeight - 16)
        z: 1
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.975
        transformOrigin: Item.Center
        Behavior on opacity {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: palette.backgroundColor
            border.width: 1
            border.color: palette.borderColor

            Rectangle {
                anchors.fill: parent
                anchors.margins: -5
                radius: 25
                color: "#28000000"
                z: -1
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: mouse.accepted = true
            }

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                Row {
                    width: parent.width
                    height: 42
                    spacing: 10

                    Rectangle {
                        width: 116
                        height: 34
                        radius: 10
                        color: palette.subtleSurfaceColor
                        border.width: 1
                        border.color: palette.fieldBorderColor
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            anchors.centerIn: parent
                            spacing: 7
                            NavbarIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 15
                                height: 15
                                iconName: "toolbox.svg"
                                iconColor: palette.iconColor
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "QUICK TOOLS"
                                color: palette.textColor
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.6
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.backRequested()
                        }
                    }

                    Column {
                        width: parent.width - 116 - 34 - parent.spacing * 2
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Text {
                            width: parent.width
                            text: root.page === "updates" ? "UPDATES"
                                : (root.page === "app-locker" ? "APP LOCKER" : "SESSION SNAPSHOTS")
                            color: palette.textColor
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: root.page === "updates" ? "A16EEN + Arch Linux · manual and daily checks"
                                : (root.page === "app-locker" ? "Password-protected application launches"
                                    : "Automatic recovery and named app sessions")
                            color: palette.mutedTextColor
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        width: 34
                        height: 34
                        radius: 10
                        color: closeMouse.containsMouse ? palette.hoverSurfaceColor : palette.subtleSurfaceColor
                        border.width: 1
                        border.color: palette.fieldBorderColor
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: palette.textColor
                            font.pixelSize: 22
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.backRequested()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: palette.fieldBorderColor
                }

                Loader {
                    id: featureLoader
                    width: parent.width
                    height: parent.height - 57
                    source: Qt.resolvedUrl("QuickToolsPage.qml")
                    onLoaded: {
                        if (item) {
                            item.page = root.page
                            item.palette = palette
                            item.requestedAppId = root.requestedAppId
                        }
                    }
                    Connections {
                        target: featureLoader.item
                        function onRequestedAppConsumed() {
                            root.requestedAppId = ""
                        }
                    }
                }
            }
        }
    }

    onPageChanged: {
        if (featureLoader.item)
            featureLoader.item.page = root.page
    }

    onRequestedAppIdChanged: {
        if (featureLoader.item)
            featureLoader.item.requestedAppId = root.requestedAppId
    }

    onOpenedChanged: {
        if (root.opened)
            Qt.callLater(() => overlayFocus.forceActiveFocus())
    }
}