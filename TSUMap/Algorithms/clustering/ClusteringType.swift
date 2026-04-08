import Foundation

enum ClusteringType: String {
    case aStar = "AStar"
    case byStraight = "EuclideanDistance"

    func metric(_ firstPoint: Place, _ secondPoint: Place, _ cashe: AStarCash) -> Double {
        switch self {
        case .aStar:
            let dist = cashe.getDistance(firstPlace: firstPoint, secondPlace: secondPoint)
            return Double(dist)
        case . byStraight:
            return EuclideanDistance(firstPoint.entryCord, secondPoint.entryCord)
        }
    }
}

func EuclideanDistance(_ firstPoint: GridPoint, _ secondPoint: GridPoint) -> Double {
    return sqrt(pow(CGFloat(firstPoint.col - secondPoint.col), 2) + pow(CGFloat(firstPoint.row - secondPoint.row), 2))
}
