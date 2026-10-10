import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: root

    required property var modelData
    required property string navbarPosition
    property bool opened: false
    property var history: []
    property string searchText: ""

    signal closeRequested()
    signal clearRequested()
    signal removeRequested(string id)

    readonly property bool horizontalNavbar:
        root.navbarPosition === "top" || root.navbarPosition === "bottom"
    readonly property real screenWidth: root.modelData ? root.modelData.width : 1920
    readonly property real screenHeight: root.modelData ? root.modelData.height : 1080
    readonly property int popupWidth: 338
    readonly property int popupHeight: 390
    readonly property var filteredHistory: {
        const needle = String(root.searchText || "").trim().toLowerCase()
        const items = Array.isArray(root.history) ? root.history : []
        if (!needle)
            return items
        return items.filter(item =>
            String(item.appName || "").toLowerCase().includes(needle)
            || String(item.summary || "").toLowerCase().includes(needle)
            || String(item.body || "").toLowerCase().includes(needle))
    }

    function ageLabel(timestamp) {
        const minutes = Math.max(0, Math.floor((Date.now() - Number(timestamp || 0)) / 60000))
        if (minutes < 1)
            return "now"
        if (minutes < 60)
            return String(minutes) + "m"
        const hours = Math.floor(minutes / 60)
        if (hours < 24)
            return String(hours) + "h"
        const days = Math.floor(hours / 24)
        return days < 2 ? "1d" : String(days) + "d"
    }

    function previewText(value) {
        return String(value || "").replace(/\s+/g, " ").trim()
    }

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

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-notification-center"
    WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

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
            + (root.opened ? 0 : 6)
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
            radius: 16
            color: "#FFFFFF"
            border.width: 1
            border.color: "#D9DEE5"

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
                onClicked: mouse.accepted = true
            }

            Column {
                id: content
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8
                z: 1

                Row {
                    width: parent.width
                    height: 25
                    spacing: 8

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        source: Qt.resolvedUrl("../assets/icons/lucide-bell.svg")
                        sourceSize.width: 32
                        sourceSize.height: 32
                        smooth: true
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            text: "NOTIFICATIONS"
                            color: "#171B21"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                        }

                        Text {
                            text: String(root.history.length) + " saved"
                            color: "#89929E"
                            font.pixelSize: 8
                        }
                    }

                    Item { width: Math.max(0, content.width - 205); height: 1 }

                    Text {
                        text: "CLEAR"
                        color: clearMouse.containsMouse ? "#111318" : "#7C8692"
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.history.length > 0

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.clearRequested()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 30
                    radius: 9
                    color: "#F7F8FA"
                    border.width: 1
                    border.color: searchInput.activeFocus ? "#BBC4CE" : "#E5E9ED"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 9
                        anchors.rightMargin: 8
                        spacing: 7

                        Image {
                            width: 13
                            height: 13
                            anchors.verticalCenter: parent.verticalCenter
                            source: Qt.resolvedUrl("../assets/icons/search.svg")
                            sourceSize.width: 26
                            sourceSize.height: 26
                            smooth: true
                        }

                        Item {
                            width: parent.width - 24
                            height: parent.height

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Search notifications"
                                color: "#9AA3AE"
                                font.pixelSize: 10
                                visible: searchInput.text.length === 0
                            }

                            TextInput {
                                id: searchInput
                                anchors.fill: parent
                                verticalAlignment: TextInput.AlignVCenter
                                text: root.searchText
                                onTextChanged: root.searchText = text
                                color: "#222831"
                                selectionColor: "#DDE5EF"
                                selectedTextColor: "#111318"
                                font.pixelSize: 10
                                clip: true
                                activeFocusOnTab: true
                                Keys.onEscapePressed: root.closeRequested()
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: Math.max(0, parent.height - 25 - 30 - 18 - content.spacing * 3)

                    ListView {
                        id: historyList
                        anchors.fill: parent
                        clip: true
                        spacing: 5
                        model: root.filteredHistory
                        visible: root.filteredHistory.length > 0
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Rectangle {
                            id: historyRow
                            required property var modelData
                            width: historyList.width
                            height: 58
                            radius: 9
                            color: historyRowMouse.containsMouse ? "#F0F2F5" : "#FAFBFC"
                            border.width: 1
                            border.color: historyRowMouse.containsMouse ? "#E1E6EB" : "#F0F2F5"

                            Row {
                                anchors.fill: parent
                                anchors.margins: 7
                                spacing: 7

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 8
                                    color: "#F0F3F6"
                                    anchors.verticalCenter: parent.verticalCenter

                                    IconImage {
                                        anchors.centerIn: parent
                                        width: 18
                                        height: 18
                                        source: historyRow.modelData.appIcon
                                            ? historyRow.modelData.appIcon
                                            : Quickshell.iconPath("dialog-information", "dialog-information")
                                    }
                                }

                                Column {
                                    width: parent.width - 62
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 3

                                    Row {
                                        width: parent.width
                                        height: 12
                                        spacing: 4

                                        Text {
                                            width: parent.width - 34
                                            text: String(historyRow.modelData.appName || "Notification")
                                            color: "#7D8793"
                                            font.pixelSize: 8
                                            elide: Text.ElideRight
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        Text {
                                            width: 30
                                            text: root.ageLabel(historyRow.modelData.timestamp)
                                            color: "#9AA3AE"
                                            font.pixelSize: 8
                                            horizontalAlignment: Text.AlignRight
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }

                                    Text {
                                        width: parent.width
                                        text: root.previewText(historyRow.modelData.summary || "Notification")
                                        color: "#212831"
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: root.previewText(historyRow.modelData.body)
                                        color: "#7D8793"
                                        font.pixelSize: 8
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }
                                }

                                Text {
                                    width: 13
                                    height: parent.height
                                    text: "×"
                                    color: removeMouse.containsMouse ? "#242B34" : "#A0A8B2"
                                    font.pixelSize: 14
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter

                                    MouseArea {
                                        id: removeMouse
                                        anchors.fill: parent
                                        anchors.margins: -3
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            mouse.accepted = true
                                            root.removeRequested(String(historyRow.modelData.id))
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: historyRowMouse
                                anchors.fill: parent
                                z: -1
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 5
                        visible: root.filteredHistory.length === 0

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.searchText.trim().length
                                ? "No matching notifications"
                                : "You're all caught up"
                            color: "#56616F"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.searchText.trim().length
                                ? "Try a different search"
                                : "New notifications will appear here"
                            color: "#99A2AD"
                            font.pixelSize: 8
                        }
                    }
                }

                Text {
                    width: parent.width
                    height: 10
                    text: "Stored on this device"
                    color: "#98A1AC"
                    font.pixelSize: 8
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            root.searchText = ""
            Qt.callLater(() => searchInput.forceActiveFocus())
        }
    }
}
