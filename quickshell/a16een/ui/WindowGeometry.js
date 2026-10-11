.pragma library

// Niri reports window tile positions and sizes in logical pixels relative to
// the visible workspace view. Using those values avoids guessing positions
// from scrolling-column indices and handles tiled/floating windows consistently.
function buildCandidates(screenWidth, screenHeight, windowItems, workspaceItems,
                         focusedWorkspaceId, focusedWindowId) {
    screenWidth = Math.max(1, Number(screenWidth) || 1);
    screenHeight = Math.max(1, Number(screenHeight) || 1);
    var workspaces = Array.isArray(workspaceItems) ? workspaceItems : [];
    var windows = Array.isArray(windowItems) ? windowItems : [];
    var workspace = null;
    var i;

    for (i = 0; i < workspaces.length; i++) {
        if (Number(workspaces[i].id) === Number(focusedWorkspaceId)) {
            workspace = workspaces[i];
            break;
        }
    }
    if (!workspace) {
        for (i = 0; i < workspaces.length; i++) {
            if (workspaces[i].is_focused === true || workspaces[i].is_active === true) {
                workspace = workspaces[i];
                break;
            }
        }
    }
    if (!workspace) return [];

    var candidates = [];
    for (i = 0; i < windows.length; i++) {
        var item = windows[i];
        var layout = item.layout;
        if (Number(item.workspace_id) !== Number(workspace.id)
                || !layout || !Array.isArray(layout.tile_size)
                || layout.tile_size.length < 2) continue;

        var position = layout.tile_pos_in_workspace_view;
        if (!Array.isArray(position) || position.length < 2) continue;
        var x = Number(position[0]);
        var y = Number(position[1]);
        var width = Number(layout.tile_size[0]);
        var height = Number(layout.tile_size[1]);
        if (!isFinite(x) || !isFinite(y) || width <= 0 || height <= 0) continue;

        var rect = { x: x, y: y, width: width, height: height };
        // The floating stack is above the tiled columns. If two floating
        // windows overlap, later entries are tested first.
        candidates.push({
            id: Number(item.id),
            title: String(item.title || item.app_id || "Window"),
            rect: rect,
            floating: item.is_floating === true,
            focused: Number(item.id) === Number(focusedWindowId),
            order: item.is_floating === true ? 100000 + i : i
        });
    }

    return candidates.filter(function(item) {
        var rect = item.rect;
        return isFinite(item.id) && rect.width > 0 && rect.height > 0
            && rect.x < screenWidth && rect.y < screenHeight
            && rect.x + rect.width > 0 && rect.y + rect.height > 0;
    }).sort(function(a, b) { return a.order - b.order; });
}
