import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    required property string navbarPosition
    property bool opened: false
    property string page: "tools"
    property var stashedApps: []

    signal closeRequested()
    signal toolRequested(string toolId)
    signal appStashRequested()
    signal backRequested()
    signal restoreRequested(string windowId)

    readonly property bool horizontalNavbar: root.navbarPosition === "top" || root.navbarPosition === "bottom"
    readonly property real screenWidth: root.modelData ? root.modelData.width : 1920
    readonly property real screenHeight: root.modelData ? root.modelData.height : 1080
    readonly property int popupWidth: 344
    readonly property int popupHeight: root.page === "stash" ? 410 : 326
    readonly property var tools: [
        { id: "screenshot", label: "Screenshot", detail: "Capture your screen", icon: "lucide-crop.svg" },
        { id: "wallpapers", label: "Wallpapers", detail: "Change your background", icon: "lucide-image.svg" },
        { id: "clipboard", label: "Clipboard", detail: "Reuse copied text", icon: "lucide-clipboard.svg" },
        { id: "calculator", label: "Calculator", detail: "Quick calculations", icon: "lucide-calculator.svg" }
    ]

    readonly property real popupX: root.horizontalNavbar
        ? root.screenWidth - root.popupWidth - 102
        : (root.navbarPosition === "left" ? 66 : root.screenWidth - root.popupWidth - 68)
    readonly property real popupY: root.horizontalNavbar
        ? (root.navbarPosition === "top" ? 40 : root.screenHeight - root.popupHeight - 40)
        : root.screenHeight - root.popupHeight - 72

    screen: root.modelData
    visible: root.opened && root.modelData !== null
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    focusable: root.opened
    width: root.screenWidth
    height: root.screenHeight

    anchors { left: true; right: true; top: true; bottom: true }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-tools-panel"
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

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
        y: Math.max(8, Math.min(root.popupY, root.screenHeight - height - 8)) + (root.opened ? 0 : 6)
        width: Math.min(root.popupWidth, root.screenWidth - 16)
        height: Math.min(root.popupHeight, root.screenHeight - 16)
        z: 1
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.97

        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            radius: 17
            color: "#FFFFFF"
            border.width: 1
            border.color: "#D9DEE5"

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: 21
                color: "#16000000"
                z: -1
            }

            MouseArea {
                anchors.fill: parent
                z: 0
                acceptedButtons: Qt.AllButtons
                onClicked: mouse.accepted = true
            }

            Column {
                anchors.fill: parent
                anchors.margins: 13
                spacing: 9
                z: 1

                Row {
                    width: parent.width
                    height: 28
                    spacing: 9

                    Rectangle {
                        visible: root.page === "stash"
                        width: 27
                        height: 27
                        radius: 9
                        color: backMouse.containsMouse ? "#EEF1F4" : "#F7F8FA"
                        border.width: 1
                        border.color: "#E9ECF0"
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            anchors.centerIn: parent
                            width: 15
                            height: 15
                            source: Qt.resolvedUrl("../assets/icons/lucide-arrow-left.svg")
                            sourceSize.width: 48
                            sourceSize.height: 48
                            smooth: true
                        }

                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.backRequested()
                        }
                    }

                    Rectangle {
                        visible: root.page === "tools" || root.page === "stash"
                        width: 28
                        height: 28
                        radius: 9
                        color: "#F2F4F7"
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            source: Qt.resolvedUrl(root.page === "stash"
                                ? "../assets/icons/lucide-archive.svg"
                                : "../assets/icons/lucide-wrench.svg")
                            sourceSize.width: 48
                            sourceSize.height: 48
                            smooth: true
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: root.page === "stash" ? "APP STASH" : "QUICK TOOLS"
                            color: "#171B21"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                        }

                        Text {
                            text: root.page === "stash"
                                ? "Hidden windows stay running"
                                : "Small things, right when you need them"
                            color: "#89929E"
                            font.pixelSize: 8
                        }
                    }
                }

                Grid {
                    id: toolsGrid
                    visible: root.page === "tools"
                    width: parent.width
                    columns: 2
                    spacing: 8
                    height: 2 * 70 + spacing

                    Repeater {
                        model: root.tools

                        delegate: Rectangle {
                            id: toolTile
                            required property var modelData
                            width: (toolsGrid.width - toolsGrid.spacing) / 2
                            height: 70
                            radius: 11
                            color: toolMouse.containsMouse ? "#F0F2F5" : "#FAFBFC"
                            border.width: 1
                            border.color: toolMouse.containsMouse ? "#DDE3E9" : "#EDF0F3"
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 9
                                anchors.rightMargin: 6
                                spacing: 8

                                Rectangle {
                                    width: 29
                                    height: 29
                                    radius: 9
                                    color: "#F0F3F6"
                                    anchors.verticalCenter: parent.verticalCenter

                                    Image {
                                        anchors.centerIn: parent
                                        width: 17
                                        height: 17
                                        source: Qt.resolvedUrl("../assets/icons/" + toolTile.modelData.icon)
                                        sourceSize.width: 48
                                        sourceSize.height: 48
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                    }
                                }

                                Column {
                                    width: parent.width - 44
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4

                                    Text {
                                        width: parent.width
                                        text: toolTile.modelData.label
                                        color: "#242B34"
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: toolTile.modelData.detail
                                        color: "#8A939E"
                                        font.pixelSize: 7
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }
                                }
                            }

                            MouseArea {
                                id: toolMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toolRequested(toolTile.modelData.id)
                            }
                        }
                    }
                }

                Rectangle {
                    visible: root.page === "tools"
                    width: parent.width
                    height: 44
                    radius: 11
                    color: appStashRowMouse.containsMouse ? "#F0F2F5" : "#FFFFFF"
                    border.width: 1
                    border.color: appStashRowMouse.containsMouse ? "#DDE3E9" : "#E8ECF0"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 9
                        spacing: 9

                        Rectangle {
                            width: 29
                            height: 29
                            radius: 9
                            color: "#F2F4F7"
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                anchors.centerIn: parent
                                width: 17
                                height: 17
                                source: Qt.resolvedUrl("../assets/icons/lucide-archive.svg")
                                sourceSize.width: 48
                                sourceSize.height: 48
                                smooth: true
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Text {
                                text: "App Stash"
                                color: "#222831"
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: root.stashedApps.length === 0
                                    ? "Your hidden apps appear here"
                                    : String(root.stashedApps.length) + (root.stashedApps.length === 1 ? " hidden window" : " hidden windows")
                                color: "#8A939E"
                                font.pixelSize: 7
                            }
                        }

                        Item {
                            width: Math.max(0, parent.width - 29 - 9 - 145 - 55)
                            height: 1
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Ctrl + Super + H"
                            color: "#7B8490"
                            font.pixelSize: 7
                            font.weight: Font.Medium
                        }
                    }

                    MouseArea {
                        id: appStashRowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.appStashRequested()
                    }
                }

                GridView {
                    id: stashGrid
                    visible: root.page === "stash" && root.stashedApps.length > 0
                    width: parent.width
                    height: root.popupHeight - 112
                    clip: true
                    cellWidth: 78
                    cellHeight: 82
                    model: root.stashedApps
                    interactive: contentHeight > height

                    delegate: Item {
                        id: stashTile
                        required property var modelData
                        width: stashGrid.cellWidth
                        height: stashGrid.cellHeight

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 1
                            width: 46
                            height: 46
                            radius: 13
                            color: stashItemMouse.containsMouse ? "#F0F2F5" : "#F7F8FA"
                            border.width: 1
                            border.color: "#E8ECF0"

                            Image {
                                anchors.centerIn: parent
                                width: 29
                                height: 29
                                source: Quickshell.iconPath(
                                    String(stashTile.modelData.icon || "application-x-executable"),
                                    "application-x-executable"
                                )
                                sourceSize.width: 96
                                sourceSize.height: 96
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                                asynchronous: true
                            }

                            MouseArea {
                                id: stashItemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.restoreRequested(String(stashTile.modelData.windowId))
                            }
                        }

                        Text {
                            anchors.top: parent.top
                            anchors.topMargin: 51
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width - 4
                            text: String(stashTile.modelData.appName || stashTile.modelData.title || "Application")
                            color: "#444D58"
                            font.pixelSize: 8
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }
                }

                Item {
                    visible: root.page === "stash" && root.stashedApps.length === 0
                    width: parent.width
                    height: root.popupHeight - 112

                    Column {
                        anchors.centerIn: parent
                        spacing: 10

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 52
                            height: 52
                            radius: 16
                            color: "#F4F6F8"
                            border.width: 1
                            border.color: "#E8ECF0"

                            Image {
                                anchors.centerIn: parent
                                width: 24
                                height: 24
                                source: Qt.resolvedUrl("../assets/icons/lucide-archive.svg")
                                sourceSize.width: 64
                                sourceSize.height: 64
                                smooth: true
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Nothing stashed yet"
                            color: "#252B34"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Press Super + H on an open app."
                            color: "#89929E"
                            font.pixelSize: 9
                        }
                    }
                }

                Text {
                    width: parent.width
                    height: 11
                    text: root.page === "stash"
                        ? "Super + H hides the focused window"
                        : "A16EEN · everyday tools"
                    color: "#9AA3AE"
                    font.pixelSize: 8
                    elide: Text.ElideRight
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible)
            Qt.callLater(() => outsideClick.forceActiveFocus())
    }
}
