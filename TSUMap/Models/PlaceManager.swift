import Foundation
import SwiftUI
import Combine
@MainActor
final class PlaceManager: ObservableObject {
    @Published var cafes: [String: Cafe] = [:]
    @Published var coworkings: [String: Coworking] = [:]
    @Published var sights: [String: Sight] = [:]
    private var aStarPaths: AStarCash?
    
    init() {
        loadData()
    }
    
    public func setGrid(grid: [[CellType]]) {
        self.aStarPaths = AStarCash(grid: grid)
    }
    
    private func loadData() {
        guard let jsonCafesURL = Bundle.main.url(forResource: "cafesData", withExtension: "json") else {
            return
        }
        guard let jsonCoworkingsURL = Bundle.main.url(forResource: "coworkingsData", withExtension: "json") else {
            return
        }
        guard let jsonSightsURL = Bundle.main.url(forResource: "sightData", withExtension: "json") else {
            return
        }
        do {
            let dataCafes = try Data(contentsOf: jsonCafesURL)
            let dataCoworkings = try Data(contentsOf: jsonCoworkingsURL)
            let dataSights = try Data(contentsOf: jsonSightsURL)
            
            var dictCafes: [String: Cafe] = [:]
            var dictCoworkings: [String: Coworking] = [:]
            var dictSights: [String: Sight] = [:]
            
            try JSONDecoder().decode([Coworking].self, from: dataCoworkings).forEach({dictCoworkings[$0.id] = $0})
            try JSONDecoder().decode([Cafe].self, from: dataCafes).forEach({dictCafes[$0.id] = $0})
            try JSONDecoder().decode([Sight].self, from: dataSights).forEach({dictSights[$0.id] = $0})
            
            self.coworkings = dictCoworkings
            self.sights = dictSights
            self.cafes = dictCafes
        } catch {
            print(error)
        }
    }
    
    public func clustering(numberClusters: Int, typeClustering: ClusteringType, typeAlgorithm: ClusteringAlgorithmType = .KMedoids, data: [Cafe]) -> [Cluster] {
        guard let paths = aStarPaths else {
            return []
        }
        switch typeAlgorithm {
        case .DBScan:
            return Clustering(data: data, numberOfClusters: numberClusters, clusteringType: typeClustering, aStarPaths: paths).startDBScan()
        case .KMedoids:
            return Clustering(data: data, numberOfClusters: numberClusters, clusteringType: typeClustering, aStarPaths: paths).startKMedoids()
        }        
    }
    
    public func getAllPlaces() -> [String: IdentifiableItem] {
        var allPlace: [String: IdentifiableItem] = [:]
        cafes.forEach({allPlace[$0.key] = IdentifiableItem(item: $0.value)})
        sights.forEach({allPlace[$0.key] = IdentifiableItem(item: $0.value)})
        coworkings.forEach({allPlace[$0.key] = IdentifiableItem(item: $0.value)})
        
        return allPlace
    }
    
    public func getPlaceById(_ id: String) -> (IdentifiableItem)? {
        let allPlaces = getAllPlaces()
        return allPlaces[id]
    }
}
