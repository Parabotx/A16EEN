import QtQuick

Item {
    id: root

    property string animationSource: ""
    property bool componentReady: false
    readonly property bool lottieReady: rendererLoader.item ? rendererLoader.item.ready : false

    anchors.fill: parent

    function syncRenderer() {
        if (!root.componentReady)
            return

        if (!root.animationSource.length) {
            rendererLoader.active = false
            rendererLoader.source = ""
            return
        }

        if (rendererLoader.item) {
            rendererLoader.item.animationSource = root.animationSource
            return
        }

        rendererLoader.active = true
        rendererLoader.setSource(Qt.resolvedUrl("MusicDancerLottie.qml"), {
            "animationSource": root.animationSource
        })
    }

    onAnimationSourceChanged: root.syncRenderer()

    Component.onCompleted: {
        root.componentReady = true
        root.syncRenderer()
    }

    Loader {
        id: rendererLoader
        anchors.fill: parent
        active: false
        onStatusChanged: {
            if (status === Loader.Error)
                console.warn("A16EEN Music: Lottie module/component unavailable; using animated fallback")
        }
    }

    // A visible fallback avoids an empty stage when Lottie is unavailable,
    // invalid, or still loading. It disappears as soon as the renderer is ready.
    Item {
        id: fallback
        anchors.fill: parent
        visible: !root.lottieReady

        Item {
            id: dancer
            width: 98
            height: 76
            y: 1

            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation { to: -3; duration: 180; easing.type: Easing.OutCubic }
                NumberAnimation { to: 1; duration: 220; easing.type: Easing.OutBounce }
                PauseAnimation { duration: 120 }
            }

            Rectangle {
                width: 19
                height: 19
                x: 39.5
                y: 5
                radius: 9.5
                color: "#E7A5C0"
                border.width: 1
                border.color: "#B96E91"

                Rectangle { width: 2.5; height: 3; x: 5; y: 7; radius: 1; color: "#563F4D" }
                Rectangle { width: 2.5; height: 3; x: 12; y: 7; radius: 1; color: "#563F4D" }
                Rectangle { width: 5; height: 2; x: 7; y: 13; radius: 1; color: "#B96E91" }
            }

            Rectangle {
                width: 19
                height: 21
                x: 39.5
                y: 27
                radius: 6
                color: "#9C78C1"
                border.width: 1
                border.color: "#7C589E"
            }

            Rectangle {
                width: 5; height: 17; x: 35; y: 28; radius: 2.5
                color: "#7C589E"; transformOrigin: Item.Top; rotation: 25
                SequentialAnimation on rotation {
                    loops: Animation.Infinite
                    NumberAnimation { to: -32; duration: 260; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 25; duration: 260; easing.type: Easing.InOutSine }
                }
            }

            Rectangle {
                width: 5; height: 17; x: 58; y: 28; radius: 2.5
                color: "#7C589E"; transformOrigin: Item.Top; rotation: -25
                SequentialAnimation on rotation {
                    loops: Animation.Infinite
                    NumberAnimation { to: 32; duration: 240; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -25; duration: 240; easing.type: Easing.InOutSine }
                }
            }

            Rectangle {
                width: 6; height: 14; x: 43; y: 46; radius: 3
                color: "#5D506F"; transformOrigin: Item.Top; rotation: -14
                SequentialAnimation on rotation {
                    loops: Animation.Infinite
                    NumberAnimation { to: 20; duration: 260; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -14; duration: 260; easing.type: Easing.InOutSine }
                }
            }

            Rectangle {
                width: 6; height: 14; x: 51; y: 46; radius: 3
                color: "#5D506F"; transformOrigin: Item.Top; rotation: 14
                SequentialAnimation on rotation {
                    loops: Animation.Infinite
                    NumberAnimation { to: -20; duration: 260; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 14; duration: 260; easing.type: Easing.InOutSine }
                }
            }

            Rectangle { width: 4; height: 4; x: 19; y: 28; radius: 2; color: "#D9A66A" }
            Rectangle { width: 3; height: 3; x: 76; y: 39; radius: 1.5; color: "#D98D80" }
            Rectangle { width: 2; height: 2; x: 26; y: 49; radius: 1; color: "#A992CF" }
        }
    }

}
