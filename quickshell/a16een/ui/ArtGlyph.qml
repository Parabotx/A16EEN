import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property string glyph: "home"
    property bool active: false
    property bool hovered: false
    property color baseColor: "#17191D"
    property color accentColor: "#3B82F6"

    implicitWidth: 19
    implicitHeight: 19

    readonly property color ink: root.active || root.hovered ? root.accentColor : root.baseColor

    scale: root.hovered ? 1.08 : (root.active ? 1.03 : 1)

    Behavior on scale {
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutCubic
        }
    }

    // Search / launcher: a hand-drawn lens with a small four-point spark.
    Shape {
        anchors.fill: parent
        visible: root.glyph === "search"
        antialiasing: true

        ShapePath {
            strokeColor: root.ink
            strokeWidth: 1.8
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 4.6
            startY: 4.2
            PathCubic { control1X: 2.2; control1Y: 6.5; control2X: 2.5; control2Y: 10.1; endX: 5.1; endY: 12.1 }
            PathCubic { control1X: 7.7; control1Y: 14.1; control2X: 11.5; control2Y: 13.1; endX: 13.1; endY: 10.7 }
            PathCubic { control1X: 14.8; control1Y: 8.2; control2X: 14.3; control2Y: 5.5; endX: 12.1; endY: 3.7 }
            PathCubic { control1X: 9.8; control1Y: 1.8; control2X: 6.9; control2Y: 2.1; endX: 4.6; endY: 4.2 }
            PathMove { x: 12.3; y: 12.1 }
            PathLine { x: 16.8; y: 16.6 }
        }

        ShapePath {
            strokeColor: root.active ? root.accentColor : "transparent"
            strokeWidth: 1.2
            fillColor: root.active ? root.accentColor : "transparent"
            capStyle: ShapePath.RoundCap
            startX: 9.3
            startY: 5.7
            PathLine { x: 10.1; y: 7.1 }
            PathLine { x: 11.7; y: 7.9 }
            PathLine { x: 10.1; y: 8.7 }
            PathLine { x: 9.3; y: 10.1 }
            PathLine { x: 8.5; y: 8.7 }
            PathLine { x: 6.9; y: 7.9 }
            PathLine { x: 8.5; y: 7.1 }
            PathLine { x: 9.3; y: 5.7 }
        }
    }

    // Home: an architectural arch instead of the stock house glyph.
    Shape {
        anchors.fill: parent
        visible: root.glyph === "home"
        antialiasing: true

        ShapePath {
            strokeColor: root.ink
            strokeWidth: 1.75
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 3.1
            startY: 9.1
            PathLine { x: 9.5; y: 3.0 }
            PathLine { x: 15.9; y: 9.1 }
            PathMove { x: 5.0; y: 7.6 }
            PathLine { x: 5.0; y: 15.7 }
            PathLine { x: 14.0; y: 15.7 }
            PathLine { x: 14.0; y: 7.6 }
        }

        ShapePath {
            strokeColor: root.active ? root.accentColor : root.ink
            strokeWidth: 1.45
            fillColor: root.active ? root.accentColor : "transparent"
            capStyle: ShapePath.RoundCap
            startX: 7.4
            startY: 15.4
            PathLine { x: 7.4; y: 11.3 }
            PathQuad { x: 9.5; y: 9.6; controlX: 7.4; controlY: 10.0 }
            PathQuad { x: 11.6; y: 11.3; controlX: 11.6; controlY: 10.0 }
            PathLine { x: 11.6; y: 15.4 }
        }
    }

    // Code: two flowing ribbons with a small diamond in the center.
    Shape {
        anchors.fill: parent
        visible: root.glyph === "code"
        antialiasing: true

        ShapePath {
            strokeColor: root.ink
            strokeWidth: 1.75
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 7.0
            startY: 3.8
            PathQuad { x: 3.3; y: 9.5; controlX: 4.0; controlY: 6.0 }
            PathQuad { x: 7.0; y: 15.2; controlX: 4.0; controlY: 12.9 }
            PathMove { x: 12.0; y: 3.8 }
            PathQuad { x: 15.7; y: 9.5; controlX: 15.0; controlY: 6.0 }
            PathQuad { x: 12.0; y: 15.2; controlX: 15.0; controlY: 12.9 }
        }

        ShapePath {
            strokeColor: root.active ? root.accentColor : root.ink
            strokeWidth: 1.45
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 8.2
            startY: 9.5
            PathLine { x: 9.5; y: 8.2 }
            PathLine { x: 10.8; y: 9.5 }
            PathLine { x: 9.5; y: 10.8 }
            PathLine { x: 8.2; y: 9.5 }
            PathLine { x: 8.2; y: 9.5 }
        }
    }

    // Web: an orbit and globe axis, intentionally softer than a stock globe icon.
    Shape {
        anchors.fill: parent
        visible: root.glyph === "web"
        antialiasing: true

        ShapePath {
            strokeColor: root.ink
            strokeWidth: 1.65
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 2.5
            startY: 9.5
            PathCubic { control1X: 4.3; control1Y: 4.7; control2X: 14.7; control2Y: 4.7; endX: 16.5; endY: 9.5 }
            PathCubic { control1X: 14.7; control1Y: 14.3; control2X: 4.3; control2Y: 14.3; endX: 2.5; endY: 9.5 }
        }

        ShapePath {
            strokeColor: root.active ? root.accentColor : root.ink
            strokeWidth: 1.3
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 9.5
            startY: 2.7
            PathCubic { control1X: 6.6; control1Y: 5.1; control2X: 6.6; control2Y: 13.9; endX: 9.5; endY: 16.3 }
            PathCubic { control1X: 12.4; control1Y: 13.9; control2X: 12.4; control2Y: 5.1; endX: 9.5; endY: 2.7 }
            PathMove { x: 3.0; y: 9.5 }
            PathLine { x: 16.0; y: 9.5 }
        }
    }

    // Comms: a single speech ribbon with three tiny signal points.
    Shape {
        anchors.fill: parent
        visible: root.glyph === "comms"
        antialiasing: true

        ShapePath {
            strokeColor: root.ink
            strokeWidth: 1.7
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 4.0
            startY: 5.1
            PathQuad { x: 4.0; y: 12.4; controlX: 2.4; controlY: 8.4 }
            PathLine { x: 6.2; y: 12.4 }
            PathLine { x: 8.0; y: 15.3 }
            PathLine { x: 8.0; y: 12.4 }
            PathQuad { x: 15.0; y: 12.4; controlX: 15.0; controlY: 14.6 }
            PathQuad { x: 15.0; y: 5.1; controlX: 15.0; controlY: 2.6 }
            PathQuad { x: 8.8; y: 5.1; controlX: 12.5; controlY: 2.6 }
            PathLine { x: 5.9; y: 5.1 }
            PathQuad { x: 4.0; y: 5.1; controlX: 4.7; controlY: 5.1 }
        }

        ShapePath {
            strokeColor: root.active ? root.accentColor : root.ink
            strokeWidth: 1.35
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 6.3
            startY: 9.0
            PathLine { x: 6.5; y: 9.0 }
            PathMove { x: 8.8; y: 9.0 }
            PathLine { x: 9.0; y: 9.0 }
            PathMove { x: 11.3; y: 9.0 }
            PathLine { x: 11.5; y: 9.0 }
        }
    }

    // Studio: faceted star / compass mark.
    Shape {
        anchors.fill: parent
        visible: root.glyph === "studio"
        antialiasing: true

        ShapePath {
            strokeColor: root.ink
            strokeWidth: 1.55
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 9.5
            startY: 2.6
            PathLine { x: 11.3; y: 7.7 }
            PathLine { x: 16.4; y: 9.5 }
            PathLine { x: 11.3; y: 11.3 }
            PathLine { x: 9.5; y: 16.4 }
            PathLine { x: 7.7; y: 11.3 }
            PathLine { x: 2.6; y: 9.5 }
            PathLine { x: 7.7; y: 7.7 }
            PathLine { x: 9.5; y: 2.6 }
        }

        ShapePath {
            strokeColor: root.active ? root.accentColor : root.ink
            strokeWidth: 1.25
            fillColor: root.active ? root.accentColor : "transparent"
            capStyle: ShapePath.RoundCap
            startX: 9.5
            startY: 6.6
            PathLine { x: 10.3; y: 8.7 }
            PathLine { x: 12.4; y: 9.5 }
            PathLine { x: 10.3; y: 10.3 }
            PathLine { x: 9.5; y: 12.4 }
            PathLine { x: 8.7; y: 10.3 }
            PathLine { x: 6.6; y: 9.5 }
            PathLine { x: 8.7; y: 8.7 }
            PathLine { x: 9.5; y: 6.6 }
        }
    }

    // Music: an asymmetric note with a tiny floating accent.
    Shape {
        anchors.fill: parent
        visible: root.glyph === "music"
        antialiasing: true

        ShapePath {
            strokeColor: root.ink
            strokeWidth: 1.8
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 12.6
            startY: 3.0
            PathLine { x: 12.6; y: 11.5 }
            PathCubic { control1X: 11.5; control1Y: 13.2; control2X: 8.5; control2Y: 14.2; endX: 7.1; endY: 12.5 }
            PathCubic { control1X: 5.9; control1Y: 11.0; control2X: 6.7; control2Y: 9.5; endX: 8.2; endY: 9.1 }
            PathMove { x: 12.6; y: 3.0 }
            PathLine { x: 15.8; y: 4.5 }
        }

        ShapePath {
            strokeColor: root.active ? root.accentColor : root.ink
            strokeWidth: 1.25
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 4.1
            startY: 4.9
            PathLine { x: 4.1; y: 2.6 }
            PathLine { x: 6.5; y: 3.9 }
            PathMove { x: 4.1; y: 2.6 }
            PathLine { x: 5.5; y: 2.6 }
        }
    }
}
