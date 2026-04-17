//
//  NeutalManager.swift
//  TSUMap
//
//  Created by Екатерина Кондрашова on 03.04.2026.
//
import Combine
import Foundation

class NeuralManager: ObservableObject {
    static let shared = NeuralManager()

    @Published var network: NeuralNetwork?

    private init() {
        loadWeights()
    }

    private func loadWeights() {
        guard let bundleURL = Bundle.main.url(forResource: "trained_network", withExtension: "json") else {
            return
        }

        do {
            let data = try Data(contentsOf: bundleURL)
            network = try JSONDecoder().decode(NeuralNetwork.self, from: data)
        } catch {}
    }

    func neuralNetworkPredict(input: [Double]) -> Int {
        guard let network else {
            return -1
        }
        return network.neuralPredict(input: input)
    }
}
