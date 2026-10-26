import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.ui
import "TicTacToe.js" as TicTacToe

PanelWindow {
    id: root

    PopupCardStyle {
        id: popupCardStyle
        containerId: "gaming"
    }

    required property var modelData
    required property string navbarPosition
    property bool opened: false
    property bool dockVisible: true
    property string currentView: "list"
    property var board: ["", "", "", "", "", "", "", "", ""]
    property string statusText: "YOUR TURN"
    property bool gameOver: false
    property bool botThinking: false

    signal closeRequested()

    readonly property bool horizontalNavbar:
        root.navbarPosition === "top" || root.navbarPosition === "bottom"
    readonly property real screenWidth: root.modelData ? root.modelData.width : 1920
    readonly property real screenHeight: root.modelData ? root.modelData.height : 1080
    readonly property int popupWidth: 310
    readonly property int popupHeight: root.currentView === "xo" ? 372 : 166
    readonly property real popupX: root.horizontalNavbar
        ? root.screenWidth - root.popupWidth - 102
        : (root.navbarPosition === "left"
            ? 66
            : root.screenWidth - root.popupWidth - 68)
    readonly property real popupY: root.horizontalNavbar
        ? (root.navbarPosition === "top"
            ? 40
            : root.screenHeight - root.popupHeight - 40)
        : root.screenHeight - root.popupHeight - 72

    screen: root.modelData
    visible: root.opened && root.dockVisible && root.modelData !== null
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    focusable: root.opened
    WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    width: root.screenWidth
    height: root.screenHeight
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-gaming"

    Timer {
        id: botMoveTimer
        interval: 180
        repeat: false
        onTriggered: root.playBotTurn()
    }

    function startGame() {
        botMoveTimer.stop()
        root.currentView = "xo"
        root.board = ["", "", "", "", "", "", "", "", ""]
        root.gameOver = false
        root.botThinking = false
        root.statusText = "YOUR TURN"
    }

    function returnToList() {
        botMoveTimer.stop()
        root.currentView = "list"
        root.botThinking = false
        root.gameOver = false
        root.statusText = "YOUR TURN"
    }

    function finishIfNeeded() {
        var result = TicTacToe.winner(root.board)
        if (result === "X") {
            root.statusText = "YOU WIN"
            root.gameOver = true
            root.botThinking = false
            return true
        }
        if (result === "O") {
            root.statusText = "BOT WINS"
            root.gameOver = true
            root.botThinking = false
            return true
        }
        if (TicTacToe.isFull(root.board)) {
            root.statusText = "DRAW"
            root.gameOver = true
            root.botThinking = false
            return true
        }
        return false
    }

    function playCell(index) {
        if (root.currentView !== "xo" || root.gameOver || root.botThinking
            || index < 0 || index > 8 || root.board[index] !== "")
            return

        var next = root.board.slice(0)
        next[index] = "X"
        root.board = next

        if (root.finishIfNeeded())
            return

        root.botThinking = true
        root.statusText = "BOT THINKING"
        botMoveTimer.restart()
    }

    function playBotTurn() {
        if (root.currentView !== "xo" || root.gameOver || !root.botThinking)
            return

        var choice = TicTacToe.bestMove(root.board, "O", "X")
        if (choice < 0) {
            root.finishIfNeeded()
            return
        }

        var next = root.board.slice(0)
        next[choice] = "O"
        root.board = next
        root.botThinking = false
        if (!root.finishIfNeeded())
            root.statusText = "YOUR TURN"
    }

    MouseArea {
        id: outsideClickArea
        anchors.fill: parent
        z: 0
        focus: true
        acceptedButtons: Qt.AllButtons
        onClicked: root.closeRequested()
        Keys.onEscapePressed: root.closeRequested()
    }

    Item {
        id: popup
        x: Math.max(8, Math.min(root.popupX, root.screenWidth - width - 8))
        y: Math.max(8, Math.min(root.popupY, root.screenHeight - height - 8))
        width: Math.min(root.popupWidth, root.screenWidth - 16)
        height: Math.min(root.popupHeight, root.screenHeight - 16)
        visible: root.opened && root.dockVisible
        z: 1

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: popupCardStyle.backgroundColor
            border.width: 1
            border.color: popupCardStyle.borderColor
            Behavior on color { ColorAnimation { duration: 135; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 135; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: 22
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
                anchors.fill: parent
                anchors.margins: 13
                spacing: 8
                z: 1

                Row {
                    width: parent.width
                    height: 28
                    spacing: 8

                    Rectangle {
                        visible: root.currentView === "xo"
                        width: visible ? 28 : 0
                        height: 28
                        radius: 9
                        color: backMouse.containsMouse ? popupCardStyle.hoverSurfaceColor : popupCardStyle.subtleSurfaceColor
                        border.width: 1
                        border.color: popupCardStyle.fieldBorderColor

                        NavbarIcon {
                            anchors.centerIn: parent
                            width: 15
                            height: 15
                            iconName: "lucide-arrow-left.svg"
                            iconColor: popupCardStyle.iconColor
                        }
                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.returnToList()
                        }
                        Accessible.name: "Back to games"
                    }

                    Text {
                        width: parent.width - (root.currentView === "xo" ? 28 : 0) - 28 - (root.currentView === "xo" ? 28 : 0) - parent.spacing * 3
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.currentView === "xo" ? "X & O" : "GAMES"
                        color: popupCardStyle.textColor
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        visible: root.currentView === "xo"
                        width: visible ? 28 : 0
                        height: 28
                        radius: 9
                        color: resetMouse.containsMouse ? popupCardStyle.hoverSurfaceColor : popupCardStyle.subtleSurfaceColor
                        border.width: 1
                        border.color: popupCardStyle.fieldBorderColor

                        NavbarIcon {
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            iconName: "lucide-rotate-cw-clean.svg"
                            iconColor: popupCardStyle.iconColor
                        }
                        MouseArea {
                            id: resetMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.startGame()
                        }
                        Accessible.name: "Restart X and O"
                    }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 9
                        color: closeMouse.containsMouse ? "#FBEDEE" : popupCardStyle.subtleSurfaceColor
                        border.width: 1
                        border.color: popupCardStyle.fieldBorderColor

                        NavbarIcon {
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            iconName: "lucide-x.svg"
                            iconColor: closeMouse.containsMouse ? "#B93832" : popupCardStyle.secondaryTextColor
                        }
                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeRequested()
                        }
                        Accessible.name: "Close games"
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: popupCardStyle.selectedSurfaceColor
                }

                Item {
                    width: parent.width
                    height: parent.height - 28 - 1 - parent.spacing * 2
                    visible: root.currentView === "list"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: 44
                        radius: 12
                        color: gameRowMouse.containsMouse ? popupCardStyle.hoverSurfaceColor : popupCardStyle.fieldColor
                        border.width: 1
                        border.color: gameRowMouse.containsMouse ? popupCardStyle.focusBorderColor : popupCardStyle.fieldBorderColor

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 10
                                anchors.verticalCenter: parent.verticalCenter
                                color: popupCardStyle.subtleSurfaceColor

                                NavbarIcon {
                                    anchors.centerIn: parent
                                    width: 18
                                    height: 18
                                    iconName: "gamepad-2.svg"
                                    iconColor: popupCardStyle.iconColor
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "X & O"
                                color: popupCardStyle.textColor
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }

                            Item { width: Math.max(0, parent.width - 118); height: 1 }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "›"
                                color: popupCardStyle.mutedTextColor
                                font.pixelSize: 22
                            }
                        }

                        MouseArea {
                            id: gameRowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.startGame()
                        }
                        Accessible.name: "X and O"
                    }
                }

                Column {
                    width: parent.width
                    visible: root.currentView === "xo"
                    spacing: 8

                    Row {
                        width: parent.width
                        height: 18
                        spacing: 6

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.gameOver ? (root.statusText === "YOU WIN" ? "#2C9665" : "#8993A1")
                                : (root.botThinking ? "#D6AD60" : "#3A9B74")
                        }

                        Text {
                            width: parent.width - 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.statusText
                            color: popupCardStyle.secondaryTextColor
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1
                        }
                    }

                    Grid {
                        id: boardGrid
                        width: Math.min(parent.width, 250)
                        height: width
                        anchors.horizontalCenter: parent.horizontalCenter
                        columns: 3
                        rows: 3
                        rowSpacing: 5
                        columnSpacing: 5

                        Repeater {
                            model: 9

                            delegate: Rectangle {
                                required property int index
                                width: (boardGrid.width - boardGrid.columnSpacing * 2) / 3
                                height: width
                                radius: 13
                                color: root.board[index] === "X" ? "#FBF0D9"
                                    : (root.board[index] === "O" ? "#E6EFFC" : popupCardStyle.fieldColor)
                                border.width: root.board[index] === "" ? 1 : 0
                                border.color: popupCardStyle.fieldBorderColor

                                Behavior on color { ColorAnimation { duration: 100; easing.type: Easing.OutCubic } }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.board[index]
                                    color: root.board[index] === "X" ? "#987020" : "#315A96"
                                    font.pixelSize: Math.min(39, parent.width * 0.48)
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: root.board[index] === "" && !root.gameOver && !root.botThinking
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.playCell(index)
                                }
                                Accessible.name: "Square " + (index + 1) + (root.board[index] ? ", " + root.board[index] : "")
                            }
                        }
                    }
                }
            }
        }
    }
}
