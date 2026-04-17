//
//  NeuralNetwork.swift
//  TSUMap
//
//  Created by Екатерина Кондрашова on 07.04.2026.
//
import Foundation

enum NeuralMathUtils {
    static func relu(_ x: Double) -> Double {
        max(0, x)
    }

    static func softmax(_ array: [Double]) -> [Double] {
        let maxVal = array.max() ?? 0.0
        let expVal = array.map { exp($0 - maxVal) }
        let sumExp = expVal.reduce(0.0, +)
        return expVal.map { $0 / sumExp }
    }

    static func dotProduct(_ inputs: [Double], _ weights: [[Double]], _ biases: [Double]) -> [Double] {
        var res = [Double](repeating: 0.0, count: biases.count)
        for i in 0 ..< biases.count {
            var sum = biases[i]
            for j in 0 ..< inputs.count {
                sum += inputs[j] * weights[i][j]
            }
            res[i] = sum
        }
        return res
    }
}

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
