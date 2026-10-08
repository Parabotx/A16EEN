import QtQuick
import QtQuick.Effects

Item {
    id: root

    // Stable renderer: always loads the bundled Lucide asset and colorizes
    // its alpha. Generated navbar SVGs remain available for previews/state,
    // but the live UI is never dependent on their file:// rendering path.
    property string iconName: ""
    property color iconColor: "#111111"
    // Backward-compatible properties used by older manager implementations.
    property string iconPath: ""
    property string fallbackIconPath: ""
    property int refreshRevision: 0
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

    readonly property string effectiveIconName: {
        if (root.iconName.length)
            return root.iconName

        const path = String(root.fallbackIconPath || root.iconPath || "")
        const marker = "/assets/icons/"
        const index = path.lastIndexOf(marker)
        if (index >= 0)
            return path.substring(index + marker.length)

        return "house.svg"
    }

    Image {
        id: iconImage
        anchors.fill: parent
        source: Qt.resolvedUrl("../assets/icons/" + root.effectiveIconName)
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
