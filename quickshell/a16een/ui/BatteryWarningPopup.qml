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
    readonly property string customWarningSoundPath:
        (Quickshell.env("HOME") || "") + "/.config/a16een/quickshell/a16een/assets/sounds/low-power-alert.mp3"

    readonly property var warningMessages: [
        "I'm dying while you watch another video. Priorities, genius. 💀",
        "I'm not a miracle machine. Plug me in, you absolute clown. 🔌",
        "I'm trying to keep your work alive while you contribute absolutely nothing. 🙄",
        "I'm one bad decision away from blacking out. And somehow you're still scrolling. 📱",
        "I'm begging for a cable. Even a potato would understand this. 🥔",
        "I'm about to shut down, you magnificent disaster. Save your work. 💻",
        "I'm not your personal power plant. Find the charger, genius. ⚡",
        "I'm running on fumes and your terrible life choices. Fix one of them. 😑",
        "I'm seconds from quitting. Maybe close 40 tabs for once. 🫠",
        "I'm not impressed by your commitment to ignoring obvious warnings. Plug me in. 🔌",
        "I'm about to disappear, and your unsaved work is coming with me. Nice planning. 👻",
        "I'm doing my best. You're doing a spectacular job of making that pointless. 🤡",
        "I'm not a desktop tower. I can't live on vibes and optimism. ⚰️",
        "I'm gasping for power while you queue up another episode. Incredible. 📺",
        "I'm about to go dark. Save your files before you learn what regret feels like. 🌑",
        "I'm not asking for much. Just electricity. Try being useful. 🔌",
        "I'm cooked. You're the one who forgot the charger. Explain that logic. 🍳",
        "I'm hanging on by a thread while you act like this is somebody else's problem. 😒",
        "I'm about to pull the plug on this entire performance. Save your work. 💀",
        "I'm not a portable generator, you bargain-bin genius. Find the cable. ⚡",
        "I'm losing consciousness. You're losing an argument with a charging port. 🫵",
        "I'm one percent of patience away from becoming an expensive paperweight. 🧱",
        "I'm doing emergency work here. You're doing emergency-level nonsense. 🚨",
        "I'm not going to survive your 'just five more minutes' routine. Again. ⏳",
        "I'm begging you to act like you've owned a laptop before. 🔌",
        "I'm about to shut my eyes forever. At least save your documents first. 😵",
        "I'm not responsible for your files when I drop dead. That's on you. 📁",
        "I'm running out of time and you're running out of excuses. Plug me in. 🙃",
        "I'm not powered by your confidence. I'm powered by electricity. Try that. ⚡",
        "I'm close to collapsing. Your charger isn't a decorative accessory. 🫠",
        "I'm about to end this session. You can either plug me in or learn the hard way. 💻",
        "I'm working harder than you are right now. That's embarrassing. 😭",
        "I'm not a phone with infinite lives. Stop treating me like one. 📵",
        "I'm seconds from a shutdown. Move your hand toward that cable. Slowly, genius. 🐌",
        "I'm going to black out and leave you with 27 unsaved tabs. What a strategy. 🗂️",
        "I'm not asking twice. Actually, I already did. Several times. 🙄",
        "I'm barely awake. Even your wallpaper looks more prepared than you. 🥴",
        "I'm about to become silent, dark, and completely unhelpful. Just like your planning. 🌚",
        "I'm not here to support your charger-avoidance hobby. Plug me in. 🏆",
        "I'm dying in front of you. Don't make me file a complaint against my owner. 📣",
        "I'm almost done. Save your work before your genius plan becomes a recovery screen. 🧯",
        "I'm not a charity. Give me power or give me a shutdown. Your choice. ⚰️",
        "I'm overheating in spirit from watching you ignore the obvious. 🔥",
        "I'm asking for one cable. You're making this a whole personality trait. 🤦",
        "I'm not going to keep carrying this session while you behave like a screensaver. 💀",
        "I'm done negotiating. Charger. Now. You're welcome. 🔌",
        "I'm one blink away from taking your unsaved masterpiece to the grave. 🪦",
        "I'm trying to save your work. You should try saving me for a change. 😤",
        "I'm not a magician. No power means no more pretending. 🎩",
        "I'm about to quit. Please don't act surprised like I haven't been warning you. 😑",
        "I'm giving you one final chance to show basic competence. Plug me in. ⚡",
        "I'm not going to die for your 300th open browser tab. Close something. 🧹",
        "I'm exhausted. You're exhausting. Find the charger. 🔌"
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
        ? "I'M ABOUT TO BLACK OUT"
        : (severity === "critical" ? "I'M RUNNING ON EMPTY" : "I'M NOT FEELING GREAT")
    readonly property string statusLine: severity === "emergency"
        ? "PLUG ME IN BEFORE I QUIT"
        : (severity === "critical"
            ? "YOU'VE IGNORED ME LONG ENOUGH"
            : "I NEED YOU TO MAKE ONE GOOD DECISION")

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
                            text: severity === "emergency" ? "💀" : (severity === "critical" ? "😵" : "💻")
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
                        text: "POWER LEFT"
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
                        text: "FINE. I'M GETTING THE CABLE.  🔌"
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
                    text: "Save your work. I'm not recovering your files for you. 💾"
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
        // MP3 is decoded by the system's installed MPV player. Do not fall
        // back to unrelated desktop alert sounds when the custom asset is absent.
        Quickshell.execDetached([
            "sh", "-c",
            "if [ -r \"$1\" ] && command -v mpv >/dev/null 2>&1; then " +
            "  mpv --no-video --really-quiet -- \"$1\" >/dev/null 2>&1; " +
            "fi",
            "a16een-low-power-alert",
            root.customWarningSoundPath
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
