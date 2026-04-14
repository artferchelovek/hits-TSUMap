import Foundation

class AStarCash {
    private var paths: [String: [String: Int]] = [:]
    private let grid: [[CellType]]

    init(grid: [[CellType]]) {
        self.grid = grid
    }

    func getDistance(firstPlace: Cafe, secondPlace: Cafe) -> Int {
        let firstId = firstPlace.id
        let secondId = secondPlace.id
        if firstPlace.entryCord == secondPlace.entryCord { return 0 }

        if let path = paths[firstId]?[secondId] {
            return path
        }

        let path = AStar(graph: grid, start: firstPlace.entryCord, end: secondPlace.entryCord)
        let pathCount = path.isEmpty ? 10000 : path.count

        if paths[firstId] == nil { paths[firstId] = [:] }
        if paths[secondId] == nil { paths[secondId] = [:] }

        paths[firstId]?[secondId] = pathCount
        paths[secondId]?[firstId] = pathCount

        return pathCount
    }
}
