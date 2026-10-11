import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var options: []
    property string selectedColor: ""
    property bool pickerEnabled: true
    signal colorPicked(string value)

    implicitHeight: Math.ceil(options.length / 5) * 43
        + Math.max(0, Math.ceil(options.length / 5) - 1) * 5
    implicitWidth: 260

    GridLayout {
        id: paletteGrid
        anchors.fill: parent
        columns: 5
        rowSpacing: 5
        columnSpacing: 5

        Repeater {
            model: root.options

            delegate: Rectangle {
                id: swatchTile
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredWidth: (paletteGrid.width - paletteGrid.columnSpacing * 4) / 5
                Layout.preferredHeight: 43
                radius: 8
                color: root.pickerEnabled && paletteMouse.containsMouse ? "#F2F4F7" : "transparent"
                border.width: root.selectedColor === modelData.value ? 1.5 : 1
                border.color: root.selectedColor === modelData.value ? "#252A31" : "#E2E6EB"
                opacity: root.pickerEnabled ? 1 : 0.42

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 5
                    width: 21
                    height: 21
                    radius: 6
                    color: swatchTile.modelData.swatch
                    border.width: swatchTile.modelData.value === "transparent" ? 1 : 0
                    border.color: "#C7CDD5"

                    Rectangle {
                        visible: swatchTile.modelData.value === "transparent"
                        width: parent.width + 4
                        height: 1.5
                        anchors.centerIn: parent
                        rotation: -42
                        color: "#D34A4A"
                    }

                    Rectangle {
                        visible: swatchTile.modelData.value === "auto"
                        anchors.fill: parent
                        radius: parent.radius
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#15171A" }
                            GradientStop { position: 0.5; color: "#15171A" }
                            GradientStop { position: 0.5; color: "#FFFFFF" }
                            GradientStop { position: 1.0; color: "#FFFFFF" }
                        }
                        border.width: 1
                        border.color: "#D2D6DC"
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    horizontalAlignment: Text.AlignHCenter
                    text: swatchTile.modelData.label
                    color: root.pickerEnabled ? "#525D6A" : "#9299A3"
                    font.pixelSize: 7
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: paletteMouse
                    anchors.fill: parent
                    enabled: root.pickerEnabled
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.colorPicked(swatchTile.modelData.value)
                }
            }
        }
    }
}
