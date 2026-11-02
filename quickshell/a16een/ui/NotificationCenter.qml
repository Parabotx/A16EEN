import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.ui

PanelWindow {
    id: root

    PopupCardStyle {
        id: popupCardStyle
        containerId: "quick-hub"
    }

    required property var modelData
    required property string navbarPosition
    property bool opened: false
    property var history: []
    property var completedActionIds: []
    property var repliedIds: []

    signal closeRequested()
    signal clearRequested()
    signal removeRequested(string id)

    readonly property bool horizontalNavbar:
        root.navbarPosition === "top" || root.navbarPosition === "bottom"
    readonly property real screenWidth: root.modelData ? root.modelData.width : 1920
    readonly property real screenHeight: root.modelData ? root.modelData.height : 1080
    readonly property int popupWidth: 378
    readonly property int popupHeight: 510

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

    function appIconSource(entry) {
        const fallback = Quickshell.iconPath("application-x-executable",
            Quickshell.iconPath("dialog-information", "dialog-information"))
        const desktopEntry = String(entry && entry.desktopEntry || "").trim()
        const suppliedIcon = String(entry && entry.appIcon || "").trim()
        const desktopFallback = desktopEntry.length
            ? Quickshell.iconPath(desktopEntry, fallback) : fallback

        if (!suppliedIcon.length)
            return desktopFallback
        if (/^(file|image|qrc|https?):/i.test(suppliedIcon) || suppliedIcon.startsWith("/"))
            return suppliedIcon
        return Quickshell.iconPath(suppliedIcon, desktopFallback)
    }

    function actionWasCompleted(id) {
        return root.completedActionIds.indexOf(String(id)) !== -1
    }

    function replyWasSent(id) {
        return root.repliedIds.indexOf(String(id)) !== -1
    }

    function invokeAction(entry, action) {
        if (!entry || !action || typeof action.invoke !== "function")
            return

        const notification = entry.notificationObject
        const resident = Boolean(notification && notification.resident)
        try {
            action.invoke()
            if (!resident)
                root.completedActionIds = root.completedActionIds.concat([String(entry.id)])
        } catch (error) {
            console.warn("A16EEN could not invoke a notification action:", error)
        }
    }

    function sendInlineReply(entry, replyText) {
        const message = String(replyText || "").trim()
        if (!entry || !entry.notificationObject || !entry.hasInlineReply || !message.length)
            return
        try {
            entry.notificationObject.sendInlineReply(message)
            root.repliedIds = root.repliedIds.concat([String(entry.id)])
        } catch (error) {
            console.warn("A16EEN could not send an inline notification reply:", error)
        }
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
            radius: 17
            color: popupCardStyle.backgroundColor
            border.width: 1
            border.color: popupCardStyle.borderColor
            Behavior on color { ColorAnimation { duration: 135; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 135; easing.type: Easing.OutCubic } }

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
                id: content
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8
                z: 1

                Row {
                    width: parent.width
                    height: 27
                    spacing: 8

                    NavbarIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 17
                        height: 17
                        iconName: "lucide-bell.svg"
                        iconColor: popupCardStyle.iconColor
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            text: "NOTIFICATIONS"
                            color: popupCardStyle.textColor
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                        }

                        Text {
                            text: String(root.history.length) + " saved on this device"
                            color: popupCardStyle.mutedTextColor
                            font.pixelSize: 8
                        }
                    }

                    Item { width: Math.max(0, content.width - 214); height: 1 }

                    Text {
                        text: "CLEAR"
                        color: clearMouse.containsMouse ? popupCardStyle.textColor : popupCardStyle.mutedTextColor
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.history.length > 0

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            anchors.margins: -7
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.clearRequested()
                        }
                    }
                }

                NotificationMediaCard {
                    id: mediaCard
                    width: parent.width
                }

                Row {
                    width: parent.width
                    height: 14
                    spacing: 6

                    Text {
                        text: "RECENT ACTIVITY"
                        color: popupCardStyle.mutedTextColor
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.7
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        width: 20
                        height: 14
                        radius: 7
                        color: popupCardStyle.subtleSurfaceColor
                        visible: root.history.length > 0
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: String(root.history.length)
                            color: popupCardStyle.secondaryTextColor
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: Math.max(72, parent.height - 27 - mediaCard.height - 14
                        - 10 - content.spacing * 4)

                    ListView {
                        id: historyList
                        anchors.fill: parent
                        clip: true
                        spacing: 6
                        model: root.history
                        visible: root.history.length > 0
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Rectangle {
                            id: historyRow
                            required property var modelData
                            width: historyList.width
                            readonly property int actionCount:
                                modelData.actions && typeof modelData.actions.length === "number"
                                    ? modelData.actions.length : 0
                            readonly property bool showActions:
                                actionCount > 0 && !root.actionWasCompleted(modelData.id)
                            readonly property bool showReply:
                                Boolean(modelData.hasInlineReply && modelData.notificationObject)
                                    && !root.replyWasSent(modelData.id)
                            height: 51 + (showActions ? 25 : 0) + (showReply ? 29 : 0)
                            radius: 10
                            color: historyRowMouse.containsMouse
                                ? popupCardStyle.hoverSurfaceColor : popupCardStyle.fieldColor
                            border.width: 1
                            border.color: popupCardStyle.fieldBorderColor

                            MouseArea {
                                id: historyRowMouse
                                anchors.fill: parent
                                z: 0
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }

                            Column {
                                anchors.fill: parent
                                anchors.margins: 7
                                spacing: 4
                                z: 1

                                Row {
                                    width: parent.width
                                    height: 37
                                    spacing: 8

                                    Rectangle {
                                        width: 30
                                        height: 30
                                        radius: 8
                                        color: popupCardStyle.subtleSurfaceColor
                                        anchors.verticalCenter: parent.verticalCenter
                                        clip: true

                                        IconImage {
                                            anchors.centerIn: parent
                                            width: 19
                                            height: 19
                                            source: root.appIconSource(historyRow.modelData)
                                        }
                                    }

                                    Column {
                                        width: parent.width - 67
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2

                                        Row {
                                            width: parent.width
                                            height: 11
                                            spacing: 4

                                            Text {
                                                width: parent.width - 34
                                                text: String(historyRow.modelData.appName || "Notification")
                                                color: popupCardStyle.mutedTextColor
                                                font.pixelSize: 8
                                                elide: Text.ElideRight
                                                verticalAlignment: Text.AlignVCenter
                                            }

                                            Text {
                                                width: 30
                                                text: root.ageLabel(historyRow.modelData.timestamp)
                                                color: popupCardStyle.mutedTextColor
                                                font.pixelSize: 8
                                                horizontalAlignment: Text.AlignRight
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                        }

                                        Text {
                                            width: parent.width
                                            text: root.previewText(historyRow.modelData.summary || "Notification")
                                            color: popupCardStyle.textColor
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            width: parent.width
                                            text: root.previewText(historyRow.modelData.body)
                                            color: popupCardStyle.secondaryTextColor
                                            font.pixelSize: 8
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                            visible: text.length > 0
                                        }
                                    }

                                    Text {
                                        width: 13
                                        height: parent.height
                                        text: "×"
                                        color: removeMouse.containsMouse
                                            ? popupCardStyle.textColor : popupCardStyle.mutedTextColor
                                        font.pixelSize: 15
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter

                                        MouseArea {
                                            id: removeMouse
                                            anchors.fill: parent
                                            anchors.margins: -4
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                mouse.accepted = true
                                                root.removeRequested(String(historyRow.modelData.id))
                                            }
                                        }
                                    }
                                }

                                Row {
                                    width: parent.width
                                    height: 22
                                    spacing: 5
                                    visible: historyRow.showActions

                                    Repeater {
                                        model: historyRow.modelData.actions || []

                                        delegate: Rectangle {
                                            id: actionButton
                                            required property var modelData
                                            width: Math.min(112, Math.max(52,
                                                String(modelData.text || "Open").length * 6 + 20))
                                            height: 22
                                            radius: 7
                                            color: actionMouse.containsMouse
                                                ? popupCardStyle.selectedSurfaceColor
                                                : popupCardStyle.subtleSurfaceColor
                                            border.width: 1
                                            border.color: popupCardStyle.fieldBorderColor

                                            Text {
                                                anchors.fill: parent
                                                anchors.leftMargin: 7
                                                anchors.rightMargin: 7
                                                text: String(actionButton.modelData.text || "Open")
                                                color: popupCardStyle.textColor
                                                font.pixelSize: 8
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }

                                            MouseArea {
                                                id: actionMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.invokeAction(historyRow.modelData, actionButton.modelData)
                                            }
                                        }
                                    }
                                }

                                Row {
                                    width: parent.width
                                    height: 25
                                    spacing: 5
                                    visible: historyRow.showReply

                                    Rectangle {
                                        width: parent.width - 49
                                        height: 25
                                        radius: 7
                                        color: popupCardStyle.subtleSurfaceColor
                                        border.width: 1
                                        border.color: replyInput.activeFocus
                                            ? popupCardStyle.focusBorderColor : popupCardStyle.fieldBorderColor

                                        Text {
                                            anchors.fill: parent
                                            anchors.leftMargin: 7
                                            verticalAlignment: Text.AlignVCenter
                                            text: String(historyRow.modelData.inlineReplyPlaceholder || "Write a reply…")
                                            color: popupCardStyle.mutedTextColor
                                            font.pixelSize: 8
                                            visible: replyInput.text.length === 0
                                        }

                                        TextInput {
                                            id: replyInput
                                            anchors.fill: parent
                                            anchors.leftMargin: 7
                                            anchors.rightMargin: 6
                                            verticalAlignment: TextInput.AlignVCenter
                                            color: popupCardStyle.textColor
                                            selectionColor: popupCardStyle.selectedSurfaceColor
                                            selectedTextColor: popupCardStyle.textColor
                                            font.pixelSize: 9
                                            clip: true
                                            Keys.onReturnPressed: {
                                                root.sendInlineReply(historyRow.modelData, text)
                                                text = ""
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: 44
                                        height: 25
                                        radius: 7
                                        color: sendMouse.containsMouse
                                            ? popupCardStyle.actionHoverColor : popupCardStyle.actionColor

                                        Text {
                                            anchors.centerIn: parent
                                            text: "SEND"
                                            color: popupCardStyle.actionTextColor
                                            font.pixelSize: 8
                                            font.weight: Font.DemiBold
                                        }

                                        MouseArea {
                                            id: sendMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.sendInlineReply(historyRow.modelData, replyInput.text)
                                                replyInput.text = ""
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 5
                        visible: root.history.length === 0

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "You're all caught up"
                            color: popupCardStyle.secondaryTextColor
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "New notifications will appear here"
                            color: popupCardStyle.mutedTextColor
                            font.pixelSize: 8
                        }
                    }
                }

                Text {
                    width: parent.width
                    height: 10
                    text: "Stored locally · latest 60 notifications"
                    color: popupCardStyle.mutedTextColor
                    font.pixelSize: 8
                }
            }
        }
    }
}
