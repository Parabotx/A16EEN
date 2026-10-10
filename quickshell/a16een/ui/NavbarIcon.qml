import QtQuick
import QtQuick.Effects

Item {
    id: root

    property string iconName: ""
    property color iconColor: "#111111"
    property string iconPath: ""
    property string fallbackIconPath: ""
    property int refreshRevision: 0
    property bool hovered: false
    property bool active: false
    property bool preserveSourceColors: false
    property string imageSource: ""

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

        const path = String(root.iconPath || root.fallbackIconPath || "")
        const marker = "/assets/icons/"
        const index = path.lastIndexOf(marker)
        if (index >= 0)
            return path.substring(index + marker.length)

        return "house.svg"
    }

    function desiredSource() {
        if (root.iconPath.length)
            return root.iconPath
        return Qt.resolvedUrl("../assets/icons/" + root.effectiveIconName)
    }

    function reloadSource() {
        const path = root.desiredSource()
        root.imageSource = ""
        Qt.callLater(() => root.imageSource = path)
    }

    Image {
        id: iconImage
        anchors.fill: parent
        source: root.imageSource
        fillMode: Image.PreserveAspectFit
        sourceSize.width: width
        sourceSize.height: height
        smooth: true
        mipmap: true
        asynchronous: true
        cache: false
        layer.enabled: !root.preserveSourceColors

        layer.effect: MultiEffect {
            colorization: 1
            colorizationColor: root.iconColor
        }

        onStatusChanged: {
            if (status === Image.Error && root.fallbackIconPath.length
                && source !== root.fallbackIconPath) {
                root.imageSource = root.fallbackIconPath
            }
        }
    }

    Component.onCompleted: root.reloadSource()
    onIconNameChanged: root.reloadSource()
    onIconPathChanged: root.reloadSource()
    onFallbackIconPathChanged: root.reloadSource()
    onRefreshRevisionChanged: root.reloadSource()
}
