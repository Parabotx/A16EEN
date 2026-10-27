import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.ui

PanelWindow {
    id: root

    required property var modelData
    required property string navbarPosition
    property bool dockVisible: true
    property bool opened: false
    property string page: "updates"
    property string requestedAppId: ""

    signal closeRequested()
    signal backRequested()

    PopupCardStyle {
        id: palette
        containerId: "quick-hub"
    }

    readonly property bool horizontalNavbar:
        root.navbarPosition === "top" || root.navbarPosition === "bottom"
    readonly property real screenWidth: root.modelData ? root.modelData.width : 1280
    readonly property real screenHeight: root.modelData ? root.modelData.height : 800
    readonly property int popupWidth: 340
    readonly property int popupHeight: root.page === "app-locker" ? 382 : 372
    readonly property real popupX: root.horizontalNavbar
        ? root.screenWidth - root.popupWidth - 102
        : (root.navbarPosition === "left"
            ? 66
            : root.screenWidth - root.popupWidth - 68)
    readonly property real popupY: root.horizontalNavbar
        ? (root.navbarPosition === "top"
            ? 40
            : root.screenHeight - root.popupHeight - 40)
        : root.screenHeight - root.popupHeight - 72

    screen: root.modelData
    visible: root.opened && root.dockVisible && root.modelData !== null
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    focusable: root.opened
    WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None
    width: root.screenWidth
    height: root.screenHeight

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-quick-tool-card"

    // The surface spans the screen only to receive outside clicks; the visible
    // panel stays compact and aligned with the rest of the A16EEN popups.
    MouseArea {
        id: outsideClick
        anchors.fill: parent
        z: 0
        focus: true
        acceptedButtons: Qt.AllButtons
        onClicked: root.closeRequested()
        Keys.onEscapePressed: root.closeRequested()
    }

    Item {
        id: card
        x: Math.max(8, Math.min(root.popupX, root.screenWidth - width - 8))
        y: Math.max(8, Math.min(root.popupY, root.screenHeight - height - 8))
            + (root.opened ? 0 : 8)
        width: Math.min(root.popupWidth, root.screenWidth - 16)
        height: Math.min(root.popupHeight, root.screenHeight - 16)
        z: 1
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.96
        transformOrigin: Item.Center

        Behavior on opacity {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
        }
        Behavior on y {
            NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: palette.backgroundColor
            border.width: 1
            border.color: palette.borderColor

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: 20
                color: "#16000000"
                z: -1
            }

            MouseArea {
                anchors.fill: parent
                z: 0
                acceptedButtons: Qt.AllButtons
                onClicked: mouse => mouse.accepted = true
            }

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8
                z: 1

                Row {
                    width: parent.width
                    height: 30
                    spacing: 8

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 8
                        color: backMouse.containsMouse ? palette.hoverSurfaceColor : palette.subtleSurfaceColor
                        border.width: 1
                        border.color: palette.fieldBorderColor
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "‹"
                            color: palette.textColor
                            font.pixelSize: 23
                            font.weight: Font.Normal
                        }

                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.backRequested()
                        }
                    }

                    Text {
                        width: parent.width - 72
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.page === "updates" ? "UPDATES"
                            : (root.page === "app-locker" ? "APP LOCKER" : "SESSION SNAPSHOTS")
                        color: palette.textColor
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.7
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 8
                        color: closeMouse.containsMouse ? palette.hoverSurfaceColor : palette.subtleSurfaceColor
                        border.width: 1
                        border.color: palette.fieldBorderColor
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: palette.textColor
                            font.pixelSize: 19
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeRequested()
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
                    active: root.opened
                    visible: root.opened
                    width: parent.width
                    height: Math.max(0, parent.height - 47)
                    source: Qt.resolvedUrl("QuickToolsPage.qml")
                    onLoaded: {
                        if (item) {
                            item.page = root.page
                            item.palette = palette
                            item.requestedAppId = root.requestedAppId
                            if (root.page === "updates")
                                Qt.callLater(() => item.refreshUpdates(false))
                            else if (root.page === "app-locker")
                                Qt.callLater(() => item.refreshLocker())
                            else if (root.page === "sessions")
                                Qt.callLater(() => item.refreshSessions())
                        }
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
            Qt.callLater(() => outsideClick.forceActiveFocus())
    }
}
