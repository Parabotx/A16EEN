.pragma library

// Estimate bounds from Niri window metadata. A16EEN uses 12px gaps and
// center-focused-column on-overflow in the default compositor layout.
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
                || win.layout.tile_size.length < 2
                || Number(win.layout.tile_size[0]) <= 0
                || Number(win.layout.tile_size[1]) <= 0) continue;
        current.push(win);
    }

    var candidates = [];
    var columnsByIndex = {};
    for (i = 0; i < current.length; i++) {
        var item = current[i];
        var layout = item.layout;
        var size = layout.tile_size;
        if (item.is_floating === true) {
            var floatingPos = layout.tile_pos_in_workspace_view;
            if (Array.isArray(floatingPos) && floatingPos.length >= 2) {
                candidates.push({
                    id: Number(item.id),
                    title: String(item.title || item.app_id || "Window"),
                    rect: {
                        x: Number(floatingPos[0]), y: Number(floatingPos[1]),
                        width: Number(size[0]), height: Number(size[1])
                    },
                    floating: true,
                    order: 100000 + i
                });
            }
            continue;
        }

        var pos = layout.pos_in_scrolling_layout;
        if (!Array.isArray(pos) || pos.length < 2) continue;
        var colIndex = Number(pos[0]);
        if (!isFinite(colIndex)) continue;
        var key = String(colIndex);
        if (!columnsByIndex[key]) {
            columnsByIndex[key] = {
                index: colIndex,
                width: Number(size[0]),
                windows: []
            };
        }
        columnsByIndex[key].width = Math.max(columnsByIndex[key].width, Number(size[0]));
        columnsByIndex[key].windows.push({
            item: item,
            tileIndex: Number(pos[1]),
            width: Number(size[0]),
            height: Number(size[1]),
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

        var focused = null;
        for (i = 0; i < current.length; i++) {
            if (Number(current[i].id) === Number(focusedWindowId)) {
                focused = current[i];
                break;
            }
        }
        var focusedPos = focused && focused.layout
            ? focused.layout.pos_in_scrolling_layout : null;
        var focusedColumn = Array.isArray(focusedPos)
            ? Number(focusedPos[0]) : columns[0].index;
        var focusedOffset = 0;
        var focusedWidth = columns[0].width;
        for (i = 0; i < columns.length; i++) {
            if (columns[i].index === focusedColumn) {
                focusedWidth = columns[i].width;
                break;
            }
            focusedOffset += columns[i].width + gap;
        }

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
