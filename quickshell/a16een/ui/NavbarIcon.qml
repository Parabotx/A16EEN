import QtQuick
import QtQuick.Effects

Item {
    id: root

    // Proven local renderer: render the bundled Lucide SVG and colorize its
    // alpha. This avoids the fragile file:// generated-SVG path used by the
    // broken navbar renderer.
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
        sourceSize.width: width
        sourceSize.height: height
        smooth: true
        mipmap: true
        asynchronous: true
        cache: false
        layer.enabled: true

        layer.effect: MultiEffect {
            colorization: 1
            colorizationColor: root.iconColor
        }
    }
}
