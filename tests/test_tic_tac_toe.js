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
vm.runInNewContext(
    source + "\nthis.api = { winner: winner, isFull: isFull, bestMove: bestMove, casualMove: casualMove };",
    context
);
const game = context.api;

assert.equal(game.winner(["X", "X", "X", "O", "", "O", "", "", ""]), "X");
assert.equal(game.winner(["X", "", "O", "X", "O", "", "O", "", "X"]), "O");
assert.equal(game.winner(["X", "O", "X", "X", "O", "O", "O", "X", "X"]), "");
assert.equal(game.isFull(["X", "O", "X", "X", "O", "O", "O", "X", "X"]), true);
assert.equal(game.isFull(["X", "O", "", "", "", "", "", "", ""]), false);

assert.equal(game.bestMove(["X", "", "X", "O", "O", "", "X", "", ""], "O", "X"), 5);
assert.equal(game.bestMove(["X", "X", "", "O", "", "", "", "", ""], "O", "X"), 2);
assert.equal(game.bestMove(["X", "O", "X", "X", "O", "O", "O", "X", "X"], "O", "X"), -1);

// The minimax helper remains perfect for exhaustive correctness checks.
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
    assert.ok(move >= 0 && move < 9 && !board[move], "optimal bot chooses an empty square");
    board[move] = "O";
    checkedBotPositions++;
    assert.ok(optimalOutcome(board, false) >= 0, "minimax policy must never allow a forced human win");
    verifyBotPolicy(board, "X");
    board[move] = "";
}
verifyBotPolicy(["", "", "", "", "", "", "", "", ""], "X");
assert.ok(checkedBotPositions > 0);

const blunderBoard = ["X", "X", "", "O", "O", "", "X", "", ""];
assert.equal(game.bestMove(blunderBoard, "O", "X"), 5);
const imperfectMove = game.casualMove(blunderBoard, "O", "X", 0.99, 0);
assert.notEqual(imperfectMove, 5, "a deliberate weak roll must allow a blunder");
assert.ok(!blunderBoard[imperfectMove], "casual bot move must still be legal");

const panel = fs.readFileSync(path.join(root, "quickshell/a16een/ui/GamingPanel.qml"), "utf8");
assert.ok(panel.includes('import "TicTacToe.js" as TicTacToe'));
assert.ok(panel.includes('import "DotsAndBoxes.js" as DotsAndBoxes'));
assert.ok(panel.includes('TicTacToe.casualMove('));
assert.ok(panel.includes('DotsAndBoxes.casualMove('));
assert.ok(panel.includes('function showResult(gameId, title, subtitle, scoreText)'));
assert.ok(panel.includes('id: resultStage'));
assert.ok(panel.includes('text: "PLAY AGAIN"'));
assert.ok(panel.includes('useContainerColor: true'));
assert.ok(panel.includes('text: "X & O"'));
assert.ok(panel.includes('text: "Dots & Boxes"'));
assert.ok(panel.includes('root.showResult("xo", "I WON"'));
assert.ok(panel.includes('root.currentView === "dots"'));
assert.ok(!panel.includes("description:"));

console.log("Tic-Tac-Toe and Gaming panel tests passed.");
