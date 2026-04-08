//
//  NeuralDenseLayer.swift
//  TSUMap
//
//  Created by Екатерина Кондрашова on 07.04.2026.
//
import Foundation

struct NeuralDenseLayer: Codable {
    let weights: [[Double]]
    let biases: [Double]
    let isOutputLayer: Bool
    
    func neuralForward(inputs: [Double]) -> [Double] {
        let z = NeuralMathUtils.dotProduct(inputs, weights, biases)
        
        if isOutputLayer {
            return NeuralMathUtils.softmax(z)
        } else {
            return z.map { NeuralMathUtils.relu($0) }
        }
    }
}
