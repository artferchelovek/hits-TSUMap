import Foundation
import SwiftUI

private func TotalSumDist(cluster: Cluster, candidateMedoid: Place, typeClusterization: ClusteringType) -> Double {
    return cluster.placesInClust.reduce(0) {sum, place in sum + typeClusterization.metric(candidateMedoid.entryCord, place.entryCord)}
}

private func findCenters(numberOfClusters: Int, clusteringType: ClusteringType, data: [Place]) -> [Place] {
    var centers: [Place] = []

    guard let firstCenter = data.randomElement() else {
        return []
    }
    centers.append(firstCenter)

    while centers.count < numberOfClusters {
        var dist: [(place: Place, dist: Double)] = []
        var sumDist: Double = 0

        for place in data {
            var minDist = Double.infinity
            for center in centers {
                let currentDist = clusteringType.metric(place.entryCord, center.entryCord)
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

func kMedoids(numberOfClusters: Int, typeClusterization: ClusteringType, data: [Place]) -> [Cluster] {
    let centroids = findCenters(numberOfClusters: numberOfClusters, clusteringType: typeClusterization, data: data)
    var clusters: [Cluster] = []
    var isMedoidChanged = true
    let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .yellow, .cyan, .mint, .indigo]
    
    while isMedoidChanged {
        isMedoidChanged = false
        
        clusters = centroids.enumerated().map { (i, medoid) in
            let color = colors[i % colors.count]
            return Cluster(medoid: medoid, color: color)
        }
        for place in data {
            var minDist: Double = Double.infinity
            var minClust: Cluster = clusters[0]
            for cluster in clusters {
                let clustMedoid = cluster.medoid
                let dist = typeClusterization.metric(place.entryCord, clustMedoid.entryCord)
                if dist < minDist {
                    minClust = cluster
                    minDist = dist
                }
            }
            minClust.placesInClust.append(place)
        }
        
        for cluster in clusters {
            var currentMedoid = cluster.medoid
            var currentCost = TotalSumDist(cluster: cluster, candidateMedoid: currentMedoid, typeClusterization: typeClusterization)
            
            for place in cluster.placesInClust {
                let newCost = TotalSumDist(cluster: cluster, candidateMedoid: place, typeClusterization: typeClusterization)
                
                if newCost < currentCost {
                    currentCost = newCost
                    currentMedoid = place
                    isMedoidChanged = true
                }
            }
        }
    }
    return clusters
}


