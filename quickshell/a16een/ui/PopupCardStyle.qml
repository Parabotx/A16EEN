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

    readonly property color backgroundColor: {
        if (root.allSettings.applyPopupCardColor !== true)
            return "#FFFFFF"
        if (root.allSettings.applyContainerColor === true && root.validColor(root.allSettings.containerColor))
            return String(root.allSettings.containerColor)
        if (root.selectedContainer.containerEnabled === true && root.validColor(root.selectedContainer.containerColor))
            return String(root.selectedContainer.containerColor)
        return "#FFFFFF"
    }
    readonly property color borderColor: {
        const hex = String(root.backgroundColor).replace("#", "")
        const brightness = (parseInt(hex.slice(0, 2), 16) * 299
            + parseInt(hex.slice(2, 4), 16) * 587
            + parseInt(hex.slice(4, 6), 16) * 114) / 1000
        return brightness < 120 ? "#3C424C" : "#D9DEE5"
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
}
