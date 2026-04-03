//
//  DatasetLoader.swift
//  TSUMap
//
//  Created by Екатерина Кондрашова on 03.04.2026.
//

import Foundation

class DatasetLoader {
    
    static func loadMNISTAndScale(fileName: String) -> [TrainingItem] {
        var dataset: [TrainingItem] = []
        
        guard let filePath = Bundle.main.path(forResource: fileName, ofType: "csv") else {
            return []
        }
        do {
            let data = try String(contentsOfFile: filePath)
            let rows = data.components(separatedBy: .newlines)
            
            for row in rows {
                let values = row.components(separatedBy: ",")
                
                if values.count >= 785 {
                    guard let labelInt = Int(values[0]) else { continue }
                    let target = NeuralNetwork.makeOneHot(digit: labelInt)
                    let pixels28x28 = values[1...784].compactMap { Double($0) }.map { $0 / 255.0 }
                    var pixels50x50 = Array(repeating: 0.0, count: 2500)
                    
                    for row50 in 0..<50 {
                        for col50 in 0..<50 {
                            let row28 = Int(Double(row50) * 28.0 / 50.0)
                            let col28 = Int(Double(col50) * 28.0 / 50.0)
                            
                            let index50 = row50 * 50 + col50
                            let index28 = row28 * 28 + col28
                            
                            pixels50x50[index50] = pixels28x28[index28]
                        }
                    }
                    let item = TrainingItem(input: pixels50x50, target: target)
                    dataset.append(item)
                }
            }
        } catch {
            return []
        }
        return dataset
    }
}
