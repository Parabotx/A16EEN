import QtQuick
import QtQuick.Effects

Item {
    id: root

    property string iconName: "house.svg"
    property color iconColor: "#111111"
    property bool hovered: false
    property bool active: false

    implicitWidth: 19
    implicitHeight: 19

    scale: root.hovered ? 1.08 : (root.active ? 1.03 : 1)

    Behavior on scale {
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutCubic
        }
    }

    Image {
        id: iconImage
        anchors.fill: parent
        source: root.iconName.length
            ? Qt.resolvedUrl("../assets/icons/" + root.iconName)
            : ""
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1
            colorizationColor: root.iconColor
        }
    }
}
