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
    static func randomGaussian() -> Double {
        return Double.random(in: -0.1...0.1)
    }
}

struct DenseLayer {
    var weights: [[Double]]
    var biases: [Double]
    var isOutputLayer: Bool
    
    var lastInputs: [Double] = []
    var lastZ: [Double] = []
    
    init(inputSize: Int, outputSize: Int, isOutput: Bool) {
        self.isOutputLayer = isOutput
        self.biases = Array(repeating: 0.0, count: outputSize)
        self.weights = (0..<outputSize).map {_ in ( 0..<inputSize).map {_ in MathUtils.randomGaussian() }
        }
    }
    
    mutating func forward(inputs: [Double]) -> [Double] {
        self.lastInputs = inputs
        let z = MathUtils.dotProduct(inputs, self.weights, self.biases)
        self.lastZ = z
        
        if isOutputLayer {
            return MathUtils.softmax(z)
        } else {
            return z.map {MathUtils.relu($0)}
        }
    }
}

struct NeuralNetwork {
    var hiddenLayer: DenseLayer
    var outputLayer: DenseLayer
    var learningRate: Double = 0.01
    
    func predict(input: [Double]) -> Int {
        var hiddenLayerCopy = hiddenLayer
        var outputLayerCopy = outputLayer
        
        let hiddenOutput = hiddenLayerCopy.forward(inputs: input)
        let finalOutput = outputLayerCopy.forward(inputs: hiddenOutput)
        
        guard let maxProbability = finalOutput.max(),
              let predictedDigit = finalOutput.firstIndex(of: maxProbability) else {
            return -1
        }
        return predictedDigit
    }
    
    mutating func train(input: [Double], target: [Double]) {
        let hOut = hiddenLayer.forward(inputs: input)
        let fOut = outputLayer.forward(inputs: hOut)
        
        var outputErrors = (0..<fOut.count).map {fOut[$0] - target[$0]}
        
        for i in 0..<outputLayer.weights.count {
            for j in 0..<outputLayer.weights[i].count {
                let gradient = outputErrors[i] * hOut[j]
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
                let gradient = hiddenErrors[j] * input[j]
                hiddenLayer.weights[i][j] -= learningRate * gradient
            }
            hiddenLayer.biases[i] -= learningRate * hiddenErrors[i]
        }
    }
}
