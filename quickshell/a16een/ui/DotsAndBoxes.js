.pragma library

// Square Dots & Boxes board. N dots on each side form (N - 1)^2 boxes,
// with N * (N - 1) horizontal edges and the same number of vertical edges.
var BOXES_PER_SIDE = 2
var BOX_COUNT = 4
var EDGE_COUNT = 6

function normalizeDotCount(value) {
    var count = Number(value)
    if (!isFinite(count) || count < 2)
        return 3
    return Math.floor(count)
}

function dotsFromBoard(horizontal, vertical, owners) {
    var ownerCount = owners && typeof owners.length === "number" ? owners.length : 0
    var boxSide = Math.round(Math.sqrt(ownerCount))
    if (boxSide > 0 && boxSide * boxSide === ownerCount)
        return boxSide + 1
    var edgeCount = horizontal && typeof horizontal.length === "number" ? horizontal.length : 6
    return Math.max(2, Math.round((1 + Math.sqrt(1 + 4 * edgeCount)) / 2))
}

function emptyHorizontal(dotsPerSide) {
    var dots = normalizeDotCount(dotsPerSide)
    var result = []
    for (var i = 0; i < dots * (dots - 1); i++)
        result.push("")
    return result
}

function emptyVertical(dotsPerSide) {
    return emptyHorizontal(dotsPerSide)
}

function emptyOwners(dotsPerSide) {
    var dots = normalizeDotCount(dotsPerSide)
    var count = (dots - 1) * (dots - 1)
    var result = []
    for (var i = 0; i < count; i++)
        result.push("")
    return result
}

function sideCount(horizontal, vertical, row, column) {
    var dots = dotsFromBoard(horizontal, vertical, [])
    var boxSide = dots - 1
    var count = 0
    if (horizontal[row * boxSide + column])
        count++
    if (horizontal[(row + 1) * boxSide + column])
        count++
    if (vertical[row * dots + column])
        count++
    if (vertical[row * dots + column + 1])
        count++
    return count
}

function countThreats(horizontal, vertical, owners) {
    var dots = dotsFromBoard(horizontal, vertical, owners)
    var boxSide = dots - 1
    var threats = 0
    for (var box = 0; box < owners.length; box++) {
        if (owners[box])
            continue
        if (sideCount(horizontal, vertical, Math.floor(box / boxSide), box % boxSide) === 3)
            threats++
    }
    return threats
}

function allBoxesOwned(owners) {
    for (var i = 0; i < owners.length; i++) {
        if (!owners[i])
            return false
    }
    return owners.length > 0
}

function scoreWinner(scores) {
    if (scores[0] > scores[1])
        return "X"
    if (scores[1] > scores[0])
        return "O"
    return ""
}

// A completed box stays with the player who drew its final edge and grants
// that player another move, including when one line captures multiple boxes.
function applyMove(horizontal, vertical, owners, scores, orientation, index, player) {
    if ((player !== "X" && player !== "O")
        || (orientation !== "h" && orientation !== "v")
        || !horizontal || !vertical || !owners || !scores)
        return null

    var dots = dotsFromBoard(horizontal, vertical, owners)
    var edgesExpected = dots * (dots - 1)
    var boxesExpected = (dots - 1) * (dots - 1)
    if (horizontal.length !== edgesExpected
        || vertical.length !== edgesExpected
        || owners.length !== boxesExpected
        || scores.length !== 2)
        return null

    if (typeof index !== "number" || index < 0
        || index >= edgesExpected || index % 1 !== 0)
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
    var boxSide = dots - 1
    for (var box = 0; box < boxesExpected; box++) {
        if (nextOwners[box])
            continue
        if (sideCount(nextHorizontal, nextVertical, Math.floor(box / boxSide), box % boxSide) === 4) {
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
    for (var h = 0; h < horizontal.length; h++) {
        if (!horizontal[h])
            moves.push({ orientation: "h", index: h })
    }
    for (var v = 0; v < vertical.length; v++) {
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

// A casual opponent is usually tactical but occasionally misses a capture.
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
