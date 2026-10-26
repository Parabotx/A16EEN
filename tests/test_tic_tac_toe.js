#!/usr/bin/env node
"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const root = path.resolve(__dirname, "..");
const sourcePath = path.join(root, "quickshell/a16een/ui/TicTacToe.js");
const source = fs.readFileSync(sourcePath, "utf8").replace(/^\.pragma library\s*/, "");
const context = {};
vm.runInNewContext(source + "\nthis.api = { winner: winner, isFull: isFull, bestMove: bestMove };", context);
const game = context.api;

assert.equal(game.winner(["X", "X", "X", "O", "", "O", "", "", ""]), "X");
assert.equal(game.winner(["X", "", "O", "X", "O", "", "O", "", "X"]), "O");
assert.equal(game.winner(["X", "O", "X", "X", "O", "O", "O", "X", "X"]), "");
assert.equal(game.isFull(["X", "O", "X", "X", "O", "O", "O", "X", "X"]), true);
assert.equal(game.isFull(["X", "O", "", "", "", "", "", "", ""]), false);

// The bot takes a forced immediate win rather than a merely defensive move.
assert.equal(game.bestMove(["X", "", "X", "O", "O", "", "X", "", ""], "O", "X"), 5);
// The bot blocks a forced human win.
assert.equal(game.bestMove(["X", "X", "", "O", "", "", "", "", ""], "O", "X"), 2);
assert.equal(game.bestMove(["X", "O", "X", "X", "O", "O", "O", "X", "X"], "O", "X"), -1);

function optimalOutcome(board, botTurn) {
    const winner = game.winner(board);
    if (winner === "O") return 1;
    if (winner === "X") return -1;
    if (game.isFull(board)) return 0;

    const values = [];
    for (let i = 0; i < 9; i++) {
        if (board[i]) continue;
        board[i] = botTurn ? "O" : "X";
        values.push(optimalOutcome(board, !botTurn));
        board[i] = "";
    }
    return botTurn ? Math.max(...values) : Math.min(...values);
}

// Explore every human choice along the bot's actual minimax policy. No branch
// may produce a forced human win, regardless of the opening or response.
let checkedBotPositions = 0;
function verifyBotPolicy(board, turn) {
    if (game.winner(board) || game.isFull(board))
        return;

    if (turn === "X") {
        for (let i = 0; i < 9; i++) {
            if (board[i]) continue;
            board[i] = "X";
            verifyBotPolicy(board, "O");
            board[i] = "";
        }
        return;
    }

    const move = game.bestMove(board, "O", "X");
    assert.ok(move >= 0 && move < 9 && !board[move], "bot must choose an empty square");
    board[move] = "O";
    checkedBotPositions++;
    assert.ok(optimalOutcome(board, false) >= 0, "bot policy must never allow a forced human win");
    verifyBotPolicy(board, "X");
    board[move] = "";
}
verifyBotPolicy(["", "", "", "", "", "", "", "", ""], "X");
assert.ok(checkedBotPositions > 0);

const panel = fs.readFileSync(path.join(root, "quickshell/a16een/ui/GamingPanel.qml"), "utf8");
assert.ok(panel.includes('import "TicTacToe.js" as TicTacToe'));
assert.ok(panel.includes('TicTacToe.bestMove(root.board, "O", "X")'));
assert.ok(panel.includes('text: "X & O"'));
assert.ok(panel.includes('text: "GAMES"'));
assert.ok(!panel.includes("description:"));

console.log("Tic-Tac-Toe minimax and Gaming panel tests passed.");
