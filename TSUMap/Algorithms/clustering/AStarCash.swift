import Foundation

var distBetweenPlaces: [GridPoint: [GridPoint: Int]] = [:]

private func cashAStar(grid: [[CellType]], places: [Place]) {
    for i in 0..<places.count {
        let startPlace = places[i].entryCord

        if distBetweenPlaces[startPlace] == nil {
            distBetweenPlaces[startPlace] = [:]
        }

        for j in i..<places.count {
            let endPlace = places[j].entryCord

            if distBetweenPlaces[endPlace] == nil {
                distBetweenPlaces[endPlace] = [:]
            }

            let dist = AStar(graph: grid, start: startPlace, end: endPlace).count
            distBetweenPlaces[endPlace]?[startPlace] = dist
            distBetweenPlaces[startPlace]?[endPlace] = dist
        }
    }
}
