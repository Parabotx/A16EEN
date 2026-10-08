import QtQuick
import QtQuick.Effects

Item {
    id: root

    // Proven local renderer: render the bundled Lucide SVG and colorize its
    // alpha. This avoids the fragile file:// generated-SVG path used by the
    // broken navbar renderer.
    property string iconName: ""
    property color iconColor: "#111111"
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

    readonly property string effectiveSource: {
        if (root.iconName.length)
            return Qt.resolvedUrl("../assets/icons/" + root.iconName)
        if (root.fallbackIconPath.length)
            return root.fallbackIconPath
        return root.iconPath
    }

    Image {
        id: iconImage
        anchors.fill: parent
        source: root.effectiveSource
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

        onStatusChanged: {
            if (status === Image.Error && root.fallbackIconPath.length
                && source !== root.fallbackIconPath) {
                source = root.fallbackIconPath
            }
        }
    }

    function refresh() {
        iconImage.source = ""
        Qt.callLater(() => iconImage.source = root.effectiveSource)
    }

    onIconNameChanged: root.refresh()
    onIconPathChanged: root.refresh()
    onFallbackIconPathChanged: root.refresh()
    onRefreshRevisionChanged: root.refresh()
    Component.onCompleted: root.refresh()
}
