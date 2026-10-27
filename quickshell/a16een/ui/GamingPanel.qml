import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.ui
import "TicTacToe.js" as TicTacToe
import "DotsAndBoxes.js" as DotsAndBoxes

PanelWindow {
    id: root

    PopupCardStyle {
        id: popupCardStyle
        containerId: "gaming"
        useContainerColor: true
    }

    required property var modelData
    required property string navbarPosition
    property bool opened: false
    property bool dockVisible: true
    property string currentView: "list"
    property string resultGame: "xo"
    property string resultTitle: "YOU WIN"
    property string resultSubtitle: ""
    property string resultScoreText: ""
    property bool resultEntered: false

    property var board: ["", "", "", "", "", "", "", "", ""]
    property string statusText: "YOUR TURN"
    property bool gameOver: false
    property bool botThinking: false

    property var dotsHorizontal: ["", "", "", "", "", ""]
    property var dotsVertical: ["", "", "", "", "", ""]
    property var dotsOwners: ["", "", "", ""]
    property var dotsScores: [0, 0]
    property string dotsStatusText: "YOUR TURN"
    property string dotsTurn: "X"
    property bool dotsGameOver: false

    signal closeRequested()

    readonly property bool horizontalNavbar:
        root.navbarPosition === "top" || root.navbarPosition === "bottom"
    readonly property real screenWidth: root.modelData ? root.modelData.width : 1920
    readonly property real screenHeight: root.modelData ? root.modelData.height : 1080
    readonly property int popupWidth: 310
    readonly property int popupHeight: root.currentView === "xo" ? 372
        : (root.currentView === "dots" ? 420
        : (root.currentView === "result" ? 350 : 166))
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
        root.resultGame = "xo"
        root.resultEntered = false
        root.board = ["", "", "", "", "", "", "", "", ""]
        root.gameOver = false
        root.dotsGameOver = false
        root.botThinking = false
        root.statusText = "YOUR TURN"
    }

    function startDotsGame() {
        botMoveTimer.stop()
        root.currentView = "dots"
        root.resultGame = "dots"
        root.resultEntered = false
        root.dotsHorizontal = DotsAndBoxes.emptyHorizontal()
        root.dotsVertical = DotsAndBoxes.emptyVertical()
        root.dotsOwners = DotsAndBoxes.emptyOwners()
        root.dotsScores = [0, 0]
        root.dotsTurn = "X"
        root.dotsStatusText = "YOUR TURN"
        root.dotsGameOver = false
        root.gameOver = false
        root.botThinking = false
    }

    function restartCurrentGame() {
        if (root.currentView === "dots" || root.resultGame === "dots")
            root.startDotsGame()
        else
            root.startGame()
    }

    function returnToList() {
        botMoveTimer.stop()
        root.currentView = "list"
        root.resultEntered = false
        root.botThinking = false
        root.gameOver = false
        root.dotsGameOver = false
        root.statusText = "YOUR TURN"
        root.dotsStatusText = "YOUR TURN"
    }

    function markCount(mark) {
        var count = 0
        for (var i = 0; i < root.board.length; i++) {
            if (root.board[i] === mark)
                count++
        }
        return count
    }

    function showResult(gameId, title, subtitle, scoreText) {
        root.resultGame = gameId
        root.resultTitle = title
        root.resultSubtitle = subtitle
        root.resultScoreText = scoreText
        root.resultEntered = false
        root.currentView = "result"
        Qt.callLater(function() {
            if (root.currentView === "result")
                root.resultEntered = true
        })
    }

    function finishIfNeeded() {
        var result = TicTacToe.winner(root.board)
        var scoreText = "X  " + root.markCount("X") + "     ·     O  " + root.markCount("O")
        if (result === "X") {
            root.statusText = "YOU WIN"
            root.gameOver = true
            root.botThinking = false
            root.showResult("xo", "YOU WIN", "You found the winning line. Beautifully played.", scoreText)
            return true
        }
        if (result === "O") {
            root.statusText = "BOT WINS"
            root.gameOver = true
            root.botThinking = false
            root.showResult("xo", "BOT WINS", "The bot found its opening this time.", scoreText)
            return true
        }
        if (TicTacToe.isFull(root.board)) {
            root.statusText = "DRAW"
            root.gameOver = true
            root.botThinking = false
            root.showResult("xo", "IT'S A DRAW", "Neither side found a winning line.", scoreText)
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

    function applyDotsMove(orientation, index, player) {
        var result = DotsAndBoxes.applyMove(
            root.dotsHorizontal,
            root.dotsVertical,
            root.dotsOwners,
            root.dotsScores,
            orientation,
            index,
            player
        )
        if (!result)
            return

        root.dotsHorizontal = result.horizontal
        root.dotsVertical = result.vertical
        root.dotsOwners = result.owners
        root.dotsScores = result.scores
        root.dotsTurn = result.turn

        if (result.gameOver) {
            root.dotsGameOver = true
            root.botThinking = false
            botMoveTimer.stop()
            var resultTitle = "IT'S A DRAW"
            var resultSubtitle = "Every box claimed. It's a close match."
            if (result.scores[0] > result.scores[1]) {
                root.dotsStatusText = "YOU WIN"
                resultTitle = "YOU WIN"
                resultSubtitle = "You claimed more boxes. What a finish!"
            } else if (result.scores[1] > result.scores[0]) {
                root.dotsStatusText = "BOT WINS"
                resultTitle = "BOT WINS"
                resultSubtitle = "The bot edged ahead this round."
            } else {
                root.dotsStatusText = "DRAW"
            }
            root.showResult(
                "dots",
                resultTitle,
                resultSubtitle,
                "YOU  " + result.scores[0] + "     ·     BOT  " + result.scores[1] + " BOXES"
            )
            return
        }

        if (result.turn === "O") {
            root.botThinking = true
            root.dotsStatusText = "BOT THINKING"
            botMoveTimer.restart()
        } else {
            root.botThinking = false
            root.dotsStatusText = player === "X" && result.claimed.length > 0
                ? (result.claimed.length === 1 ? "BOX CLAIMED · DRAW AGAIN" : "2 BOXES · DRAW AGAIN")
                : "YOUR TURN"
        }
    }

    function playDotsLine(orientation, index) {
        if (root.currentView !== "dots" || root.dotsGameOver || root.botThinking
            || root.dotsTurn !== "X")
            return
        root.applyDotsMove(orientation, index, "X")
    }

    function playBotTurn() {
        if (root.gameOver || !root.botThinking)
            return

        if (root.currentView === "xo") {
            var choice = TicTacToe.casualMove(
                root.board, "O", "X", Math.random(), Math.random()
            )
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
            return
        }

        if (root.currentView === "dots" && !root.dotsGameOver && root.dotsTurn === "O") {
            var move = DotsAndBoxes.casualMove(
                root.dotsHorizontal,
                root.dotsVertical,
                root.dotsOwners,
                "O",
                Math.random(),
                Math.random()
            )
            if (!move)
                return
            root.applyDotsMove(move.orientation, move.index, "O")
        }
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
                        visible: root.currentView !== "list"
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
                        width: parent.width - (root.currentView !== "list" ? 28 : 0)
                            - 28 - (root.currentView !== "list" ? 28 : 0) - parent.spacing * 3
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.currentView === "xo" ? "X & O"
                            : (root.currentView === "dots" ? "DOTS & BOXES"
                            : (root.currentView === "result" ? "ROUND RESULT" : "GAMES"))
                        color: popupCardStyle.textColor
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        visible: root.currentView !== "list"
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
                            onClicked: root.restartCurrentGame()
                        }
                        Accessible.name: "Restart current game"
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
                    id: gameContent
                    width: parent.width
                    height: parent.height - 28 - 1 - parent.spacing * 2

                    Item {
                        anchors.fill: parent
                        visible: root.currentView === "list"

                        Column {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            spacing: 5

                            Rectangle {
                                width: parent.width
                                height: 42
                                radius: 12
                                color: xoRowMouse.containsMouse ? popupCardStyle.hoverSurfaceColor : popupCardStyle.fieldColor
                                border.width: 1
                                border.color: xoRowMouse.containsMouse ? popupCardStyle.focusBorderColor : popupCardStyle.fieldBorderColor

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 10

                                    Rectangle {
                                        width: 30
                                        height: 30
                                        radius: 9
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: popupCardStyle.subtleSurfaceColor

                                        NavbarIcon {
                                            anchors.centerIn: parent
                                            width: 17
                                            height: 17
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

                                    Item { width: Math.max(0, parent.width - 116); height: 1 }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "›"
                                        color: popupCardStyle.mutedTextColor
                                        font.pixelSize: 22
                                    }
                                }

                                MouseArea {
                                    id: xoRowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.startGame()
                                }
                                Accessible.name: "X and O"
                            }

                            Rectangle {
                                width: parent.width
                                height: 42
                                radius: 12
                                color: dotsRowMouse.containsMouse ? popupCardStyle.hoverSurfaceColor : popupCardStyle.fieldColor
                                border.width: 1
                                border.color: dotsRowMouse.containsMouse ? popupCardStyle.focusBorderColor : popupCardStyle.fieldBorderColor

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 10

                                    Rectangle {
                                        width: 30
                                        height: 30
                                        radius: 9
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: popupCardStyle.subtleSurfaceColor

                                        NavbarIcon {
                                            anchors.centerIn: parent
                                            width: 17
                                            height: 17
                                            iconName: "lucide-grid-2x2.svg"
                                            iconColor: popupCardStyle.iconColor
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Dots & Boxes"
                                        color: popupCardStyle.textColor
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }

                                    Item { width: Math.max(0, parent.width - 148); height: 1 }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "›"
                                        color: popupCardStyle.mutedTextColor
                                        font.pixelSize: 22
                                    }
                                }

                                MouseArea {
                                    id: dotsRowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.startDotsGame()
                                }
                                Accessible.name: "Dots and Boxes"
                            }
                        }
                    }

                    Item {
                        anchors.fill: parent
                        visible: root.currentView === "xo"

                        Column {
                            anchors.fill: parent
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

                    Item {
                        anchors.fill: parent
                        visible: root.currentView === "dots"

                        Column {
                            width: parent.width
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            spacing: 5

                            Row {
                                width: parent.width
                                height: 17
                                spacing: 6

                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: root.dotsGameOver
                                        ? (root.dotsStatusText === "YOU WIN" ? "#2C9665" : "#8993A1")
                                        : (root.botThinking ? "#D6AD60" : "#3A9B74")
                                }

                                Text {
                                    width: parent.width - 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.dotsStatusText
                                    color: popupCardStyle.secondaryTextColor
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.7
                                    elide: Text.ElideRight
                                }
                            }

                            Row {
                                width: parent.width
                                height: 22
                                spacing: 8

                                Rectangle {
                                    width: (parent.width - parent.spacing) / 2
                                    height: parent.height
                                    radius: 7
                                    color: "#FBF0D9"
                                    Text {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        text: "YOU   " + root.dotsScores[0]
                                        color: "#987020"
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                Rectangle {
                                    width: (parent.width - parent.spacing) / 2
                                    height: parent.height
                                    radius: 7
                                    color: "#E6EFFC"
                                    Text {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        text: "BOT   " + root.dotsScores[1]
                                        color: "#315A96"
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }

                            Item {
                                id: dotsBoard
                                readonly property real inset: 11
                                readonly property real step: (width - inset * 2) / 2
                                width: Math.min(parent.width, 230)
                                height: width
                                anchors.horizontalCenter: parent.horizontalCenter

                                Repeater {
                                    model: 4
                                    delegate: Rectangle {
                                        required property int index
                                        readonly property int rowIndex: Math.floor(index / 2)
                                        readonly property int columnIndex: index % 2
                                        x: dotsBoard.inset + columnIndex * dotsBoard.step + 6
                                        y: dotsBoard.inset + rowIndex * dotsBoard.step + 6
                                        width: dotsBoard.step - 12
                                        height: width
                                        radius: 9
                                        color: root.dotsOwners[index] === "X" ? "#FBF0D9"
                                            : (root.dotsOwners[index] === "O" ? "#E6EFFC" : popupCardStyle.fieldColor)
                                        border.width: root.dotsOwners[index] ? 0 : 1
                                        border.color: popupCardStyle.fieldBorderColor
                                        Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.dotsOwners[index]
                                            color: root.dotsOwners[index] === "X" ? "#987020" : "#315A96"
                                            font.pixelSize: 24
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                }

                                Repeater {
                                    model: 6
                                    delegate: Item {
                                        required property int index
                                        readonly property int rowIndex: Math.floor(index / 2)
                                        readonly property int columnIndex: index % 2
                                        x: dotsBoard.inset + columnIndex * dotsBoard.step + 5
                                        y: dotsBoard.inset + rowIndex * dotsBoard.step - 12
                                        width: dotsBoard.step - 10
                                        height: 24

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: parent.width
                                            height: 4
                                            radius: 2
                                            color: root.dotsHorizontal[index] === "X" ? "#BA8B39"
                                                : (root.dotsHorizontal[index] === "O" ? "#4B74B8"
                                                : (horizontalEdgeMouse.containsMouse ? popupCardStyle.focusBorderColor : popupCardStyle.fieldBorderColor))
                                            opacity: root.dotsHorizontal[index] ? 1 : 0.78
                                        }

                                        MouseArea {
                                            id: horizontalEdgeMouse
                                            anchors.fill: parent
                                            enabled: root.dotsHorizontal[index] === "" && !root.dotsGameOver
                                                && !root.botThinking && root.dotsTurn === "X"
                                            hoverEnabled: true
                                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: root.playDotsLine("h", index)
                                        }
                                        Accessible.name: "Horizontal line " + (index + 1)
                                    }
                                }

                                Repeater {
                                    model: 6
                                    delegate: Item {
                                        required property int index
                                        readonly property int rowIndex: Math.floor(index / 3)
                                        readonly property int columnIndex: index % 3
                                        x: dotsBoard.inset + columnIndex * dotsBoard.step - 12
                                        y: dotsBoard.inset + rowIndex * dotsBoard.step + 5
                                        width: 24
                                        height: dotsBoard.step - 10

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 4
                                            height: parent.height
                                            radius: 2
                                            color: root.dotsVertical[index] === "X" ? "#BA8B39"
                                                : (root.dotsVertical[index] === "O" ? "#4B74B8"
                                                : (verticalEdgeMouse.containsMouse ? popupCardStyle.focusBorderColor : popupCardStyle.fieldBorderColor))
                                            opacity: root.dotsVertical[index] ? 1 : 0.78
                                        }

                                        MouseArea {
                                            id: verticalEdgeMouse
                                            anchors.fill: parent
                                            enabled: root.dotsVertical[index] === "" && !root.dotsGameOver
                                                && !root.botThinking && root.dotsTurn === "X"
                                            hoverEnabled: true
                                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: root.playDotsLine("v", index)
                                        }
                                        Accessible.name: "Vertical line " + (index + 1)
                                    }
                                }

                                Repeater {
                                    model: 9
                                    delegate: Rectangle {
                                        required property int index
                                        readonly property int rowIndex: Math.floor(index / 3)
                                        readonly property int columnIndex: index % 3
                                        x: dotsBoard.inset + columnIndex * dotsBoard.step - width / 2
                                        y: dotsBoard.inset + rowIndex * dotsBoard.step - height / 2
                                        width: 10
                                        height: 10
                                        radius: 5
                                        color: popupCardStyle.textColor
                                        border.width: 1
                                        border.color: popupCardStyle.backgroundColor
                                        z: 5
                                    }
                                }
                            }
                        }
                    }
                    Item {
                        id: resultStage
                        anchors.fill: parent
                        visible: root.currentView === "result"
                        opacity: root.resultEntered ? 1 : 0
                        scale: root.resultEntered ? 1 : 0.94
                        transformOrigin: Item.Center
                        Behavior on opacity {
                            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                        }
                        Behavior on scale {
                            NumberAnimation { duration: 300; easing.type: Easing.OutBack }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 16
                            color: popupCardStyle.fieldColor
                            border.width: 1
                            border.color: root.resultTitle === "YOU WIN"
                                ? popupCardStyle.successColor : popupCardStyle.fieldBorderColor
                        }

                        Repeater {
                            model: 16
                            delegate: Rectangle {
                                id: confettiParticle
                                required property int index
                                width: index % 3 === 0 ? 5 : 3
                                height: index % 3 === 0 ? 8 : 3
                                radius: 2
                                x: 12 + ((index * 37) % Math.max(1, resultStage.width - 24))
                                y: -10
                                rotation: index * 23
                                color: index % 4 === 0 ? popupCardStyle.successColor
                                    : (index % 4 === 1 ? "#D6AD60"
                                    : (index % 4 === 2 ? "#6F94CF" : "#D5A3BC"))
                                opacity: root.resultEntered && root.resultTitle === "YOU WIN" ? 1 : 0
                                z: 1
                                NumberAnimation on y {
                                    from: -10
                                    to: resultStage.height + 10
                                    duration: 880 + index * 34
                                    easing.type: Easing.OutCubic
                                    running: root.resultEntered && root.resultTitle === "YOU WIN"
                                }
                                NumberAnimation on rotation {
                                    from: index * 23
                                    to: index * 23 + 250
                                    duration: 880 + index * 34
                                    running: root.resultEntered && root.resultTitle === "YOU WIN"
                                }
                            }
                        }

                        Column {
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            anchors.rightMargin: 9
                            anchors.topMargin: 10
                            anchors.bottomMargin: 8
                            spacing: 5
                            z: 2

                            Item {
                                width: parent.width
                                height: 76
                                Rectangle {
                                    id: resultHalo
                                    anchors.centerIn: parent
                                    width: 68
                                    height: 68
                                    radius: 34
                                    color: root.resultTitle === "YOU WIN" ? "#DDF3E5"
                                        : (root.resultTitle === "BOT WINS" ? "#F9E5E5" : "#E6EDF8")
                                    border.width: 1
                                    border.color: root.resultTitle === "YOU WIN" ? "#A7D9B8"
                                        : (root.resultTitle === "BOT WINS" ? "#E9B8B8" : "#C7D5EA")
                                    scale: root.resultEntered ? 1 : 0.66
                                    rotation: root.resultEntered ? 0 : -12
                                    Behavior on scale {
                                        NumberAnimation { duration: 360; easing.type: Easing.OutBack }
                                    }
                                    Behavior on rotation {
                                        NumberAnimation { duration: 360; easing.type: Easing.OutCubic }
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: root.resultTitle === "YOU WIN" ? "✦"
                                            : (root.resultTitle === "BOT WINS" ? "↗" : "＝")
                                        color: root.resultTitle === "YOU WIN" ? "#287A50"
                                            : (root.resultTitle === "BOT WINS" ? "#B44F54" : "#4A6592")
                                        font.pixelSize: 34
                                        font.weight: Font.DemiBold
                                    }
                                }
                                Rectangle {
                                    anchors.centerIn: resultHalo
                                    width: 82
                                    height: 82
                                    radius: 41
                                    color: "transparent"
                                    border.width: 1
                                    border.color: root.resultTitle === "YOU WIN" ? "#657A52" : popupCardStyle.fieldBorderColor
                                    opacity: root.resultEntered ? 0 : 0.8
                                    scale: root.resultEntered ? 1.2 : 0.82
                                    Behavior on opacity { NumberAnimation { duration: 430; easing.type: Easing.OutCubic } }
                                    Behavior on scale { NumberAnimation { duration: 430; easing.type: Easing.OutCubic } }
                                }
                            }

                            Text {
                                width: parent.width
                                text: root.resultTitle === "YOU WIN" ? "NICE MOVE"
                                    : (root.resultTitle === "BOT WINS" ? "NEXT ROUND" : "WELL MATCHED")
                                horizontalAlignment: Text.AlignHCenter
                                color: popupCardStyle.mutedTextColor
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.8
                            }
                            Text {
                                width: parent.width
                                text: root.resultTitle
                                horizontalAlignment: Text.AlignHCenter
                                color: popupCardStyle.textColor
                                font.pixelSize: 23
                                font.weight: Font.Black
                            }
                            Text {
                                width: parent.width
                                height: 30
                                text: root.resultSubtitle
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.WordWrap
                                color: popupCardStyle.secondaryTextColor
                                font.pixelSize: 9
                            }
                            Rectangle {
                                width: parent.width
                                height: 27
                                radius: 9
                                color: popupCardStyle.subtleSurfaceColor
                                border.width: 1
                                border.color: popupCardStyle.fieldBorderColor
                                Text {
                                    anchors.fill: parent
                                    text: root.resultScoreText
                                    color: popupCardStyle.textColor
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                            Row {
                                width: parent.width
                                height: 34
                                spacing: 7
                                Rectangle {
                                    width: (parent.width - parent.spacing) / 2
                                    height: parent.height
                                    radius: 10
                                    color: replayMouse.containsMouse
                                        ? popupCardStyle.actionHoverColor : popupCardStyle.actionColor
                                    Text {
                                        anchors.centerIn: parent
                                        text: "PLAY AGAIN"
                                        color: popupCardStyle.actionTextColor
                                        font.pixelSize: 8
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 0.5
                                    }
                                    MouseArea {
                                        id: replayMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.restartCurrentGame()
                                    }
                                    Accessible.name: "Play again"
                                }
                                Rectangle {
                                    width: (parent.width - parent.spacing) / 2
                                    height: parent.height
                                    radius: 10
                                    color: gamesMouse.containsMouse
                                        ? popupCardStyle.hoverSurfaceColor : popupCardStyle.subtleSurfaceColor
                                    border.width: 1
                                    border.color: popupCardStyle.fieldBorderColor
                                    Text {
                                        anchors.centerIn: parent
                                        text: "ALL GAMES"
                                        color: popupCardStyle.textColor
                                        font.pixelSize: 8
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 0.5
                                    }
                                    MouseArea {
                                        id: gamesMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.returnToList()
                                    }
                                    Accessible.name: "Return to all games"
                                }
                            }
                        }
                    }

                }
            }
        }
    }
}
