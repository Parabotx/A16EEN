import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property bool opened: false
    property string noteText: ""
    property bool storageReady: false
    property bool saved: true

    signal closeRequested()

    screen: root.modelData
    visible: root.opened && root.modelData !== null
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "a16een-quick-notes"
    focusable: root.opened
    WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    FileView {
        id: notesStorage
        path: Quickshell.stateDir + "/quick-notes.txt"
        preload: true
        printErrors: false
        atomicWrites: true
        onLoaded: root.loadState()
        onLoadFailed: root.storageReady = true
    }

    Timer {
        id: saveTimer
        interval: 280
        repeat: false
        onTriggered: {
            if (!root.storageReady)
                return
            notesStorage.setText(root.noteText)
            root.saved = true
        }
    }

    function loadState() {
        if (root.storageReady)
            return
        root.noteText = String(notesStorage.text() || "")
        root.storageReady = true
        root.saved = true
    }

    function saveNow() {
        saveTimer.stop()
        if (!root.storageReady)
            return
        notesStorage.setText(root.noteText)
        root.saved = true
    }

    onOpenedChanged: {
        if (opened && root.storageReady)
            Qt.callLater(() => notesEditor.forceActiveFocus())
        else if (!opened)
            root.saveNow()
    }

    onStorageReadyChanged: {
        if (storageReady && opened)
            Qt.callLater(() => notesEditor.forceActiveFocus())
    }

    Item {
        anchors.fill: parent
        visible: root.opened

        Rectangle {
            anchors.fill: parent
            color: "#440D1117"

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: root.closeRequested()
            }
        }

        Rectangle {
            id: noteCard
            z: 1
            anchors.centerIn: parent
            width: Math.min(660, root.modelData ? root.modelData.width - 40 : 620)
            height: Math.min(500, root.modelData ? root.modelData.height - 40 : 460)
            radius: 24
            color: "#FFFFFF"
            border.width: 1
            border.color: "#DCE2E9"

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: 28
                color: "#16000000"
                z: -1
            }

            Column {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 14

                Row {
                    width: parent.width
                    height: 38
                    spacing: 12

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 164
                        spacing: 3

                        Text {
                            text: "NOTES"
                            color: "#12161C"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.2
                        }

                        Text {
                            text: "A quiet place for your thoughts"
                            color: "#7A8491"
                            font.pixelSize: 11
                        }
                    }

                    Item { width: 1; height: 1 }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 94
                        height: 28
                        radius: 14
                        color: "#F5F7F9"
                        border.width: 1
                        border.color: "#E4E8ED"

                        Row {
                            anchors.centerIn: parent
                            spacing: 5

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 6
                                height: 6
                                radius: 3
                                color: root.saved ? "#2F9B67" : "#C38A31"
                            }

                            Text {
                                text: root.saved ? "SAVED" : "SAVING"
                                color: "#626D79"
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.7
                            }
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 32
                        radius: 11
                        color: closeMouse.containsMouse ? "#F0F2F5" : "#FFFFFF"
                        border.width: 1
                        border.color: "#E3E7EC"

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: "#333B45"
                            font.pixelSize: 22
                            font.weight: Font.Normal
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
                    height: 1
                    color: "#E9EDF1"
                }

                Text {
                    text: "QUICK NOTE"
                    color: "#87919E"
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.1
                }

                Rectangle {
                    width: parent.width
                    height: Math.max(190, parent.height - 144)
                    radius: 17
                    color: "#FAFBFC"
                    border.width: 1
                    border.color: notesEditor.activeFocus ? "#B8C5D4" : "#E5EAF0"

                    TextEdit {
                        id: notesEditor
                        anchors.fill: parent
                        anchors.margins: 17
                        text: root.noteText
                        color: "#202833"
                        selectedTextColor: "#FFFFFF"
                        selectionColor: "#6E8FB9"
                        font.family: "Noto Sans"
                        font.pixelSize: 14
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        persistentSelection: true
                        clip: true
                        activeFocusOnPress: true
                        enabled: root.storageReady
                        verticalAlignment: TextEdit.AlignTop

                        onTextChanged: {
                            if (!root.storageReady || root.noteText === text)
                                return
                            root.noteText = text
                            root.saved = false
                            saveTimer.restart()
                        }

                        Keys.onEscapePressed: root.closeRequested()
                    }

                    Text {
                        visible: notesEditor.text.length === 0 && !notesEditor.activeFocus
                        anchors.left: notesEditor.left
                        anchors.top: notesEditor.top
                        text: "Write something you want to remember…"
                        color: "#A0A9B4"
                        font.family: "Noto Sans"
                        font.pixelSize: 14
                        enabled: false
                    }
                }

                Row {
                    width: parent.width
                    height: 24
                    spacing: 6

                    Text {
                        text: "AUTOSAVES LOCALLY"
                        color: "#98A1AD"
                        font.pixelSize: 9
                        font.weight: Font.Medium
                        font.letterSpacing: 0.8
                    }

                    Item { width: Math.max(1, parent.width - 200); height: 1 }

                    Text {
                        text: root.noteText.length + " characters"
                        color: "#98A1AD"
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
