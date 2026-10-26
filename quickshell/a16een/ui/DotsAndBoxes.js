.pragma library

// 3x3 dots form a 2x2 set of boxes: six horizontal and six vertical edges.
var BOXES_PER_SIDE = 2
var BOX_COUNT = 4
var EDGE_COUNT = 6

function emptyHorizontal() {
    return ["", "", "", "", "", ""]
}

function emptyVertical() {
    return ["", "", "", "", "", ""]
}

function emptyOwners() {
    return ["", "", "", ""]
}

function sideCount(horizontal, vertical, row, column) {
    var count = 0
    if (horizontal[row * BOXES_PER_SIDE + column])
        count++
    if (horizontal[(row + 1) * BOXES_PER_SIDE + column])
        count++
    if (vertical[row * 3 + column])
        count++
    if (vertical[row * 3 + column + 1])
        count++
    return count
}

function countThreats(horizontal, vertical, owners) {
    var threats = 0
    for (var box = 0; box < BOX_COUNT; box++) {
        if (owners[box])
            continue
        if (sideCount(horizontal, vertical, Math.floor(box / 2), box % 2) === 3)
            threats++
    }
    return threats
}

function allBoxesOwned(owners) {
    for (var i = 0; i < BOX_COUNT; i++) {
        if (!owners[i])
            return false
    }
    return true
}

function scoreWinner(scores) {
    if (scores[0] > scores[1])
        return "X"
    if (scores[1] > scores[0])
        return "O"
    return ""
}

// Apply a single legal edge. A completed box is owned by the line drawer and
// earns that same player another move; closing two boxes still earns one turn.
function applyMove(horizontal, vertical, owners, scores, orientation, index, player) {
    if ((player !== "X" && player !== "O")
        || (orientation !== "h" && orientation !== "v"))
        return null

    var maxIndex = EDGE_COUNT - 1
    if (typeof index !== "number" || index < 0 || index > maxIndex || index % 1 !== 0)
        return null

    var nextHorizontal = horizontal.slice(0)
    var nextVertical = vertical.slice(0)
    var nextOwners = owners.slice(0)
    var nextScores = scores.slice(0)

    if (orientation === "h") {
        if (nextHorizontal[index])
            return null
        nextHorizontal[index] = player
    } else {
        if (nextVertical[index])
            return null
        nextVertical[index] = player
    }

    var claimed = []
    for (var box = 0; box < BOX_COUNT; box++) {
        if (nextOwners[box])
            continue
        if (sideCount(nextHorizontal, nextVertical, Math.floor(box / 2), box % 2) === 4) {
            nextOwners[box] = player
            claimed.push(box)
            nextScores[player === "X" ? 0 : 1]++
        }
    }

    var gameOver = allBoxesOwned(nextOwners)
    var turn = claimed.length > 0 ? player : (player === "X" ? "O" : "X")
    return {
        horizontal: nextHorizontal,
        vertical: nextVertical,
        owners: nextOwners,
        scores: nextScores,
        claimed: claimed,
        turn: turn,
        gameOver: gameOver,
        winner: gameOver ? scoreWinner(nextScores) : ""
    }
}

function legalMoves(horizontal, vertical) {
    var moves = []
    for (var h = 0; h < EDGE_COUNT; h++) {
        if (!horizontal[h])
            moves.push({ orientation: "h", index: h })
    }
    for (var v = 0; v < EDGE_COUNT; v++) {
        if (!vertical[v])
            moves.push({ orientation: "v", index: v })
    }
    return moves
}

function moveScore(horizontal, vertical, owners, move, player) {
    var beforeThreats = countThreats(horizontal, vertical, owners)
    var result = applyMove(
        horizontal, vertical, owners, [0, 0],
        move.orientation, move.index, player
    )
    if (!result)
        return -Infinity

    var newThreats = countThreats(result.horizontal, result.vertical, result.owners)
    var threatsCreated = Math.max(0, newThreats - beforeThreats)
    // Taking a box is strongly rewarded; opening a box for the opponent is risky.
    return result.claimed.length * 100 - threatsCreated * 18
}

function rankedMoves(horizontal, vertical, owners, player) {
    var moves = legalMoves(horizontal, vertical)
    var ranked = []
    for (var i = 0; i < moves.length; i++) {
        ranked.push({
            move: moves[i],
            score: moveScore(horizontal, vertical, owners, moves[i], player)
        })
    }
    return ranked
}

function bestMove(horizontal, vertical, owners, player) {
    var ranked = rankedMoves(horizontal, vertical, owners, player)
    if (ranked.length === 0)
        return null

    var best = ranked[0]
    for (var i = 1; i < ranked.length; i++) {
        if (ranked[i].score > best.score)
            best = ranked[i]
    }
    return best.move
}

// The bot is intentionally a casual opponent, not a perfect solver. Most turns
// favor captures and safe edges; some turns choose a weaker edge and can gift boxes.
function casualMove(horizontal, vertical, owners, player, roll, choiceRoll) {
    var ranked = rankedMoves(horizontal, vertical, owners, player)
    if (ranked.length === 0)
        return null

    var skillRoll = typeof roll === "number" ? roll : Math.random()
    var best = ranked[0]
    for (var i = 1; i < ranked.length; i++) {
        if (ranked[i].score > best.score)
            best = ranked[i]
    }
    if (skillRoll < 0.70)
        return best.move

    var alternatives = []
    if (skillRoll < 0.90) {
        for (var j = 0; j < ranked.length; j++) {
            if (ranked[j].score < best.score)
                alternatives.push(ranked[j].move)
        }
    }

    if (alternatives.length === 0) {
        for (var k = 0; k < ranked.length; k++) {
            if (ranked[k].move.orientation !== best.move.orientation
                || ranked[k].move.index !== best.move.index)
                alternatives.push(ranked[k].move)
        }
    }
    if (alternatives.length === 0)
        return best.move

    var pickRoll = typeof choiceRoll === "number" ? choiceRoll : Math.random()
    pickRoll = Math.max(0, Math.min(0.999999, pickRoll))
    return alternatives[Math.floor(pickRoll * alternatives.length)]
}
