.pragma library

var ROWS = 6
var COLUMNS = 7
var CONNECT = 4
var CENTER_ORDER = [3, 2, 4, 1, 5, 0, 6]

function emptyBoard() {
    var board = []
    for (var i = 0; i < ROWS * COLUMNS; i++)
        board.push("")
    return board
}

function isFull(board) {
    for (var column = 0; column < COLUMNS; column++) {
        if (!board[column])
            return false
    }
    return true
}

function legalMoves(board) {
    var moves = []
    for (var i = 0; i < CENTER_ORDER.length; i++) {
        var column = CENTER_ORDER[i]
        if (board[column] === "")
            moves.push(column)
    }
    return moves
}

function drop(board, column, player) {
    if (!board || board.length !== ROWS * COLUMNS
        || (player !== "X" && player !== "O")
        || typeof column !== "number" || column % 1 !== 0
        || column < 0 || column >= COLUMNS || board[column] !== "")
        return null

    var next = board.slice(0)
    for (var row = ROWS - 1; row >= 0; row--) {
        var index = row * COLUMNS + column
        if (next[index] !== "")
            continue
        next[index] = player
        return { board: next, row: row, column: column }
    }
    return null
}

function winner(board) {
    if (!board || board.length !== ROWS * COLUMNS)
        return ""
    for (var row = 0; row < ROWS; row++) {
        for (var column = 0; column < COLUMNS; column++) {
            var player = board[row * COLUMNS + column]
            if (!player)
                continue
            if (column + 3 < COLUMNS
                && board[row * COLUMNS + column + 1] === player
                && board[row * COLUMNS + column + 2] === player
                && board[row * COLUMNS + column + 3] === player)
                return player
            if (row + 3 < ROWS
                && board[(row + 1) * COLUMNS + column] === player
                && board[(row + 2) * COLUMNS + column] === player
                && board[(row + 3) * COLUMNS + column] === player)
                return player
            if (row + 3 < ROWS && column + 3 < COLUMNS
                && board[(row + 1) * COLUMNS + column + 1] === player
                && board[(row + 2) * COLUMNS + column + 2] === player
                && board[(row + 3) * COLUMNS + column + 3] === player)
                return player
            if (row - 3 >= 0 && column + 3 < COLUMNS
                && board[(row - 1) * COLUMNS + column + 1] === player
                && board[(row - 2) * COLUMNS + column + 2] === player
                && board[(row - 3) * COLUMNS + column + 3] === player)
                return player
        }
    }
    return ""
}

function countInWindow(board, cells, player) {
    var count = 0
    for (var i = 0; i < cells.length; i++) {
        if (board[cells[i]] === player)
            count++
    }
    return count
}

function evaluateWindow(board, cells, botMark, humanMark) {
    var bot = countInWindow(board, cells, botMark)
    var human = countInWindow(board, cells, humanMark)
    var empty = CONNECT - bot - human
    if (bot > 0 && human > 0)
        return 0
    if (bot === 4)
        return 100000
    if (human === 4)
        return -100000
    if (bot === 3 && empty === 1)
        return 70
    if (bot === 2 && empty === 2)
        return 9
    if (bot === 1 && empty === 3)
        return 1
    if (human === 3 && empty === 1)
        return -85
    if (human === 2 && empty === 2)
        return -10
    if (human === 1 && empty === 3)
        return -1
    return 0
}

function evaluatePosition(board, botMark, humanMark) {
    var score = 0
    for (var row = 0; row < ROWS; row++) {
        var center = board[row * COLUMNS + 3]
        if (center === botMark)
            score += 4
        else if (center === humanMark)
            score -= 4
    }

    for (var r = 0; r < ROWS; r++) {
        for (var c = 0; c < COLUMNS; c++) {
            var horizontal = []
            var vertical = []
            var diagonalDown = []
            var diagonalUp = []
            if (c + 3 < COLUMNS) {
                for (var h = 0; h < CONNECT; h++)
                    horizontal.push(r * COLUMNS + c + h)
                score += evaluateWindow(board, horizontal, botMark, humanMark)
            }
            if (r + 3 < ROWS) {
                for (var v = 0; v < CONNECT; v++)
                    vertical.push((r + v) * COLUMNS + c)
                score += evaluateWindow(board, vertical, botMark, humanMark)
            }
            if (r + 3 < ROWS && c + 3 < COLUMNS) {
                for (var d = 0; d < CONNECT; d++)
                    diagonalDown.push((r + d) * COLUMNS + c + d)
                score += evaluateWindow(board, diagonalDown, botMark, humanMark)
            }
            if (r - 3 >= 0 && c + 3 < COLUMNS) {
                for (var u = 0; u < CONNECT; u++)
                    diagonalUp.push((r - u) * COLUMNS + c + u)
                score += evaluateWindow(board, diagonalUp, botMark, humanMark)
            }
        }
    }
    return score
}

function minimax(board, depth, alpha, beta, maximizing, botMark, humanMark) {
    var result = winner(board)
    if (result === botMark)
        return 100000 + depth
    if (result === humanMark)
        return -100000 - depth
    if (isFull(board) || depth <= 0)
        return evaluatePosition(board, botMark, humanMark)

    var moves = legalMoves(board)
    if (maximizing) {
        var best = -Infinity
        for (var i = 0; i < moves.length; i++) {
            var move = drop(board, moves[i], botMark)
            var value = minimax(move.board, depth - 1, alpha, beta, false, botMark, humanMark)
            if (value > best)
                best = value
            if (best > alpha)
                alpha = best
            if (beta <= alpha)
                break
        }
        return best
    }

    var worst = Infinity
    for (var j = 0; j < moves.length; j++) {
        var response = drop(board, moves[j], humanMark)
        var responseValue = minimax(response.board, depth - 1, alpha, beta, true, botMark, humanMark)
        if (responseValue < worst)
            worst = responseValue
        if (worst < beta)
            beta = worst
        if (beta <= alpha)
            break
    }
    return worst
}

function bestMove(board, botMark, humanMark, depth) {
    var bot = botMark || "O"
    var human = humanMark || "X"
    var searchDepth = typeof depth === "number" ? Math.max(1, Math.floor(depth)) : 4
    var moves = legalMoves(board)
    if (moves.length === 0)
        return -1

    // Never miss a one-move win.
    for (var i = 0; i < moves.length; i++) {
        var winningDrop = drop(board, moves[i], bot)
        if (winner(winningDrop.board) === bot)
            return moves[i]
    }
    // Block a visible immediate win before evaluating longer plans.
    for (var j = 0; j < moves.length; j++) {
        var humanDrop = drop(board, moves[j], human)
        if (winner(humanDrop.board) === human)
            return moves[j]
    }

    var bestColumn = moves[0]
    var bestScore = -Infinity
    for (var k = 0; k < moves.length; k++) {
        var candidate = drop(board, moves[k], bot)
        var score = minimax(candidate.board, searchDepth - 1, -Infinity, Infinity, false, bot, human)
        if (score > bestScore) {
            bestScore = score
            bestColumn = moves[k]
        }
    }
    return bestColumn
}
