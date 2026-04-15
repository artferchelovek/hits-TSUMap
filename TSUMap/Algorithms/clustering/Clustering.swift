import Foundation
import SwiftUI

class Clustering {
    private var clusteringType: ClusteringType
    private var dataPlace: [Cafe]
    private var numberOfClusters: Int
    private var aStarPaths: AStarCash

    init(data: [Cafe], numberOfClusters: Int, clusteringType: ClusteringType, aStarPaths: AStarCash) {
        self.clusteringType = clusteringType
        dataPlace = data
        self.numberOfClusters = numberOfClusters
        self.aStarPaths = aStarPaths
    }

    private func TotalSumDist(cluster: Cluster, candidateMedoid: Cafe) -> Double {
        cluster.placesInClust
            .reduce(0) { sum, place in sum + clusteringType.metric(candidateMedoid, place, aStarPaths) }
    }

    private func findCenters() -> [Cafe] {
        var centers: [Cafe] = []

        guard let firstCenter = dataPlace.randomElement() else {
            return []
        }
        centers.append(firstCenter)

        while centers.count < numberOfClusters {
            var dist: [(place: Cafe, dist: Double)] = []
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
            let target = Double.random(in: 0 ... 1) * sumDist

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

    func startKMedoids() -> [Cluster] {
        var centroids = findCenters()
        var clusters: [Cluster] = []
        var isMedoidChanged = true
        let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .yellow, .cyan, .mint, .indigo]
        var iter = 0
        let maxIter = 100

        while isMedoidChanged, iter < maxIter {
            isMedoidChanged = false

            clusters = centroids.enumerated().map { i, medoid in
                let color = colors[i % colors.count]
                return Cluster(medoid: medoid, color: color)
            }

            for place in dataPlace {
                var minDist = Double.infinity
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

            var newCentroids: [Cafe] = []
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

    func startDBScan() -> [Cluster] {
        let eps = 32.5
        let m = 3

        var clusters: [Cluster] = []
        var clusteredPlaces: Set<Cafe> = []
        var visitedPlaces: Set<Cafe> = []
        var noisePlaces: Set<Cafe> = []

        let placeInVicinity = { (place: Cafe) -> [Cafe] in
            var places: [Cafe] = []
            self.dataPlace.forEach { self.clusteringType.metric($0, place, self.aStarPaths) <= eps ? places.append($0) : nil }
            return places
        }

        for place in dataPlace {
            if visitedPlaces.contains(place) { continue }
            visitedPlaces.insert(place)

            var vicinityObjects = placeInVicinity(place)

            if vicinityObjects.count < m {
                noisePlaces.insert(place)
            } else {
                let clust = Cluster(medoid: place, color: .red)
                clusteredPlaces.insert(place)
                clust.placesInClust.append(place)

                while !vicinityObjects.isEmpty {
                    guard let x = vicinityObjects.popLast() else {
                        break
                    }

                    if !visitedPlaces.contains(x) {
                        visitedPlaces.insert(x)
                        let placesEps = placeInVicinity(x)

                        if placesEps.count > m {
                            let newNeighbors = placesEps.filter { !visitedPlaces.contains($0) }
                            vicinityObjects.append(contentsOf: newNeighbors)
                        }
                    }

                    if !clusteredPlaces.contains(x) {
                        clusteredPlaces.insert(x)
                        clust.placesInClust.append(x)
                        noisePlaces.remove(x)
                    }
                }
                clusters.append(clust)
            }
        }
        for place in noisePlaces {
            var clust = Cluster(medoid: place, color: .blue)
            clust.placesInClust.append(place)
            clusters.append(clust)
        }

        return clusters
    }
}
