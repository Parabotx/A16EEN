import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.ui

Rectangle {
    id: root

    property string selectedPlayerKey: ""
    readonly property var players: Mpris.players.values
    readonly property var player: {
        const connected = root.players || []
        if (root.selectedPlayerKey.length) {
            const selected = connected.find(item => String(item.dbusName || item.identity || "") === root.selectedPlayerKey)
            if (selected)
                return selected
        }
        return connected.find(item => item.isPlaying)
            || connected.find(item => String(item.trackTitle || "").length > 0)
            || null
    }
    readonly property bool hasMedia: root.player !== null
        && (Boolean(root.player.isPlaying) || String(root.player.trackTitle || "").length > 0)

    width: parent ? parent.width : 0
    height: root.hasMedia ? 105 : 0
    visible: root.hasMedia
    radius: 12
    color: popupCardStyle.subtleSurfaceColor
    border.width: 1
    border.color: popupCardStyle.fieldBorderColor
    clip: true

    PopupCardStyle {
        id: popupCardStyle
        containerId: "quick-hub"
    }

    function playerKey(value) {
        return String(value && (value.dbusName || value.identity) || "")
    }

    function cyclePlayer() {
        const connected = root.players || []
        if (connected.length < 2)
            return
        const currentKey = root.playerKey(root.player)
        let currentIndex = connected.findIndex(item => root.playerKey(item) === currentKey)
        if (currentIndex < 0)
            currentIndex = 0
        const next = connected[(currentIndex + 1) % connected.length]
        root.selectedPlayerKey = root.playerKey(next)
    }

    function formatTime(seconds) {
        const value = Math.max(0, Math.floor(Number(seconds) || 0))
        const minutes = Math.floor(value / 60)
        const remaining = value % 60
        return minutes + ":" + (remaining < 10 ? "0" : "") + remaining
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.player !== null && root.player.isPlaying && root.player.positionSupported
        onTriggered: {
            if (root.player)
                root.player.positionChanged()
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 9
        spacing: 9

        Rectangle {
            Layout.preferredWidth: 68
            Layout.preferredHeight: 68
            Layout.alignment: Qt.AlignVCenter
            radius: 9
            color: popupCardStyle.fieldColor
            border.width: 1
            border.color: popupCardStyle.fieldBorderColor
            clip: true

            Image {
                anchors.fill: parent
                source: root.player ? String(root.player.trackArtUrl || "") : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }

            NavbarIcon {
                anchors.centerIn: parent
                width: 25
                height: 25
                iconName: "music.svg"
                iconColor: popupCardStyle.iconColor
                visible: !root.player || !root.player.trackArtUrl
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                spacing: 5

                Text {
                    text: "NOW PLAYING"
                    color: popupCardStyle.mutedTextColor
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.8
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.player ? String(root.player.identity || root.player.desktopEntry || "Media") : ""
                    color: popupCardStyle.secondaryTextColor
                    font.pixelSize: 8
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    Layout.maximumWidth: 92
                }

                Text {
                    text: "↗"
                    visible: root.player && root.player.canRaise
                    color: popupCardStyle.mutedTextColor
                    font.pixelSize: 10

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.player && root.player.canRaise)
                                root.player.raise()
                        }
                    }
                }

                Text {
                    text: "›"
                    visible: root.players && root.players.length > 1
                    color: popupCardStyle.mutedTextColor
                    font.pixelSize: 15

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -5
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cyclePlayer()
                    }
                }
            }

            Text {
                text: root.player ? String(root.player.trackTitle || "Media playing") : ""
                color: popupCardStyle.textColor
                font.pixelSize: 10
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.player
                    ? String(root.player.trackArtist || root.player.trackAlbum || "Unknown artist")
                    : ""
                color: popupCardStyle.secondaryTextColor
                font.pixelSize: 8
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 22
                    radius: 7
                    color: root.player && root.player.canGoPrevious
                        ? popupCardStyle.fieldColor : popupCardStyle.subtleSurfaceColor
                    opacity: root.player && root.player.canGoPrevious ? 1 : 0.42

                    NavbarIcon {
                        anchors.centerIn: parent
                        width: 12
                        height: 12
                        iconPath: Qt.resolvedUrl("../assets/icons/music-skip-back.svg")
                        iconColor: popupCardStyle.iconColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.player && root.player.canGoPrevious
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.player.previous()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 29
                    Layout.preferredHeight: 22
                    radius: 7
                    color: popupCardStyle.selectedSurfaceColor

                    NavbarIcon {
                        anchors.centerIn: parent
                        width: 13
                        height: 13
                        iconPath: root.player && root.player.isPlaying
                            ? Qt.resolvedUrl("../assets/icons/music-pause.svg")
                            : Qt.resolvedUrl("../assets/icons/music-play.svg")
                        iconColor: popupCardStyle.iconColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.player && root.player.canTogglePlaying
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.player.togglePlaying()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 22
                    radius: 7
                    color: root.player && root.player.canGoNext
                        ? popupCardStyle.fieldColor : popupCardStyle.subtleSurfaceColor
                    opacity: root.player && root.player.canGoNext ? 1 : 0.42

                    NavbarIcon {
                        anchors.centerIn: parent
                        width: 12
                        height: 12
                        iconPath: Qt.resolvedUrl("../assets/icons/music-skip-forward.svg")
                        iconColor: popupCardStyle.iconColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.player && root.player.canGoNext
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.player.next()
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.player && root.player.positionSupported
                        ? root.formatTime(root.player.position) + " / " + root.formatTime(root.player.length)
                        : (root.player && root.player.isPlaying ? "Playing" : "Paused")
                    color: popupCardStyle.mutedTextColor
                    font.pixelSize: 7
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
