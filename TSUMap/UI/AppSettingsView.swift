//
//  AppSettingsView.swift
//  TSUMap
//
//  Created by Artem on 17.04.2026.
//

import SwiftUI

struct AppSettingsView: View {
    @ObservedObject var settingsManager: SettingsManager

    @State private var isBuildPath: Bool = false
    @State private var Speed: Int = 1

    @State private var ClusterType: ClusteringType = .aStar
    @State private var ClusterAlgorithm: ClusteringAlgorithmType = .KMedoids

    fileprivate func aStarSettings() -> some View {
        Section("A*") {
            Toggle(isOn: $settingsManager.isBuildPath) {
                Text("Процесс поиска маршрута")
            }

            VStack(alignment: .leading) {
                Text("Скорость поиска")
                Picker("", selection: $settingsManager.buildPathSpeed) {
                    ForEach(1 ... 5, id: \.self) { value in
                        Text("x\(value)").tag(Double(value))
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!settingsManager.isBuildPath)
            }
            .foregroundColor(settingsManager.isBuildPath ? .primary : .secondary)
        }
    }

    fileprivate func clusterSettings() -> some View {
        Section("Кластеризация") {
            Picker("Метрика", selection: $settingsManager.clusterType) {
                Text("Пешая").tag(ClusteringType.aStar)
                Text("По прямой").tag(ClusteringType.byStraight)
            }
            Picker("Алгоритм", selection: $settingsManager.clusterAlgorithm) {
                Text("DBScan").tag(ClusteringAlgorithmType.DBScan)
                Text("K-средних").tag(ClusteringAlgorithmType.KMedoids)
            }
        }
    }

    var body: some View {
        NavigationView {
            List {
                aStarSettings()

                clusterSettings()
            }
            .navigationTitle("Настройки")
        }
    }
}

#Preview {
    AppSettingsView(
        settingsManager: SettingsManager()
    )
}
