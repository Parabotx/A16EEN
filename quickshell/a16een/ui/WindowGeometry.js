.pragma library

// Niri exposes exact workspace-view geometry for floating windows, but some
// versions leave tile_pos_in_workspace_view unset for tiled windows. For
// those, reconstruct positions from the column/tile indices and tile sizes.
function buildCandidates(screenWidth, screenHeight, windowItems, workspaceItems,
                         focusedWorkspaceId, focusedWindowId) {
    screenWidth = Math.max(1, Number(screenWidth) || 1);
    screenHeight = Math.max(1, Number(screenHeight) || 1);
    var gap = 12;
    var workspaces = Array.isArray(workspaceItems) ? workspaceItems : [];
    var windows = Array.isArray(windowItems) ? windowItems : [];
    var workspace = null;
    var i, j;

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

    var current = [];
    for (i = 0; i < windows.length; i++) {
        var win = windows[i];
        if (Number(win.workspace_id) !== Number(workspace.id)
                || !win.layout || !Array.isArray(win.layout.tile_size)
                || win.layout.tile_size.length < 2) continue;
        current.push(win);
    }

    var candidates = [];
    var columnsByIndex = {};
    for (i = 0; i < current.length; i++) {
        var item = current[i];
        var layout = item.layout;
        var size = layout.tile_size;
        var width = Number(size[0]);
        var height = Number(size[1]);
        if (!isFinite(width) || !isFinite(height) || width <= 0 || height <= 0) continue;

        var position = layout.tile_pos_in_workspace_view;
        if (Array.isArray(position) && position.length >= 2
                && isFinite(Number(position[0])) && isFinite(Number(position[1]))) {
            candidates.push({
                id: Number(item.id),
                title: String(item.title || item.app_id || "Window"),
                rect: {
                    x: Number(position[0]), y: Number(position[1]),
                    width: width, height: height
                },
                floating: item.is_floating === true,
                focused: Number(item.id) === Number(focusedWindowId),
                order: item.is_floating === true ? 100000 + i : i
            });
            continue;
        }

        // Tiled windows commonly have no tile_pos_in_workspace_view. Use
        // their scrolling-layout coordinates to build per-column geometry.
        var scrollingPos = layout.pos_in_scrolling_layout;
        if (item.is_floating === true || !Array.isArray(scrollingPos)
                || scrollingPos.length < 2) continue;
        var columnIndex = Number(scrollingPos[0]);
        var tileIndex = Number(scrollingPos[1]);
        if (!isFinite(columnIndex) || !isFinite(tileIndex)) continue;
        var key = String(columnIndex);
        if (!columnsByIndex[key]) {
            columnsByIndex[key] = {
                index: columnIndex,
                width: width,
                windows: []
            };
        }
        columnsByIndex[key].width = Math.max(columnsByIndex[key].width, width);
        columnsByIndex[key].windows.push({
            item: item,
            tileIndex: tileIndex,
            width: width,
            height: height,
            order: i
        });
    }

    var columns = [];
    for (var colKey in columnsByIndex) {
        if (Object.prototype.hasOwnProperty.call(columnsByIndex, colKey))
            columns.push(columnsByIndex[colKey]);
    }
    columns.sort(function(a, b) { return a.index - b.index; });

    if (columns.length) {
        var contentWidth = 0;
        for (i = 0; i < columns.length; i++)
            contentWidth += columns[i].width + (i ? gap : 0);

        var focusedColumn = columns[0].index;
        var focusedWidth = columns[0].width;
        for (i = 0; i < current.length; i++) {
            if (Number(current[i].id) !== Number(focusedWindowId)
                    || !current[i].layout
                    || !Array.isArray(current[i].layout.pos_in_scrolling_layout)) continue;
            focusedColumn = Number(current[i].layout.pos_in_scrolling_layout[0]);
            break;
        }

        var focusedOffset = 0;
        for (i = 0; i < columns.length; i++) {
            if (columns[i].index === focusedColumn) {
                focusedWidth = columns[i].width;
                break;
            }
            focusedOffset += columns[i].width + gap;
        }

        // A16EEN uses center-focused-column "on-overflow".
        var x = gap;
        if (contentWidth > screenWidth - gap * 2)
            x = screenWidth / 2 - focusedOffset - focusedWidth / 2;

        for (i = 0; i < columns.length; i++) {
            var column = columns[i];
            var ordered = column.windows;
            ordered.sort(function(a, b) { return a.tileIndex - b.tileIndex; });
            var contentHeight = 0;
            for (j = 0; j < ordered.length; j++)
                contentHeight += ordered[j].height + (j ? gap : 0);
            var y = contentHeight < screenHeight - gap * 2
                ? (screenHeight - contentHeight) / 2 : gap;

            for (j = 0; j < ordered.length; j++) {
                var entry = ordered[j];
                candidates.push({
                    id: Number(entry.item.id),
                    title: String(entry.item.title || entry.item.app_id || "Window"),
                    rect: { x: x, y: y, width: entry.width, height: entry.height },
                    floating: false,
                    focused: Number(entry.item.id) === Number(focusedWindowId),
                    order: entry.order
                });
                y += entry.height + gap;
            }
            x += column.width + gap;
        }
    }

    return candidates.filter(function(item) {
        var rect = item.rect;
        return isFinite(item.id) && rect.width > 0 && rect.height > 0
            && rect.x < screenWidth && rect.y < screenHeight
            && rect.x + rect.width > 0 && rect.y + rect.height > 0;
    }).sort(function(a, b) { return a.order - b.order; });
}
