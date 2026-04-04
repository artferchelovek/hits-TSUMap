import Foundation

enum ClusteringType: String {
    case Astar = "AStar"
    case byStraight = "EuclideanDistance"

    func metric(_ firstPoint: GridPoint, _ secondPoint: GridPoint) -> Double {
        switch self {
        case .Astar:
            let distance = distBetweenPlaces[firstPoint]?[secondPoint] ?? Int.max
            return Double(distance)
        case . byStraight:
            return EuclideanDistance(firstPoint, secondPoint)
        }
    }
}

func EuclideanDistance(_ firstPoint: GridPoint, _ secondPoint: GridPoint) -> Double {
    return sqrt(pow(CGFloat(firstPoint.col - secondPoint.col), 2) + pow(CGFloat(firstPoint.row - secondPoint.row), 2))
}
