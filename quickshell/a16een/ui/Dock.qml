import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower

PanelWindow {
    id: root

    required property var modelData
    required property var workspaces
    required property int focusedWorkspaceId
    required property bool fullscreenActive

    signal launcherRequested()

    readonly property color dockBackground: "#FFFFFF"
    readonly property color dockBorder: "#E5E7EB"
    readonly property color iconColor: "#111111"
    readonly property color hoverBackground: "#F3F4F6"

    readonly property string stateDir: {
        const stateHome = Quickshell.env("XDG_STATE_HOME")
        const home = Quickshell.env("HOME") || ""
        return (stateHome && stateHome.length ? stateHome : home + "/.local/state") + "/a16een"
    }

    readonly property string navbarIconRoot: root.stateDir + "/navbar-icons"
    readonly property string navbarReadyPath: root.navbarIconRoot + "/ready"
    readonly property string workspaceCountPath: root.stateDir + "/workspace-count"

    property int navbarRevision: 0
    property int workspaceCount: 6
    property bool edgeRevealed: false
    required property string navbarPosition

    readonly property var workspaceCatalog: [
        { id: "home", icon: "house.svg" },
        { id: "code", icon: "code.svg" },
        { id: "web", icon: "globe.svg" },
        { id: "comms", icon: "messages-square.svg" },
        { id: "studio", icon: "sparkles.svg" },
        { id: "music", icon: "music.svg" },
        { id: "games", icon: "gamepad-2.svg" },
        { id: "files", icon: "folder.svg" },
        { id: "lab", icon: "terminal.svg" }
    ]

    readonly property var visibleWorkspaces: root.workspaceCatalog.slice(0, root.workspaceCount)

    readonly property bool horizontalNavbar:
        root.navbarPosition === "top" || root.navbarPosition === "bottom"

    readonly property int dockHeight: root.horizontalNavbar
        ? 44
        : Math.max(
            260,
            root.visibleWorkspaces.length * 32
                + Math.max(0, root.visibleWorkspaces.length - 1) * 4
                + 18
        )

    readonly property int dockWidth: root.horizontalNavbar
        ? Math.max(
            44,
            root.visibleWorkspaces.length * 32
                + Math.max(0, root.visibleWorkspaces.length - 1) * 4
                + 20
        )
        : 44

    readonly property bool dockVisible: !root.fullscreenActive || root.edgeRevealed

    readonly property int surfaceWidth:
        root.horizontalNavbar
            ? (root.dockVisible ? root.dockWidth : root.modelData.width)
            : (root.dockVisible ? 66 : 8)

    readonly property int surfaceHeight:
        root.horizontalNavbar
            ? (root.dockVisible ? root.dockHeight : 8)
            : (root.dockVisible ? root.dockHeight : 240)

    readonly property int horizontalCenterMargin:
        Math.max(0, Math.round((root.modelData.width - root.surfaceWidth) / 2))

    readonly property int verticalCenterMargin:
        Math.max(0, Math.round((root.modelData.height - root.surfaceHeight) / 2))

    function loadWorkspaceCount(raw) {
        const value = Number(String(raw || "").trim())
        if (value >= 2 && value <= 9)
            root.workspaceCount = Math.floor(value)
    }

    function generatedIconPath(slot) {
        return "file://" + root.navbarIconRoot + "/" + slot + ".svg"
    }

    function fallbackIconPath(iconName) {
        return Qt.resolvedUrl("../assets/icons/" + iconName)
    }

    FileView {
        id: navbarReadyFile
        path: root.navbarReadyPath
        watchChanges: true
        printErrors: false
        onFileChanged: root.navbarRevision++
        onLoaded: root.navbarRevision++
    }

    FileView {
        id: workspaceCountFile
        path: root.workspaceCountPath
        watchChanges: true
        printErrors: false
        onLoaded: root.loadWorkspaceCount(this.text())
        onFileChanged: root.loadWorkspaceCount(this.text())
    }

    screen: modelData
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    width: root.surfaceWidth
    height: root.surfaceHeight

    // The actual Wayland surface is only the navbar-sized area. It never
    // covers the rest of the screen, even while the navbar is hidden.
    anchors {
        left: root.horizontalNavbar || root.navbarPosition === "left"
        right: !root.horizontalNavbar && root.navbarPosition === "right"
        top: root.horizontalNavbar ? root.navbarPosition === "top" : true
        bottom: root.horizontalNavbar && root.navbarPosition === "bottom"
    }

    margins {
        left: root.horizontalNavbar ? root.horizontalCenterMargin : 0
        right: 0
        top: root.horizontalNavbar ? 0 : root.verticalCenterMargin
        bottom: 0
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-dock"

    function workspaceIsFocused(name) {
        const current = root.workspaces.find(workspace => workspace.name === name)
        return !!current && current.id === root.focusedWorkspaceId
    }

    function focusWorkspace(name) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", name])
    }

    function revealDock() {
        root.edgeRevealed = true
        hideRevealTimer.stop()
    }

    function scheduleHide() {
        if (root.fullscreenActive)
            hideRevealTimer.restart()
    }

    Timer {
        id: hideRevealTimer
        interval: 320
        repeat: false
        onTriggered: root.edgeRevealed = false
    }

    onFullscreenActiveChanged: {
        root.edgeRevealed = false
        hideRevealTimer.stop()
    }

    MouseArea {
        id: edgeReveal
        x: root.horizontalNavbar
            ? 0
            : (root.navbarPosition === "right" ? parent.width - width : 0)
        y: root.horizontalNavbar
            ? (root.navbarPosition === "bottom" ? parent.height - height : 0)
            : 0
        width: root.horizontalNavbar ? parent.width : 8
        height: root.horizontalNavbar ? 8 : parent.height
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        // In fullscreen horizontal mode a separate full-width sensor must
        // own edge detection. The dock surface itself resizes when revealed.
        enabled: !(root.fullscreenActive && root.horizontalNavbar)
        z: 10
        onEntered: root.revealDock()
        onExited: root.scheduleHide()
    }

    // Keep the fullscreen TOP/BOTTOM trigger stable while the visual dock
    // changes from a full-width 8px hidden surface to a compact centered dock.
    // Otherwise resizing the dock surface moves it out from under a cursor
    // parked away from the center, immediately firing MouseArea.onExited.
    PanelWindow {
        id: horizontalEdgeSensor
        screen: root.modelData
        visible: root.fullscreenActive && root.horizontalNavbar
        color: "transparent"
        aboveWindows: true
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        width: root.modelData.width
        height: 8

        anchors {
            left: true
            right: true
            top: root.navbarPosition === "top"
            bottom: root.navbarPosition === "bottom"
        }

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "a16een-dock-edge-sensor"

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: root.revealDock()
            onExited: root.scheduleHide()
        }
    }

    // Hover-expandable battery capsule. Keep the Wayland panel at a fixed
    // maximum size so hover does not resize/reposition the native surface.
    // Only the inner pill animates, with its screen-facing edge pinned.
    PanelWindow {
        id: batteryStatusPanel
        screen: root.modelData
        visible: root.dockVisible
            && UPower.displayDevice.ready
            && UPower.displayDevice.isPresent
        color: "transparent"
        aboveWindows: true
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0

        // Stable outer surface prevents the pointer leaving the surface while
        // the pill opens/closes, which caused the repeated hover flicker.
        width: root.horizontalNavbar ? 98 : 82
        height: root.horizontalNavbar ? 46 : 52

        anchors {
            left: root.navbarPosition === "left"
            right: root.horizontalNavbar || root.navbarPosition === "right"
            top: root.navbarPosition === "top"
            bottom: root.navbarPosition !== "top"
        }

        margins {
            left: 12
            right: 12
            top: 12
            bottom: 12
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "a16een-battery-status"

        function batteryPercent() {
            if (!UPower.displayDevice.ready || !UPower.displayDevice.isPresent)
                return 0

            const raw = Number(UPower.displayDevice.percentage)
            if (!Number.isFinite(raw))
                return 0

            // Some Quickshell/UPower builds expose charge as a 0..1 fraction,
            // while others expose a 0..100 percentage. Normalize both so 0.52
            // becomes 52%, instead of the incorrect 1%.
            const normalized = raw > 0 && raw <= 1 ? raw * 100 : raw
            return Math.max(0, Math.min(100, Math.round(normalized)))
        }

        function batteryIconColor() {
            const state = UPower.displayDevice.state

            if (state === UPowerDeviceState.Charging
                || state === UPowerDeviceState.PendingCharge)
                return "#16A34A"

            if (state !== UPowerDeviceState.FullyCharged
                && batteryStatusPanel.batteryPercent() < 20
                && UPower.onBattery)
                return "#E5484D"

            return "#111318"
        }

        Rectangle {
            id: batteryPill
            x: (root.horizontalNavbar || root.navbarPosition === "right")
                ? parent.width - width - 2
                : 2
            y: root.navbarPosition === "top"
                ? 2
                : parent.height - height - 2
            width: root.horizontalNavbar
                ? (batteryHoverSensor.containsMouse ? 92 : 40)
                : (batteryHoverSensor.containsMouse ? 76 : 38)
            height: root.horizontalNavbar ? 40 : 46
            radius: 13
            color: "#FFFFFF"
            border.width: 1
            border.color: "#D9DEE5"
            z: 1

            Behavior on width {
                NumberAnimation {
                    duration: 190
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: 16
                color: "#10000000"
                z: -1
            }

            // Track the visible capsule, not the whole transparent native window.
            // Its parent grows away from the screen-facing edge, while the outer
            // PanelWindow remains fixed-size so Wayland geometry stays stable.
            MouseArea {
                id: batteryHoverSensor
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                cursorShape: Qt.ArrowCursor
                z: 10
            }

            BatteryGlyph {
                id: batteryGlyph
                horizontal: root.horizontalNavbar
                percentage: batteryStatusPanel.batteryPercent()
                tint: batteryStatusPanel.batteryIconColor()
                charging: UPower.displayDevice.state === UPowerDeviceState.Charging
                    || UPower.displayDevice.state === UPowerDeviceState.PendingCharge
                width: root.horizontalNavbar ? 27 : 18
                height: root.horizontalNavbar ? 20 : 28
                x: root.horizontalNavbar
                    ? batteryPill.width - width - 6
                    : (batteryHoverSensor.containsMouse
                        ? (root.navbarPosition === "right"
                            ? batteryPill.width - width - 5
                            : 5)
                        : Math.round((batteryPill.width - width) / 2))
                y: Math.round((batteryPill.height - height) / 2)

            }

            Text {
                id: batteryPercentLabel
                visible: opacity > 0.02
                opacity: batteryHoverSensor.containsMouse ? 1 : 0
                x: root.horizontalNavbar
                    ? 8
                    : (root.navbarPosition === "right" ? 5 : 29)
                y: Math.round((batteryPill.height - height) / 2)
                width: root.horizontalNavbar ? 43 : 41
                text: batteryStatusPanel.batteryPercent() + "%"
                color: "#111318"
                font.pixelSize: root.horizontalNavbar ? 12 : 11
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter

                Behavior on opacity {
                    NumberAnimation {
                        duration: 130
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    Rectangle {
        id: dock
        x: root.horizontalNavbar
            ? Math.round((parent.width - width) / 2)
            : (root.dockVisible
                ? 10
                : (root.navbarPosition === "right" ? parent.width + 2 : -width - 2))
        y: root.horizontalNavbar
            ? (root.dockVisible
                ? 0
                : (root.navbarPosition === "bottom" ? parent.height + 2 : -height - 2))
            : Math.round((parent.height - height) / 2)

        width: root.horizontalNavbar ? root.dockWidth : 44
        height: root.dockHeight
        radius: 18
        color: root.dockBackground
        border.width: 1
        border.color: root.dockBorder

        Behavior on x {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: 21
            color: "#16000000"
            z: -1
        }

        Grid {
            anchors.centerIn: parent
            columns: root.horizontalNavbar ? root.visibleWorkspaces.length : 1
            rows: root.horizontalNavbar ? 1 : root.visibleWorkspaces.length
            rowSpacing: 4
            columnSpacing: 4

            Repeater {
                model: root.visibleWorkspaces

                delegate: Rectangle {
                    id: workspaceButton

                    required property var modelData
                    required property int index

                    width: 32
                    height: 32
                    radius: 11

                    readonly property bool active:
                        root.workspaceIsFocused(modelData.id)

                    color: workspaceMouse.containsMouse
                        ? root.hoverBackground
                        : "transparent"

                    // Keep the active marker on the physical edge of the screen.
                    // Explicit x/y geometry avoids stale conditional anchors when the
                    // dock changes between vertical and horizontal orientations.
                    Rectangle {
                        id: activeWorkspaceMarker
                        visible: workspaceButton.active
                        width: root.horizontalNavbar ? 16 : 3
                        height: root.horizontalNavbar ? 3 : 16
                        radius: 2
                        x: root.horizontalNavbar
                            ? Math.round((workspaceButton.width - width) / 2)
                            : (root.navbarPosition === "left"
                                ? 2
                                : workspaceButton.width - width - 2)
                        y: root.horizontalNavbar
                            ? (root.navbarPosition === "top"
                                ? 2
                                : workspaceButton.height - height - 2)
                            : Math.round((workspaceButton.height - height) / 2)
                        color: root.iconColor
                        z: 0
                    }

                    NavbarImage {
                        anchors.centerIn: parent
                        width: 19
                        height: 19
                        slot: modelData.id
                        generatedPath: root.generatedIconPath(modelData.id)
                        fallbackPath: root.fallbackIconPath(modelData.icon)
                        refreshRevision: root.navbarRevision
                        active: workspaceButton.active
                        hovered: workspaceMouse.containsMouse
                        z: 1
                    }

                    MouseArea {
                        id: workspaceMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.revealDock()
                        onExited: root.scheduleHide()
                        onClicked: root.focusWorkspace(modelData.id)
                    }
                }
            }
        }
    }

    component BatteryGlyph: Item {
        id: glyphRoot

        property bool horizontal: true
        property real percentage: 0
        property color tint: "#111318"
        property bool charging: false

        Behavior on percentage {
            NumberAnimation {
                duration: 260
                easing.type: Easing.OutCubic
            }
        }

        readonly property real bodyX: horizontal ? 0 : 3
        readonly property real bodyY: horizontal ? 2 : 4
        readonly property real bodyWidth: horizontal ? width - 4 : width - 6
        readonly property real bodyHeight: horizontal ? height - 4 : height - 6
        readonly property real innerWidth: Math.max(0, bodyWidth - 4)
        readonly property real innerHeight: Math.max(0, bodyHeight - 4)
        readonly property real fillRatio: Math.max(0, Math.min(100, percentage)) / 100

        // While charging, tint the empty interior lightly so the white lightning
        // bolt remains visible even at low charge. The stronger fill below still
        // tracks the actual percentage.
        Rectangle {
            x: glyphRoot.bodyX + 2
            y: glyphRoot.bodyY + 2
            width: glyphRoot.innerWidth
            height: glyphRoot.innerHeight
            visible: glyphRoot.charging
            color: "#DDF8E5"
            radius: 1
            z: -1
        }

        // Fill is drawn inside the battery body, proportional to actual charge.
        Rectangle {
            x: glyphRoot.bodyX + 2
            y: glyphRoot.horizontal
                ? glyphRoot.bodyY + 2
                : glyphRoot.bodyY + 2 + glyphRoot.innerHeight * (1 - glyphRoot.fillRatio)
            width: glyphRoot.horizontal
                ? glyphRoot.innerWidth * glyphRoot.fillRatio
                : glyphRoot.innerWidth
            height: glyphRoot.horizontal
                ? glyphRoot.innerHeight
                : glyphRoot.innerHeight * glyphRoot.fillRatio
            color: glyphRoot.tint
            radius: 1
            z: 0
        }

        Rectangle {
            x: glyphRoot.bodyX
            y: glyphRoot.bodyY
            width: glyphRoot.bodyWidth
            height: glyphRoot.bodyHeight
            color: "transparent"
            border.width: 1.5
            border.color: glyphRoot.tint
            radius: 2.5
            z: 1
        }

        Rectangle {
            x: glyphRoot.horizontal ? glyphRoot.width - width : Math.round((glyphRoot.width - width) / 2)
            y: glyphRoot.horizontal ? Math.round((glyphRoot.height - height) / 2) : 1
            width: glyphRoot.horizontal ? 3 : 4
            height: glyphRoot.horizontal ? 4 : 3
            color: glyphRoot.tint
            radius: 1
            z: 2
        }
        // A contrasting lightning bolt is drawn inside the body only while
        // charging. Its dark-green outline keeps it legible over both the pale
        // charging interior and the stronger proportional charge fill.
        Shape {
            anchors.fill: parent
            visible: glyphRoot.charging
            z: 3

            ShapePath {
                fillColor: "#FFFFFF"
                strokeColor: "#166534"
                strokeWidth: 0.65
                startX: glyphRoot.width * 0.54
                startY: glyphRoot.height * 0.17
                PathLine { x: glyphRoot.width * 0.34; y: glyphRoot.height * 0.52 }
                PathLine { x: glyphRoot.width * 0.48; y: glyphRoot.height * 0.52 }
                PathLine { x: glyphRoot.width * 0.41; y: glyphRoot.height * 0.83 }
                PathLine { x: glyphRoot.width * 0.67; y: glyphRoot.height * 0.42 }
                PathLine { x: glyphRoot.width * 0.53; y: glyphRoot.height * 0.42 }
                PathLine { x: glyphRoot.width * 0.54; y: glyphRoot.height * 0.17 }
            }
        }
    }

    component NavbarImage: Item {
        required property string slot
        property string generatedPath: ""
        property string fallbackPath: ""
        property int refreshRevision: 0
        property bool hovered: false
        property bool active: false

        implicitWidth: 19
        implicitHeight: 19
        scale: hovered ? 1.08 : (active ? 1.03 : 1)

        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        Image {
            id: navbarImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            sourceSize.width: width
            sourceSize.height: height
            smooth: true
            mipmap: true
            cache: false
            asynchronous: true
            source: parent.generatedPath.length
                ? parent.generatedPath
                : parent.fallbackPath

            onStatusChanged: {
                if (status === Image.Error && parent.fallbackPath.length
                    && source !== parent.fallbackPath) {
                    source = parent.fallbackPath
                }
            }
        }

        onRefreshRevisionChanged: {
            navbarImage.source = ""
            Qt.callLater(() => {
                navbarImage.source = root.generatedIconPath(slot)
            })
        }
    }
}
