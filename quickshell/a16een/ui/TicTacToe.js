.pragma library

var winningLines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6]
]

// Returns "X", "O", or an empty string when the board has no winner.
function winner(board) {
    for (var i = 0; i < winningLines.length; i++) {
        var line = winningLines[i]
        var mark = board[line[0]]
        if (mark && mark === board[line[1]] && mark === board[line[2]])
            return mark
    }
    return ""
}

function isFull(board) {
    for (var i = 0; i < 9; i++) {
        if (!board[i])
            return false
    }
    return true
}

function minimax(board, botMark, humanMark, botTurn, depth) {
    var result = winner(board)
    if (result === botMark)
        return 10 - depth
    if (result === humanMark)
        return depth - 10
    if (isFull(board))
        return 0

    var bestScore = botTurn ? -Infinity : Infinity
    for (var i = 0; i < 9; i++) {
        if (board[i])
            continue
        board[i] = botTurn ? botMark : humanMark
        var score = minimax(board, botMark, humanMark, !botTurn, depth + 1)
        board[i] = ""
        if (botTurn)
            bestScore = Math.max(bestScore, score)
        else
            bestScore = Math.min(bestScore, score)
    }
    return bestScore
}

// Optimal play: the bot cannot be beaten. Center/corners are visited first to
// make its opening choices feel intentional while retaining minimax accuracy.
function bestMove(board, botMark, humanMark) {
    if (winner(board) || isFull(board))
        return -1

    var work = board.slice(0)
    var moveOrder = [4, 0, 2, 6, 8, 1, 3, 5, 7]
    var choice = -1
    var bestScore = -Infinity

    for (var i = 0; i < moveOrder.length; i++) {
        var index = moveOrder[i]
        if (work[index])
            continue
        work[index] = botMark
        var score = minimax(work, botMark, humanMark, false, 1)
        work[index] = ""
        if (score > bestScore) {
            bestScore = score
            choice = index
        }
    }
    return choice
}
