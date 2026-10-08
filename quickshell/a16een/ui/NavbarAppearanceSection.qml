import QtQuick

Item {
    id: root

    property bool active: false
    property string selectedSlot: ""
    property string selectedIcon: ""
    property string selectedStyle: "solid:#111318"
    property var colors: []
    property var styleChoices: []

    signal iconStyleSelected(string style)
    signal colorSelected(string color)

    Column {
        anchors.fill: parent
        anchors.margins: 2
        spacing: 12

        Row {
            width: parent.width
            height: 54
            spacing: 12

            Rectangle {
                width: 54
                height: 54
                radius: 14
                color: "#FFFFFF"
                border.width: 1
                border.color: "#CBD3DB"

                Image {
                    anchors.centerIn: parent
                    width: 26
                    height: 26
                    sourceSize.width: width
                    sourceSize.height: height
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    source: selectedIcon.length
                        ? Qt.resolvedUrl("../assets/icons/" + selectedIcon)
                        : Qt.resolvedUrl("../assets/icons/palette.svg")
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    text: selectedSlot.toUpperCase() + " APPEARANCE"
                    color: "#111318"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Text {
                    text: selectedStyle.toUpperCase()
                    color: "#64748B"
                    font.pixelSize: 7
                    elide: Text.ElideRight
                }
            }
        }

        Text {
            text: "COLORS"
            color: "#64748B"
            font.pixelSize: 7
            font.weight: Font.DemiBold
            font.letterSpacing: 1
        }

        Flickable {
            width: parent.width
            height: 34
            clip: true
            contentWidth: colorRow.width
            contentHeight: colorRow.height
            boundsBehavior: Flickable.StopAtBounds

            Row {
                id: colorRow
                height: 22
                spacing: 5

                Repeater {
                    model: root.colors

                    delegate: Rectangle {
                        width: 22
                        height: 22
                        radius: 7
                        color: "#FFFFFF"
                        border.width: 1
                        border.color: root.selectedStyle === "solid:" + modelData
                            ? "#111318" : "#CBD3DB"

                        Rectangle {
                            anchors.centerIn: parent
                            width: 12
                            height: 12
                            radius: 6
                            color: modelData
                            border.width: modelData === "#FFFFFF" ? 1 : 0
                            border.color: "#9AA6B2"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.colorSelected(modelData)
                        }
                    }
                }
            }
        }

        Text {
            text: "DESIGNS"
            color: "#64748B"
            font.pixelSize: 7
            font.weight: Font.DemiBold
            font.letterSpacing: 1
        }

        Flickable {
            width: parent.width
            height: 150
            clip: true
            contentWidth: designGrid.width
            contentHeight: designGrid.height
            boundsBehavior: Flickable.StopAtBounds

            Grid {
                id: designGrid
                width: parent.width
                columns: 3
                rowSpacing: 7
                columnSpacing: 7
                height: Math.ceil(root.styleChoices.length / 3) * 38

                Repeater {
                    model: root.styleChoices

                    delegate: Rectangle {
                        width: (designGrid.width - 14) / 3
                        height: 32
                        radius: 9
                        color: "#FFFFFF"
                        border.width: 1
                        border.color: root.selectedStyle === modelData.spec
                            ? "#111318" : "#CBD3DB"

                        Rectangle {
                            id: preview
                            anchors.left: parent.left
                            anchors.leftMargin: 7
                            anchors.verticalCenter: parent.verticalCenter
                            width: 28
                            height: 18
                            radius: 5
                            color: modelData.a

                            Rectangle {
                                visible: modelData.kind === "split"
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width / 2
                                radius: 5
                                color: modelData.b
                            }

                            Rectangle {
                                visible: modelData.kind === "gradient"
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width / 2
                                radius: 5
                                color: modelData.b
                            }
                        }

                        Text {
                            anchors.left: preview.right
                            anchors.leftMargin: 5
                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.name
                            color: "#334155"
                            font.pixelSize: 6
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.iconStyleSelected(modelData.spec)
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 54
            radius: 13
            color: "#FBFCFD"
            border.width: 1
            border.color: "#CBD3DB"

            Text {
                anchors.centerIn: parent
                text: "Appearance applies to the selected workspace icon."
                color: "#64748B"
                font.pixelSize: 8
            }
        }
    }
}
