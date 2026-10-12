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
    property real innerOrbitAngle: 0
    property real middleOrbitAngle: 0
    property real outerOrbitAngle: 0

    // Match the Music widget's vertical center (72 + half of its 170 px card).
    readonly property int centerFromBottom: root.navbarPosition === "bottom" ? 159 : 157
    readonly property int orbitDiameter: root.activeApps.length > 13 ? 260
        : root.activeApps.length > 5 ? 194
        : root.activeApps.length > 1 ? 132 : 82
    readonly property int shelfWidth: root.shape === "circle" ? root.orbitDiameter
        : root.modelData
            ? Math.min(Math.max(root.activeApps.length > 0 ? root.activeApps.length * 39 + 22 : 166,
                root.activeApps.length > 0 ? 58 : 150), Math.max(150, root.modelData.width - 24))
            : 200
    readonly property int shelfHeight: root.shape === "circle" ? root.orbitDiameter
        : root.activeApps.length ? 48 : 38
    readonly property int shelfRadius: root.shape === "circle" ? root.shelfWidth / 2
        : root.shape === "capsule" ? 24
        : root.shape === "rounded" ? 12 : 7
    readonly property int innerOrbitCount: Math.max(0, Math.min(4, root.activeApps.length - 1))
    readonly property int middleOrbitCount: Math.max(0, Math.min(8, root.activeApps.length - 5))
    readonly property int outerOrbitCount: Math.max(0, Math.min(3, root.activeApps.length - 13))
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

    function orbitRadiusFor(index) {
        if (index <= 4)
            return 43
        if (index <= 12)
            return 75
        return 107
    }

    function orbitSlotFor(index) {
        if (index <= 4)
            return index - 1
        if (index <= 12)
            return index - 5
        return index - 13
    }

    function orbitCountFor(index) {
        if (index <= 4)
            return root.innerOrbitCount
        if (index <= 12)
            return root.middleOrbitCount
        return root.outerOrbitCount
    }

    function orbitAngleFor(index) {
        if (index === 0)
            return 0
        const count = Math.max(1, root.orbitCountFor(index))
        const angle = -90 + root.orbitSlotFor(index) * 360 / count
        if (index <= 4)
            return angle + root.innerOrbitAngle
        if (index <= 12)
            return angle + root.middleOrbitAngle
        return angle + root.outerOrbitAngle
    }

    function launchApp(app) {
        try {
            app.entry.execute()
        } catch (error) {
            console.error("A16EEN App Shelf could not launch " + app.name + ":", error)
        }
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

    NumberAnimation {
        target: root
        property: "innerOrbitAngle"
        from: 0
        to: 360
        duration: 26000
        loops: Animation.Infinite
        running: root.widgetEnabled && root.shape === "circle" && root.innerOrbitCount > 0
    }

    NumberAnimation {
        target: root
        property: "middleOrbitAngle"
        from: 360
        to: 0
        duration: 36000
        loops: Animation.Infinite
        running: root.widgetEnabled && root.shape === "circle" && root.middleOrbitCount > 0
    }

    NumberAnimation {
        target: root
        property: "outerOrbitAngle"
        from: 0
        to: 360
        duration: 48000
        loops: Animation.Infinite
        running: root.widgetEnabled && root.shape === "circle" && root.outerOrbitCount > 0
    }

    Rectangle {
        id: shelfCard
        width: root.shelfWidth
        height: root.shelfHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: root.modelData ? -Math.round(root.modelData.width * 0.10) : 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.centerFromBottom - height / 2
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

        // Concentric tracks stay still while the app buttons orbit smoothly.
        Repeater {
            model: [
                { size: 86, visible: root.activeApps.length > 1 },
                { size: 150, visible: root.activeApps.length > 5 },
                { size: 214, visible: root.activeApps.length > 13 }
            ]

            delegate: Rectangle {
                required property var modelData
                width: modelData.size
                height: modelData.size
                anchors.centerIn: parent
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: "#22FFFFFF"
                visible: root.shape === "circle" && modelData.visible
            }
        }

        // The original compact horizontal shelf remains unchanged in behavior.
        Row {
            anchors.centerIn: parent
            spacing: 3
            visible: root.shape !== "circle" && root.activeApps.length > 0

            Repeater {
                model: root.activeApps

                delegate: Item {
                    required property var modelData
                    width: 36
                    height: 36

                    Rectangle {
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
                            onClicked: root.launchApp(modelData)
                        }
                    }

                    Rectangle {
                        visible: root.shape !== "circle" && root.hoveredDesktopId === modelData.desktopId
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.top
                        anchors.bottomMargin: 6
                        width: Math.min(150, Math.max(64, barHoverLabel.implicitWidth + 18))
                        height: 25
                        radius: 7
                        color: "#F20D1118"
                        border.width: 1
                        border.color: "#35FFFFFF"
                        z: 10

                        Text {
                            id: barHoverLabel
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

        // Circle mode: app zero remains in the hub; the next groups occupy
        // four, eight, then up to three points on successively larger orbits.
        Repeater {
            model: root.activeApps
            visible: root.shape === "circle"

            delegate: Item {
                required property var modelData
                required property int index
                width: index === 0 ? 40 : 34
                height: width
                x: (shelfCard.width - width) / 2
                    + (index === 0 ? 0 : Math.cos(root.orbitAngleFor(index) * Math.PI / 180)
                        * root.orbitRadiusFor(index))
                y: (shelfCard.height - height) / 2
                    + (index === 0 ? 0 : Math.sin(root.orbitAngleFor(index) * Math.PI / 180)
                        * root.orbitRadiusFor(index))
                z: index === 0 ? 3 : 2

                Rectangle {
                    id: orbitTile
                    anchors.fill: parent
                    radius: width / 2
                    color: orbitMouse.containsMouse
                        ? "#35FFFFFF" : (parent.index === 0 ? "#26FFFFFF" : "#14FFFFFF")
                    border.width: parent.index === 0 || orbitMouse.containsMouse ? 1 : 0
                    border.color: "#45FFFFFF"

                    Image {
                        anchors.centerIn: parent
                        width: parent.parent.index === 0 ? 24 : 21
                        height: width
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
                        id: orbitMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.hoveredDesktopId = modelData.desktopId
                        onExited: root.hoveredDesktopId = ""
                        onClicked: root.launchApp(modelData)
                    }
                }

                Rectangle {
                    visible: root.hoveredDesktopId === modelData.desktopId
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.top
                    anchors.bottomMargin: 6
                    width: Math.min(150, Math.max(64, circleHoverLabel.implicitWidth + 18))
                    height: 25
                    radius: 7
                    color: "#F20D1118"
                    border.width: 1
                    border.color: "#35FFFFFF"
                    z: 10

                    Text {
                        id: circleHoverLabel
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

        Column {
            anchors.centerIn: parent
            spacing: 4
            visible: root.shape === "circle" && root.activeApps.length === 0

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 18
                height: 18
                source: Qt.resolvedUrl("../assets/icons/lucide-app-window.svg")
                sourceSize.width: 36
                sourceSize.height: 36
                smooth: true
            }

            Text {
                text: "PIN APPS"
                color: "#CAD2DD"
                font.family: "Inter"
                font.pixelSize: 6
                font.weight: Font.DemiBold
                font.letterSpacing: 0.6
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 8
            visible: root.shape !== "circle" && root.activeApps.length === 0

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