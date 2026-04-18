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
    
    static func oneHot(target: Int, count: Int) -> [Double] {
        var res = [Double](repeating: 0.0, count: count)
        res[target] = 1.0
        return res
    }
}

struct NeuralDenseLayer: Codable {
    var weights: [[Double]]
    var biases: [Double]
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
    var hiddenLayer: NeuralDenseLayer
    var outputLayer: NeuralDenseLayer

    func neuralPredict(input: [Double]) -> Int {
        let hOut = hiddenLayer.neuralForward(inputs: input)
        let fOut = outputLayer.neuralForward(inputs: hOut)

        if fOut.contains(where: \.isNaN) {
            return -1
        }

        return fOut.enumerated().max(by: { $0.element < $1.element })?.offset ?? -1
    }
    
    mutating func train(input: [Double], targetLabel: Int, learningRate: Double) {
            
        var hiddenZ = [Double](repeating: 0.0, count: hiddenLayer.biases.count)
        var hiddenA = [Double](repeating: 0.0, count: hiddenLayer.biases.count)
            
        for i in 0..<hiddenLayer.biases.count {
            var sum = hiddenLayer.biases[i]
            for j in 0..<input.count {
                sum += input[j] * hiddenLayer.weights[i][j]
            }
            hiddenZ[i] = sum
            hiddenA[i] = NeuralMathUtils.relu(sum)
        }

        var outputZ = [Double](repeating: 0.0, count: outputLayer.biases.count)
        
        for i in 0..<outputLayer.biases.count {
            var sum = outputLayer.biases[i]
            for j in 0..<hiddenA.count {
                sum += hiddenA[j] * outputLayer.weights[i][j]
            }
            outputZ[i] = sum
        }
        let outputA = NeuralMathUtils.softmax(outputZ)

        
        let targetVector = NeuralMathUtils.oneHot(target: targetLabel, count: outputLayer.biases.count)
            
        var outputDeltas = [Double](repeating: 0.0, count: outputLayer.biases.count)
        for i in 0..<outputLayer.biases.count {
            outputDeltas[i] = outputA[i] - targetVector[i]
        }

        var hiddenDeltas = [Double](repeating: 0.0, count: hiddenLayer.biases.count)
        for i in 0..<hiddenLayer.biases.count {
            var error = 0.0
            for k in 0..<outputLayer.biases.count {
                error += outputDeltas[k] * outputLayer.weights[k][i]
            }
            hiddenDeltas[i] = error * NeuralMathUtils.relu(hiddenZ[i])
        }


        for i in 0..<outputLayer.biases.count {
            outputLayer.biases[i] -= learningRate * outputDeltas[i]
            for j in 0..<hiddenA.count {
                outputLayer.weights[i][j] -= learningRate * outputDeltas[i] * hiddenA[j]
            }
        }

        for i in 0..<hiddenLayer.biases.count {
            hiddenLayer.biases[i] -= learningRate * hiddenDeltas[i]
            for j in 0..<input.count {
                hiddenLayer.weights[i][j] -= learningRate * hiddenDeltas[i] * input[j]
            }
        }
    }
}
