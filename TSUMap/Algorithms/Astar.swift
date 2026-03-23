import Foundation

private struct Node: Hashable, Equatable {
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

func isValidStep(graph: [[Int]], vertex: GridPoint, isVisited: Set<GridPoint>) -> Bool {

    return vertex.col >= 0
        && vertex.row >= 0
        && vertex.row < graph.count
        && vertex.col < graph[0].count
        && !isVisited.contains(vertex)
        && graph[vertex.row][vertex.col] == 0
}

func AStar(graph: [[Int]], start: GridPoint, end: GridPoint) -> [GridPoint] {

    var isVisited: Set<GridPoint> = []
    var opened: [Node] = []

    let neighbors = [(0, 1), (1, 0), (-1, 0), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)]
    var parents: [GridPoint: GridPoint] = [:]
    opened.append( Node(start, h(start, end), 0))

    while !opened.isEmpty {

        opened = opened.sorted(by: ({$0.funcF < $1.funcF}))
        guard let currentVertex = opened.first else {
            break
        }

        opened.removeAll(where: {$0 == currentVertex})
        isVisited.insert(currentVertex.point)

        if currentVertex.point == end {
            break
        }

        for (row, col) in neighbors {
            let neighborsPos = GridPoint(row: currentVertex.point.row + row, col: currentVertex.point.col + col)

            if !isValidStep(graph: graph, vertex: neighborsPos, isVisited: isVisited) {continue}

            let neighborH = h(neighborsPos, end)
            let neighborDist = (row == 0 || col == 0) ? currentVertex.dist + sqrt(2) : currentVertex.dist + 1

            guard let item = opened.firstIndex(where: {$0.point == neighborsPos}) else {

                opened.append(Node(neighborsPos, neighborH, neighborDist))
                parents[neighborsPos] = currentVertex.point

                continue
            }

            if opened[item].dist > neighborDist {
                opened[item] = Node(neighborsPos, neighborH, neighborDist)
                parents[neighborsPos] = currentVertex.point
            }
        }
    }

    var path: [GridPoint] = []
    path.append(end)
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
