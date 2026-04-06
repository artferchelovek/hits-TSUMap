import Foundation

 struct AStarNode: Hashable, Equatable, Comparable {
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
    
    static func < (lhs: AStarNode, rhs: AStarNode) -> Bool {
        if lhs.funcF != rhs.funcF {
            return lhs.funcF < rhs.funcF
        }
        return lhs.funcH < rhs.funcH
    }
}

func h(_ point: GridPoint, _ target: GridPoint) -> Double {
    let dx = Double(point.row - target.row)
    let dy = Double(point.col - target.col)

    return sqrt(pow(dx, 2) + pow(dy, 2))
}

func isValidStep(graph: [[CellType]], vertex: GridPoint, isVisited: Set<GridPoint>, prepatstvie: [GridPoint]) -> Bool {

    return vertex.col >= 0
        && vertex.row >= 0
        && vertex.row < graph.count
        && vertex.col < graph[0].count
        && !isVisited.contains(vertex)
        && graph[vertex.row][vertex.col] == .path
        && !prepatstvie.contains(vertex)
}

func AStar(graph: [[CellType]], start: GridPoint, end: GridPoint, onTrip: [GridPoint] = [], prepatstvie: [GridPoint] = []) -> [GridPoint] {

    var isVisited: Set<GridPoint> = []
    var distance: [GridPoint: Double] = [start: 0]
    var pq = PriorityQueue()
    
    let neighbors = [(0, 1), (1, 0), (-1, 0), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)]
    var parents: [GridPoint: GridPoint] = [:]
    
    let startEl = AStarNode(start, h(start, end), 0)
    
    pq.addElem(newElem: startEl)
    while !pq.isEmpty {

        guard let currentVertex = pq.pop() else {
            break
        }

        if currentVertex.point == end {
            return createPath(parents: parents, start: start, end: end)
        }
        
        isVisited.insert(currentVertex.point)

        for (row, col) in neighbors {
            let neighborPos = GridPoint(row: currentVertex.point.row + row, col: currentVertex.point.col + col)

            if !isValidStep(graph: graph, vertex: neighborPos, isVisited: isVisited, prepatstvie: prepatstvie) {continue}

            let step = (row == 0 || col == 0) ? 1.0 : sqrt(2.0)
            let neighborDist = distance[currentVertex.point]! + step
           
            if neighborDist < (distance[neighborPos] ?? Double.infinity) {
                distance[neighborPos] = neighborDist
                parents[neighborPos] = currentVertex.point
                
                let neighborNode = AStarNode(neighborPos, h(neighborPos, end), neighborDist)
                pq.addElem(newElem: neighborNode)
            }
        }
    }

    return createPath(parents: parents, start: start, end: end)
}

func createPath(parents: [GridPoint: GridPoint], start: GridPoint, end: GridPoint) -> [GridPoint] {
    if start == end { return [] }
    var path: [GridPoint] = [end]
    var currentVertex: GridPoint = end

    while currentVertex != start {
        guard let nextNode = parents[currentVertex] else {
            return []
        }
        currentVertex = nextNode
        path.append(nextNode)
    }

    return path.reversed()
}
