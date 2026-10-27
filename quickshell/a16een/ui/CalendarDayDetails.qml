import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.ui

PanelWindow {
    id: root

    required property var modelData
    required property string navbarPosition
    required property bool dockVisible
    required property bool opened
    required property int selectedDay
    required property int selectedMonth
    required property int selectedYear
    required property var selectedEvent

    signal closeRequested()
    signal hoveringChanged(bool hovering)

    PopupCardStyle {
        id: popupCardStyle
        containerId: "time"
    }

    CalendarCommemorations {
        id: calendarData
    }

    readonly property bool horizontalNavbar:
        root.navbarPosition === "top" || root.navbarPosition === "bottom"
    readonly property var months: [
        "መስከረም", "ጥቅምት", "ሕዳር", "ታህሳስ",
        "ጥር", "የካቲት", "መጋቢት", "ሚያዝያ",
        "ግንቦት", "ሰኔ", "ሐምሌ", "ነሐሴ", "ጳጉሜ"
    ]
    readonly property var dayInfo: root.selectedEvent || calendarData.forDate(root.selectedMonth, root.selectedDay)
    property bool surfaceVisible: false
    property string selectedSaintMaryImage: ""
    property string selectedKidaneMehretImage: ""
    readonly property string calendarAssetDirectory:
        Quickshell.env("HOME") + "/.config/a16een/quickshell/a16een/assets/calendar"

    function chooseRandomPortrait(pool, output) {
        const files = String(output || "").split("\n")
            .map(name => name.trim())
            .filter(name => /\.(jpg|jpeg|png|webp|avif)$/i.test(name))
        const current = pool === "saint-mary"
            ? root.selectedSaintMaryImage : root.selectedKidaneMehretImage

        if (files.length === 0) {
            if (pool === "saint-mary")
                root.selectedSaintMaryImage = ""
            else if (pool === "kidane-mehret")
                root.selectedKidaneMehretImage = ""
            return
        }

        let nextIndex = Math.floor(Math.random() * files.length)
        if (files.length > 1 && files[nextIndex] === current)
            nextIndex = (nextIndex + 1 + Math.floor(Math.random() * (files.length - 1))) % files.length

        if (pool === "saint-mary")
            root.selectedSaintMaryImage = files[nextIndex]
        else if (pool === "kidane-mehret")
            root.selectedKidaneMehretImage = files[nextIndex]
    }

    function refreshCurrentPortrait() {
        const pool = root.dayInfo ? String(root.dayInfo.imagePool || "") : ""
        if (pool === "saint-mary" && !maryImageScanner.running)
            maryImageScanner.running = true
        else if (pool === "kidane-mehret" && !kidaneMehretImageScanner.running)
            kidaneMehretImageScanner.running = true
    }

    function portraitSource() {
        const pool = root.dayInfo ? String(root.dayInfo.imagePool || "") : ""
        if (pool === "saint-mary" && root.selectedSaintMaryImage.length > 0)
            return Qt.resolvedUrl("../assets/calendar/saint-mary/" + root.selectedSaintMaryImage)
        if (pool === "kidane-mehret" && root.selectedKidaneMehretImage.length > 0)
            return Qt.resolvedUrl("../assets/calendar/kidane-mehret/" + root.selectedKidaneMehretImage)
        return root.dayInfo && root.dayInfo.image
            ? Qt.resolvedUrl("../assets/calendar/" + root.dayInfo.image) : ""
    }

    Process {
        id: maryImageScanner
        command: [
            "find", root.calendarAssetDirectory + "/saint-mary",
            "-mindepth", "1", "-maxdepth", "1", "-type", "f",
            "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg",
            "-o", "-iname", "*.png", "-o", "-iname", "*.webp",
            "-o", "-iname", "*.avif", ")",
            "-printf", "%f\\n"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.chooseRandomPortrait("saint-mary", text)
        }
    }

    Process {
        id: kidaneMehretImageScanner
        command: [
            "find", root.calendarAssetDirectory + "/kidane-mehret",
            "-mindepth", "1", "-maxdepth", "1", "-type", "f",
            "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg",
            "-o", "-iname", "*.png", "-o", "-iname", "*.webp",
            "-o", "-iname", "*.avif", ")",
            "-printf", "%f\\n"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.chooseRandomPortrait("kidane-mehret", text)
        }
    }

    screen: root.modelData
    visible: root.surfaceVisible && root.dockVisible && root.modelData !== null
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    width: 324
    height: 366

    anchors {
        left: root.navbarPosition !== "right"
        right: root.navbarPosition === "right"
        top: root.navbarPosition !== "bottom"
        bottom: root.navbarPosition === "bottom"
    }

    margins {
        // Match the calendar's screen edge and sit 12px beside it.
        left: root.horizontalNavbar ? 312
            : (root.navbarPosition === "left" ? 366 : 12)
        right: root.horizontalNavbar ? 12
            : (root.navbarPosition === "right" ? 368 : 12)
        top: root.navbarPosition === "bottom" ? 12
            : (root.horizontalNavbar ? 56 : 12)
        bottom: root.navbarPosition === "bottom" ? 56 : 12
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-calendar-day-details"

    onOpenedChanged: {
        if (root.opened) {
            hideTimer.stop()
            root.surfaceVisible = true
            root.refreshCurrentPortrait()
        } else {
            hideTimer.restart()
        }
    }

    onSelectedDayChanged: {
        if (root.opened)
            root.refreshCurrentPortrait()
    }

    onSelectedEventChanged: {
        if (root.opened)
            root.refreshCurrentPortrait()
    }

    onDockVisibleChanged: {
        if (!root.dockVisible) {
            hideTimer.stop()
            root.surfaceVisible = false
        }
    }

    Component.onCompleted: {
        if (root.opened)
            root.surfaceVisible = true
    }

    Timer {
        id: hideTimer
        interval: 210
        repeat: false
        onTriggered: {
            if (!root.opened)
                root.surfaceVisible = false
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 22
        color: popupCardStyle.backgroundColor
        border.width: 1
        border.color: popupCardStyle.borderColor
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.955
        transformOrigin: root.navbarPosition === "right"
            ? Item.TopRight
            : (root.navbarPosition === "bottom" ? Item.BottomLeft : Item.TopLeft)

        Behavior on color {
            ColorAnimation { duration: 145; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 175; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 205; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: 26
            color: "#16000000"
            z: -1
        }

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 4

            Row {
                width: parent.width
                height: 24
                spacing: 7

                Rectangle {
                    width: Math.min(202, parent.width - 34)
                    height: 23
                    radius: 9
                    color: popupCardStyle.subtleSurfaceColor
                    border.width: 1
                    border.color: popupCardStyle.fieldBorderColor

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        text: root.dayInfo.category
                        color: popupCardStyle.secondaryTextColor
                        font.family: "Noto Sans Ethiopic"
                        font.pixelSize: 9
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Item { width: Math.max(0, parent.width - 202 - 24 - 14); height: 1 }

                Rectangle {
                    width: 24
                    height: 24
                    radius: 8
                    color: closeHover.containsMouse
                        ? popupCardStyle.hoverSurfaceColor
                        : popupCardStyle.subtleSurfaceColor
                    border.width: 1
                    border.color: popupCardStyle.fieldBorderColor

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: popupCardStyle.secondaryTextColor
                        font.pixelSize: 17
                        font.weight: Font.Light
                    }

                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 2

                Text {
                    width: parent.width
                    text: root.dayInfo.title
                    color: popupCardStyle.textColor
                    font.family: "Noto Sans Ethiopic"
                    font.pixelSize: 19
                    font.weight: Font.DemiBold
                    maximumLineCount: 1
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.months[root.selectedMonth - 1] + " " + root.selectedDay
                        + " · " + root.selectedYear + " ዓ.ም."
                    color: popupCardStyle.mutedTextColor
                    font.family: "Noto Sans Ethiopic"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }
            }

            // Portraits sit on the outside edge of the card; the text stays
            // nearer the calendar so the two popups read as one composition.
            Row {
                width: parent.width
                height: 106
                spacing: 8
                layoutDirection: root.navbarPosition === "right"
                    ? Qt.LeftToRight : Qt.RightToLeft

                Rectangle {
                    id: portraitFrame
                    visible: root.dayInfo.image !== undefined && String(root.dayInfo.image).length > 0
                    width: visible ? 84 : 0
                    height: parent.height
                    radius: 13
                    color: popupCardStyle.subtleSurfaceColor
                    border.width: 1
                    border.color: popupCardStyle.fieldBorderColor
                    clip: true

                    Image {
                        id: portraitImage
                        anchors.fill: parent
                        anchors.margins: 1
                        source: portraitFrame.visible ? root.portraitSource() : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        smooth: true
                        visible: status === Image.Ready
                    }

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 10
                        spacing: 3
                        visible: portraitFrame.visible && portraitImage.status !== Image.Ready

                        Text {
                            width: parent.width
                            text: "✧"
                            color: popupCardStyle.actionColor
                            font.pixelSize: 21
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            width: parent.width
                            text: "ምስል"
                            color: popupCardStyle.mutedTextColor
                            font.family: "Noto Sans Ethiopic"
                            font.pixelSize: 9
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }
                }

                Column {
                    width: parent.width - (portraitFrame.visible ? 92 : 0)
                    height: parent.height
                    spacing: 5

                    Text {
                        width: parent.width
                        height: 14
                        text: "የዕለቱ መታሰቢያ"
                        color: popupCardStyle.actionColor
                        font.family: "Noto Sans Ethiopic"
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        height: parent.height - 19
                        text: root.dayInfo.description
                        color: popupCardStyle.secondaryTextColor
                        font.family: "Noto Sans Ethiopic"
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                        maximumLineCount: 5
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: popupCardStyle.fieldBorderColor
                opacity: 0.8
            }

            Rectangle {
                width: parent.width
                visible: root.dayInfo.showScripture !== false
                height: 112
                radius: 15
                color: popupCardStyle.subtleSurfaceColor
                border.width: 1
                border.color: popupCardStyle.fieldBorderColor

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 5

                    Row {
                        width: parent.width
                        height: 15
                        spacing: 5

                        Text {
                            text: "✧"
                            color: popupCardStyle.actionColor
                            font.pixelSize: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "የመጽሐፍ ቅዱስ ጥቅስ"
                            color: popupCardStyle.secondaryTextColor
                            font.family: "Noto Sans Ethiopic"
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        width: parent.width
                        height: 45
                        text: "“" + root.dayInfo.verse + "”"
                        color: popupCardStyle.textColor
                        font.family: "Noto Sans Ethiopic"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        wrapMode: Text.WordWrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.dayInfo.reference
                        color: popupCardStyle.actionColor
                        font.family: "Noto Sans Ethiopic"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            Text {
                width: parent.width
                height: 28
                text: root.dayInfo.reflection
                color: popupCardStyle.mutedTextColor
                font.family: "Noto Sans Ethiopic"
                font.pixelSize: 9
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }

        // A HoverHandler tracks the card without intercepting the close button.
        HoverHandler {
            onHoveredChanged: root.hoveringChanged(hovered)
        }
    }
}
