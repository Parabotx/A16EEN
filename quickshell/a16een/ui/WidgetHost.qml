import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property var modelData: null
    property bool timeEnabled: true
    property bool pulseEnabled: false
    property bool workspaceEnabled: false
    property bool timeUse24Hour: true
    property bool timeShowSeconds: false
    property real systemLoad: 0
    property int volumePercent: 0
    property bool volumeMuted: false
    property var workspaces: []
    property int focusedWorkspaceId: -1

    screen: root.modelData
    visible: root.modelData !== null
    color: "transparent"
    aboveWindows: false
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "a16een-widget-host"

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    // Each widget is independently loaded. A broken optional widget cannot
    // prevent the rest of A16EEN from starting.
    Loader {
        id: timeLoader
        anchors.fill: parent
        active: root.timeEnabled
        source: "TimeWidget.qml"

        onLoaded: {
            item.modelData = root.modelData
            item.widgetEnabled = root.timeEnabled
            item.use24Hour = root.timeUse24Hour
            item.showSeconds = root.timeShowSeconds
        }
    }

    Connections {
        target: root
        function onTimeEnabledChanged() {
            if (timeLoader.item) timeLoader.item.widgetEnabled = root.timeEnabled
        }
        function onTimeUse24HourChanged() {
            if (timeLoader.item) timeLoader.item.use24Hour = root.timeUse24Hour
        }
        function onTimeShowSecondsChanged() {
            if (timeLoader.item) timeLoader.item.showSeconds = root.timeShowSeconds
        }
    }

    Loader {
        id: pulseLoader
        anchors.fill: parent
        active: root.pulseEnabled
        source: "SystemPulseWidget.qml"

        onLoaded: {
            item.modelData = root.modelData
            item.widgetEnabled = root.pulseEnabled
            item.systemLoad = root.systemLoad
            item.volumePercent = root.volumePercent
            item.volumeMuted = root.volumeMuted
        }
    }

    Connections {
        target: root
        function onPulseEnabledChanged() {
            if (pulseLoader.item) pulseLoader.item.widgetEnabled = root.pulseEnabled
        }
        function onSystemLoadChanged() {
            if (pulseLoader.item) pulseLoader.item.systemLoad = root.systemLoad
        }
        function onVolumePercentChanged() {
            if (pulseLoader.item) pulseLoader.item.volumePercent = root.volumePercent
        }
        function onVolumeMutedChanged() {
            if (pulseLoader.item) pulseLoader.item.volumeMuted = root.volumeMuted
        }
    }

    Loader {
        id: workspaceLoader
        anchors.fill: parent
        active: root.workspaceEnabled
        source: "WorkspaceWidget.qml"

        onLoaded: {
            item.modelData = root.modelData
            item.widgetEnabled = root.workspaceEnabled
            item.workspaces = root.workspaces
            item.focusedWorkspaceId = root.focusedWorkspaceId
        }
    }

    Connections {
        target: root
        function onWorkspaceEnabledChanged() {
            if (workspaceLoader.item) workspaceLoader.item.widgetEnabled = root.workspaceEnabled
        }
        function onWorkspacesChanged() {
            if (workspaceLoader.item) workspaceLoader.item.workspaces = root.workspaces
        }
        function onFocusedWorkspaceIdChanged() {
            if (workspaceLoader.item) workspaceLoader.item.focusedWorkspaceId = root.focusedWorkspaceId
        }
    }
}
