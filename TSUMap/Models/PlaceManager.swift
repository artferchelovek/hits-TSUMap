import Foundation
import SwiftUI
import Combine
@MainActor
final class PlaceManager: ObservableObject {
    @Published var places: [String: Place] = [:]
    private var aStarPaths: AStarCash?
    
    init() {
        loadData()
    }
    
    public func getPlaceById(_ result: String) -> Place? {
        return places[result]
    }
    
    public func setGrid(grid: [[CellType]]) {
        self.aStarPaths = AStarCash(grid: grid)
    }
    
    private func loadData() {
        guard let jsonURL = Bundle.main.url(forResource: "dataPlace", withExtension: "json") else {
            return
        }
        do {
            let data = try Data(contentsOf: jsonURL)
            
            let decoderPlaces = try JSONDecoder().decode([Place].self, from: data)
            var dict: [String: Place] = [:]
            for place in decoderPlaces {
                dict[place.id] = place
            }
            
            self.places = dict
        } catch {
            print(error)
        }
    }
    
    public func clustering(numberClusters: Int, typeClustering: ClusteringType, data: [Place]) -> [Cluster] {
        guard let paths = aStarPaths else {
            return []
        }
        
        return Clustering(data: data, numberOfClusters: numberClusters, clusteringType: typeClustering, aStarPaths: paths).startClustering()
    }
}
