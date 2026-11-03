import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../theme" as AdaptiveTheme

Rectangle {
    id: root

    property var player: null

    readonly property bool adaptive: AdaptiveTheme.WallpaperTheme.enabled
        && AdaptiveTheme.WallpaperTheme.paletteReady
    readonly property color cardSurface: adaptive
        ? Qt.rgba(AdaptiveTheme.WallpaperTheme.surface.r, AdaptiveTheme.WallpaperTheme.surface.g, AdaptiveTheme.WallpaperTheme.surface.b, 0.92)
        : "#FFFFFF08"
    readonly property color primaryText: adaptive
        ? AdaptiveTheme.WallpaperTheme.onSurface : "#F5F2EA"
    readonly property color secondaryText: adaptive
        ? AdaptiveTheme.WallpaperTheme.onSurfaceVariant : "#8D94A3"
    readonly property color accent: adaptive
        ? AdaptiveTheme.WallpaperTheme.primary : "#D7B56D"

    Layout.fillWidth: true
    implicitHeight: 116
    radius: 18
    color: root.cardSurface
    border.width: 1
    border.color: adaptive ? AdaptiveTheme.WallpaperTheme.outline : "#FFFFFF10"

    readonly property var activePlayer: {
        const players = Mpris.players.values
        return players.find(player => player.isPlaying) || players[0] || null
    }

    onActivePlayerChanged: player = activePlayer

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Rectangle {
            implicitWidth: 70
            implicitHeight: 70
            radius: 14
            color: root.adaptive ? AdaptiveTheme.WallpaperTheme.primaryContainer : "#D7B56D14"
            clip: true

            Image {
                anchors.fill: parent
                source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                visible: !root.player || !root.player.trackArtUrl
                text: "♪"
                color: root.accent
                font.pixelSize: 28
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Text {
                text: root.player ? (root.player.trackTitle || "Nothing playing") : "No media player"
                color: root.primaryText
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.player ? (root.player.trackArtist || root.player.identity || "Media") : "Start music or video to see it here"
                color: root.secondaryText
                font.pixelSize: 10
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                spacing: 7

                Rectangle {
                    implicitWidth: 29
                    implicitHeight: 24
                    radius: 9
                    color: root.player && root.player.canGoPrevious ? "#FFFFFF0A" : "#FFFFFF04"

                    Text {
                        anchors.centerIn: parent
                        text: "‹"
                        color: root.player && root.player.canGoPrevious ? "#F5F2EA" : "#4E5561"
                        font.pixelSize: 16
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !!root.player && root.player.canGoPrevious
                        onClicked: root.player.previous()
                    }
                }

                Rectangle {
                    implicitWidth: 38
                    implicitHeight: 24
                    radius: 9
                    color: "#D7B56D1C"

                    Text {
                        anchors.centerIn: parent
                        text: root.player && root.player.isPlaying ? "Ⅱ" : "▶"
                        color: "#D7B56D"
                        font.pixelSize: 11
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !!root.player && root.player.canTogglePlaying
                        onClicked: root.player.togglePlaying()
                    }
                }

                Rectangle {
                    implicitWidth: 29
                    implicitHeight: 24
                    radius: 9
                    color: root.player && root.player.canGoNext ? "#FFFFFF0A" : "#FFFFFF04"

                    Text {
                        anchors.centerIn: parent
                        text: "›"
                        color: root.player && root.player.canGoNext ? "#F5F2EA" : "#4E5561"
                        font.pixelSize: 16
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !!root.player && root.player.canGoNext
                        onClicked: root.player.next()
                    }
                }
            }
        }
    }
}
