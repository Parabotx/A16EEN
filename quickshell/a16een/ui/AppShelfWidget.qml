import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool widgetEnabled: false
    property var apps: []
    property string shape: "capsule"
    property string navbarPosition: "right"
    property string hoveredDesktopId: ""

    readonly property int bottomGap: root.navbarPosition === "bottom" ? 84 : 34
    readonly property int shelfWidth: root.modelData
        ? Math.min(Math.max(root.activeApps.length > 0 ? root.activeApps.length * 39 + 22 : 166,
            root.activeApps.length > 0 ? 58 : 150), Math.max(150, root.modelData.width - 24))
        : 200
    readonly property int shelfRadius: root.shape === "capsule" ? 24
        : root.shape === "rounded" ? 12 : 7
    readonly property var activeApps: {
        const catalog = [...DesktopEntries.applications.values]
        const resolved = []
        for (const saved of root.apps) {
            const desktopId = String(saved.desktopId || "")
            const entry = catalog.find(app => String(app.id || "") === desktopId)
            if (!entry || entry.noDisplay)
                continue
            resolved.push({
                desktopId: desktopId,
                name: String(entry.name || saved.name || "Application"),
                icon: String(entry.icon || saved.icon || ""),
                entry: entry
            })
        }
        return resolved.slice(0, 16)
    }

    screen: modelData
    color: "transparent"
    visible: root.widgetEnabled && root.modelData !== null
    aboveWindows: false
    exclusiveZone: 0
    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    mask: Region { item: shelfCard }
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "a16een-widget-app-shelf"

    Rectangle {
        id: shelfCard
        width: root.shelfWidth
        height: root.activeApps.length ? 48 : 38
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bottomGap
        radius: root.shelfRadius
        color: "#D911151D"
        border.width: 1
        border.color: "#35FFFFFF"
        clip: false

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(4, root.shelfRadius - 1)
            color: "transparent"
            border.width: 1
            border.color: "#0FFFFFFF"
        }

        Row {
            anchors.centerIn: parent
            spacing: 3
            visible: root.activeApps.length > 0

            Repeater {
                model: root.activeApps

                delegate: Item {
                    required property var modelData
                    width: 36
                    height: 36

                    Rectangle {
                        id: appTile
                        anchors.centerIn: parent
                        width: 32
                        height: 32
                        radius: root.shape === "capsule" ? 12
                            : root.shape === "rounded" ? 8 : 4
                        color: appMouse.containsMouse ? "#28FFFFFF" : "transparent"
                        border.width: appMouse.containsMouse ? 1 : 0
                        border.color: "#28FFFFFF"

                        Image {
                            anchors.centerIn: parent
                            width: 21
                            height: 21
                            source: modelData.icon.length
                                ? Quickshell.iconPath(modelData.icon, "application-x-executable")
                                : Quickshell.iconPath("application-x-executable", "application-x-executable")
                            sourceSize.width: 64
                            sourceSize.height: 64
                            asynchronous: true
                            cache: true
                            smooth: true
                            fillMode: Image.PreserveAspectFit
                        }

                        MouseArea {
                            id: appMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.hoveredDesktopId = modelData.desktopId
                            onExited: root.hoveredDesktopId = ""
                            onClicked: {
                                try {
                                    modelData.entry.execute()
                                } catch (error) {
                                    console.error("A16EEN App Shelf could not launch " + modelData.name + ":", error)
                                }
                            }
                        }
                    }

remove permanent labels under icons                    Rectangle {
                        visible: root.hoveredDesktopId === modelData.desktopId
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.top
                        anchors.bottomMargin: 6
                        width: Math.min(150, Math.max(64, hoverLabel.implicitWidth + 18))
                        height: 25
                        radius: 7
                        color: "#F20D1118"
                        border.width: 1
                        border.color: "#35FFFFFF"
                        z: 10

                        Text {
                            id: hoverLabel
                            anchors.centerIn: parent
                            text: modelData.name
                            color: "#F1F4F7"
                            font.family: "Inter"
                            font.pixelSize: 9
                            elide: Text.ElideRight
                            width: parent.width - 12
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 8
            visible: root.activeApps.length === 0

            Image {
                width: 15
                height: 15
                anchors.verticalCenter: parent.verticalCenter
                source: Qt.resolvedUrl("../assets/icons/lucide-app-window.svg")
                sourceSize.width: 30
                sourceSize.height: 30
                smooth: true
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "PIN APPS IN WIDGETS"
                color: "#CAD2DD"
                font.family: "Inter"
                font.pixelSize: 8
                font.weight: Font.DemiBold
                font.letterSpacing: 0.7
            }
        }
    }
}
