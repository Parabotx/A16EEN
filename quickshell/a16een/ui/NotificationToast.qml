import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.ui

PanelWindow {
    id: root

    PopupCardStyle {
        id: popupCardStyle
        containerId: "quick-hub"
    }

    required property var modelData
    property var notification: null

    function appIconSource() {
        const fallback = Quickshell.iconPath("application-x-executable",
            Quickshell.iconPath("dialog-information", "dialog-information"))
        const desktopEntry = String(root.notification && root.notification.desktopEntry || "").trim()
        const suppliedIcon = String(root.notification && root.notification.appIcon || "").trim()
        const desktopFallback = desktopEntry.length ? Quickshell.iconPath(desktopEntry, fallback) : fallback
        if (!suppliedIcon.length)
            return desktopFallback
        if (/^(file|image|qrc|https?):/i.test(suppliedIcon) || suppliedIcon.startsWith("/"))
            return suppliedIcon
        return Quickshell.iconPath(suppliedIcon, desktopFallback)
    }

    screen: modelData
    color: "transparent"
    visible: notification !== null

    anchors {
        top: true
        right: true
    }

    margins {
        top: 72
        right: 14
    }

    implicitWidth: 322
    implicitHeight: 78

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: popupCardStyle.backgroundColor
        border.width: 1
        border.color: popupCardStyle.borderColor

        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: 18
            color: "#16000000"
            z: -1
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 9

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                Layout.alignment: Qt.AlignTop
                radius: 8
                color: popupCardStyle.subtleSurfaceColor

                IconImage {
                    anchors.centerIn: parent
                    implicitWidth: 19
                    implicitHeight: 19
                    source: root.appIconSource()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: root.notification ? (root.notification.appName || "Notification") : ""
                    color: popupCardStyle.mutedTextColor
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: root.notification ? (root.notification.summary || "Notification") : ""
                    color: popupCardStyle.textColor
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: root.notification ? (root.notification.body || "") : ""
                    color: popupCardStyle.secondaryTextColor
                    font.pixelSize: 9
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    Layout.fillWidth: true
                }
            }
        }
    }
}
