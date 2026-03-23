import Foundation

private struct AStarNode: Hashable, Equatable {
    let point: GridPoint
    let funcH: Double
    let dist: Double
    var funcF: Double

    init(_ points: GridPoint, _ h: Double, _ distance: Double) {
        point = points
        funcH = h
        dist = distance
        funcF = distance + h
    }
}

func h(_ point: GridPoint, _ target: GridPoint) -> Double {
    let dx = Double(point.row - target.row)
    let dy = Double(point.col - target.col)

    return sqrt(pow(dx, 2) + pow(dy, 2))
}

func isValidStep(graph: [[CellType]], vertex: GridPoint, isVisited: Set<GridPoint>) -> Bool {

    return vertex.col >= 0
        && vertex.row >= 0
        && vertex.row < graph.count
        && vertex.col < graph[0].count
        && !isVisited.contains(vertex)
        && graph[vertex.row][vertex.col] == .path
}

func AStar(graph: [[CellType]], start: GridPoint, end: GridPoint) -> [GridPoint] {

    var isVisited: Set<GridPoint> = []
    var opened: [AStarNode] = []

    let neighbors = [(0, 1), (1, 0), (-1, 0), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)]
    var parents: [GridPoint: GridPoint] = [:]
    opened.append( AStarNode(start, h(start, end), 0))

    while !opened.isEmpty {

        opened = opened.sorted(by: ({$0.funcF < $1.funcF}))
        guard let currentVertex = opened.first else {
            break
        }

        if currentVertex.point == end {
            return createPath(parents: parents, start: start, end: end)
        }

        opened.removeFirst()
        isVisited.insert(currentVertex.point)

        for (row, col) in neighbors {
            let neighborsPos = GridPoint(row: currentVertex.point.row + row, col: currentVertex.point.col + col)

            if !isValidStep(graph: graph, vertex: neighborsPos, isVisited: isVisited) {continue}

            let neighborH = h(neighborsPos, end)
            let neighborDist = (row == 0 || col == 0) ? currentVertex.dist + 1 : currentVertex.dist + sqrt(2)

            guard let item = opened.firstIndex(where: {$0.point == neighborsPos}) else {

                opened.append(AStarNode(neighborsPos, neighborH, neighborDist))
                parents[neighborsPos] = currentVertex.point

                continue
            }

            if opened[item].dist > neighborDist {
                opened[item] = AStarNode(neighborsPos, neighborH, neighborDist)
                parents[neighborsPos] = currentVertex.point
            }
        }
    }

    return createPath(parents: parents, start: start, end: end)
}

func createPath(parents: [GridPoint: GridPoint], start: GridPoint, end: GridPoint) -> [GridPoint] {
    var path: [GridPoint] = [end]
    var currentVertex: GridPoint = end

    while currentVertex != start {
        guard let nextNode = parents[currentVertex] else {
            break
        }
        currentVertex = nextNode
        path.append(nextNode)
    }

    return path
}
