//
//  neuralEngine.swift
//  TSUMap
//
//  Created by Екатерина Кондрашова on 01.04.2026.
//
import Foundation

struct MathUtils {
    static func relu(_ x: Double) -> Double {
        return max(0, x)
    }
    static func reluDerivative(_ x: Double) -> Double {
        return x > 0 ? 1.0 : 0.0
    }
    static func softmax(_ Array: [Double]) -> [Double] {
        let maxVal = Array.max() ?? 0.0
        let expValues = Array.map { exp($0 - maxVal) }
        let sumExp = expValues.reduce(0.0, +)
        return expValues.map { $0 / sumExp }
    }
    static func dotProduct(_ inputs: [Double], _ weights: [[Double]], _ biases: [Double]) -> [Double] {
        var res = [Double](repeating: 0.0, count: biases.count)
        for i in 0..<biases.count {
            var sum = biases[i]
            for j in 0..<inputs.count {
                sum += inputs[j] * weights[i][j]
            }
            res[i] = sum
        }
        return res
    }
}

struct DenseLayer: Codable {
    var weights: [[Double]]
    var biases: [Double]
    var isOutputLayer: Bool
    
    var lastZ: [Double] = []
    var lastInputs: [Double] = []
    
    init(inputSize: Int, outputSize: Int, isOutput: Bool) {
        self.isOutputLayer = isOutput
        self.biases = Array(repeating: 0.0, count: outputSize)
        
        let limit = sqrt(6.0 / Double(inputSize + outputSize))
        self.weights = (0..<outputSize).map { _ in
            (0..<inputSize).map { _ in Double.random(in: -limit...limit) }
        }
    }
    
    mutating func forward(inputs: [Double]) -> [Double] {
        self.lastInputs = inputs
        let z = MathUtils.dotProduct(inputs, weights, biases)
        self.lastZ = z
        
        if isOutputLayer {
            return MathUtils.softmax(z)
        } else {
            return z.map { MathUtils.relu($0) }
        }
    }
}

struct NeuralNetwork: Codable {
    var hiddenLayer: DenseLayer
    var outputLayer: DenseLayer
    var learningRate: Double = 0.0005
    
    init(hiddenLayer: DenseLayer, outputLayer: DenseLayer) {
        self.hiddenLayer = hiddenLayer
        self.outputLayer = outputLayer
    }
    
    func predict(input: [Double]) -> Int {
        var mutableSelf = self
        let hOut = mutableSelf.hiddenLayer.forward(inputs: input)
        let fOut = mutableSelf.outputLayer.forward(inputs: hOut)
        
        if fOut.contains(where: { $0.isNaN }) {
            return -1
        }
        
        return fOut.enumerated().max(by: { $0.element < $1.element })?.offset ?? -1
    }
    
    mutating func train(input: [Double], target: [Double]) {
        let hOut = hiddenLayer.forward(inputs: input)
        let fOut = outputLayer.forward(inputs: hOut)
        
        var outputErrors = [Double](repeating: 0.0, count: target.count)
        for i in 0..<target.count {
            outputErrors[i] = fOut[i] - target[i]
        }
        
        for i in 0..<outputLayer.weights.count {
            for j in 0..<outputLayer.weights[i].count {
                var gradient = outputErrors[i] * hOut[j]
                gradient = max(-1.0, min(1.0, gradient))
                outputLayer.weights[i][j] -= learningRate * gradient
            }
            outputLayer.biases[i] -= learningRate * outputErrors[i]
        }
        
        var hiddenErrors = Array(repeating: 0.0, count: hOut.count)
        for j in 0..<hiddenLayer.weights.count {
            var error = 0.0
            for i in 0..<outputLayer.weights.count {
                error += outputErrors[i] * outputLayer.weights[i][j]
            }
            hiddenErrors[j] = error * MathUtils.reluDerivative(hiddenLayer.lastZ[j])
        }
        
        for i in 0..<hiddenLayer.weights.count {
            for j in 0..<hiddenLayer.weights[i].count {
                var gradient = hiddenErrors[i] * input[j]
                gradient = max(-1.0, min(1.0, gradient))
                hiddenLayer.weights[i][j] -= learningRate * gradient
            }
            hiddenLayer.biases[i] -= learningRate * hiddenErrors[i]
        }
    }
}

struct TrainingItem {
    let input: [Double]
    let target: [Double]
}

extension NeuralNetwork {
    static func makeOneHot(digit: Int) -> [Double] {
        var array = Array(repeating: 0.0, count: 10)
        if digit >= 0 && digit < 10 {
            array[digit] = 1.0
        }
        return array
    }
    
    mutating func trainEpochs(data: [TrainingItem], epochs: Int) {
        for epoch in 1...epochs {
            let shuffledData = data.shuffled()
            for item in shuffledData {
                self.train(input: item.input, target: item.target)
            }
        }
    }
}
