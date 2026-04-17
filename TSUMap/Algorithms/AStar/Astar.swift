import Foundation

class AStar {
    private var graph: [[CellType]]
    private var obstacle: [GridPoint]

    init(graph: [[CellType]], obstacle: [GridPoint] = []) {
        self.graph = graph
        self.obstacle = obstacle
    }

    private func h(_ point: GridPoint, _ target: GridPoint) -> Double {
        let dx = Double(point.row - target.row)
        let dy = Double(point.col - target.col)

        return sqrt(pow(dx, 2) + pow(dy, 2))
    }

    private func isValidStep(
        vertex: GridPoint,
        isVisited: Set<GridPoint>
    ) -> Bool {
        vertex.col >= 0
            && vertex.row >= 0
            && vertex.row < graph.count
            && vertex.col < graph[0].count
            && !isVisited.contains(vertex)
            && graph[vertex.row][vertex.col] == .path
            && !obstacle.contains(vertex)
    }

    private func createPath(parents: [GridPoint: GridPoint], start: GridPoint, end: GridPoint) -> [GridPoint] {
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

    func aStarBetweenSeveralPoints(start: GridPoint, points: [GridPoint], end: GridPoint) -> [GridPoint] {
        var intermediatePoints: [GridPoint] = [start]
        intermediatePoints += points
        intermediatePoints.append(end)

        var path: [GridPoint] = []

        for i in 0 ..< intermediatePoints.count - 1 {
            let from = intermediatePoints[i]
            let to = intermediatePoints[i + 1]

            var part = aStarAlgorithm(start: from, end: to)
            if part.isEmpty {
                return []
            }
            part.removeFirst()
            path += part
        }

        return path
    }

    func aStarAlgorithm(start: GridPoint, end: GridPoint) -> [GridPoint] {
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

                if !isValidStep(vertex: neighborPos, isVisited: isVisited) { continue }

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

    func aStarGenerator(start: GridPoint, end: GridPoint) -> AsyncStream<InfoAboutPoint> {
        AsyncStream { continuation in
            let task = Task {
                var isVisited: Set<GridPoint> = []
                var distance: [GridPoint: Double] = [start: 0]
                var pq = PriorityQueue()
                let neighbors = [(0, 1), (1, 0), (-1, 0), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)]
                var parents: [GridPoint: GridPoint] = [:]

                let startEl = AStarNode(start, h(start, end), 0)

                pq.addElem(newElem: startEl)
                while !pq.isEmpty {
                    if Task.isCancelled {
                        return
                    }

                    guard let currentVertex = pq.pop() else {
                        break
                    }

                    if currentVertex.point == end {
                        let finalPath = createPath(parents: parents, start: start, end: end)
                        continuation.yield(InfoAboutPoint(
                            point: currentVertex.point,
                            openPoints: pq.allGridPoints,
                            pathToPoint: Set(createPath(parents: parents, start: start, end: currentVertex.point)),
                            isEnd: true,
                            path: finalPath
                        ))
                        continuation.finish()
                        return
                    }

                    isVisited.insert(currentVertex.point)

                    for (row, col) in neighbors {
                        let neighborPos = GridPoint(row: currentVertex.point.row + row, col: currentVertex.point.col + col)

                        if !isValidStep(vertex: neighborPos, isVisited: isVisited) { continue }

                        let step = (row == 0 || col == 0) ? 1.0 : sqrt(2.0)
                        let neighborDist = distance[currentVertex.point]! + step

                        if neighborDist < (distance[neighborPos] ?? Double.infinity) {
                            distance[neighborPos] = neighborDist
                            parents[neighborPos] = currentVertex.point

                            let neighborNode = AStarNode(neighborPos, h(neighborPos, end), neighborDist)
                            pq.addElem(newElem: neighborNode)
                        }
                    }

                    continuation.yield(InfoAboutPoint(
                        point: currentVertex.point,
                        openPoints: pq.allGridPoints,
                        pathToPoint: Set(createPath(parents: parents, start: start, end: currentVertex.point)),
                        isEnd: false,
                        path: []
                    ))
                }

                continuation.finish()
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}
