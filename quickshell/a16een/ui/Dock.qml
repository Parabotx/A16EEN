import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: root

    required property var modelData

    signal launcherRequested()

    readonly property color dockBackground: "#FFFFFEF8"
    readonly property color dockBorder: "#E5E7EB"
    readonly property color iconPrimary: "#111827"
    readonly property color iconMuted: "#4B5563"
    readonly property color hoverBackground: "#F1F3F5"
    readonly property color activeBackground: "#111827"

    readonly property string searchIcon: Qt.resolvedUrl("../assets/icons/search.svg")
    readonly property string terminalFallbackIcon: Qt.resolvedUrl("../assets/icons/terminal.svg")
    readonly property string browserFallbackIcon: Qt.resolvedUrl("../assets/icons/globe.svg")
    readonly property string filesFallbackIcon: Qt.resolvedUrl("../assets/icons/folder.svg")
    readonly property string codeFallbackIcon: Qt.resolvedUrl("../assets/icons/code-2.svg")

    screen: modelData
    color: "transparent"
    aboveWindows: true
    exclusiveZone: 0
    implicitWidth: 96

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

    function applicationIcon(entry, fallback) {
        if (!entry || !entry.icon) return fallback

        try {
            return Quickshell.iconPath(entry.icon, "application-x-executable")
        } catch (error) {
            return fallback
        }
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
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 18

        width: 68
        height: 278
        radius: 26

        color: root.dockBackground
        border.width: 1
        border.color: root.dockBorder

        // Subtle floating shadow.
        Rectangle {
            anchors.fill: parent
            anchors.margins: -5
            radius: 31
            color: "#16000000"
            z: -1
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 8

            DockIconButton {
                tooltip: "Applications"
                iconSource: root.searchIcon
                dark: true
                onClicked: root.launcherRequested()
            }

            Separator {}

            DockAppButton {
                tooltip: "Terminal"
                app: root.findApplication(["foot", "terminal", "console"])
                fallbackIcon: root.terminalFallbackIcon
                fallbackCommand: ["foot"]
                onLaunchRequested: root.launch(app, fallbackCommand)
            }

            DockAppButton {
                tooltip: "Web browser"
                app: root.findApplication([
                    "firefox",
                    "mozilla firefox",
                    "chromium",
                    "brave",
                    "google chrome",
                    "microsoft edge"
                ])
                fallbackIcon: root.browserFallbackIcon
                onLaunchRequested: if (app) root.launch(app)
            }

            DockAppButton {
                tooltip: "Files"
                app: root.findApplication([
                    "thunar",
                    "nautilus",
                    "dolphin",
                    "pcmanfm",
                    "file manager"
                ])
                fallbackIcon: root.filesFallbackIcon
                onLaunchRequested: if (app) root.launch(app)
            }

            DockAppButton {
                tooltip: "Code editor"
                app: root.findApplication([
                    "visual studio code",
                    "code",
                    "vscodium",
                    "zed",
                    "codium"
                ])
                fallbackIcon: root.codeFallbackIcon
                onLaunchRequested: if (app) root.launch(app)
            }
        }
    }

    component Separator: Rectangle {
        Layout.alignment: Qt.AlignHCenter
        width: 28
        height: 1
        color: "#E5E7EB"
    }

    component DockIconButton: Rectangle {
        property string tooltip: ""
        property string iconSource: ""
        property bool dark: false

        signal clicked()

        Layout.alignment: Qt.AlignHCenter
        width: 46
        height: 46
        radius: 15

        color: dark
            ? root.activeBackground
            : (hover.containsMouse ? root.hoverBackground : "transparent")

        border.width: dark ? 0 : (hover.containsMouse ? 1 : 0)
        border.color: root.dockBorder

        Behavior on color {
            ColorAnimation { duration: 110 }
        }

        Image {
            anchors.centerIn: parent
            width: 21
            height: 21
            source: parent.iconSource
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            asynchronous: true
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }

        DockTooltip {
            visible: hover.containsMouse
            text: parent.tooltip
        }
    }

    component DockAppButton: Rectangle {
        property string tooltip: ""
        property var app: null
        property string fallbackIcon: ""
        property list<string> fallbackCommand: []

        signal launchRequested()

        Layout.alignment: Qt.AlignHCenter
        width: 46
        height: 46
        radius: 15

        color: hover.containsMouse ? root.hoverBackground : "transparent"
        border.width: hover.containsMouse ? 1 : 0
        border.color: root.dockBorder

        opacity: app ? 1.0 : 0.42

        Behavior on color {
            ColorAnimation { duration: 110 }
        }

        IconImage {
            anchors.centerIn: parent
            width: 22
            height: 22
            source: app
                ? root.applicationIcon(app, fallbackIcon)
                : fallbackIcon
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            enabled: !!app || fallbackCommand.length > 0
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: parent.launchRequested()
        }

        DockTooltip {
            visible: hover.containsMouse
            text: parent.tooltip
        }
    }

    component DockTooltip: Rectangle {
        property string text: ""

        x: parent.width + 10
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(150, label.implicitWidth + 22)
        height: 30
        radius: 10
        color: "#111827"
        border.width: 1
        border.color: "#1F2937"
        z: 30

        Text {
            id: label
            anchors.centerIn: parent
            text: parent.text
            color: "#FFFFFF"
            font.pixelSize: 9
            font.weight: Font.DemiBold
        }
    }
}
