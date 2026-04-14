//
//  NeuralNetwork.swift
//  TSUMap
//
//  Created by Екатерина Кондрашова on 07.04.2026.
//
import Foundation

struct NeuralNetwork: Codable {
    let hiddenLayer: NeuralDenseLayer
    let outputLayer: NeuralDenseLayer

    func neuralPredict(input: [Double]) -> Int {
        let hOut = hiddenLayer.neuralForward(inputs: input)
        let fOut = outputLayer.neuralForward(inputs: hOut)

        if fOut.contains(where: \.isNaN) {
            return -1
        }

        return fOut.enumerated().max(by: { $0.element < $1.element })?.offset ?? -1
    }
}
