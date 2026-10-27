#!/usr/bin/env node
"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const root = path.resolve(__dirname, "..");
const sourcePath = path.join(root, "quickshell/a16een/ui/ConnectFour.js");
const source = fs.readFileSync(sourcePath, "utf8").replace(/^\.pragma library\s*/, "");
const context = {};
vm.runInNewContext(
    source + "\nthis.api = { ROWS, COLUMNS, emptyBoard, isFull, legalMoves, drop, winner, bestMove };",
    context
);
const game = context.api;

assert.equal(game.ROWS, 6);
assert.equal(game.COLUMNS, 7);
assert.equal(game.emptyBoard().length, 42);
assert.equal(game.legalMoves(game.emptyBoard()).length, 7);

let board = game.emptyBoard();
const firstDrop = game.drop(board, 3, "X");
assert.ok(firstDrop);
assert.equal(firstDrop.row, 5, "tokens fall to the lowest available slot");
assert.equal(firstDrop.board[5 * 7 + 3], "X");
assert.equal(board[5 * 7 + 3], "", "moves return a fresh board");
assert.equal(game.drop(firstDrop.board, 3, "O").row, 4);

assert.equal(game.drop(board, -1, "X"), null);
assert.equal(game.drop(board, 7, "O"), null);
assert.equal(game.drop(board, 3, "Z"), null);

function playSequence(columns, startingPlayer) {
    let current = game.emptyBoard();
    let player = startingPlayer || "X";
    for (const column of columns) {
        const moved = game.drop(current, column, player);
        assert.ok(moved, "test sequence contains a legal move");
        current = moved.board;
        const won = game.winner(current);
        if (won) return { board: current, winner: won };
        player = player === "X" ? "O" : "X";
    }
    return { board: current, winner: game.winner(current) };
}

assert.equal(playSequence([0, 4, 1, 4, 2, 5, 3], "X").winner, "X",
    "horizontal four-in-a-row");
assert.equal(playSequence([0, 1, 0, 1, 0, 1, 0], "X").winner, "X",
    "vertical four-in-a-row");

const diagonal = game.emptyBoard();
// A gravity-valid position with X climbing diagonally from bottom-left to top-right.
diagonal[5 * 7 + 0] = "X";
diagonal[5 * 7 + 1] = "O";
diagonal[4 * 7 + 1] = "X";
diagonal[5 * 7 + 2] = "O";
diagonal[4 * 7 + 2] = "O";
diagonal[3 * 7 + 2] = "X";
diagonal[5 * 7 + 3] = "O";
diagonal[4 * 7 + 3] = "O";
diagonal[3 * 7 + 3] = "O";
diagonal[2 * 7 + 3] = "X";
assert.equal(game.winner(diagonal), "X", "diagonal four-in-a-row");

board = game.emptyBoard();
for (const col of [0, 1, 2])
    board = game.drop(board, col, "O").board;
assert.equal(game.bestMove(board, "O", "X"), 3, "bot takes a winning fourth token");

board = game.emptyBoard();
for (const col of [0, 1, 2])
    board = game.drop(board, col, "X").board;
assert.equal(game.bestMove(board, "O", "X"), 3, "bot blocks the player's immediate win");

const filled = [];
for (let row = 0; row < game.ROWS; row++) {
    for (let col = 0; col < game.COLUMNS; col++)
        filled.push((col + Math.floor(row / 2)) % 2 === 0 ? "X" : "O");
}
assert.equal(game.isFull(filled), true);
assert.equal(game.legalMoves(filled).length, 0);
assert.equal(game.bestMove(filled, "O", "X"), -1);
assert.equal(game.winner(filled), "", "full non-winning board should be a draw");

const panel = fs.readFileSync(path.join(root, "quickshell/a16een/ui/GamingPanel.qml"), "utf8");
assert.ok(panel.includes('import "ConnectFour.js" as ConnectFour'));
assert.ok(panel.includes("function startConnectFour()"));
assert.ok(panel.includes("root.playConnectFourColumn(index % ConnectFour.COLUMNS)"));
assert.ok(panel.includes('Accessible.name: "Connect Four"'));
assert.ok(panel.includes('root.showResult("connect4", "I WON"'));

console.log("Connect Four logic and UI tests passed.");
