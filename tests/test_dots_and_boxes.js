#!/usr/bin/env node
"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const root = path.resolve(__dirname, "..");
const sourcePath = path.join(root, "quickshell/a16een/ui/DotsAndBoxes.js");
const source = fs.readFileSync(sourcePath, "utf8").replace(/^\.pragma library\s*/, "");
const context = {};
vm.runInNewContext(
    source + "\nthis.api = { emptyHorizontal, emptyVertical, emptyOwners, sideCount, countThreats, applyMove, legalMoves, bestMove, casualMove };",
    context
);
const game = context.api;
const h = () => game.emptyHorizontal();
const v = () => game.emptyVertical();
const owners = () => game.emptyOwners();

assert.equal(h().length, 6, "3x3 dots need six horizontal lines");
assert.equal(v().length, 6, "3x3 dots need six vertical lines");
assert.equal(owners().length, 4, "3x3 dots enclose four boxes");

const opening = game.applyMove(h(), v(), owners(), [0, 0], "h", 0, "X");
assert.equal(opening.turn, "O", "a line that closes no box hands over the turn");
assert.deepEqual(Array.from(opening.claimed), []);
assert.equal(opening.gameOver, false);
assert.equal(game.applyMove(opening.horizontal, opening.vertical, opening.owners, opening.scores, "h", 0, "O"), null,
    "a line cannot be drawn twice");

const almostBoxH = ["X", "", "X", "", "", ""];
const almostBoxV = ["X", "", "", "", "", ""];
const single = game.applyMove(almostBoxH, almostBoxV, owners(), [0, 0], "v", 1, "X");
assert.deepEqual(Array.from(single.claimed), [0]);
assert.equal(single.owners[0], "X");
assert.deepEqual(Array.from(single.scores), [1, 0]);
assert.equal(single.turn, "X", "closing a box earns another move");

const twoBoxesH = ["X", "X", "X", "X", "", ""];
const twoBoxesV = ["O", "", "O", "", "", ""];
const double = game.applyMove(twoBoxesH, twoBoxesV, owners(), [0, 0], "v", 1, "O");
assert.deepEqual(Array.from(double.claimed), [0, 1]);
assert.deepEqual(Array.from(double.scores), [0, 2], "one line can claim two boxes");
assert.equal(double.turn, "O", "a double box still earns just one extra turn");

const endH = ["X", "O", "X", "O", "X", "O"];
const endV = ["X", "O", "O", "X", "O", ""];
const endOwners = ["X", "O", "O", ""];
const finished = game.applyMove(endH, endV, endOwners, [1, 2], "v", 5, "O");
assert.equal(finished.gameOver, true);
assert.deepEqual(Array.from(finished.scores), [1, 3]);
assert.equal(finished.winner, "O");

const tacticalH = ["X", "", "X", "", "", ""];
const tacticalV = ["X", "", "", "", "", ""];
const tacticalOwners = owners();
const best = game.bestMove(tacticalH, tacticalV, tacticalOwners, "O");
assert.deepEqual({ orientation: best.orientation, index: best.index }, { orientation: "v", index: 1 },
    "the smart bot should take an available box");
const blunder = game.casualMove(tacticalH, tacticalV, tacticalOwners, "O", 0.99, 0);
assert.ok(blunder.orientation !== "v" || blunder.index !== 1,
    "a high mistake roll may pass up an available box");
assert.ok(game.legalMoves(tacticalH, tacticalV).some(
    move => move.orientation === blunder.orientation && move.index === blunder.index
), "bot blunders must still be legal");

const panel = fs.readFileSync(path.join(root, "quickshell/a16een/ui/GamingPanel.qml"), "utf8");
assert.ok(panel.includes('DotsAndBoxes.applyMove('));
assert.ok(panel.includes('root.applyDotsMove(move.orientation, move.index, "O")'));
assert.ok(panel.includes('root.dotsStatusText'));
assert.ok(panel.includes('Accessible.name: "Dots and Boxes"'));

console.log("Dots and Boxes game logic and UI tests passed.");
