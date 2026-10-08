    signal navbarPositionChanged(string position)

    // The expanded command-center card becomes a light card for navbar mode.
    // The card itself is bounded; this does not create a screen-wide cover.
    readonly property color surface: root.widgetViewOpen || root.controlViewOpen || root.iconThemeViewOpen || root.workspacePresetViewOpen || root.navbarViewOpen ? "#FFFFFF" : "#000000"
    readonly property color borderColor: "#1A1A1A"
    readonly property color fieldBackground: "#0A0A0A"
    readonly property color fieldBorder: "#1C1C1C"
    readonly property color fieldFocusBorder: "#333333"
    readonly property color primaryText: "#FFFFFF"
    readonly property color secondaryText: "#6F6F6F"