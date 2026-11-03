import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    property bool active: false
    property var workspaceItems: []
    property int focusedWorkspaceId: -1
    property string navbarPosition: "right"
    property var wallpaperAssignments: ({})
    property string selectedWorkspaceName: ""
    property string currentProfile: "adaptive"
    property string statusMessage: "READY"
    property string pendingRailPosition: ""

    signal backRequested()
    signal navbarPositionRequested(string position)
    signal workspaceWallpaperRequested(string workspaceName)

    readonly property var workspaceList: {
        const source = Array.isArray(root.workspaceItems) ? root.workspaceItems : []
        const named = source.filter(item => item && String(item.name || "").length && String(item.name) !== "app-stash")
        if (named.length) return named
        return [{id:1,name:"home"},{id:2,name:"code"},{id:3,name:"web"},{id:4,name:"comms"},{id:5,name:"studio"},{id:6,name:"music"}]
    }
    readonly property string selectedLabel: {
        const found = root.workspaceList.find(item => String(item.name) === root.selectedWorkspaceName)
        return found ? String(found.name).replace(/-/g," ").toUpperCase() : "HOME"
    }
    readonly property string selectedWallpaperPath: String((root.wallpaperAssignments || {})[root.selectedWorkspaceName] || "")
    readonly property string selectedWallpaperName: root.selectedWallpaperPath.length ? root.selectedWallpaperPath.split("/").pop() : "Using default desktop wallpaper"
    readonly property bool horizontalRail: root.navbarPosition === "top" || root.navbarPosition === "bottom"
    readonly property var layoutProfiles: [
        {id:"adaptive",title:"ADAPTIVE",subtitle:"Full width → balanced columns",description:"One window fills the workspace. When another opens, columns share the available width."},
        {id:"columns",title:"COLUMNS",subtitle:"Consistent side-by-side",description:"Keep tiled columns at half width, with more columns available by scrolling."},
        {id:"canvas",title:"CANVAS",subtitle:"Freeform desktop",description:"Windows become floating panels. Move and resize them freely across the workspace."}
    ]

    function selectWorkspace(name) {
        if (!name || root.selectedWorkspaceName === String(name)) return
        root.selectedWorkspaceName = String(name)
        root.loadProfile()
        root.statusMessage = "SELECTED " + root.selectedLabel
    }
    function loadProfile() {
        if (!root.selectedWorkspaceName.length) return
        profileReader.command = ["a16een-workspace-layout","get-profile",root.selectedWorkspaceName]
        profileReader.running = false
        Qt.callLater(() => profileReader.running = true)
    }
    function setProfile(profile) {
        if (!root.selectedWorkspaceName.length) return
        root.statusMessage = "APPLYING " + profile.toUpperCase() + " TO " + root.selectedLabel
        profileWriter.command = ["a16een-workspace-layout","set-profile",root.selectedWorkspaceName,profile]
        profileWriter.running = false
        Qt.callLater(() => profileWriter.running = true)
    }
    function setRailOrientation(horizontal) {
        const target = horizontal ? (root.navbarPosition === "bottom" ? "bottom" : "top") : (root.navbarPosition === "left" ? "left" : "right")
        if ((horizontal && root.horizontalRail) || (!horizontal && !root.horizontalRail)) return
        root.pendingRailPosition = target
        root.statusMessage = "UPDATING WORKSPACE RAIL"
        railWriter.command = ["a16een-navbar-layout","set",target]
        railWriter.running = false
        Qt.callLater(() => railWriter.running = true)
    }
    function changeWallpaper() {
        if (root.selectedWorkspaceName.length) root.workspaceWallpaperRequested(root.selectedWorkspaceName)
    }
    function clearWallpaper() {
        if (!root.selectedWorkspaceName.length) return
        wallpaperClearProcess.command = ["a16een-wallpaper","workspace-unset",root.selectedWorkspaceName]
        wallpaperClearProcess.running = false
        Qt.callLater(() => wallpaperClearProcess.running = true)
    }
    function syncSelectedWorkspace() {
        if (!root.active) return
        const focused = root.workspaceList.find(item => Number(item.id) === Number(root.focusedWorkspaceId))
        if (focused) root.selectedWorkspaceName = String(focused.name)
        else if (!root.selectedWorkspaceName.length && root.workspaceList.length) root.selectedWorkspaceName = String(root.workspaceList[0].name)
        root.loadProfile()
    }

    Process {
        id: profileReader
        command: ["a16een-workspace-layout","get-profile",root.selectedWorkspaceName || "home"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const value = String(text || "").trim()
                if (["adaptive","columns","canvas"].includes(value)) root.currentProfile = value
            }
        }
    }
    Process {
        id: profileWriter
        command: []
        running: false
        stderr: StdioCollector { onStreamFinished: { const message = String(text || "").trim(); if (message.length) root.statusMessage = message.toUpperCase() } }
        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.currentProfile = profileWriter.command[3] || "adaptive"
                root.statusMessage = "LAYOUT SAVED FOR " + root.selectedLabel
            } else root.statusMessage = "LAYOUT CHANGE FAILED"
        }
    }
    Process {
        id: railWriter
        command: []
        running: false
        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.navbarPosition = root.pendingRailPosition
                root.navbarPositionRequested(root.pendingRailPosition)
                root.statusMessage = "WORKSPACE RAIL UPDATED"
            } else root.statusMessage = "RAIL UPDATE FAILED"
        }
    }
    Process {
        id: wallpaperClearProcess
        command: []
        running: false
        onExited: function(exitCode) {
            root.statusMessage = exitCode === 0 ? "WORKSPACE WALLPAPER RESET" : "COULD NOT RESET WORKSPACE WALLPAPER"
        }
    }

    Component.onCompleted: root.syncSelectedWorkspace()
    onActiveChanged: { if (root.active) Qt.callLater(() => root.syncSelectedWorkspace()) }
    onFocusedWorkspaceIdChanged: { if (root.active) root.syncSelectedWorkspace() }
    Keys.onEscapePressed: root.backRequested()

    Column {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 15

        Row {
            width: parent.width
            height: 42
            spacing: 12
            Rectangle {
                width: 36; height: 36; radius: 11
                color: backMouse.containsMouse ? "#ECEFF3" : "#F5F6F8"
                border.width: 1; border.color: "#E2E6EB"
                anchors.verticalCenter: parent.verticalCenter
                Text { anchors.centerIn: parent; text: "‹"; color: "#20252C"; font.pixelSize: 25 }
                MouseArea { id: backMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.backRequested() }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                Text { text: "WORKSPACE STUDIO"; color: "#15191F"; font.pixelSize: 16; font.weight: Font.DemiBold; font.letterSpacing: 1.0 }
                Text { text: "Arrange how your desktop behaves in each space."; color: "#77818D"; font.pixelSize: 10 }
            }
        }

        Flickable {
            width: parent.width
            height: Math.max(0,parent.height-60)
            contentWidth: width
            contentHeight: contentColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: contentColumn
                width: parent.width
                spacing: 16

                Text { text: "WORKSPACE"; color: "#737D89"; font.pixelSize: 9; font.weight: Font.DemiBold; font.letterSpacing: 1.0 }
                Flickable {
                    width: parent.width; height: 52
                    contentWidth: workspaceButtons.implicitWidth; contentHeight: height
                    clip: true; flickableDirection: Flickable.HorizontalFlick
                    boundsBehavior: Flickable.StopAtBounds
                    Row {
                        id: workspaceButtons
                        spacing: 8
                        Repeater {
                            model: root.workspaceList
                            delegate: Rectangle {
                                required property var modelData
                                width: Math.max(72,Math.min(112,(root.width-92)/Math.min(root.workspaceList.length,6)))
                                height: 46; radius: 11
                                color: String(modelData.name) === root.selectedWorkspaceName ? "#20262F" : "#F5F6F8"
                                border.width: 1; border.color: String(modelData.name) === root.selectedWorkspaceName ? "#20262F" : "#E2E6EB"
                                Text {
                                    anchors.centerIn: parent
                                    text: String(modelData.name || "workspace").replace(/-/g," ").toUpperCase()
                                    color: String(modelData.name) === root.selectedWorkspaceName ? "#FFFFFF" : "#3D4652"
                                    font.pixelSize: 9; font.weight: Font.DemiBold
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selectWorkspace(modelData.name) }
                            }
                        }
                    }
                }

                Row {
                    width: parent.width; height: 26; spacing: 8
                    Text { text: "LAYOUT MODE"; color: "#737D89"; font.pixelSize: 9; font.weight: Font.DemiBold; font.letterSpacing: 1.0; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "FOR " + root.selectedLabel; color: "#B18B3F"; font.pixelSize: 9; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                }

                Row {
                    width: parent.width; height: 158; spacing: 9
                    Repeater {
                        model: root.layoutProfiles
                        delegate: Rectangle {
                            id: profileCard
                            required property var modelData
                            width: (contentColumn.width-18)/3; height: 150; radius: 13
                            color: root.currentProfile === modelData.id ? "#F8F3E8" : "#F7F8FA"
                            border.width: root.currentProfile === modelData.id ? 2 : 1
                            border.color: root.currentProfile === modelData.id ? "#C6A15A" : "#E5E8ED"
                            Column {
                                anchors.fill: parent; anchors.margins: 12; spacing: 9
                                Row {
                                    spacing: 7
                                    Text { text: modelData.title; color: "#1F252D"; font.pixelSize: 10; font.weight: Font.DemiBold }
                                    Text { text: root.currentProfile === modelData.id ? "✓" : ""; color: "#A7833F"; font.pixelSize: 11; font.weight: Font.Bold }
                                }
                                Rectangle {
                                    width: parent.width; height: 39; radius: 7; color: "#E8EBEF"
                                    Row {
                                        anchors.fill: parent; anchors.margins: 5; spacing: 4
                                        Repeater {
                                            model: modelData.id === "canvas" ? 3 : 2
                                            delegate: Rectangle {
                                                required property int index
                                                width: (parent.width - (profileCard.modelData.id === "canvas" ? 8 : 4)) / (profileCard.modelData.id === "canvas" ? 3 : 2)
                                                height: parent.height
                                                radius: 4
                                                color: profileCard.modelData.id === "canvas"
                                                    ? (index === 1 ? "#4C5968" : "#8C99A8")
                                                    : (profileCard.modelData.id === "adaptive" && index === 0 ? "#4C5968" : "#8C99A8")
                                                opacity: profileCard.modelData.id === "adaptive" && index === 1 ? 0.65 : 1
                                            }
                                        }
                                    }
                                }
                                Text { width: parent.width; text: modelData.subtitle; color: "#4F5966"; font.pixelSize: 8; font.weight: Font.DemiBold; wrapMode: Text.WordWrap }
                                Text { width: parent.width; text: modelData.description; color: "#77818D"; font.pixelSize: 8; wrapMode: Text.WordWrap }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.setProfile(modelData.id) }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: "#E7EAEE" }
                Text { text: "WORKSPACE RAIL"; color: "#737D89"; font.pixelSize: 9; font.weight: Font.DemiBold; font.letterSpacing: 1.0 }

                Row {
                    width: parent.width; height: 58; spacing: 10
                    Repeater {
                        model: [{id:"vertical",title:"VERTICAL",note:"Left or right edge"},{id:"horizontal",title:"HORIZONTAL",note:"Top or bottom edge"}]
                        delegate: Rectangle {
                            required property var modelData
                            width: (parent.width-10)/2; height: 54; radius: 11
                            color: (modelData.id === "horizontal") === root.horizontalRail ? "#F8F3E8" : "#F7F8FA"
                            border.width: (modelData.id === "horizontal") === root.horizontalRail ? 2 : 1
                            border.color: (modelData.id === "horizontal") === root.horizontalRail ? "#C6A15A" : "#E5E8ED"
                            Column {
                                anchors.centerIn: parent; spacing: 3
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.title; color: "#252B33"; font.pixelSize: 9; font.weight: Font.DemiBold }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.note; color: "#7B8591"; font.pixelSize: 8 }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.setRailOrientation(modelData.id === "horizontal") }
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: "Niri keeps workspaces vertically ordered internally. This setting changes the A16EEN workspace rail to a horizontal or vertical row."
                    color: "#8A939E"; font.pixelSize: 8; wrapMode: Text.WordWrap
                }

                Rectangle { width: parent.width; height: 1; color: "#E7EAEE" }

                Rectangle {
                    width: parent.width; height: 76; radius: 12; color: "#F7F8FA"; border.width: 1; border.color: "#E5E8ED"
                    Row {
                        anchors.fill: parent; anchors.margins: 13; spacing: 12
                        Column {
                            width: Math.max(120,parent.width-165); anchors.verticalCenter: parent.verticalCenter; spacing: 5
                            Text { text: "WORKSPACE WALLPAPER"; color: "#272E37"; font.pixelSize: 9; font.weight: Font.DemiBold; font.letterSpacing: 0.6 }
                            Text { width: parent.width; text: root.selectedWallpaperName; color: "#7A8592"; font.pixelSize: 8; elide: Text.ElideMiddle }
                        }
                        Rectangle {
                            width: 112; height: 34; radius: 9; color: "#222831"; anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: "CHANGE"; color: "#FFFFFF"; font.pixelSize: 8; font.weight: Font.DemiBold }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.changeWallpaper() }
                        }
                        Rectangle {
                            width: 30; height: 34; radius: 9; color: "#ECEFF3"; visible: root.selectedWallpaperPath.length>0
                            anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: "↺"; color: "#47515E"; font.pixelSize: 16 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.clearWallpaper() }
                        }
                    }
                }

                Text { text: root.statusMessage; color: "#9A7A3D"; font.pixelSize: 8; font.weight: Font.DemiBold; font.letterSpacing: 0.7 }
            }
        }
    }
}
