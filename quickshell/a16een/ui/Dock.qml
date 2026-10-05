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
    readonly property color activeBackground: "#111827"

    readonly property string searchIcon: Qt.resolvedUrl("../assets/icons/search.svg")
    readonly property string terminalIcon: Qt.resolvedUrl("../assets/icons/terminal.svg")
    readonly property string browserIcon: Qt.resolvedUrl("../assets/icons/globe.svg")
    readonly property string filesIcon: Qt.resolvedUrl("../assets/icons/folder.svg")
    readonly property string codeIcon: Qt.resolvedUrl("../assets/icons/code-2.svg")

    screen: modelData
    color: "transparent"
    aboveWindows: true
    exclusiveZone: 0
    implicitWidth: 100

    anchors {
        left: true
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
                ...(entry.keywords || [])
            ].filter(value => value).join(" ").toLowerCase()

            return keywords.some(keyword => haystack.includes(keyword))
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
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.verticalCenter: parent.verticalCenter

        width: 68
        height: 278
        radius: 26
        color: root.dockBackground
        border.width: 1
        border.color: root.dockBorder

        Rectangle {
            anchors.fill: parent
            anchors.margins: -5
            radius: 31
            color: "#18000000"
            z: -1
        }

        Column {
            anchors.centerIn: parent
            spacing: 8

            // Launcher
            Rectangle {
                width: 46
                height: 46
                radius: 15
                color: launcherMouse.containsMouse ? root.hoverBackground : root.activeBackground

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
                    x: parent.width + 10
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
                width: 28
                height: 1
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.dockBorder
            }

            // Terminal
            Rectangle {
                width: 46
                height: 46
                radius: 15
                color: terminalMouse.containsMouse ? root.hoverBackground : "transparent"

                Image {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
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
                width: 46
                height: 46
                radius: 15
                color: browserMouse.containsMouse ? root.hoverBackground : "transparent"
                opacity: browserApp ? 1.0 : 0.38

                readonly property var browserApp: root.findApplication([
                    "firefox",
                    "mozilla firefox",
                    "chromium",
                    "brave",
                    "google chrome",
                    "microsoft edge"
                ])

                Image {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    source: browserApp && browserApp.icon
                        ? Quickshell.iconPath(browserApp.icon, "web-browser")
                        : root.browserIcon
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    mipmap: true
                    smooth: true
                }

                MouseArea {
                    id: browserMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !!parent.browserApp
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.launch(parent.browserApp)
                }
            }

            // File manager
            Rectangle {
                width: 46
                height: 46
                radius: 15
                color: filesMouse.containsMouse ? root.hoverBackground : "transparent"
                opacity: filesApp ? 1.0 : 0.38

                readonly property var filesApp: root.findApplication([
                    "thunar",
                    "nautilus",
                    "dolphin",
                    "pcmanfm",
                    "file manager"
                ])

                Image {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    source: filesApp && filesApp.icon
                        ? Quickshell.iconPath(filesApp.icon, "folder")
                        : root.filesIcon
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    mipmap: true
                    smooth: true
                }

                MouseArea {
                    id: filesMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !!parent.filesApp
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.launch(parent.filesApp)
                }
            }

            // Code editor
            Rectangle {
                width: 46
                height: 46
                radius: 15
                color: codeMouse.containsMouse ? root.hoverBackground : "transparent"
                opacity: codeApp ? 1.0 : 0.38

                readonly property var codeApp: root.findApplication([
                    "visual studio code",
                    "code",
                    "vscodium",
                    "zed",
                    "codium"
                ])

                Image {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    source: codeApp && codeApp.icon
                        ? Quickshell.iconPath(codeApp.icon, "text-editor")
                        : root.codeIcon
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    mipmap: true
                    smooth: true
                }

                MouseArea {
                    id: codeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !!parent.codeApp
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.launch(parent.codeApp)
                }
            }
        }
    }
}
