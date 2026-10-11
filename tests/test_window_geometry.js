const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");

const path = require("node:path").join(
    __dirname, "..", "quickshell", "a16een", "ui", "WindowGeometry.js"
);
const source = fs.readFileSync(path, "utf8").replace(/^\.pragma library\s*/, "");
const sandbox = {};
vm.runInNewContext(source, sandbox, { filename: path });

const windows = [
    {
        id: 11, title: "Firefox", app_id: "firefox", workspace_id: 7,
        is_floating: false,
        layout: { tile_pos_in_workspace_view: [20, 30], tile_size: [600, 700] }
    },
    {
        id: 12, title: "Terminal", app_id: "foot", workspace_id: 7,
        is_floating: true,
        layout: { tile_pos_in_workspace_view: [650, 120], tile_size: [460, 400] }
    },
    {
        id: 13, title: "Other workspace", workspace_id: 8,
        layout: { tile_pos_in_workspace_view: [0, 0], tile_size: [500, 500] }
    },
    {
        id: 14, title: "No position", workspace_id: 7,
        layout: { tile_pos_in_workspace_view: null, tile_size: [200, 200] }
    },
    {
        id: 15, title: "Off screen", workspace_id: 7,
        layout: { tile_pos_in_workspace_view: [1200, 0], tile_size: [200, 200] }
    }
];
const workspaces = [
    { id: 7, is_focused: true, is_active: true },
    { id: 8, is_focused: false, is_active: false }
];

const result = sandbox.buildCandidates(1200, 800, windows, workspaces, 7, 11);
const simple = result.map(item => ({
    id: item.id,
    title: item.title,
    rect: item.rect,
    floating: item.floating,
    focused: item.focused
}));
assert.deepEqual(JSON.parse(JSON.stringify(simple)), [
    {
        id: 11, title: "Firefox",
        rect: { x: 20, y: 30, width: 600, height: 700 },
        floating: false, focused: true
    },
    {
        id: 12, title: "Terminal",
        rect: { x: 650, y: 120, width: 460, height: 400 },
        floating: true, focused: false
    }
]);
assert.deepEqual(
    JSON.parse(JSON.stringify(sandbox.buildCandidates(1200, 800, windows, [], 7, 11))),
    []
);

console.log("Screenshot window geometry tests passed.");
