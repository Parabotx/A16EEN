import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    visible: false
    width: 0
    height: 0

    property string containerId: "utilities"
    property var appearanceSettings: ({})

    readonly property string stateDir: {
        const stateHome = Quickshell.env("XDG_STATE_HOME")
        const home = Quickshell.env("HOME") || ""
        return (stateHome && stateHome.length ? stateHome : home + "/.local/state") + "/a16een"
    }
    readonly property string appearanceSettingsPath: root.stateDir + "/navbar-appearance.json"
    readonly property string appearanceReadyPath: root.stateDir + "/navbar-icons/appearance-ready"
    readonly property var allSettings: root.appearanceSettings && root.appearanceSettings.all
        ? root.appearanceSettings.all : ({})
    readonly property var containers: root.appearanceSettings && root.appearanceSettings.containers
        ? root.appearanceSettings.containers : ({})
    readonly property var selectedContainer: root.containers[root.containerId] || ({})
    readonly property bool popupCardColorEnabled: root.containerId === "data-meter"
        || root.allSettings.applyPopupCardColor === true
        || root.selectedContainer.applyPopupCardColor === true

    function loadAppearanceSettings(raw) {
        try {
            const parsed = JSON.parse(String(raw || "{}"))
            root.appearanceSettings = parsed && typeof parsed === "object" ? parsed : ({})
        } catch (error) {
            root.appearanceSettings = ({})
        }
    }
    function validColor(value) {
        return /^#[0-9A-Fa-f]{6}$/.test(String(value || ""))
    }

    function luminance(value) {
        // QColor may stringify as either #RRGGBB or #AARRGGBB; read the
        // final six digits so contrast works with both representations.
        const match = String(value || "").match(/#(?:[0-9A-Fa-f]{2})?([0-9A-Fa-f]{6})$/)
        if (!match)
            return 255
        const hex = match[1]
        return (parseInt(hex.slice(0, 2), 16) * 299
            + parseInt(hex.slice(2, 4), 16) * 587
            + parseInt(hex.slice(4, 6), 16) * 114) / 1000
    }
    function validHexColor(value) {
        return /^#[0-9A-Fa-f]{6}$/.test(String(value || ""))
    }
    function relativeLuminance(value) {
        const match = String(value || "").match(/#(?:[0-9A-Fa-f]{2})?([0-9A-Fa-f]{6})$/)
        if (!match)
            return 1
        const hex = match[1]
        const channels = [
            parseInt(hex.slice(0, 2), 16) / 255,
            parseInt(hex.slice(2, 4), 16) / 255,
            parseInt(hex.slice(4, 6), 16) / 255
        ].map(channel => channel <= 0.04045
            ? channel / 12.92
            : Math.pow((channel + 0.055) / 1.055, 2.4))
        return channels[0] * 0.2126 + channels[1] * 0.7152 + channels[2] * 0.0722
    }
    function contrastRatio(firstColor, secondColor) {
        const first = root.relativeLuminance(firstColor)
        const second = root.relativeLuminance(secondColor)
        return (Math.max(first, second) + 0.05) / (Math.min(first, second) + 0.05)
    }

    // The global switch enables every popup. Otherwise each section can opt in
    // independently; the speed capsule keeps its existing per-container behavior.
    property color backgroundColor: {
        if (!root.popupCardColorEnabled)
            return "#FFFFFF"
        if (root.allSettings.applyContainerColor === true && root.validHexColor(root.allSettings.containerColor))
            return String(root.allSettings.containerColor)
        if (root.selectedContainer.containerEnabled === true
            && root.validHexColor(root.selectedContainer.containerColor))
            return String(root.selectedContainer.containerColor)
        return "#FFFFFF"
    }
    Behavior on backgroundColor {
        ColorAnimation { duration: 140; easing.type: Easing.OutCubic }
    }

    // Select the foreground with stronger actual contrast for custom colors.
    readonly property bool darkMode: root.contrastRatio("#F3F5F8", root.backgroundColor)
        > root.contrastRatio("#1B2027", root.backgroundColor)

    property color textColor: root.darkMode ? "#F3F5F8" : "#1B2027"
    property color secondaryTextColor: root.darkMode ? "#BAC3CE" : "#667180"
    property color mutedTextColor: root.darkMode ? "#929BA8" : "#8A939E"
    property color fieldColor: root.darkMode ? Qt.lighter(root.backgroundColor, 1.16) : "#FAFBFC"
    property color subtleSurfaceColor: root.darkMode ? Qt.lighter(root.backgroundColor, 1.10) : "#F7F8FA"
    property color hoverSurfaceColor: root.darkMode ? Qt.lighter(root.backgroundColor, 1.24) : "#EEF1F4"
    property color selectedSurfaceColor: root.darkMode ? Qt.lighter(root.backgroundColor, 1.34) : "#E9EDF1"
    property color fieldBorderColor: root.darkMode ? "#454D58" : "#E4E9EF"
    property color focusBorderColor: root.darkMode ? "#728198" : "#B8C5D4"
    property color actionColor: root.darkMode ? Qt.lighter(root.backgroundColor, 1.65) : "#242A32"
    property color actionHoverColor: root.darkMode ? Qt.lighter(root.backgroundColor, 1.90) : "#171C23"
    property color actionTextColor: "#F3F5F8"

    property color iconColor: {
        let desired = "inherit"
        if (root.allSettings.applyIconColor === true)
            desired = String(root.allSettings.iconColor || "auto")
        else if (root.selectedContainer.iconColor)
            desired = String(root.selectedContainer.iconColor)

        if (desired === "auto" || desired === "inherit" || !root.validHexColor(desired))
            return root.textColor
        // Keep explicit icon accents only when they remain distinguishable
        // against this popup's actual background.
        if (root.contrastRatio(desired, root.backgroundColor) < 3.0)
            return root.textColor
        return desired
    }

    property color dangerColor: root.darkMode ? "#FF827A" : "#B93832"
    property color successColor: root.darkMode ? "#75D6A3" : "#327858"
    property color borderColor: root.darkMode ? "#3C424C" : "#D9DEE5"
    Behavior on textColor { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
    Behavior on secondaryTextColor { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
    Behavior on mutedTextColor { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
    Behavior on fieldColor { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
    Behavior on subtleSurfaceColor { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
    Behavior on hoverSurfaceColor { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
    Behavior on selectedSurfaceColor { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
    Behavior on fieldBorderColor { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
    Behavior on focusBorderColor { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
    Behavior on actionColor { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
    Behavior on actionHoverColor { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
    Behavior on actionTextColor { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
    Behavior on iconColor { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
    Behavior on borderColor { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }

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
}
