pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool enabled: false
    property bool paletteReady: false
    property string scheme: ""
    property string wallpaper: ""
    property var palette: ({})

    readonly property string statePath: Quickshell.stateDir + "/wallpaper-theme.json"

    readonly property color background: root.color("background", "#10141B")
    readonly property color foreground: root.color("foreground", "#E8ECF2")
    readonly property color surface: root.color("surface", root.background)
    readonly property color onSurface: root.color("onSurface", root.foreground)
    readonly property color surfaceVariant: root.color("surfaceVariant", "#29313C")
    readonly property color onSurfaceVariant: root.color("onSurfaceVariant", "#C1CAD6")
    readonly property color primary: root.color("primary", "#A9BCE0")
    readonly property color onPrimary: root.color("onPrimary", "#172235")
    readonly property color primaryContainer: root.color("primaryContainer", "#344761")
    readonly property color onPrimaryContainer: root.color("onPrimaryContainer", "#E3EBF8")
    readonly property color secondary: root.color("secondary", "#AFC9C5")
    readonly property color tertiary: root.color("tertiary", "#D2B6CC")
    readonly property color outline: root.color("outline", "#748091")
    readonly property color error: root.color("error", "#CF7778")

    function color(key, fallback) {
        const value = String(root.palette && root.palette[key] || "")
        return /^#[0-9A-Fa-f]{6}$/.test(value) ? value : fallback
    }

    function load(raw) {
        try {
            const parsed = JSON.parse(String(raw || "{}"))
            root.enabled = parsed.enabled === true
            root.scheme = parsed.scheme === "light" || parsed.scheme === "dark"
                ? parsed.scheme : ""
            root.wallpaper = String(parsed.wallpaper || "")
            root.palette = parsed.palette && typeof parsed.palette === "object"
                ? parsed.palette : ({})
            root.paletteReady = Object.keys(root.palette).length > 0
        } catch (error) {
            root.enabled = false
            root.scheme = ""
            root.wallpaper = ""
            root.palette = ({})
            root.paletteReady = false
            console.warn("A16EEN wallpaper palette could not be read:", error)
        }
    }

    FileView {
        path: root.statePath
        watchChanges: true
        printErrors: false
        onLoaded: root.load(this.text())
        onFileChanged: root.load(this.text())
    }
}
