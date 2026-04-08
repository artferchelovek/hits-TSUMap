import Foundation
import SwiftUI

class Clustering {
    private var clusteringType: ClusteringType
    private var dataPlace: [Place]
    private var numberOfClusters: Int
    private var aStarPaths: AStarCash
    
    init (data: [Place], numberOfClusters: Int, clusteringType: ClusteringType, aStarPaths: AStarCash) {
        self.clusteringType = clusteringType
        self.dataPlace = data
        self.numberOfClusters = numberOfClusters
        self.aStarPaths = aStarPaths
    }
    
    private func TotalSumDist(cluster: Cluster, candidateMedoid: Place) -> Double {
        return cluster.placesInClust.reduce(0) {sum, place in sum + clusteringType.metric(candidateMedoid, place, aStarPaths)}
    }
    
    private func findCenters() -> [Place] {
        var centers: [Place] = []
        
        guard let firstCenter = dataPlace.randomElement() else {
            return []
        }
        centers.append(firstCenter)
        
        while centers.count < numberOfClusters {
            var dist: [(place: Place, dist: Double)] = []
            var sumDist: Double = 0
            
            for place in dataPlace {
                var minDist = Double.infinity
                for center in centers {
                    let currentDist = clusteringType.metric(place, center, aStarPaths)
                    if currentDist < minDist {
                        minDist = currentDist
                    }
                }
                minDist = pow(minDist, 2)
                sumDist += minDist
                dist.append((place, minDist))
            }
            
            if sumDist == 0 {
                break
            }
            
            var currentDist: Double = 0
            let target = Double.random(in: 0...1) * sumDist
            
            for (place, dist) in dist {
                currentDist += dist
                if currentDist >= target {
                    centers.append(place)
                    break
                }
            }
        }
        return centers
    }
    
    func startClustering() -> [Cluster] {
        var centroids = findCenters()
        var clusters: [Cluster] = []
        var isMedoidChanged = true
        let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .yellow, .cyan, .mint, .indigo]
        var iter = 0
        let maxIter = 1000
        while isMedoidChanged && iter < maxIter {
            isMedoidChanged = false
            
            clusters = centroids.enumerated().map { (i, medoid) in
                let color = colors[i % colors.count]
                return Cluster(medoid: medoid, color: color)
            }
            for place in dataPlace {
                var minDist: Double = Double.infinity
                var minClust: Cluster = clusters[0]
                for cluster in clusters {
                    let clustMedoid = cluster.medoid
                    let dist = clusteringType.metric(place, clustMedoid, aStarPaths)
                    if dist < minDist {
                        minClust = cluster
                        minDist = dist
                    }
                }
                minClust.placesInClust.append(place)
            }
            
            var newCentroids: [Place] = []
            for cluster in clusters {
                var currentMedoid = cluster.medoid
                var currentCost = TotalSumDist(cluster: cluster, candidateMedoid: currentMedoid)
                
                for place in cluster.placesInClust {
                    let newCost = TotalSumDist(cluster: cluster, candidateMedoid: place)
                    
                    if newCost < currentCost {
                        currentCost = newCost
                        currentMedoid = place
                        isMedoidChanged = true
                    }
                }
                newCentroids.append(currentMedoid)
            }
            iter += 1
            centroids = newCentroids
        }
        return clusters
    }
}
