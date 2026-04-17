//
//  SettingsManager.swift
//  TSUMap
//
//  Created by Artem on 17.04.2026.
//

import Combine
import Foundation

@MainActor
final class SettingsManager: ObservableObject {
    private static let fileURL: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("app_settings.json")
    }()

    struct SaveData: Codable {
        let isBuildPath: Bool
        let buildPathSpeed: Double
        let clusterType: ClusteringType
        let clusterAlgorithm: ClusteringAlgorithmType
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.fileURL),
              let decoded = try? JSONDecoder().decode(SaveData.self, from: data)
        else {
            return
        }

        isBuildPath = decoded.isBuildPath
        buildPathSpeed = decoded.buildPathSpeed
        clusterType = decoded.clusterType
        clusterAlgorithm = decoded.clusterAlgorithm
    }

    private func save() {
        let dataToSave = SaveData(
            isBuildPath: isBuildPath,
            buildPathSpeed: buildPathSpeed,
            clusterType: clusterType,
            clusterAlgorithm: clusterAlgorithm
        )

        if let encoded = try? JSONEncoder().encode(dataToSave) {
            try? encoded.write(to: Self.fileURL)
        }
    }

    @Published var isBuildPath: Bool = false {
        didSet { save() }
    }

    @Published var buildPathSpeed: Double = 1.0 {
        didSet { save() }
    }

    @Published var clusterType: ClusteringType = .aStar {
        didSet { save() }
    }

    @Published var clusterAlgorithm: ClusteringAlgorithmType = .DBScan {
        didSet { save() }
    }
}
