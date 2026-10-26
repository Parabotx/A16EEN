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

// Best possible move. Keep this deterministic helper for tests and for the
// occasional sharp bot turn; casualMove deliberately adds human-like mistakes.
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

function rankedMoves(board, botMark, humanMark) {
    var moveOrder = [4, 0, 2, 6, 8, 1, 3, 5, 7]
    var work = board.slice(0)
    var moves = []
    for (var i = 0; i < moveOrder.length; i++) {
        var index = moveOrder[i]
        if (work[index])
            continue
        work[index] = botMark
        var score = minimax(work, botMark, humanMark, false, 1)
        work[index] = ""
        moves.push({ index: index, score: score })
    }
    return moves
}

// A single bot with varied judgement: it usually plays optimally, sometimes
// chooses a weaker move, and occasionally makes a plainly imperfect move.
// roll and choiceRoll are injectable so automated tests can check blunders.
function casualMove(board, botMark, humanMark, roll, choiceRoll) {
    if (winner(board) || isFull(board))
        return -1

    var skillRoll = typeof roll === "number" ? roll : Math.random()
    var optimal = bestMove(board, botMark, humanMark)
    if (skillRoll < 0.68)
        return optimal

    var ranked = rankedMoves(board, botMark, humanMark)
    var alternatives = []
    var bestScore = -Infinity
    for (var i = 0; i < ranked.length; i++)
        bestScore = Math.max(bestScore, ranked[i].score)

    if (skillRoll < 0.90) {
        for (var j = 0; j < ranked.length; j++) {
            if (ranked[j].score < bestScore)
                alternatives.push(ranked[j].index)
        }
    }

    if (alternatives.length === 0) {
        for (var k = 0; k < ranked.length; k++) {
            if (ranked[k].index !== optimal)
                alternatives.push(ranked[k].index)
        }
    }
    if (alternatives.length === 0)
        return optimal

    var pickRoll = typeof choiceRoll === "number" ? choiceRoll : Math.random()
    pickRoll = Math.max(0, Math.min(0.999999, pickRoll))
    return alternatives[Math.floor(pickRoll * alternatives.length)]
}
