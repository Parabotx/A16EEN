import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool active: false
    property var workspaces: []
    property var appearanceSettings: ({})
    property string selectedScope: "all"
    property string statusText: "READY"
    property string pendingScope: "all"
    property string pendingSlot: "-"
    property string pendingKey: ""
    property string pendingValue: ""

    readonly property string stateDir: {
        const stateHome = Quickshell.env("XDG_STATE_HOME")
        const home = Quickshell.env("HOME") || ""
        return (stateHome && stateHome.length ? stateHome : home + "/.local/state") + "/a16een"
    }
    readonly property string settingsPath: root.stateDir + "/navbar-appearance.json"
    readonly property bool writing: appearanceProcess.running

    readonly property var surfaceColors: [
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
        { value: "#1F2937", label: "Steel", swatch: "#1F2937" },
        { value: "#F1F5F9", label: "Cloud", swatch: "#F1F5F9" }
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

    readonly property var scopeChoices: {
        const list = [{ id: "all", name: "ALL WORKSPACES", description: "Shared settings" }]
        for (let i = 0; i < root.workspaces.length; i++) {
            const workspace = root.workspaces[i]
            list.push({
                id: String(workspace.id),
                name: String(workspace.name || workspace.id).toUpperCase(),
                description: String(workspace.description || "")
            })
        }
        return list
    }

    readonly property bool isAllScope: root.selectedScope === "all"
    readonly property bool globalVisibilityLocked: !root.isAllScope
        && root.allSetting("visibilityControl", false)
    readonly property bool globalContainerLocked: !root.isAllScope
        && root.allSetting("applyContainerColor", false)
    readonly property bool globalIconLocked: !root.isAllScope
        && root.allSetting("applyIconColor", false)

    function loadSettings(raw) {
        try {
            const parsed = JSON.parse(String(raw || "{}"))
            root.appearanceSettings = parsed && typeof parsed === "object"
                ? parsed : ({})
        } catch (error) {
            root.appearanceSettings = ({})
        }
    }

    function allSetting(key, fallback) {
        const all = root.appearanceSettings && root.appearanceSettings.all
            ? root.appearanceSettings.all : ({})
        return all[key] !== undefined ? all[key] : fallback
    }

    function workspaceSetting(slot, key, fallback) {
        const spaces = root.appearanceSettings && root.appearanceSettings.workspaces
            ? root.appearanceSettings.workspaces : ({})
        const item = spaces[slot] || ({})
        return item[key] !== undefined ? item[key] : fallback
    }

    function selectedScopeName() {
        const item = root.scopeChoices.find(function(entry) {
            return entry.id === root.selectedScope
        })
        return item ? item.name : "WORKSPACE"
    }

    function toggleValue(key) {
        return root.allSetting(key, false) ? "off" : "on"
    }

    function setSetting(scope, slot, key, value) {
        if (root.writing)
            return

        if (scope === "workspace") {
            if (key === "visible" && root.allSetting("visibilityControl", false)) {
                root.statusText = "TURN OFF ALL VISIBILITY CONTROL FIRST"
                return
            }
            if (key === "containerColor" && root.allSetting("applyContainerColor", false)) {
                root.statusText = "TURN OFF ALL CONTAINER COLOR FIRST"
                return
            }
            if (key === "iconColor" && root.allSetting("applyIconColor", false)) {
                root.statusText = "TURN OFF ALL ICON COLOR FIRST"
                return
            }
        }

        root.pendingScope = scope
        root.pendingSlot = slot
        root.pendingKey = key
        root.pendingValue = String(value)
        root.statusText = "APPLYING"
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
        command: [
            "/usr/local/bin/a16een-navbar-appearance",
            "set",
            root.pendingScope,
            root.pendingSlot,
            root.pendingKey,
            root.pendingValue
        ]
        running: false
        onExited: function(exitCode) {
            root.statusText = exitCode === 0 ? "SAVED" : "SAVE FAILED"
            settingsFile.reload()
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 14

        ColumnLayout {
            Layout.preferredWidth: 140
            Layout.minimumWidth: 124
            Layout.fillHeight: true
            spacing: 6

            Text {
                Layout.leftMargin: 6
                text: "SELECT NAVBAR"
                color: "#858E99"
                font.pixelSize: 8
                font.weight: Font.DemiBold
                font.letterSpacing: 1.0
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: scopeColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: scopeColumn
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: root.scopeChoices

                        delegate: Rectangle {
                            required property var modelData
                            width: scopeColumn.width
                            height: 43
                            radius: 9
                            color: root.selectedScope === modelData.id
                                ? "#E9EDF2"
                                : (scopeMouse.containsMouse ? "#F4F6F8" : "transparent")
                            border.width: root.selectedScope === modelData.id ? 1 : 0
                            border.color: "#D6DCE3"
                            opacity: root.writing ? 0.78 : 1

                            Column {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 9
                                anchors.rightMargin: 5
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
                                    visible: modelData.id === "all"
                                    text: "Every workspace"
                                    color: "#8A939E"
                                    font.pixelSize: 7
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: scopeMouse
                                anchors.fill: parent
                                enabled: !root.writing
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedScope = modelData.id
                            }
                        }
                    }
                }
            }

            Text {
                Layout.leftMargin: 5
                Layout.rightMargin: 5
                Layout.bottomMargin: 2
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
            radius: 13
            color: "#FFFFFF"
            border.width: 1
            border.color: "#E6E9ED"
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 7

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            text: root.isAllScope ? "Navbar appearance" : root.selectedScopeName()
                            color: "#161A20"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.isAllScope
                                ? "Set the shared surface and apply colors across every workspace."
                                : "Customize only this workspace button."
                            color: "#7B8591"
                            font.pixelSize: 9
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

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#EDF0F3"
                }

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

                        Text {
                            visible: root.isAllScope
                            text: "NAVBAR SURFACE"
                            color: "#7C8794"
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                        }

                        NavbarColorPalette {
                            visible: root.isAllScope
                            Layout.fillWidth: true
                            Layout.preferredHeight: implicitHeight
                            options: root.surfaceColors
                            selectedColor: String(root.allSetting("surfaceColor", "#FFFFFF"))
                            pickerEnabled: !root.writing
                            onColorPicked: value => root.setSetting("all", "-", "surfaceColor", value)
                        }

                        Rectangle {
                            visible: root.isAllScope
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: "#EDF0F3"
                        }

                        Text {
                            visible: root.isAllScope
                            text: "ALL WORKSPACE CONTROLS"
                            color: "#7C8794"
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                        }

                        Repeater {
                            visible: root.isAllScope
                            model: [
                                {
                                    key: "visibilityControl",
                                    title: "Control visibility for all",
                                    detail: "Temporarily replace individual visibility switches."
                                },
                                {
                                    key: "applyContainerColor",
                                    title: "Apply one container color",
                                    detail: "Use one background color for all workspace buttons."
                                },
                                {
                                    key: "applyIconColor",
                                    title: "Apply one icon color",
                                    detail: "Use one icon color across every workspace."
                                }
                            ]

                            delegate: RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 10

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: modelData.title
                                        color: "#28313B"
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: modelData.detail
                                        color: "#858E99"
                                        font.pixelSize: 8
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: 34
                                    Layout.preferredHeight: 19
                                    radius: 10
                                    color: root.allSetting(modelData.key, false) ? "#252B33" : "#E2E6EA"

                                    Rectangle {
                                        width: 13
                                        height: 13
                                        radius: 7
                                        y: 3
                                        x: root.allSetting(modelData.key, false) ? 18 : 3
                                        color: "#FFFFFF"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: !root.writing
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setSetting("all", "-", modelData.key, root.toggleValue(modelData.key))
                                    }
                                }
                            }
                        }

                        RowLayout {
                            visible: root.isAllScope && root.allSetting("visibilityControl", false)
                            Layout.fillWidth: true
                            spacing: 10

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: "Show all workspace buttons"
                                    color: "#28313B"
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: "Turn the whole workspace strip on or off."
                                    color: "#858E99"
                                    font.pixelSize: 8
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 19
                                radius: 10
                                color: root.allSetting("visible", true) ? "#252B33" : "#E2E6EA"

                                Rectangle {
                                    width: 13
                                    height: 13
                                    radius: 7
                                    y: 3
                                    x: root.allSetting("visible", true) ? 18 : 3
                                    color: "#FFFFFF"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !root.writing
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setSetting("all", "-", "visible",
                                        root.allSetting("visible", true) ? "off" : "on")
                                }
                            }
                        }

                        Text {
                            visible: root.isAllScope && root.allSetting("applyContainerColor", false)
                            text: "CONTAINER COLOR FOR ALL"
                            color: "#7C8794"
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                        }

                        NavbarColorPalette {
                            visible: root.isAllScope && root.allSetting("applyContainerColor", false)
                            Layout.fillWidth: true
                            Layout.preferredHeight: implicitHeight
                            options: root.containerColors.filter(function(item) { return item.value !== "transparent" })
                            selectedColor: String(root.allSetting("containerColor", "#15171A"))
                            pickerEnabled: !root.writing
                            onColorPicked: value => root.setSetting("all", "-", "containerColor", value)
                        }

                        Text {
                            visible: root.isAllScope && root.allSetting("applyIconColor", false)
                            text: "ICON COLOR FOR ALL"
                            color: "#7C8794"
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                        }

                        NavbarColorPalette {
                            visible: root.isAllScope && root.allSetting("applyIconColor", false)
                            Layout.fillWidth: true
                            Layout.preferredHeight: implicitHeight
                            options: root.iconColors
                            selectedColor: String(root.allSetting("iconColor", "auto"))
                            pickerEnabled: !root.writing
                            onColorPicked: value => root.setSetting("all", "-", "iconColor", value)
                        }

                        Text {
                            visible: root.isAllScope && root.allSetting("applyIconColor", false)
                            text: "Auto contrast chooses black or white for visibility against each button background."
                            color: "#77818D"
                            font.pixelSize: 8
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            visible: !root.isAllScope
                            text: "WORKSPACE BUTTON"
                            color: "#7C8794"
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                        }

                        RowLayout {
                            visible: !root.isAllScope
                            Layout.fillWidth: true
                            spacing: 10

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: "Show this workspace"
                                    color: "#28313B"
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: "Hide only this button from the navbar."
                                    color: "#858E99"
                                    font.pixelSize: 8
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 19
                                radius: 10
                                opacity: (root.globalVisibilityLocked || root.writing) ? 0.42 : 1
                                color: root.workspaceSetting(root.selectedScope, "visible", true) ? "#252B33" : "#E2E6EA"

                                Rectangle {
                                    width: 13
                                    height: 13
                                    radius: 7
                                    y: 3
                                    x: root.workspaceSetting(root.selectedScope, "visible", true) ? 18 : 3
                                    color: "#FFFFFF"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !root.writing && !root.globalVisibilityLocked
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: root.setSetting("workspace", root.selectedScope, "visible",
                                        root.workspaceSetting(root.selectedScope, "visible", true) ? "off" : "on")
                                }
                            }
                        }

                        Text {
                            visible: root.globalVisibilityLocked
                            text: "Individual visibility is locked. Turn off 'Control visibility for all' under All Workspaces first."
                            color: "#9A6722"
                            font.pixelSize: 8
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            visible: !root.isAllScope
                            text: "CONTAINER BACKGROUND"
                            color: "#7C8794"
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                        }

                        NavbarColorPalette {
                            visible: !root.isAllScope
                            Layout.fillWidth: true
                            Layout.preferredHeight: implicitHeight
                            options: root.containerColors
                            selectedColor: String(root.workspaceSetting(root.selectedScope, "containerColor", "transparent"))
                            pickerEnabled: !root.writing && !root.globalContainerLocked
                            onColorPicked: value => root.setSetting("workspace", root.selectedScope, "containerColor", value)
                        }

                        Text {
                            visible: root.globalContainerLocked
                            text: "Individual container colors are locked. Turn off 'Apply one container color' under All Workspaces first."
                            color: "#9A6722"
                            font.pixelSize: 8
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            visible: !root.isAllScope
                            text: "ICON COLOR"
                            color: "#7C8794"
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                        }

                        NavbarColorPalette {
                            visible: !root.isAllScope
                            Layout.fillWidth: true
                            Layout.preferredHeight: implicitHeight
                            options: root.individualIconColors
                            selectedColor: String(root.workspaceSetting(root.selectedScope, "iconColor", "inherit"))
                            pickerEnabled: !root.writing && !root.globalIconLocked
                            onColorPicked: value => root.setSetting("workspace", root.selectedScope, "iconColor", value)
                        }

                        Text {
                            visible: root.globalIconLocked
                            text: "Individual icon colors are locked. Turn off 'Apply one icon color' under All Workspaces first."
                            color: "#9A6722"
                            font.pixelSize: 8
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            visible: !root.isAllScope
                            text: "Inherit keeps the original icon style. Auto contrast adjusts the icon to remain readable on its container."
                            color: "#77818D"
                            font.pixelSize: 8
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }

    onActiveChanged: {
        if (root.active)
            settingsFile.reload()
    }
}
