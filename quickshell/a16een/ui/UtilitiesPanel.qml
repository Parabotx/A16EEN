import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.ui

PanelWindow {
    id: root

    required property var modelData
    required property string navbarPosition
    property bool opened: false
    property bool dockVisible: true
    property string selectedMode: "wifi"

    signal closeRequested()
    signal modeRequested(string mode)

    readonly property bool horizontalNavbar:
        root.navbarPosition === "top" || root.navbarPosition === "bottom"
    readonly property real screenWidth: root.modelData ? root.modelData.width : 1920
    readonly property real screenHeight: root.modelData ? root.modelData.height : 1080
    readonly property int popupWidth: 360
    readonly property int popupHeight: root.selectedMode === "clipboard" ? 440 : 340
    readonly property real popupX: root.horizontalNavbar
        ? 100
        : (root.navbarPosition === "left"
            ? 66
            : Math.max(8, root.screenWidth - root.popupWidth - 66))
    readonly property real popupY: root.horizontalNavbar
        ? (root.navbarPosition === "top"
            ? 42
            : Math.max(8, root.screenHeight - root.popupHeight - 42))
        : 118

    screen: root.modelData
    visible: root.opened && root.dockVisible && root.modelData !== null
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    focusable: root.opened
    width: root.screenWidth
    height: root.screenHeight

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-utilities"
    WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    MouseArea {
        id: outsideClick
        anchors.fill: parent
        z: 0
        focus: true
        acceptedButtons: Qt.AllButtons

        onClicked: root.closeRequested()
        Keys.onEscapePressed: root.closeRequested()
    }

    Item {
        id: card
        x: Math.max(8, Math.min(root.popupX, root.screenWidth - width - 8))
        y: Math.max(8, Math.min(root.popupY, root.screenHeight - height - 8))
            + (root.opened ? 0 : 8)
        width: Math.min(root.popupWidth, root.screenWidth - 16)
        height: Math.min(root.popupHeight, root.screenHeight - 16)
        z: 1
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.96
        transformOrigin: Item.Center

        Behavior on opacity {
            NumberAnimation {
                duration: 170
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 210
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: 210
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: "#FFFFFF"
            border.width: 1
            border.color: "#D9DEE5"

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: 20
                color: "#16000000"
                z: -1
            }

            MouseArea {
                anchors.fill: parent
                z: 0
                acceptedButtons: Qt.AllButtons
                onClicked: mouse.accepted = true
            }

            Column {
                id: cardContent
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8
                z: 1

                Row {
                    id: modeTabs
                    width: parent.width
                    height: 29
                    spacing: 6

                    Repeater {
                        model: [
                            { id: "wifi", label: "Wi-Fi", icon: "wifi" },
                            { id: "bluetooth", label: "Bluetooth", icon: "bluetooth" }
                        ]

                        delegate: Rectangle {
                            id: tabButton
                            required property var modelData
                            width: (modeTabs.width - modeTabs.spacing) / 2
                            height: 29
                            radius: 9
                            color: root.selectedMode === tabButton.modelData.id
                                ? "#20262E"
                                : (tabMouse.containsMouse ? "#EEF1F4" : "#F6F7F9")
                            border.width: 1
                            border.color: root.selectedMode === tabButton.modelData.id
                                ? "#20262E" : "#E3E8ED"

                            Behavior on color {
                                ColorAnimation { duration: 120 }
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Image {
                                    width: 14
                                    height: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: Qt.resolvedUrl("../assets/icons/"
                                        + "lucide-" + tabButton.modelData.icon
                                        + (root.selectedMode === tabButton.modelData.id
                                            ? "-refined.svg" : "-refined-dark.svg"))
                                    sourceSize.width: 28
                                    sourceSize.height: 28
                                    smooth: true
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: tabButton.modelData.label
                                    color: root.selectedMode === tabButton.modelData.id
                                        ? "#FFFFFF" : "#5D6875"
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.modeRequested(tabButton.modelData.id)
                            }
                        }
                    }
                }

                Rectangle {
                    id: clipboardButton
                    width: parent.width
                    height: 29
                    radius: 9
                    color: root.selectedMode === "clipboard"
                        ? "#20262E"
                        : (clipboardButtonMouse.containsMouse ? "#EEF1F4" : "#F6F7F9")
                    border.width: 1
                    border.color: root.selectedMode === "clipboard" ? "#20262E" : "#E3E8ED"

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 7

                        Image {
                            width: 14
                            height: 14
                            anchors.verticalCenter: parent.verticalCenter
                            source: Qt.resolvedUrl("../assets/icons/lucide-clipboard"
                                + (root.selectedMode === "clipboard"
                                    ? "-refined.svg" : "-refined-dark.svg"))
                            sourceSize.width: 28
                            sourceSize.height: 28
                            smooth: true
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Clipboard"
                            color: root.selectedMode === "clipboard" ? "#FFFFFF" : "#5D6875"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "24H"
                        color: root.selectedMode === "clipboard" ? "#CBD2DB" : "#8A939E"
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.6
                    }

                    MouseArea {
                        id: clipboardButtonMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.modeRequested("clipboard")
                    }
                }

                Item {
                    id: detailPane
                    width: parent.width
                    height: parent.height - modeTabs.height - clipboardButton.height
                        - cardContent.spacing * 2

                    ControlDetailSection {
                        id: details
                        anchors.fill: parent
                        mode: root.selectedMode
                        active: root.opened && root.selectedMode !== "clipboard"
                        embedded: true
                        doNotDisturb: false
                        visible: root.selectedMode !== "clipboard"
                        onBackRequested: root.closeRequested()
                    }

                    Item {
                        id: clipboardContent
                        anchors.fill: parent
                        visible: root.selectedMode === "clipboard"

                        property var clipboardItems: []
                        property string clipboardSearch: ""
                        property string clipboardActionMessage: ""

                        readonly property var filteredClipboardItems:
                            rootFilter(clipboardItems, clipboardSearch)

                        function rootFilter(items, query) {
                            const needle = String(query || "").trim().toLowerCase()
                            if (!needle)
                                return items
                            return items.filter(item =>
                                String(item.content || "").toLowerCase().includes(needle))
                        }

                        function previewText(value) {
                            return String(value || "").replace(/\s+/g, " ").trim()
                        }

                        function ageLabel(timestamp) {
                            const seconds = Math.max(0, Math.floor((Date.now() - Number(timestamp || 0)) / 1000))
                            if (seconds < 60)
                                return "now"
                            if (seconds < 3600)
                                return Math.floor(seconds / 60) + "m"
                            return Math.floor(seconds / 3600) + "h"
                        }

                        function refreshHistory() {
                            if (!clipboardListProcess.running)
                                clipboardListProcess.running = true
                        }

                        function runAction(action, entryId) {
                            if (clipboardActionProcess.running)
                                return
                            clipboardContent.clipboardActionMessage = action === "copy"
                                ? "Copied" : (action === "delete" ? "Removed" : "History cleared")
                            clipboardActionProcess.command = entryId
                                ? ["/usr/local/bin/a16een-clipboard", action, String(entryId)]
                                : ["/usr/local/bin/a16een-clipboard", action]
                            clipboardActionProcess.running = true
                        }

                        Process {
                            id: clipboardListProcess
                            command: ["/usr/local/bin/a16een-clipboard", "list"]
                            running: false

                            stdout: StdioCollector {
                                onStreamFinished: {
                                    try {
                                        clipboardContent.clipboardItems = JSON.parse(String(text || "[]"))
                                    } catch (error) {
                                        clipboardContent.clipboardItems = []
                                        console.warn("A16EEN clipboard history could not be read:", error)
                                    }
                                }
                            }
                        }

                        Process {
                            id: clipboardActionProcess
                            command: ["/usr/local/bin/a16een-clipboard", "list"]
                            running: false

                            onExited: (exitCode, exitStatus) => {
                                if (exitCode !== 0)
                                    clipboardContent.clipboardActionMessage = "Action failed"
                                clipboardStatusReset.restart()
                                clipboardContent.refreshHistory()
                            }
                        }

                        Timer {
                            interval: 1800
                            repeat: true
                            running: root.opened && root.selectedMode === "clipboard"
                            onTriggered: clipboardContent.refreshHistory()
                        }

                        Timer {
                            id: clipboardStatusReset
                            interval: 2300
                            repeat: false
                            onTriggered: clipboardContent.clipboardActionMessage = ""
                        }

                        onVisibleChanged: {
                            if (visible) {
                                clipboardContent.refreshHistory()
                                Qt.callLater(() => clipboardSearchInput.forceActiveFocus())
                            } else {
                                clipboardSearch = ""
                            }
                        }

                        Column {
                            anchors.fill: parent
                            spacing: 7

                            Row {
                                width: parent.width
                                height: 15
                                spacing: 7

                                Text {
                                    text: "RECENT COPIES"
                                    color: "#687381"
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.8
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: String(clipboardContent.clipboardItems.length)
                                    color: "#9AA3AE"
                                    font.pixelSize: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Item { width: parent.width - 155; height: 1 }

                                Text {
                                    id: clipboardClearLabel
                                    text: "CLEAR"
                                    color: clipboardClearMouse.containsMouse ? "#111318" : "#7B8591"
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: clipboardContent.clipboardItems.length > 0

                                    MouseArea {
                                        id: clipboardClearMouse
                                        anchors.fill: parent
                                        anchors.margins: -5
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: clipboardContent.runAction("clear", "")
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 31
                                radius: 9
                                color: "#F7F8FA"
                                border.width: 1
                                border.color: clipboardSearchInput.activeFocus ? "#BBC4CE" : "#E5E9ED"

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 9
                                    anchors.rightMargin: 8
                                    spacing: 7

                                    Image {
                                        width: 13
                                        height: 13
                                        anchors.verticalCenter: parent.verticalCenter
                                        source: Qt.resolvedUrl("../assets/icons/search.svg")
                                        sourceSize.width: 26
                                        sourceSize.height: 26
                                        smooth: true
                                    }

                                    Item {
                                        width: parent.width - 24
                                        height: parent.height

                                        Text {
                                            anchors.fill: parent
                                            verticalAlignment: Text.AlignVCenter
                                            text: "Search copied text"
                                            color: "#9AA3AE"
                                            font.pixelSize: 10
                                            visible: clipboardSearchInput.text.length === 0
                                        }

                                        TextInput {
                                            id: clipboardSearchInput
                                            anchors.fill: parent
                                            verticalAlignment: TextInput.AlignVCenter
                                            text: clipboardContent.clipboardSearch
                                            onTextChanged: clipboardContent.clipboardSearch = text
                                            color: "#222831"
                                            selectionColor: "#DDE5EF"
                                            selectedTextColor: "#111318"
                                            font.pixelSize: 10
                                            clip: true
                                            activeFocusOnTab: true
                                            Keys.onEscapePressed: root.closeRequested()
                                        }
                                    }
                                }
                            }

                            Item {
                                width: parent.width
                                height: Math.max(0, parent.height - 15 - 31 - 14)

                                ListView {
                                    id: clipboardHistoryList
                                    anchors.fill: parent
                                    clip: true
                                    spacing: 3
                                    model: clipboardContent.filteredClipboardItems
                                    visible: clipboardContent.filteredClipboardItems.length > 0
                                    boundsBehavior: Flickable.StopAtBounds

                                    delegate: Rectangle {
                                        id: clipboardEntry
                                        required property var modelData
                                        width: clipboardHistoryList.width
                                        height: 32
                                        radius: 8
                                        color: clipboardEntryMouse.containsMouse ? "#EEF1F4" : "#FAFBFC"

                                        MouseArea {
                                            id: clipboardEntryMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: clipboardContent.runAction("copy", clipboardEntry.modelData.id)
                                        }

                                        Row {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 5
                                            spacing: 6

                                            Text {
                                                width: Math.max(35, parent.width - 57)
                                                height: parent.height
                                                verticalAlignment: Text.AlignVCenter
                                                text: clipboardContent.previewText(clipboardEntry.modelData.content)
                                                color: "#252B33"
                                                font.pixelSize: 9
                                                elide: Text.ElideRight
                                                maximumLineCount: 1
                                            }

                                            Text {
                                                width: 19
                                                height: parent.height
                                                verticalAlignment: Text.AlignVCenter
                                                horizontalAlignment: Text.AlignRight
                                                text: clipboardContent.ageLabel(clipboardEntry.modelData.timestamp)
                                                color: "#98A1AC"
                                                font.pixelSize: 8
                                            }

                                            Item {
                                                width: 13
                                                height: parent.height

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "×"
                                                    color: removeClipboardMouse.containsMouse ? "#111318" : "#98A1AC"
                                                    font.pixelSize: 14
                                                }

                                                MouseArea {
                                                    id: removeClipboardMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        mouse.accepted = true
                                                        clipboardContent.runAction("delete", clipboardEntry.modelData.id)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 5
                                    visible: clipboardContent.filteredClipboardItems.length === 0

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: clipboardContent.clipboardSearch.trim().length
                                            ? "No matching text"
                                            : "Nothing copied yet"
                                        color: "#596573"
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: clipboardContent.clipboardSearch.trim().length
                                            ? "Try a different search"
                                            : "Text clears automatically after 24 hours"
                                        color: "#9AA3AE"
                                        font.pixelSize: 8
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                height: 12
                                text: clipboardContent.clipboardActionMessage.length
                                    ? clipboardContent.clipboardActionMessage
                                    : "Click an item to copy it again"
                                color: "#97A1AD"
                                font.pixelSize: 8
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
