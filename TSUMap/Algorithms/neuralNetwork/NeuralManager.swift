//
//  NeutalManager.swift
//  TSUMap
//
//  Created by Екатерина Кондрашова on 03.04.2026.
//
import Foundation
import SwiftUI
import Combine

class NeuralManager: ObservableObject {
    static let shared = NeuralManager()
    
    @Published var network: NeuralNetwork
    @Published var isTraining = false
    
    private let fileURL: URL
    
    private init() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        self.fileURL = paths[0].appendingPathComponent("trained_network.json")
        
        self.network = NeuralNetwork(
            hiddenLayer: DenseLayer(inputSize: 2500, outputSize: 128, isOutput: false),
            outputLayer: DenseLayer(inputSize: 128, outputSize: 10, isOutput: true)
        )
        
        loadWeights()
    }
    
    func saveWeights() {
        do {
            let data = try JSONEncoder().encode(network)
            try data.write(to: fileURL)
            print("Веса успешно сохранены!")
        } catch {
            print("Ошибка сохранения весов: \(error)")
        }
    }
    
    func loadWeights() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            self.network = try JSONDecoder().decode(NeuralNetwork.self, from: data)
            print("Обученная сеть успешно загружена из файла!")
        } catch {
            print("Ошибка загрузки весов: \(error)")
        }
    }
    
    func trainFromScratch() {
        self.isTraining = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let dataset = DatasetLoader.loadMNISTAndScale(fileName: "mnist_train")
            self.network.trainEpochs(data: dataset, epochs: 2)
            self.saveWeights()
            
            DispatchQueue.main.async {
                self.isTraining = false
            }
        }
    }
}
