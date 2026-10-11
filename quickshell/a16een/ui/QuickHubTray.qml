import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    required property string navbarPosition
    required property bool dockVisible
    property int unreadCount: 0
    property bool notificationsOpen: false
    property bool toolsOpen: false

    signal notificationsRequested()
    signal toolsRequested()

    readonly property bool horizontalNavbar:
        root.navbarPosition === "top" || root.navbarPosition === "bottom"

    property var appearanceSettings: ({})
    property int navbarRevision: 0
    readonly property string stateDir: {
        const stateHome = Quickshell.env("XDG_STATE_HOME")
        const home = Quickshell.env("HOME") || ""
        return (stateHome && stateHome.length ? stateHome : home + "/.local/state") + "/a16een"
    }
    readonly property string navbarIconRoot: root.stateDir + "/navbar-icons"
    readonly property string appearanceSettingsPath: root.stateDir + "/navbar-appearance.json"
    readonly property string navbarReadyPath: root.navbarIconRoot + "/ready"
    readonly property string appearanceReadyPath: root.navbarIconRoot + "/appearance-ready"

    function loadAppearanceSettings(raw) {
        try {
            const parsed = JSON.parse(String(raw || "{}"))
            root.appearanceSettings = parsed && typeof parsed === "object" ? parsed : ({})
        } catch (error) { root.appearanceSettings = ({}) }
    }
    function appearanceAll() {
        return root.appearanceSettings && root.appearanceSettings.all ? root.appearanceSettings.all : ({})
    }
    function appearanceContainer(id) {
        const containers = root.appearanceSettings && root.appearanceSettings.containers
            ? root.appearanceSettings.containers : ({})
        return containers[id] || ({})
    }
    function containerIsVisible(id) {
        const all = root.appearanceAll()
        if (all.visibilityControl === true) return all.visible !== false
        return root.appearanceContainer(id).visible !== false
    }
    function containerColorFor(id) {
        const all = root.appearanceAll()
        const item = root.appearanceContainer(id)
        if (all.applyContainerColor === true && /^#[0-9A-Fa-f]{6}$/.test(String(all.containerColor || "")))
            return String(all.containerColor)
        if (item.containerEnabled === true && /^#[0-9A-Fa-f]{6}$/.test(String(item.containerColor || "")))
            return String(item.containerColor)
        return "#FFFFFF"
    }
    function appearanceLuminance(value) {
        const match = String(value || "").match(/^#([0-9A-Fa-f]{6})$/)
        if (!match) return 255
        const hex = match[1]
        return (parseInt(hex.slice(0, 2), 16) * 299
            + parseInt(hex.slice(2, 4), 16) * 587
            + parseInt(hex.slice(4, 6), 16) * 114) / 1000
    }
    function hoverColorFor(id) {
        const background = root.containerColorFor(id)
        return root.appearanceLuminance(background) < 120
            ? Qt.lighter(background, 1.24) : Qt.darker(background, 1.04)
    }
    function generatedIconPath(actionId) {
        return "file://" + root.navbarIconRoot + "/quick-hub-" + actionId + ".svg"
    }

    FileView {
        id: appearanceFile
        path: root.appearanceSettingsPath
        watchChanges: true
        printErrors: false
        onLoaded: root.loadAppearanceSettings(this.text())
        onFileChanged: root.loadAppearanceSettings(this.text())
    }
    FileView {
        id: appearanceReadyFile
        path: root.appearanceReadyPath
        watchChanges: true
        printErrors: false
        onLoaded: appearanceFile.reload()
        onFileChanged: appearanceFile.reload()
    }

    FileView {
        id: navbarReadyFile
        path: root.navbarReadyPath
        watchChanges: true
        printErrors: false
        onLoaded: {
            root.navbarRevision++
            appearanceFile.reload()
        }
        onFileChanged: {
            root.navbarRevision++
            appearanceFile.reload()
        }
    }

    screen: root.modelData
    visible: root.dockVisible && root.modelData !== null && root.containerIsVisible("quick-hub")
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    width: root.horizontalNavbar ? 52 : 28
    height: root.horizontalNavbar ? 28 : 52

    anchors {
        left: !root.horizontalNavbar && root.navbarPosition === "left"
        right: root.horizontalNavbar || root.navbarPosition === "right"
        top: root.navbarPosition === "top"
        bottom: root.navbarPosition !== "top"
    }

    // Sit directly between the main navbar and the Notes / Tasks / Presets tray.
    margins {
        left: root.horizontalNavbar ? 0 : 10
        right: root.horizontalNavbar ? 186 : 10
        top: 0
        bottom: root.horizontalNavbar ? 0 : 156
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-notifications-tools"

    Rectangle {
        anchors.fill: parent
        radius: 11
        color: root.containerColorFor("quick-hub")
        border.width: 1
        border.color: root.appearanceLuminance(root.containerColorFor("quick-hub")) < 120
            ? "#3C424C" : "#D9DEE5"

        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: 14
            color: "#10000000"
            z: -1
        }

        Row {
            visible: root.horizontalNavbar
            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: [
                    { id: "notifications", icon: "lucide-bell.svg", active: root.notificationsOpen },
                    { id: "tools", icon: "lucide-toolbox.svg", active: root.toolsOpen }
                ]

                delegate: Item {
                    id: actionItem
                    required property var modelData
                    width: 22
                    height: 22

                    Rectangle {
                        anchors.fill: parent
                        radius: 7
                        color: actionMouse.containsMouse || actionItem.modelData.active
                            ? root.hoverColorFor("quick-hub") : "transparent"
                        border.width: actionItem.modelData.active ? 1 : 0
                        border.color: root.appearanceLuminance(root.containerColorFor("quick-hub")) < 120
                            ? "#535B66" : "#E2E6EB"

                        Image {
                            id: actionImage
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            sourceSize.width: 64
                            sourceSize.height: 64
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            cache: false
                            source: root.generatedIconPath(actionItem.modelData.id)
                            onStatusChanged: {
                                if (status === Image.Error)
                                    source = Qt.resolvedUrl("../assets/icons/" + actionItem.modelData.icon)
                            }
                            Connections {
                                target: root
                                function onNavbarRevisionChanged() {
                                    actionImage.source = ""
                                    Qt.callLater(() => actionImage.source = root.generatedIconPath(actionItem.modelData.id))
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: actionItem.modelData.id === "notifications" && root.unreadCount > 0
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.rightMargin: 0
                        anchors.topMargin: 0
                        width: root.unreadCount > 9 ? 13 : 10
                        height: 10
                        radius: 5
                        color: "#D94841"
                        border.width: 1
                        border.color: "#FFFFFF"

                        Text {
                            anchors.centerIn: parent
                            text: root.unreadCount > 9 ? "9+" : String(root.unreadCount)
                            color: "#FFFFFF"
                            font.pixelSize: 6
                            font.weight: Font.Bold
                            visible: root.unreadCount > 1
                        }
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activate(actionItem.modelData.id)
                    }
                }
            }
        }

        Column {
            visible: !root.horizontalNavbar
            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: [
                    { id: "notifications", icon: "lucide-bell.svg", active: root.notificationsOpen },
                    { id: "tools", icon: "lucide-toolbox.svg", active: root.toolsOpen }
                ]

                delegate: Item {
                    id: actionItem
                    required property var modelData
                    width: 22
                    height: 22

                    Rectangle {
                        anchors.fill: parent
                        radius: 7
                        color: actionMouse.containsMouse || actionItem.modelData.active
                            ? root.hoverColorFor("quick-hub") : "transparent"
                        border.width: actionItem.modelData.active ? 1 : 0
                        border.color: root.appearanceLuminance(root.containerColorFor("quick-hub")) < 120
                            ? "#535B66" : "#E2E6EB"

                        Image {
                            id: actionImage
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            sourceSize.width: 64
                            sourceSize.height: 64
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            cache: false
                            source: root.generatedIconPath(actionItem.modelData.id)
                            onStatusChanged: {
                                if (status === Image.Error)
                                    source = Qt.resolvedUrl("../assets/icons/" + actionItem.modelData.icon)
                            }
                            Connections {
                                target: root
                                function onNavbarRevisionChanged() {
                                    actionImage.source = ""
                                    Qt.callLater(() => actionImage.source = root.generatedIconPath(actionItem.modelData.id))
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: actionItem.modelData.id === "notifications" && root.unreadCount > 0
                        anchors.right: parent.right
                        anchors.top: parent.top
                        width: root.unreadCount > 9 ? 13 : 10
                        height: 10
                        radius: 5
                        color: "#D94841"
                        border.width: 1
                        border.color: "#FFFFFF"

                        Text {
                            anchors.centerIn: parent
                            text: root.unreadCount > 9 ? "9+" : String(root.unreadCount)
                            color: "#FFFFFF"
                            font.pixelSize: 6
                            font.weight: Font.Bold
                            visible: root.unreadCount > 1
                        }
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activate(actionItem.modelData.id)
                    }
                }
            }
        }
    }

    function activate(actionId) {
        if (actionId === "notifications")
            root.notificationsRequested()
        else if (actionId === "tools")
            root.toolsRequested()
    }
}
