import Foundation

class ClusterManger {
    var clusters: [ClusteringType: [Cluster]] = [:]

    public func takeCluster(type: ClusteringType, numberClusters: Int, data: [Place]) -> [Cluster] {
        guard let clust = clusters[type] else {
            let clust = kMedoids(numberOfClusters: numberClusters, typeClusterization: type, data: data)
            clusters[type] = clust
            return clust
        }

        return clust
    }
}
