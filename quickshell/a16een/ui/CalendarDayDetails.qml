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
    property var saintMaryImageFiles: []
    property var kidaneMehretImageFiles: []
    property bool saintMaryScanComplete: false
    property bool kidaneMehretScanComplete: false
    readonly property string calendarAssetDirectory:
        Quickshell.env("HOME") + "/.config/a16een/quickshell/a16een/assets/calendar"
    readonly property int detailCardWidth: {
        const screenWidth = root.modelData && root.modelData.width > 0
            ? Number(root.modelData.width) : 1366
        const available = screenWidth - (root.horizontalNavbar ? 324 : 378)
        return Math.max(320, Math.min(560, available))
    }
    readonly property int detailCardHeight: {
        const screenHeight = root.modelData && root.modelData.height > 0
            ? Number(root.modelData.height) : 768
        return Math.max(320, Math.min(560, screenHeight - 68))
    }

    function imageFileList(output) {
        return String(output || "").split("\n")
            .map(name => name.trim())
            .filter(name => /\.(jpg|jpeg|png|webp|avif)$/i.test(name))
    }

    function storePortraitFiles(pool, output) {
        const files = root.imageFileList(output)
        if (pool === "saint-mary") {
            root.saintMaryImageFiles = files
            root.saintMaryScanComplete = true
        } else if (pool === "kidane-mehret") {
            root.kidaneMehretImageFiles = files
            root.kidaneMehretScanComplete = true
        }

        // Show the bundled fallback while scanning, then switch to the chosen
        // portrait immediately when the cached list arrives.
        if (root.opened && root.dayInfo
            && String(root.dayInfo.imagePool || "") === pool && files.length > 0)
            root.chooseRandomPortrait(pool, files)
    }

    function chooseRandomPortrait(pool, candidates) {
        const files = candidates || []
        const current = pool === "saint-mary"
            ? root.selectedSaintMaryImage : root.selectedKidaneMehretImage

        if (!files.length) {
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

    function selectCurrentPortrait() {
        const pool = root.dayInfo ? String(root.dayInfo.imagePool || "") : ""
        if (pool === "saint-mary") {
            if (root.saintMaryImageFiles.length > 0)
                root.chooseRandomPortrait(pool, root.saintMaryImageFiles)
            else if (!root.saintMaryScanComplete && !maryImageScanner.running)
                maryImageScanner.running = true
        } else if (pool === "kidane-mehret") {
            if (root.kidaneMehretImageFiles.length > 0)
                root.chooseRandomPortrait(pool, root.kidaneMehretImageFiles)
            else if (!root.kidaneMehretScanComplete && !kidaneMehretImageScanner.running)
                kidaneMehretImageScanner.running = true
        }
    }

    function refreshCurrentPortrait() {
        portraitRefreshTimer.restart()
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

    Timer {
        id: portraitRefreshTimer
        interval: 8
        repeat: false
        onTriggered: root.selectCurrentPortrait()
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
            onStreamFinished: root.storePortraitFiles("saint-mary", text)
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
            onStreamFinished: root.storePortraitFiles("kidane-mehret", text)
        }
    }

    screen: root.modelData
    visible: (root.surfaceVisible || root.opened) && root.dockVisible && root.modelData !== null
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    width: root.detailCardWidth
    height: root.detailCardHeight

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
            portraitRefreshTimer.stop()
            root.surfaceVisible = false
            if (root.opened)
                root.closeRequested()
            root.hoveringChanged(false)
        }
    }

    Component.onCompleted: {
        // Cache each portrait directory before the first detail-card opening.
        if (!maryImageScanner.running && !root.saintMaryScanComplete)
            maryImageScanner.running = true
        if (!kidaneMehretImageScanner.running && !root.kidaneMehretScanComplete)
            kidaneMehretImageScanner.running = true
        if (root.opened) {
            root.surfaceVisible = true
            root.refreshCurrentPortrait()
        }
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
        radius: 26
        color: Qt.rgba(popupCardStyle.backgroundColor.r,
            popupCardStyle.backgroundColor.g, popupCardStyle.backgroundColor.b, 0.91)
        border.width: 1
        border.color: popupCardStyle.darkMode ? "#65FFFFFF" : "#A6FFFFFF"
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.975
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
            anchors.margins: -5
            radius: 31
            color: "#1C000000"
            z: -1
        }

        // A fine inner highlight gives the translucent surface a glass edge.
        Rectangle {
            x: 18
            y: 1
            width: parent.width - 36
            height: 1
            radius: 1
            color: popupCardStyle.darkMode ? "#45FFFFFF" : "#DFFFFFFF"
            z: 1
        }

        Row {
            id: cardBody
            anchors.fill: parent
            anchors.margins: 18
            spacing: 18

            Rectangle {
                id: portraitFrame
                visible: root.dayInfo.image !== undefined
                    && String(root.dayInfo.image).length > 0
                width: visible ? Math.min(224, Math.max(124, cardBody.width * 0.40)) : 0
                height: parent.height
                radius: 19
                color: popupCardStyle.subtleSurfaceColor
                border.width: 1
                border.color: popupCardStyle.darkMode ? "#55FFFFFF" : "#BFFFFFFF"
                clip: true

                Image {
                    id: portraitImage
                    anchors.fill: parent
                    anchors.margins: 1
                    source: portraitFrame.visible ? root.portraitSource() : ""
                    sourceSize.width: Math.max(1, portraitFrame.width * 2)
                    sourceSize.height: Math.max(1, portraitFrame.height * 2)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    smooth: true
                    mipmap: true
                    visible: status === Image.Ready
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 18
                    color: "transparent"
                    border.width: 1
                    border.color: "#38FFFFFF"
                    z: 1
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: Math.min(108, parent.height * 0.24)
                    radius: 18
                    color: "#180B111A"
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#000B111A" }
                        GradientStop { position: 1.0; color: "#950B111A" }
                    }
                    visible: portraitImage.status === Image.Ready
                    z: 1
                }

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 18
                    spacing: 8
                    visible: portraitFrame.visible && portraitImage.status !== Image.Ready
                    z: 2

                    Text {
                        width: parent.width
                        text: "✧"
                        color: popupCardStyle.actionColor
                        font.pixelSize: 42
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        width: parent.width
                        text: "ምስል"
                        color: popupCardStyle.mutedTextColor
                        font.family: "Noto Sans Ethiopic"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: "Portrait loading"
                        color: popupCardStyle.mutedTextColor
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Column {
                id: detailsColumn
                width: parent.width - portraitFrame.width - cardBody.spacing
                height: parent.height
                spacing: 8

                Row {
                    width: parent.width
                    height: 30
                    spacing: 9

                    Rectangle {
                        width: Math.max(0, parent.width - 43)
                        height: parent.height
                        radius: 11
                        color: Qt.rgba(popupCardStyle.subtleSurfaceColor.r,
                            popupCardStyle.subtleSurfaceColor.g,
                            popupCardStyle.subtleSurfaceColor.b, 0.76)
                        border.width: 1
                        border.color: popupCardStyle.fieldBorderColor

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 11
                            anchors.rightMargin: 11
                            text: root.dayInfo.category
                            color: popupCardStyle.secondaryTextColor
                            font.family: "Noto Sans Ethiopic"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Rectangle {
                        width: 32
                        height: 30
                        radius: 11
                        color: closeHover.containsMouse
                            ? popupCardStyle.hoverSurfaceColor
                            : Qt.rgba(popupCardStyle.subtleSurfaceColor.r,
                                popupCardStyle.subtleSurfaceColor.g,
                                popupCardStyle.subtleSurfaceColor.b, 0.72)
                        border.width: 1
                        border.color: popupCardStyle.fieldBorderColor

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: popupCardStyle.secondaryTextColor
                            font.pixelSize: 22
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
                    spacing: 4

                    Text {
                        width: parent.width
                        text: root.dayInfo.title
                        color: popupCardStyle.textColor
                        font.family: "Noto Sans Ethiopic"
                        font.pixelSize: 23
                        font.weight: Font.DemiBold
                        maximumLineCount: 2
                        wrapMode: Text.WordWrap
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.months[root.selectedMonth - 1] + " " + root.selectedDay
                            + " · " + root.selectedYear + " ዓ.ም."
                        color: popupCardStyle.mutedTextColor
                        font.family: "Noto Sans Ethiopic"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: popupCardStyle.fieldBorderColor
                    opacity: 0.9
                }

                Column {
                    width: parent.width
                    spacing: 6

                    Text {
                        width: parent.width
                        height: 16
                        text: "የዕለቱ መታሰቢያ"
                        color: popupCardStyle.actionColor
                        font.family: "Noto Sans Ethiopic"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        height: Math.min(100, Math.max(58, detailsColumn.height * 0.18))
                        text: root.dayInfo.description
                        color: popupCardStyle.secondaryTextColor
                        font.family: "Noto Sans Ethiopic"
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                        maximumLineCount: 7
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    width: parent.width
                    visible: root.dayInfo.showScripture !== false
                    height: visible ? Math.min(176, Math.max(112, detailsColumn.height * 0.31)) : 0
                    radius: 17
                    color: Qt.rgba(popupCardStyle.subtleSurfaceColor.r,
                        popupCardStyle.subtleSurfaceColor.g,
                        popupCardStyle.subtleSurfaceColor.b, 0.68)
                    border.width: 1
                    border.color: popupCardStyle.fieldBorderColor

                    Column {
                        anchors.fill: parent
                        anchors.margins: 13
                        spacing: 8

                        Row {
                            width: parent.width
                            height: 18
                            spacing: 7

                            Text {
                                text: "✧"
                                color: popupCardStyle.actionColor
                                font.pixelSize: 17
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "የመጽሐፍ ቅዱስ ጥቅስ"
                                color: popupCardStyle.secondaryTextColor
                                font.family: "Noto Sans Ethiopic"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            width: parent.width
                            height: parent.height - 54
                            text: "“" + root.dayInfo.verse + "”"
                            color: popupCardStyle.textColor
                            font.family: "Noto Sans Ethiopic"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            wrapMode: Text.WordWrap
                            maximumLineCount: 5
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: root.dayInfo.reference
                            color: popupCardStyle.actionColor
                            font.family: "Noto Sans Ethiopic"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                Text {
                    width: parent.width
                    height: Math.max(36, parent.height * 0.09)
                    text: root.dayInfo.reflection
                    color: popupCardStyle.mutedTextColor
                    font.family: "Noto Sans Ethiopic"
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
            }
        }

        HoverHandler {
            onHoveredChanged: root.hoveringChanged(hovered)
        }
    }
}
