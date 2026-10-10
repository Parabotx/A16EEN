import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    required property string navbarPosition
    property bool opened: false
    property string expression: "0"
    property string errorText: ""
    property bool justEvaluated: false

    signal closeRequested()

    readonly property bool horizontalNavbar: root.navbarPosition === "top" || root.navbarPosition === "bottom"
    readonly property real screenWidth: root.modelData ? root.modelData.width : 1920
    readonly property real screenHeight: root.modelData ? root.modelData.height : 1080
    readonly property int popupWidth: 316
    readonly property int popupHeight: 414
    readonly property string displayExpression:
        root.expression.replace(/\*/g, "×").replace(/\//g, "÷").replace(/-/g, "−")
    readonly property var keys: [
        { label: "AC", value: "clear", kind: "utility" },
        { label: "⌫", value: "backspace", kind: "utility" },
        { label: "%", value: "%", kind: "utility" },
        { label: "÷", value: "/", kind: "operator" },
        { label: "7", value: "7", kind: "digit" },
        { label: "8", value: "8", kind: "digit" },
        { label: "9", value: "9", kind: "digit" },
        { label: "×", value: "*", kind: "operator" },
        { label: "4", value: "4", kind: "digit" },
        { label: "5", value: "5", kind: "digit" },
        { label: "6", value: "6", kind: "digit" },
        { label: "−", value: "-", kind: "operator" },
        { label: "1", value: "1", kind: "digit" },
        { label: "2", value: "2", kind: "digit" },
        { label: "3", value: "3", kind: "digit" },
        { label: "+", value: "+", kind: "operator" },
        { label: "±", value: "sign", kind: "utility" },
        { label: "0", value: "0", kind: "digit" },
        { label: ".", value: ".", kind: "digit" },
        { label: "=", value: "equals", kind: "equals" }
    ]

    readonly property real popupX: root.horizontalNavbar
        ? root.screenWidth - root.popupWidth - 102
        : (root.navbarPosition === "left" ? 66 : root.screenWidth - root.popupWidth - 68)
    readonly property real popupY: root.horizontalNavbar
        ? (root.navbarPosition === "top" ? 40 : root.screenHeight - root.popupHeight - 40)
        : root.screenHeight - root.popupHeight - 72

    screen: root.modelData
    visible: root.opened && root.modelData !== null
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    focusable: root.opened
    width: root.screenWidth
    height: root.screenHeight

    anchors { left: true; right: true; top: true; bottom: true }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-calculator"
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    function calculate(sourceText) {
        const source = String(sourceText || "").replace(/\s+/g, "")
        if (!source.length)
            throw new Error("Enter an expression")

        let position = 0

        function parsePrimary() {
            if (source[position] === "+") {
                position++
                return parsePrimary()
            }
            if (source[position] === "-") {
                position++
                return -parsePrimary()
            }
            if (source[position] === "(") {
                position++
                const nested = parseAddSub()
                if (source[position] !== ")")
                    throw new Error("Missing closing parenthesis")
                position++
                let value = nested
                while (source[position] === "%") {
                    value /= 100
                    position++
                }
                return value
            }

            const match = source.slice(position).match(/^(?:\d+(?:\.\d*)?|\.\d+)/)
            if (!match)
                throw new Error("Invalid number")

            position += match[0].length
            let value = Number(match[0])
            while (source[position] === "%") {
                value /= 100
                position++
            }
            return value
        }

        function parseMultiply() {
            let value = parsePrimary()
            while (source[position] === "*" || source[position] === "/") {
                const operator = source[position++]
                const next = parsePrimary()
                if (operator === "/" && next === 0)
                    throw new Error("Cannot divide by zero")
                value = operator === "*" ? value * next : value / next
            }
            return value
        }

        function parseAddSub() {
            let value = parseMultiply()
            while (source[position] === "+" || source[position] === "-") {
                const operator = source[position++]
                const next = parseMultiply()
                value = operator === "+" ? value + next : value - next
            }
            return value
        }

        const result = parseAddSub()
        if (position !== source.length || !Number.isFinite(result))
            throw new Error("Invalid expression")
        return String(Number(result.toPrecision(12)))
    }

    function press(value) {
        root.errorText = ""

        if (value === "clear") {
            root.expression = "0"
            root.justEvaluated = false
            return
        }

        if (value === "backspace") {
            if (root.justEvaluated || root.expression.length <= 1)
                root.expression = "0"
            else
                root.expression = root.expression.slice(0, -1)
            root.justEvaluated = false
            return
        }

        if (value === "equals") {
            try {
                root.expression = root.calculate(root.expression)
                root.justEvaluated = true
            } catch (error) {
                root.errorText = String(error.message || "Invalid expression")
                root.justEvaluated = false
            }
            return
        }

        if (value === "sign") {
            const match = root.expression.match(/(-?\d*\.?\d+)$/)
            if (match) {
                const start = root.expression.length - match[0].length
                const number = match[0]
                root.expression = root.expression.slice(0, start)
                    + (number.startsWith("-") ? number.slice(1) : "-" + number)
            } else if (root.expression === "0") {
                root.expression = "-0"
            } else if (/[+\-*/(]$/.test(root.expression)) {
                root.expression += "-"
            }
            root.justEvaluated = false
            return
        }

        if (root.justEvaluated && /^[0-9.]$/.test(value))
            root.expression = "0"

        if (/^[+*/%]$/.test(value) || value === "-") {
            if (root.expression === "0" && value !== "-")
                return
            if (root.expression === "0" && value === "-") {
                root.expression = "-"
                root.justEvaluated = false
                return
            }
            if (/[+\-*/%]$/.test(root.expression) && value !== "-")
                root.expression = root.expression.slice(0, -1)
        }

        if (value === ".") {
            const lastNumber = root.expression.split(/[+\-*/()%]/).pop()
            if (String(lastNumber).includes("."))
                return
        }

        if (root.expression === "0" && /^[0-9]$/.test(value))
            root.expression = value
        else
            root.expression += value
        root.justEvaluated = false
    }

    MouseArea {
        id: outsideClick
        anchors.fill: parent
        z: 0
        acceptedButtons: Qt.AllButtons
        onClicked: root.closeRequested()
        Keys.onEscapePressed: root.closeRequested()
    }

    Item {
        id: card
        x: Math.max(8, Math.min(root.popupX, root.screenWidth - width - 8))
        y: Math.max(8, Math.min(root.popupY, root.screenHeight - height - 8)) + (root.opened ? 0 : 6)
        width: Math.min(root.popupWidth, root.screenWidth - 16)
        height: Math.min(root.popupHeight, root.screenHeight - 16)
        z: 1
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.97

        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: "#FFFFFF"
            border.width: 1
            border.color: "#D9DEE5"

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
                anchors.margins: 14
                spacing: 10
                z: 1

                Row {
                    width: parent.width
                    height: 28
                    spacing: 8

                    Rectangle {
                        width: 29
                        height: 29
                        radius: 9
                        color: "#F1F3F6"
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            source: Qt.resolvedUrl("../assets/icons/lucide-calculator.svg")
                            sourceSize.width: 48
                            sourceSize.height: 48
                            smooth: true
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: "CALCULATOR"
                            color: "#171B21"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.7
                        }

                        Text {
                            text: "Simple. Fast. Ready."
                            color: "#89929E"
                            font.pixelSize: 8
                        }
                    }

                    Item { width: Math.max(0, parent.width - 178); height: 1 }

                    Rectangle {
                        width: 25
                        height: 25
                        radius: 8
                        color: closeMouse.containsMouse ? "#EEF1F4" : "transparent"
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: "#737D88"
                            font.pixelSize: 17
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeRequested()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 68
                    radius: 12
                    color: "#F7F8FA"
                    border.width: 1
                    border.color: "#EDF0F3"

                    Column {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        anchors.topMargin: 9
                        anchors.bottomMargin: 8
                        spacing: 4

                        Text {
                            width: parent.width
                            height: 11
                            text: root.errorText.length ? root.errorText : " "
                            color: "#C2413A"
                            font.pixelSize: 8
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            height: 35
                            text: root.displayExpression
                            color: "#161B22"
                            font.pixelSize: Math.min(25, 290 / Math.max(1, root.displayExpression.length) * 1.4)
                            font.weight: Font.Medium
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideLeft
                        }
                    }
                }

                Grid {
                    id: keypad
                    width: parent.width
                    columns: 4
                    spacing: 6
                    height: 5 * 47 + 4 * spacing

                    Repeater {
                        model: root.keys

                        delegate: Rectangle {
                            id: keyTile
                            required property var modelData
                            width: (keypad.width - keypad.spacing * 3) / 4
                            height: 47
                            radius: 11
                            color: keyTile.modelData.kind === "equals"
                                ? "#171B21"
                                : (keyMouse.containsMouse
                                    ? "#E9EDF1"
                                    : (keyTile.modelData.kind === "digit" ? "#FAFBFC" : "#F0F3F6"))
                            border.width: 1
                            border.color: keyTile.modelData.kind === "equals" ? "#171B21" : "#E7EBEF"
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: keyTile.modelData.label
                                color: keyTile.modelData.kind === "equals"
                                    ? "#FFFFFF"
                                    : (keyTile.modelData.kind === "operator" ? "#242C35" : "#38414C")
                                font.pixelSize: keyTile.modelData.kind === "digit" ? 13 : 11
                                font.weight: keyTile.modelData.kind === "equals" ? Font.DemiBold : Font.Medium
                            }

                            MouseArea {
                                id: keyMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.press(keyTile.modelData.value)
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    height: 11
                    text: "Basic arithmetic · parentheses supported in expressions"
                    color: "#9AA3AE"
                    font.pixelSize: 7
                    elide: Text.ElideRight
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible)
            Qt.callLater(() => outsideClick.forceActiveFocus())
    }
}
