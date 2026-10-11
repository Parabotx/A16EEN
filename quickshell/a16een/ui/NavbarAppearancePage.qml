import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    property bool active: false
    property bool dataMeterEnabled: false
    property var appearanceSettings: ({})
    property string selectedScope: "all"
    property string statusText: "READY"
    property string pendingScope: "all"
    property string pendingSlot: "-"
    property string pendingKey: ""
    property string pendingValue: ""

    signal dataMeterToggleRequested(bool enabled)

    readonly property string stateDir: {
        const stateHome = Quickshell.env("XDG_STATE_HOME")
        const home = Quickshell.env("HOME") || ""
        return (stateHome && stateHome.length ? stateHome : home + "/.local/state") + "/a16een"
    }
    readonly property string settingsPath: root.stateDir + "/navbar-appearance.json"
    readonly property bool writing: appearanceProcess.running

    readonly property var containerChoices: [
        { id: "all", name: "All Containers", detail: "Shared settings" },
        { id: "workspaces", name: "Workspaces", detail: "Workspace icon rail" },
        { id: "battery", name: "Battery", detail: "Battery capsule" },
        { id: "time", name: "Clock / Time", detail: "Clock display" },
        { id: "utilities", name: "Utilities", detail: "Wi-Fi and Bluetooth" },
        { id: "power", name: "Power", detail: "Power button" },
        { id: "quick-actions", name: "Tasks, Notes & Presets", detail: "Productivity shortcut group" },
        { id: "quick-hub", name: "Notifications & Tools", detail: "Notifications and tools group" }
    ]
    readonly property var containerColors: [
        { value: "transparent", label: "Default", swatch: "#F4F5F7" },
        { value: "#FFFFFF", label: "White", swatch: "#FFFFFF" },
        { value: "#F4F5F7", label: "Pearl", swatch: "#F4F5F7" },
        { value: "#E7E8EA", label: "Mist", swatch: "#E7E8EA" },
        { value: "#D6D9DE", label: "Silver", swatch: "#D6D9DE" },
        { value: "#EEE9E0", label: "Sand", swatch: "#EEE9E0" },
        { value: "#15171A", label: "Ink", swatch: "#15171A" },
        { value: "#070B13", label: "Midnight", swatch: "#070B13" },
        { value: "#20242B", label: "Carbon", swatch: "#20242B" },
        { value: "#222831", label: "Graphite", swatch: "#222831" },
        { value: "#263241", label: "Navy", swatch: "#263241" },
        { value: "#30343B", label: "Slate", swatch: "#30343B" },
        { value: "#1E3A5F", label: "Deep Blue", swatch: "#1E3A5F" },
        { value: "#0F766E", label: "Teal", swatch: "#0F766E" },
        { value: "#1D4ED8", label: "Blue", swatch: "#1D4ED8" }
    ]
    readonly property var allContainerColors: root.containerColors.filter(function(item) {
        return item.value !== "transparent"
    })
    readonly property var iconColors: [
        { value: "auto", label: "Auto", swatch: "#6B7280" },
        { value: "#111318", label: "Black", swatch: "#111318" },
        { value: "#FFFFFF", label: "White", swatch: "#FFFFFF" },
        { value: "#374151", label: "Graphite", swatch: "#374151" },
        { value: "#64748B", label: "Slate", swatch: "#64748B" },
        { value: "#1D4ED8", label: "Blue", swatch: "#1D4ED8" },
        { value: "#0EA5E9", label: "Sky", swatch: "#0EA5E9" },
        { value: "#0D9488", label: "Teal", swatch: "#0D9488" },
        { value: "#16A34A", label: "Green", swatch: "#16A34A" },
        { value: "#CA8A04", label: "Gold", swatch: "#CA8A04" },
        { value: "#EA580C", label: "Orange", swatch: "#EA580C" },
        { value: "#DB2777", label: "Pink", swatch: "#DB2777" },
        { value: "#A855F7", label: "Purple", swatch: "#A855F7" },
        { value: "#E7E8EA", label: "Mist", swatch: "#E7E8EA" },
        { value: "#93C5FD", label: "Ice Blue", swatch: "#93C5FD" }
    ]
    readonly property var individualIconColors: [
        { value: "inherit", label: "Inherit", swatch: "#E7E8EA" },
        { value: "auto", label: "Auto", swatch: "#6B7280" },
        { value: "#111318", label: "Black", swatch: "#111318" },
        { value: "#FFFFFF", label: "White", swatch: "#FFFFFF" },
        { value: "#374151", label: "Graphite", swatch: "#374151" },
        { value: "#64748B", label: "Slate", swatch: "#64748B" },
        { value: "#1D4ED8", label: "Blue", swatch: "#1D4ED8" },
        { value: "#0EA5E9", label: "Sky", swatch: "#0EA5E9" },
        { value: "#0D9488", label: "Teal", swatch: "#0D9488" },
        { value: "#16A34A", label: "Green", swatch: "#16A34A" },
        { value: "#CA8A04", label: "Gold", swatch: "#CA8A04" },
        { value: "#EA580C", label: "Orange", swatch: "#EA580C" },
        { value: "#DB2777", label: "Pink", swatch: "#DB2777" },
        { value: "#A855F7", label: "Purple", swatch: "#A855F7" },
        { value: "#E7E8EA", label: "Mist", swatch: "#E7E8EA" }
    ]

    readonly property bool isAllScope: root.selectedScope === "all"
    readonly property bool visibilityLocked: !root.isAllScope && root.allSetting("visibilityControl", false)
    readonly property bool backgroundLocked: !root.isAllScope && root.allSetting("applyContainerColor", false)
    readonly property bool iconLocked: !root.isAllScope && root.allSetting("applyIconColor", false)

    function loadSettings(raw) {
        try {
            const parsed = JSON.parse(String(raw || "{}"))
            root.appearanceSettings = parsed && typeof parsed === "object" ? parsed : ({})
        } catch (error) {
            root.appearanceSettings = ({})
        }
    }
    function allSetting(key, fallback) {
        const all = root.appearanceSettings && root.appearanceSettings.all ? root.appearanceSettings.all : ({})
        return all[key] !== undefined ? all[key] : fallback
    }
    function containerSetting(id, key, fallback) {
        const containers = root.appearanceSettings && root.appearanceSettings.containers
            ? root.appearanceSettings.containers : ({})
        const item = containers[id] || ({})
        return item[key] !== undefined ? item[key] : fallback
    }
    function currentContainerColor() {
        return root.containerSetting(root.selectedScope, "containerEnabled", false)
            ? root.containerSetting(root.selectedScope, "containerColor", "transparent")
            : "transparent"
    }
    function toggleAll(key) {
        root.setSetting("all", "-", key, root.allSetting(key, false) ? "off" : "on")
    }
    function updateLocalSetting(scope, slot, key, value) {
        let next = {}
        try {
            next = JSON.parse(JSON.stringify(root.appearanceSettings || {}))
        } catch (error) {
            next = {}
        }
        const boolKeys = ["visible", "visibilityControl", "applyContainerColor", "applyIconColor", "applyPopupCardColor"]
        const parsedValue = boolKeys.includes(key)
            ? ["on", "true"].includes(String(value).toLowerCase()) : value
        if (scope === "all") {
            next.all = next.all || ({})
            next.all[key] = parsedValue
        } else {
            next.containers = next.containers || ({})
            next.containers[slot] = next.containers[slot] || ({})
            next.containers[slot][key] = parsedValue
            if (key === "containerColor")
                next.containers[slot].containerEnabled = value !== "transparent"
        }
        root.appearanceSettings = next
    }
    function setSetting(scope, slot, key, value) {
        if (root.writing) return
        if (scope === "container") {
            if (key === "visible" && root.allSetting("visibilityControl", false)) {
                root.statusText = "Disable All visibility control first."
                return
            }
            if (key === "containerColor" && root.allSetting("applyContainerColor", false)) {
                root.statusText = "Disable All background override first."
                return
            }
            if (key === "iconColor" && root.allSetting("applyIconColor", false)) {
                root.statusText = "Disable All icon-color override first."
                return
            }
        }
        root.pendingScope = scope
        root.pendingSlot = slot
        root.pendingKey = key
        root.pendingValue = String(value)
        root.updateLocalSetting(scope, slot, key, String(value))
        root.statusText = "SAVING"
        appearanceProcess.running = true
    }

    FileView {
        id: settingsFile
        path: root.settingsPath
        watchChanges: true
        printErrors: false
        onLoaded: root.loadSettings(this.text())
        onFileChanged: root.loadSettings(this.text())
    }
    Process {
        id: appearanceProcess
        command: ["/usr/local/bin/a16een-navbar-appearance", "set",
            root.pendingScope, root.pendingSlot, root.pendingKey, root.pendingValue]
        running: false
        onExited: function(exitCode) {
            root.statusText = exitCode === 0 ? "SAVED" : "SAVE FAILED"
            settingsFile.reload()
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 12

        ColumnLayout {
            // Keep the category list sidebar-sized so it cannot collapse the settings pane.
            Layout.preferredWidth: 154
            Layout.minimumWidth: 154
            Layout.maximumWidth: 154
            Layout.fillWidth: false
            Layout.fillHeight: true
            spacing: 4
            Text {
                Layout.leftMargin: 5
                text: "NAVBAR CONTAINERS"
                color: "#858E99"
                font.pixelSize: 8
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
            }
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: containerList.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: containerList
                    width: parent.width
                    spacing: 3
                    Repeater {
                        model: root.containerChoices
                        delegate: Rectangle {
                            required property var modelData
                            width: containerList.width
                            height: 44
                            radius: 8
                            color: root.selectedScope === modelData.id ? "#E9EDF2"
                                : (scopeMouse.containsMouse ? "#F3F5F7" : "transparent")
                            border.width: root.selectedScope === modelData.id ? 1 : 0
                            border.color: "#D6DCE3"
                            Column {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 8
                                anchors.rightMargin: 4
                                spacing: 3
                                Text {
                                    width: parent.width
                                    text: modelData.name
                                    color: root.selectedScope === modelData.id ? "#20262E" : "#586371"
                                    font.pixelSize: 8
                                    font.weight: root.selectedScope === modelData.id ? Font.DemiBold : Font.Medium
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width
                                    text: modelData.detail
                                    color: "#8A939E"
                                    font.pixelSize: 6
                                    elide: Text.ElideRight
                                }
                            }
                            MouseArea {
                                id: scopeMouse
                                anchors.fill: parent
                                enabled: !root.writing
                                hoverEnabled: true
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: root.selectedScope = modelData.id
                            }
                        }
                    }
                }
            }
            Text {
                Layout.leftMargin: 4
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: "Changes save automatically."
                color: "#8A939E"
                font.pixelSize: 8
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: "#FFFFFF"
            border.width: 1
            border.color: "#E6E9ED"
            clip: true
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: root.isAllScope ? "All navbar containers"
                                : root.containerChoices.find(function(item) { return item.id === root.selectedScope }).name
                            color: "#161A20"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.isAllScope
                                ? "Shared settings for Workspaces, Battery, Clock, Utilities, Power, Tasks/Notes/Presets and Notifications/Tools."
                                : root.containerChoices.find(function(item) { return item.id === root.selectedScope }).detail
                            color: "#7B8591"
                            font.pixelSize: 8
                            wrapMode: Text.WordWrap
                        }
                    }
                    Text {
                        text: root.statusText
                        color: root.statusText === "SAVE FAILED" ? "#B42318" : "#77818D"
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                    }
                }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#EDF0F3" }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: settingsColumn.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    ColumnLayout {
                        id: settingsColumn
                        width: parent.width
                        spacing: 9

                        ToggleRow {
                            visible: root.isAllScope
                            Layout.fillWidth: true
                            title: "Override visibility"
                            detail: "Control every navbar container with one switch."
                            checked: root.allSetting("visibilityControl", false)
                            enabledControl: !root.writing
                            onToggleRequested: root.toggleAll("visibilityControl")
                        }
                        ToggleRow {
                            visible: root.isAllScope && root.allSetting("visibilityControl", false)
                            Layout.fillWidth: true
                            title: "Show all containers"
                            detail: "Turn the entire navbar group on or off."
                            checked: root.allSetting("visible", true)
                            enabledControl: !root.writing
                            onToggleRequested: root.setSetting("all", "-", "visible",
                                root.allSetting("visible", true) ? "off" : "on")
                        }
                        ToggleRow {
                            visible: root.isAllScope
                            Layout.fillWidth: true
                            title: "Override backgrounds"
                            detail: "Use the same color for all navbar containers."
                            checked: root.allSetting("applyContainerColor", false)
                            enabledControl: !root.writing
                            onToggleRequested: root.toggleAll("applyContainerColor")
                        }
                        PaletteRow {
                            visible: root.isAllScope && root.allSetting("applyContainerColor", false)
                            Layout.fillWidth: true
                            title: "Background color"
                            detail: "Shared container background."
                            options: root.allContainerColors
                            selectedColor: String(root.allSetting("containerColor", "#15171A"))
                            enabledControl: !root.writing
                            onColorPicked: value => root.setSetting("all", "-", "containerColor", value)
                        }
                        ToggleRow {
                            visible: root.isAllScope
                            Layout.fillWidth: true
                            title: "Apply container colors to popup cards"
                            detail: "Let Power, Clock, Utilities, Notes, Tasks, Presets, Notifications and Tools cards follow their container colors."
                            checked: root.allSetting("applyPopupCardColor", false)
                            enabledControl: !root.writing
                            onToggleRequested: root.toggleAll("applyPopupCardColor")
                        }
                        ToggleRow {
                            visible: root.isAllScope
                            Layout.fillWidth: true
                            title: "Show network speed meter"
                            detail: "Show live upload/download speed in the navbar; detailed usage stays in Tools."
                            checked: root.dataMeterEnabled
                            enabledControl: !root.writing
                            onToggleRequested: root.dataMeterToggleRequested(!root.dataMeterEnabled)
                        }
                        ToggleRow {
                            visible: root.isAllScope
                            Layout.fillWidth: true
                            title: "Override icon colors"
                            detail: "Apply one color across every navbar icon."
                            checked: root.allSetting("applyIconColor", false)
                            enabledControl: !root.writing
                            onToggleRequested: root.toggleAll("applyIconColor")
                        }
                        PaletteRow {
                            visible: root.isAllScope && root.allSetting("applyIconColor", false)
                            Layout.fillWidth: true
                            title: "Icon color"
                            detail: "Auto contrast keeps icons readable."
                            options: root.iconColors
                            selectedColor: String(root.allSetting("iconColor", "auto"))
                            enabledControl: !root.writing
                            onColorPicked: value => root.setSetting("all", "-", "iconColor", value)
                        }

                        ToggleRow {
                            visible: !root.isAllScope
                            Layout.fillWidth: true
                            title: "Show this container"
                            detail: "Hide or show only this navbar element."
                            checked: root.containerSetting(root.selectedScope, "visible", true)
                            enabledControl: !root.writing && !root.visibilityLocked
                            onToggleRequested: root.setSetting("container", root.selectedScope, "visible",
                                root.containerSetting(root.selectedScope, "visible", true) ? "off" : "on")
                        }
                        Text {
                            visible: !root.isAllScope && root.visibilityLocked
                            Layout.fillWidth: true
                            text: "Visibility is locked. Disable All Containers → Override visibility first."
                            color: "#9A6722"
                            font.pixelSize: 8
                            wrapMode: Text.WordWrap
                        }
                        PaletteRow {
                            visible: !root.isAllScope
                            Layout.fillWidth: true
                            title: "Background"
                            detail: "Default restores the original container color."
                            options: root.containerColors
                            selectedColor: root.currentContainerColor()
                            enabledControl: !root.writing && !root.backgroundLocked
                            onColorPicked: value => root.setSetting("container", root.selectedScope, "containerColor", value)
                        }
                        Text {
                            visible: !root.isAllScope && root.backgroundLocked
                            Layout.fillWidth: true
                            text: "Background is locked. Disable All Containers → Override backgrounds first."
                            color: "#9A6722"
                            font.pixelSize: 8
                            wrapMode: Text.WordWrap
                        }
                        PaletteRow {
                            visible: !root.isAllScope
                            Layout.fillWidth: true
                            title: "Icon color"
                            detail: "Inherit keeps the original style; Auto selects a contrast-safe color."
                            options: root.individualIconColors
                            selectedColor: String(root.containerSetting(root.selectedScope, "iconColor", "inherit"))
                            enabledControl: !root.writing && !root.iconLocked
                            onColorPicked: value => root.setSetting("container", root.selectedScope, "iconColor", value)
                        }
                        Text {
                            visible: !root.isAllScope && root.iconLocked
                            Layout.fillWidth: true
                            text: "Icon color is locked. Disable All Containers → Override icon colors first."
                            color: "#9A6722"
                            font.pixelSize: 8
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }

    component ToggleRow: RowLayout {
        id: toggleRoot
        property string title: ""
        property string detail: ""
        property bool checked: false
        property bool enabledControl: true
        signal toggleRequested()
        spacing: 10
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                Layout.fillWidth: true
                text: toggleRoot.title
                color: "#28313B"
                font.pixelSize: 9
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
            }
            Text {
                Layout.fillWidth: true
                text: toggleRoot.detail
                color: "#858E99"
                font.pixelSize: 7
                wrapMode: Text.WordWrap
            }
        }
        Rectangle {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 19
            radius: 10
            color: toggleRoot.checked ? "#252B33" : "#E2E6EA"
            Behavior on color {
                ColorAnimation { duration: 110; easing.type: Easing.OutCubic }
            }
            Rectangle {
                width: 13
                height: 13
                radius: 7
                y: 3
                x: toggleRoot.checked ? 18 : 3
                color: "#FFFFFF"
                Behavior on x {
                    NumberAnimation { duration: 115; easing.type: Easing.OutCubic }
                }
            }
            MouseArea {
                anchors.fill: parent
                enabled: toggleRoot.enabledControl
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: toggleRoot.toggleRequested()
            }
        }
    }

    component PaletteRow: RowLayout {
        id: paletteRoot
        property string title: ""
        property string detail: ""
        property var options: []
        property string selectedColor: ""
        property bool enabledControl: true
        signal colorPicked(string value)
        spacing: 8
        ColumnLayout {
            Layout.preferredWidth: 96
            Layout.minimumWidth: 82
            spacing: 3
            Text {
                Layout.fillWidth: true
                text: paletteRoot.title
                color: "#28313B"
                font.pixelSize: 9
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
            }
            Text {
                Layout.fillWidth: true
                text: paletteRoot.detail
                color: "#858E99"
                font.pixelSize: 7
                wrapMode: Text.WordWrap
            }
        }
        NavbarColorPalette {
            Layout.fillWidth: true
            Layout.preferredWidth: 250
            Layout.preferredHeight: implicitHeight
            options: paletteRoot.options
            selectedColor: paletteRoot.selectedColor
            pickerEnabled: paletteRoot.enabledControl
            onColorPicked: value => paletteRoot.colorPicked(value)
        }
    }

    onActiveChanged: {
        if (root.active)
            settingsFile.reload()
    }
}
