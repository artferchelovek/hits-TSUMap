//
//  NeutalManager.swift
//  TSUMap
//
//  Created by Екатерина Кондрашова on 03.04.2026.
//
import Foundation
import Combine

class NeuralManager: ObservableObject {
    static let shared = NeuralManager()
    
    @Published private(set) var network: NeuralNetwork?
    
    private init() {
        loadWeights()
    }
    
    private func loadWeights() {
        guard let bundleURL = Bundle.main.url(forResource: "trained_network", withExtension: "json") else {
            return
        }
        
        do {
            let data = try Data(contentsOf: bundleURL)
            self.network = try JSONDecoder().decode(NeuralNetwork.self, from: data)
        } catch { }
    }
    
    func neuralNetworkPredict(input: [Double]) -> Int {
        guard let network = network else {
            return -1
        }
        return network.neuralPredict(input: input)
    }
}
