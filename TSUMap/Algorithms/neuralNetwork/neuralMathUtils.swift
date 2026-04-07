//
//  MathUtilsForNeural.swift
//  TSUMap
//
//  Created by Екатерина Кондрашова on 07.04.2026.
//
import Foundation

struct NeuralMathUtils {
    static func relu(_ x: Double) -> Double {
        return max(0, x)
    }
    
    static func softmax(_ array: [Double]) -> [Double] {
        let maxVal = array.max() ?? 0.0
        let expVal = array.map { exp($0 - maxVal) }
        let sumExp = expVal.reduce(0.0, +)
        return expVal.map { $0 / sumExp }
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
