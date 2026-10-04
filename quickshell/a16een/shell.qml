//@ pragma AppId a16een

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import Quickshell.Services.UPower
import qs.ui

ShellRoot {
    id: root

    property bool launcherOpen: false
    property bool dashboardOpen: false
    property string searchText: ""

    property var workspaces: []
    property var windows: []
    property int focusedWorkspaceId: -1
    property int focusedWindowId: -1
    property string activeTitle: "A16EEN"

    property real systemLoad: 0
    property int volumePercent: 0
    property bool volumeMuted: false
    property string networkLabel: "OFFLINE"
    property string bluetoothLabel: "BT OFF"

    property var latestNotification: null

    readonly property var primaryScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    function consumeNiriEvent(raw) {
        const line = String(raw).trim()
        if (!line.length) return

        try {
            const event = JSON.parse(line)

            if (event.WorkspacesChanged) {
                root.workspaces = event.WorkspacesChanged.workspaces || []
                return
            }

            if (event.WindowsChanged) {
                root.windows = event.WindowsChanged.windows || []
                return
            }

            if (event.WindowOpenedOrChanged) {
                const incoming = event.WindowOpenedOrChanged.window
                const next = [...root.windows].filter(window => window.id !== incoming.id)
                next.push(incoming)
                root.windows = next
                if (incoming.is_focused) root.focusedWindowId = incoming.id
                return
            }

            if (event.WindowClosed) {
                root.windows = root.windows.filter(window => window.id !== event.WindowClosed.id)
                if (root.focusedWindowId === event.WindowClosed.id) {
                    root.focusedWindowId = -1
                }
                return
            }

            if (event.WindowFocusChanged) {
                root.focusedWindowId = event.WindowFocusChanged.id === null
                    ? -1
                    : event.WindowFocusChanged.id
                return
            }

            if (event.WorkspaceActivated) {
                if (event.WorkspaceActivated.focused === true) {
                    root.focusedWorkspaceId = event.WorkspaceActivated.id
                }
                return
            }
        } catch (error) {
            // Ignore malformed or version-incompatible event lines.
        }
    }

    readonly property string computedActiveTitle: {
        const focused = root.windows.find(window => window.id === root.focusedWindowId)
        return focused ? (focused.title || focused.app_id || "Desktop") : "A16EEN"
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.launcherOpen = !root.launcherOpen
            if (root.launcherOpen) root.dashboardOpen = false
        }

        function open(): void {
            root.launcherOpen = true
            root.dashboardOpen = false
        }

        function close(): void {
            root.launcherOpen = false
        }
    }

    IpcHandler {
        target: "dashboard"

        function toggle(): void {
            root.dashboardOpen = !root.dashboardOpen
            if (root.dashboardOpen) root.launcherOpen = false
        }

        function open(): void {
            root.dashboardOpen = true
            root.launcherOpen = false
        }

        function close(): void {
            root.dashboardOpen = false
        }
    }

    NotificationServer {
        id: notificationServer

        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        imageSupported: true
        actionsSupported: false
        persistenceSupported: false

        onNotification: notification => {
            if (root.latestNotification) root.latestNotification.tracked = false
            notification.tracked = true
            root.latestNotification = notification
            notificationTimer.restart()
        }
    }

    Timer {
        id: notificationTimer
        interval: 5500
        repeat: false

        onTriggered: {
            if (root.latestNotification) {
                root.latestNotification.tracked = false
            }
            root.latestNotification = null
        }
    }

    Process {
        id: niriEvents

        command: ["niri", "msg", "--json", "event-stream"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.consumeNiriEvent(data)
        }

        onRunningChanged: {
            if (!running) reconnectTimer.start()
        }
    }

    Timer {
        id: reconnectTimer
        interval: 1500
        repeat: false
        onTriggered: niriEvents.running = true
    }

    Process {
        id: loadProcess

        command: ["cat", "/proc/loadavg"]

        stdout: StdioCollector {
            onStreamFinished: {
                const pieces = text.trim().split(/\s+/)
                if (pieces.length > 0) root.systemLoad = Number(pieces[0]) || 0
            }
        }
    }

    Process {
        id: volumeProcess

        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]

        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim()
                const match = output.match(/Volume:\s*([0-9.]+)/)
                if (match) root.volumePercent = Math.round(Number(match[1]) * 100)
                root.volumeMuted = /\[MUTED\]/.test(output)
            }
        }
    }

    Process {
        id: networkProcess

        command: ["nmcli", "-t", "-f", "STATE,CONNECTION,TYPE", "connection", "show", "--active"]

        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim().split("\n").find(value => value.length)
                if (!line) {
                    root.networkLabel = "OFFLINE"
                    return
                }
                const pieces = line.split(":")
                root.networkLabel = pieces.length > 1 && pieces[1].length ? pieces[1] : "CONNECTED"
            }
        }
    }

    Process {
        id: bluetoothProcess

        command: ["bluetoothctl", "show"]

        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/Powered:\s*(yes|no)/i)
                root.bluetoothLabel = match && match[1].toLowerCase() === "yes" ? "BT ON" : "BT OFF"
            }
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: true

        onTriggered: {
            loadProcess.running = false
            loadProcess.running = true

            volumeProcess.running = false
            volumeProcess.running = true

            networkProcess.running = false
            networkProcess.running = true

            bluetoothProcess.running = false
            bluetoothProcess.running = true
        }
    }

    Variants {
        model: Quickshell.screens

        Wallpaper {
            modelData: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        TopBar {
            modelData: modelData
            workspaces: root.workspaces
            focusedWorkspaceId: root.focusedWorkspaceId
            activeTitle: root.computedActiveTitle
            systemLoad: root.systemLoad
            volumePercent: root.volumePercent
            volumeMuted: root.volumeMuted
            networkLabel: root.networkLabel
            bluetoothLabel: root.bluetoothLabel
        }
    }

    Launcher {
        modelData: root.primaryScreen
        opened: root.launcherOpen
        searchText: root.searchText
        onSearchTextChanged: root.searchText = searchText
    }

    Dashboard {
        modelData: root.primaryScreen
        opened: root.dashboardOpen
        activeTitle: root.computedActiveTitle
        systemLoad: root.systemLoad
        volumePercent: root.volumePercent
        volumeMuted: root.volumeMuted
    }

    NotificationToast {
        modelData: root.primaryScreen
        notification: root.latestNotification
    }
}
