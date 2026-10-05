import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData

    signal launcherRequested()

    readonly property color dockBackground: "#FFFFFEF8"
    readonly property color dockBorder: "#E5E7EB"
    readonly property color iconColor: "#111827"
    readonly property color hoverBackground: "#F1F3F5"

    readonly property string searchIcon: Qt.resolvedUrl("../assets/icons/search.svg")
    readonly property string terminalIcon: Qt.resolvedUrl("../assets/icons/terminal.svg")
    readonly property string browserIcon: Qt.resolvedUrl("../assets/icons/globe.svg")
    readonly property string filesIcon: Qt.resolvedUrl("../assets/icons/folder.svg")
    readonly property string codeIcon: Qt.resolvedUrl("../assets/icons/code-2.svg")

    screen: modelData
    color: "transparent"
    aboveWindows: true
    exclusiveZone: 0
    implicitWidth: 86

    anchors {
        right: true
        top: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-dock"

    function findApplication(keywords) {
        const apps = DesktopEntries.applications.values || []

        return apps.find(entry => {
            const haystack = [
                entry.name,
                entry.genericName,
                entry.comment,
                ...(entry.keywords || []),
                entry.id
            ].filter(value => value).join(" ").toLowerCase()

            return keywords.some(keyword => haystack.includes(keyword.toLowerCase()))
        }) || null
    }

    function launch(entry, fallbackCommand) {
        try {
            if (entry) {
                entry.execute()
            } else if (fallbackCommand) {
                Quickshell.execDetached(fallbackCommand)
            }
        } catch (error) {
            console.error("A16EEN dock launch failed:", error)
        }
    }

    Rectangle {
        id: dock
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        width: 56
        height: 278
        radius: 22
        color: root.dockBackground
        border.width: 1
        border.color: root.dockBorder

        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: 26
            color: "#18000000"
            z: -1
        }

        Column {
            anchors.centerIn: parent
            spacing: 6

            // Launcher
            Rectangle {
                width: 38
                height: 38
                radius: 13
                color: launcherMouse.containsMouse ? root.hoverBackground : "transparent"

                Image {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: root.searchIcon
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    mipmap: true
                    smooth: true
                }

                MouseArea {
                    id: launcherMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.launcherRequested()
                }

                Rectangle {
                    visible: launcherMouse.containsMouse
                    x: -118
                    anchors.verticalCenter: parent.verticalCenter
                    width: 108
                    height: 30
                    radius: 10
                    color: "#111827"
                    z: 10

                    Text {
                        anchors.centerIn: parent
                        text: "Applications"
                        color: "#FFFFFF"
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                }
            }

            Rectangle {
                width: 26
                height: 1
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.dockBorder
            }

            // Terminal
            Rectangle {
                width: 38
                height: 38
                radius: 13
                color: terminalMouse.containsMouse ? root.hoverBackground : "transparent"

                Image {
                    anchors.centerIn: parent
                    width: 21
                    height: 21
                    source: root.terminalIcon
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    mipmap: true
                    smooth: true
                }

                MouseArea {
                    id: terminalMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.launch(
                        root.findApplication(["foot", "terminal", "console"]),
                        ["foot"]
                    )
                }
            }

            // Browser
            Rectangle {
                id: browserButton
                width: 38
                height: 38
                radius: 13
                color: browserMouse.containsMouse ? root.hoverBackground : "transparent"

                readonly property var browserApp: root.findApplication([
                    "firefox",
                    "mozilla firefox",
                    "chromium",
                    "brave",
                    "google chrome",
                    "microsoft edge",
                    "web browser"
                ])

                Image {
                    id: browserImage
                    anchors.centerIn: parent
                    width: 21
                    height: 21
                    source: browserButton.browserApp && browserButton.browserApp.icon
                        ? Quickshell.iconPath(browserButton.browserApp.icon, "web-browser")
                        : root.browserIcon
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    mipmap: true
                    smooth: true

                    onStatusChanged: {
                        if (status === Image.Error)
                            source = root.browserIcon
                    }
                }

                MouseArea {
                    id: browserMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !!browserButton.browserApp
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.launch(browserButton.browserApp)
                }
            }

            // File manager
            Rectangle {
                id: filesButton
                width: 38
                height: 38
                radius: 13
                color: filesMouse.containsMouse ? root.hoverBackground : "transparent"

                readonly property var filesApp: root.findApplication([
                    "thunar",
                    "nautilus",
                    "dolphin",
                    "pcmanfm",
                    "nemo",
                    "file manager",
                    "files"
                ])

                Image {
                    id: filesImage
                    anchors.centerIn: parent
                    width: 21
                    height: 21
                    source: filesButton.filesApp && filesButton.filesApp.icon
                        ? Quickshell.iconPath(filesButton.filesApp.icon, "folder")
                        : root.filesIcon
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    mipmap: true
                    smooth: true

                    onStatusChanged: {
                        if (status === Image.Error)
                            source = root.filesIcon
                    }
                }

                MouseArea {
                    id: filesMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !!filesButton.filesApp
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.launch(filesButton.filesApp)
                }
            }

            // Code editor
            Rectangle {
                id: codeButton
                width: 38
                height: 38
                radius: 13
                color: codeMouse.containsMouse ? root.hoverBackground : "transparent"

                readonly property var codeApp: root.findApplication([
                    "visual studio code",
                    "code",
                    "vscodium",
                    "zed",
                    "codium"
                ])

                Image {
                    id: codeImage
                    anchors.centerIn: parent
                    width: 21
                    height: 21
                    source: codeButton.codeApp && codeButton.codeApp.icon
                        ? Quickshell.iconPath(codeButton.codeApp.icon, "text-editor")
                        : root.codeIcon
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    mipmap: true
                    smooth: true

                    onStatusChanged: {
                        if (status === Image.Error)
                            source = root.codeIcon
                    }
                }

                MouseArea {
                    id: codeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !!codeButton.codeApp
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.launch(codeButton.codeApp)
                }
            }
        }
    }
}
