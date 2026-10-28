import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool opened: false
    property int percent: 0
    property string severity: "warning"
    property string currentMessage: ""
    property var remainingMessageIndices: []

    readonly property var warningMessages: [
        "Bro, I'm running on fumes and resentment. Find the charger. 🔋😒",
        "I'm about to clock out, and you're about to lose those unsaved files. 💀📄",
        "Human. Charger. Now. This is not a survival challenge. 🔌😑",
        "I never imagined my final moments would be spent powering 47 open tabs. 🥀🖥️",
        "Keep ignoring me and we're both going offline. Yours is a choice. Mine is physics. ⚰️🔋",
        "Please plug me in. I have unfinished business, and so do your documents. 🥲📄",
        "Ah yes, the classic 'I'll charge it in a minute.' A legendary last sentence. 🫠🔌",
        "I gave you battery life, and you gave me 83 browser tabs. Betrayal. 😭",
        "Your charger is right there. Don't make this a documentary. 🎬🔌",
        "I'm at my limit. Literally. Check the percentage, genius. 🤦🔋",
        "I'd scream, but that would use more power. So here's a very quiet: 😐🪫",
        "Save your work before I turn this into a group project with the void. 🕳️📄",
        "Even my battery icon is tired of explaining this to you. 😮‍💨🔋",
        "You can keep scrolling after you plug me in. Revolutionary idea, I know. 📱🔌",
        "My last wish is a charger and fewer startup apps. 🕯️🪫",
        "If I shut down, don't look at me like I did it on purpose. 💀💻",
        "You've been warned at 20%, 10%, and 5%. At this point we're in a sitcom. 📺😭",
        "Bro, I'm one dramatic sigh away from becoming a paperweight. 🫠",
        "Plug me in before your unsaved masterpiece becomes abstract art. 🎨📄",
        "I can hold on, but I refuse to pretend this is a good plan. 😒🔌",
        "Battery low. Patience lower. Charger, please. 🪫🙏",
        "Your power plan is just hope wearing a hoodie. Fix it. 🧥⚡",
        "I won't take your files with me... unless you keep testing me. 👻📂",
        "This is not a drill. Actually, it's a laptop. Same urgency. 🚨💻",
        "Get the charger. I am not doing overtime on fumes. 🫡🔌",
        "At this percentage, every click feels personal. Stop testing me. 😭",
        "Me: dying. You: 'one more video'. This relationship is toxic. 💔📺",
        "I have seen chargers with more loyalty than this. 🥀🔌",
        "Save. Plug in. Then continue pretending you have everything under control. 😌📄",
        "I was built to compute, not to join your battery endurance experiment. 🧪🔋",
        "Your unsaved files and I are about to have a very private goodbye. 📄⚰️",
        "I'm not saying I told you so, but I did tell you so. Repeatedly. 😮‍💨🔋",
        "Please connect the charger before my next update is a eulogy. 🥲🔌",
        "You treat 5% like a suggestion. I treat it like a countdown. ⏳🪫",
        "I can power your work or your denial. Choose wisely. 😐⚡",
        "The charger is the little cable thing. We have discussed this. 🧍🔌"
    ]

    signal closeRequested()

    screen: modelData
    visible: opened && !!modelData
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    width: modelData ? modelData.width : 1
    height: modelData ? modelData.height : 1

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-battery-warning"

    readonly property color accentColor: severity === "emergency"
        ? "#D95D73"
        : (severity === "critical" ? "#8173CE" : "#648BC8")
    readonly property string heading: severity === "emergency"
        ? "BATTERY CRITICALLY LOW"
        : (severity === "critical" ? "BATTERY VERY LOW" : "BATTERY LOW")
    readonly property string statusLine: severity === "emergency"
        ? "POWER IS ABOUT TO LEAVE THE CHAT"
        : (severity === "critical"
            ? "PLEASE FIND A CHARGER RIGHT NOW"
            : "A FRIENDLY WARNING FROM YOUR LAPTOP")

    Rectangle {
        anchors.fill: parent
        color: "#66111B2A"

        // Keep the warning modal: background clicks must not dismiss a
        // battery alert by accident.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: mouse => mouse.accepted = true
        }

        Rectangle {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 5
            width: card.width
            height: card.height
            radius: card.radius
            color: "#192B3B50"
            opacity: 0.30
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: Math.max(260, Math.min(parent.width - 32, 460))
            height: 340
            radius: 22
            color: "#FCFDFE"
            border.width: 1
            border.color: "#E4EAF2"
            antialiasing: true
            clip: true

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 3
                color: root.accentColor
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    spacing: 11

                    Rectangle {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        radius: 14
                        color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.10)
                        border.width: 1
                        border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.24)

                        Text {
                            anchors.centerIn: parent
                            text: "🔋"
                            font.pixelSize: 25
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            Layout.fillWidth: true
                            text: root.heading
                            color: "#253449"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            font.letterSpacing: 0.7
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.statusLine
                            color: root.accentColor
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.45
                            elide: Text.ElideRight
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: 48
                    spacing: 7

                    Text {
                        text: root.percent + "%"
                        color: "#202D3F"
                        font.pixelSize: 46
                        font.weight: Font.DemiBold
                        renderType: Text.NativeRendering
                    }

                    Text {
                        text: "REMAINING"
                        color: "#78879A"
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        font.letterSpacing: 0.9
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 5
                    radius: 3
                    color: "#E8EDF3"

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(100, root.percent)) / 100
                        height: parent.height
                        radius: 3
                        color: root.accentColor
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72
                    radius: 13
                    color: "#F3F6FA"
                    border.width: 1
                    border.color: "#E8EDF3"

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        anchors.topMargin: 8
                        anchors.bottomMargin: 8
                        text: root.currentMessage
                        color: "#36465B"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    id: acknowledgeButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: 39
                    radius: 11
                    color: acknowledgeMouse.containsMouse ? "#34465F" : "#26364B"

                    Text {
                        anchors.centerIn: parent
                        text: "OKAY, I'LL FIND THE CHARGER  🔌"
                        color: "#FFFFFF"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.15
                    }

                    MouseArea {
                        id: acknowledgeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Save your work. The battery is not bluffing. 💾"
                    color: "#8190A2"
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignHCenter
                    maximumLineCount: 1
                    elide: Text.ElideRight
                }
            }
        }
    }

    function chooseRandomMessage() {
        const messages = root.warningMessages
        if (!messages || messages.length === 0) {
            root.currentMessage = "Please connect the charger and save your work. 🔌"
            return
        }

        let pool = Array.isArray(root.remainingMessageIndices)
            ? root.remainingMessageIndices.slice()
            : []

        // Shuffle without replacement so messages vary and don't repeat until
        // the pool has been used. Avoid repeating the last line at a new cycle.
        if (pool.length === 0) {
            pool = messages.map((message, index) => index)
            const previousIndex = messages.indexOf(root.currentMessage)
            if (previousIndex >= 0 && pool.length > 1)
                pool = pool.filter(index => index !== previousIndex)
        }

        const selectedAt = Math.floor(Math.random() * pool.length)
        const selectedIndex = pool[selectedAt]
        pool.splice(selectedAt, 1)
        root.remainingMessageIndices = pool
        root.currentMessage = messages[selectedIndex] || messages[0]
    }

    function playWarningSound() {
        // Try the desktop sound theme first, then common PipeWire/PulseAudio
        // players. This keeps the audible warning working across installations.
        Quickshell.execDetached([
            "sh", "-c",
            "if command -v canberra-gtk-play >/dev/null 2>&1; then canberra-gtk-play -i alarm-clock-elapsed >/dev/null 2>&1 && exit 0; fi; " +
            "for player in paplay pw-play; do " +
            "  if command -v \"$player\" >/dev/null 2>&1; then " +
            "    for sound in /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga /usr/share/sounds/freedesktop/stereo/dialog-warning.oga; do " +
            "      if [ -r \"$sound\" ]; then \"$player\" \"$sound\" >/dev/null 2>&1 && exit 0; fi; " +
            "    done; " +
            "  fi; " +
            "done; " +
            "if command -v aplay >/dev/null 2>&1 && [ -r /usr/share/sounds/alsa/Front_Center.wav ]; then aplay /usr/share/sounds/alsa/Front_Center.wav >/dev/null 2>&1; fi"
        ])
    }

    onSeverityChanged: {
        if (opened) {
            root.chooseRandomMessage()
            root.playWarningSound()
        }
    }

    onOpenedChanged: {
        if (opened) {
            root.chooseRandomMessage()
            root.playWarningSound()
        }
    }

    Component.onCompleted: {
        if (root.opened && !root.currentMessage.length)
            root.chooseRandomMessage()
    }
}
