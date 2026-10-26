import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    required property string currentWallpaperPath
    required property bool desktopAnimationAllowed
    property string previewWallpaperPath: ""
    property bool editorialTimeWidgetEnabled: true
    property bool timeUse24Hour: true
    property bool timeShowSeconds: false

    readonly property string fallbackPath: Qt.resolvedUrl("../assets/wallpapers/default.png")
    readonly property string activePath: root.previewWallpaperPath.length
        ? root.previewWallpaperPath
        : (root.currentWallpaperPath.length
            ? root.currentWallpaperPath
            : root.fallbackPath)
    readonly property string lowerPath: root.activePath.toLowerCase()
    readonly property bool isAnimatedImage: lowerPath.endsWith(".gif")
        || lowerPath.endsWith(".webp")
    readonly property bool isVideo: lowerPath.endsWith(".mp4")
        || lowerPath.endsWith(".webm")
        || lowerPath.endsWith(".mov")
        || lowerPath.endsWith(".m4v")
        || lowerPath.endsWith(".mkv")

    screen: modelData
    color: "#050608"
    aboveWindows: false
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "a16een-wallpaper"

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    Rectangle {
        anchors.fill: parent
        color: "#050608"
    }

    // Double-buffer the wallpaper: load the next file behind the current one,
    // then fade the outgoing layer only after the incoming layer is ready.
    property bool wallpaperLayersReady: false
    property bool frontIsA: true
    property string displayedWallpaperPath: ""
    property string pendingWallpaperPath: ""
    property string transitionWallpaperPath: ""

    WallpaperTransitionLayer {
        id: wallpaperLayerA
        anchors.fill: parent
        z: 2
        opacity: 1
        desktopAnimationAllowed: false
    }

    WallpaperTransitionLayer {
        id: wallpaperLayerB
        anchors.fill: parent
        z: 1
        opacity: 1
        desktopAnimationAllowed: false
    }

    function currentWallpaperLayer() {
        return root.frontIsA ? wallpaperLayerA : wallpaperLayerB
    }

    function stagingWallpaperLayer() {
        return root.frontIsA ? wallpaperLayerB : wallpaperLayerA
    }

    function requestWallpaperTransition(path) {
        const desiredPath = path && path.length ? path : root.fallbackPath
        if (!root.wallpaperLayersReady) {
            root.initialWallpaperPath = desiredPath
            return
        }

        root.pendingWallpaperPath = desiredPath
        if (transitionFade.running)
            return

        if (desiredPath === root.displayedWallpaperPath) {
            const staging = root.stagingWallpaperLayer()
            staging.desktopAnimationAllowed = false
            staging.sourcePath = ""
            return
        }

        root.prepareIncomingWallpaper()
    }

    property string initialWallpaperPath: ""

    function prepareIncomingWallpaper() {
        if (!root.wallpaperLayersReady || transitionFade.running
                || !root.pendingWallpaperPath.length
                || root.pendingWallpaperPath === root.displayedWallpaperPath)
            return

        const incoming = root.stagingWallpaperLayer()
        if (incoming.sourcePath !== root.pendingWallpaperPath) {
            // Decode the staged wallpaper without running its animation or
            // video until it is about to become visible.
            incoming.desktopAnimationAllowed = false
            incoming.sourcePath = root.pendingWallpaperPath
        }
        Qt.callLater(root.tryBeginWallpaperTransition)
    }

    function tryBeginWallpaperTransition() {
        if (!root.wallpaperLayersReady || transitionFade.running
                || !root.pendingWallpaperPath.length
                || root.pendingWallpaperPath === root.displayedWallpaperPath)
            return

        const incoming = root.stagingWallpaperLayer()
        if (incoming.sourcePath !== root.pendingWallpaperPath) {
            root.prepareIncomingWallpaper()
            return
        }
        if (!incoming.contentReady)
            return

        root.transitionWallpaperPath = root.pendingWallpaperPath
        const outgoing = root.currentWallpaperLayer()
        outgoing.desktopAnimationAllowed = false
        incoming.desktopAnimationAllowed = root.desktopAnimationAllowed
        // Keep the current wallpaper above the staged image until the new
        // image/video is genuinely ready; fading this layer reveals it smoothly.
        outgoing.z = 2
        incoming.z = 1
        transitionFade.target = outgoing
        transitionFade.from = 1
        transitionFade.to = 0
        transitionFade.start()
    }

    function finishWallpaperTransition() {
        if (!root.transitionWallpaperPath.length)
            return

        root.displayedWallpaperPath = root.transitionWallpaperPath
        root.frontIsA = !root.frontIsA

        const incoming = root.currentWallpaperLayer()
        const outgoing = root.stagingWallpaperLayer()
        incoming.opacity = 1
        incoming.z = 2
        incoming.desktopAnimationAllowed = root.desktopAnimationAllowed

        // Unload the previous full-resolution image/video immediately after
        // the fade. Thumbnail resources are separately released when the
        // picker closes, keeping only the current desktop wallpaper resident.
        outgoing.desktopAnimationAllowed = false
        outgoing.sourcePath = ""
        outgoing.opacity = 1
        outgoing.z = 1
        root.transitionWallpaperPath = ""

        if (root.pendingWallpaperPath === root.displayedWallpaperPath) {
            root.pendingWallpaperPath = ""
        } else if (root.pendingWallpaperPath.length) {
            Qt.callLater(root.prepareIncomingWallpaper)
        }
    }

    Connections {
        target: wallpaperLayerA
        function onContentReadyChanged() {
            root.tryBeginWallpaperTransition()
        }
    }

    Connections {
        target: wallpaperLayerB
        function onContentReadyChanged() {
            root.tryBeginWallpaperTransition()
        }
    }

    onActivePathChanged: root.requestWallpaperTransition(root.activePath)

    onDesktopAnimationAllowedChanged: {
        if (!transitionFade.running)
            root.currentWallpaperLayer().desktopAnimationAllowed = root.desktopAnimationAllowed
    }

    NumberAnimation {
        id: transitionFade
        target: null
        property: "opacity"
        duration: 190
        easing.type: Easing.InOutCubic
        onFinished: root.finishWallpaperTransition()
    }

    Component.onCompleted: {
        const initial = root.initialWallpaperPath.length
            ? root.initialWallpaperPath : root.activePath
        wallpaperLayerA.sourcePath = initial
        wallpaperLayerA.desktopAnimationAllowed = root.desktopAnimationAllowed
        wallpaperLayerA.z = 2
        wallpaperLayerA.opacity = 1
        wallpaperLayerB.sourcePath = ""
        wallpaperLayerB.desktopAnimationAllowed = false
        wallpaperLayerB.z = 1
        wallpaperLayerB.opacity = 1
        root.displayedWallpaperPath = initial
        root.wallpaperLayersReady = true
        if (root.activePath !== initial)
            root.requestWallpaperTransition(root.activePath)
    }

    Rectangle {
        anchors.fill: parent
        color: "#050608"
        opacity: 0.22
        z: 3
    }

    EditorialTimeWidget {
        anchors.fill: parent
        widgetEnabled: root.editorialTimeWidgetEnabled
        use24Hour: root.timeUse24Hour
        showSeconds: root.timeShowSeconds
    }
}
