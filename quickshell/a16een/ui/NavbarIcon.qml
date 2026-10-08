import QtQuick
import Quickshell

Item {
    id: root

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

    function refresh() {
        const primary = String(root.iconPath || "")
        const fallback = String(root.fallbackIconPath || "")
        image.source = ""
        Qt.callLater(() => {
            if (primary.length)
                image.source = primary
            else
                image.source = fallback
        })
    }

    Image {
        id: image
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        sourceSize.width: width
        sourceSize.height: height
        smooth: true
        mipmap: true
        asynchronous: true

        onStatusChanged: {
            if (status === Image.Error && root.fallbackIconPath.length
                && source !== root.fallbackIconPath) {
                source = root.fallbackIconPath
            }
        }
    }

    onIconPathChanged: root.refresh()
    onRefreshRevisionChanged: root.refresh()
    Component.onCompleted: root.refresh()
}
