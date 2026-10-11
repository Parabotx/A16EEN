import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    required property string navbarPosition
    required property bool dockVisible

    signal notesRequested()
    signal tasksRequested()
    signal presetsRequested()

    readonly property bool horizontalNavbar:
        root.navbarPosition === "top" || root.navbarPosition === "bottom"

    readonly property var actions: [
        { id: "notes", icon: "quick-notes.svg", label: "Notes" },
        { id: "tasks", icon: "quick-tasks.svg", label: "Tasks" },
        { id: "presets", icon: "quick-presets.svg", label: "Presets" }
    ]

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
        return "file://" + root.navbarIconRoot + "/quick-actions-" + actionId + ".svg"
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
        id: navbarReadyFile
        path: root.navbarReadyPath
        watchChanges: true
        printErrors: false
        onLoaded: root.navbarRevision++
        onFileChanged: root.navbarRevision++
    }

    screen: root.modelData
    visible: root.dockVisible && root.modelData !== null && root.containerIsVisible("quick-actions")
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    // Size the shell surface to the three compact buttons, with minimal padding.
    width: root.horizontalNavbar ? 76 : 36
    height: root.horizontalNavbar ? 28 : 76

    anchors {
        left: !root.horizontalNavbar && root.navbarPosition === "left"
        right: root.horizontalNavbar || root.navbarPosition === "right"
        top: root.navbarPosition === "top"
        bottom: root.navbarPosition !== "top"
    }

    // Vertically, the tray sits between the workspace rail and battery pill,
    // just eight pixels above the battery panel. Horizontally, it sits just
    // before the battery capsule, away from the centered workspace navbar.
    margins {
        // Vertical trays sit just outside the navbar's visible 44px rail.
        // Horizontal trays share the battery capsule's 12px edge alignment.
        // Align the vertical tray exactly with the visible 44px navbar rail.
        // Horizontally it sits directly beside the battery capsule.
        // Keep the holder flush against the active screen side just like
        // the workspace rail. Horizontal layouts keep the small battery gap.
        left: root.horizontalNavbar ? 0 : 10
        right: root.horizontalNavbar ? 102 : 10
        top: 0
        bottom: root.horizontalNavbar ? 0 : 72
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-quick-actions"

    Rectangle {
        anchors.fill: parent
        radius: 11
        color: root.containerColorFor("quick-actions")
        border.width: 1
        border.color: root.appearanceLuminance(root.containerColorFor("quick-actions")) < 120
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
                model: root.actions

                delegate: Rectangle {
                    id: actionButton
                    required property var modelData

                    width: 22
                    height: 22
                    radius: 7
                    color: actionHover.containsMouse ? root.hoverColorFor("quick-actions") : "transparent"
                    border.width: actionHover.containsMouse ? 1 : 0
                    border.color: root.appearanceLuminance(root.containerColorFor("quick-actions")) < 120
                        ? "#535B66" : "#E2E6EB"

                    Image {
                        id: actionImage
                        anchors.centerIn: parent
                        width: 13
                        height: 13
                        sourceSize.width: 34
                        sourceSize.height: 34
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        cache: false
                        source: root.generatedIconPath(actionButton.modelData.id)
                        onStatusChanged: {
                            if (status === Image.Error)
                                source = Qt.resolvedUrl("../assets/icons/" + actionButton.modelData.icon)
                        }
                        Connections {
                            target: root
                            function onNavbarRevisionChanged() {
                                actionImage.source = ""
                                Qt.callLater(() => actionImage.source = root.generatedIconPath(actionButton.modelData.id))
                            }
                        }
                    }

                    MouseArea {
                        id: actionHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activateAction(actionButton.modelData.id)
                    }
                }
            }
        }

        Column {
            visible: !root.horizontalNavbar
            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: root.actions

                delegate: Rectangle {
                    id: actionButton
                    required property var modelData

                    width: 22
                    height: 22
                    radius: 7
                    color: actionHover.containsMouse ? root.hoverColorFor("quick-actions") : "transparent"
                    border.width: actionHover.containsMouse ? 1 : 0
                    border.color: root.appearanceLuminance(root.containerColorFor("quick-actions")) < 120
                        ? "#535B66" : "#E2E6EB"

                    Image {
                        id: actionImage
                        anchors.centerIn: parent
                        width: 13
                        height: 13
                        sourceSize.width: 30
                        sourceSize.height: 30
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        cache: false
                        source: root.generatedIconPath(actionButton.modelData.id)
                        onStatusChanged: {
                            if (status === Image.Error)
                                source = Qt.resolvedUrl("../assets/icons/" + actionButton.modelData.icon)
                        }
                        Connections {
                            target: root
                            function onNavbarRevisionChanged() {
                                actionImage.source = ""
                                Qt.callLater(() => actionImage.source = root.generatedIconPath(actionButton.modelData.id))
                            }
                        }
                    }

                    MouseArea {
                        id: actionHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activateAction(actionButton.modelData.id)
                    }
                }
            }
        }
    }

    function activateAction(actionId) {
        switch (actionId) {
        case "notes":
            root.notesRequested()
            break
        case "tasks":
            root.tasksRequested()
            break
        case "presets":
            root.presetsRequested()
            break
        }
    }
}
