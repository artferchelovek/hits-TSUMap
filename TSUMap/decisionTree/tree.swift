//
//  tree.swift
//  TSUMap
//
//  Created by Екатерина Кондрашова on 20.03.2026.
//

import Foundation
import SwiftUI

struct Attribute {
    var location: String
    var budget: String
    var time_available: String
    var food_type: String
    var queue_tolerance: String
    var weather: String
    var recommended_place: String
}


func CVSParser(content: String) -> [Attribute] {
    var attributes: [Attribute] = []
    let rows = content.split(separator: "\n")
    
    for row in rows {
        let words = row.split(separator: ",")
        if words.count == 7 {
            let attribute = Attribute(
                location: words[0].trimmingCharacters(in: .whitespaces),
                budget: words[1].trimmingCharacters(in: .whitespaces),
                time_available: words[2].trimmingCharacters(in: .whitespaces),
                food_type: words[3].trimmingCharacters(in: .whitespaces),
                queue_tolerance: words[4].trimmingCharacters(in: .whitespaces),
                weather: words[5].trimmingCharacters(in: .whitespaces),
                recommended_place: words[6].trimmingCharacters(in: .whitespaces)
            )
            attributes.append(attribute)
        }
    }
    print("мяу")
    return attributes
}

func Entropy(_ data: [Attribute]) -> Double {
    var counts: [String: Double] = [:]
    for item in data {
        counts[ item.recommended_place, default: 0.0] += 1.0
    }
    
    let totalCount = Double(data.count)
    var entropy = 0.0
    for count in counts.values {
        let p = count / totalCount
        entropy -= p * log2(p)
    }
    return entropy
}

func getValue (from item: Attribute, for column: String) -> String {
    switch column {
    case "location": return item.location
    case "budget": return item.budget
    case "time_available": return item.time_available
    case "food_type": return item.food_type
    case "queue_tolerance": return item.queue_tolerance
    case "weather": return item.weather
    case "recommended_place": return item.recommended_place
    default: return ""
    }
}

func InformationGain(from data: [Attribute], for columnName: String) -> Double {
    let totalEntropy = Entropy(data)
    
    var groups: [String: [Attribute]] = [:]
    for item in data {
        let value = getValue(from: item, for: columnName)
        if groups[value] == nil {
            groups[value] = [item]
        } else {
            groups[value]?.append(item)
        }
    }
    var entropy = 0.0
    for group in groups.values {
        entropy += Entropy(group) * Double(group.count) / Double(data.count)
    }
    return totalEntropy - entropy
}

class Node {
    var attributeName : String?
    var children : [String: Node] = [:]
    var result : String?
    var defaultResult: String?
    
    init(attributeName: String, defaultResult: String? = nil) {
        self.attributeName = attributeName
        self.defaultResult = defaultResult
    }
    init (result: String) {
        self.result = result
    }
}

func buildTree(data: [Attribute], availableAttributes: [String]) -> Node {
    let element = data[0].recommended_place
    let allSame = data.allSatisfy{$0.recommended_place == element}
    if allSame {
        return Node(result: element)
    }
    
    var counts: [String: Int] = [:]
    for item in data {
        counts[item.recommended_place, default: 0] += 1
    }
    let mostCommon = counts.max(by: { $0.value < $1.value })!.key
       
    if availableAttributes.isEmpty {
        return Node(result: mostCommon)
    }
    
    var bestAttribute = ""
    var bestGain = -1.0
    for attribute in availableAttributes {
        let gain = InformationGain(from: data, for: attribute)
        if gain > bestGain {
            bestGain = gain
            bestAttribute = attribute
        }
    }
    
    let node = Node(attributeName: bestAttribute, defaultResult: mostCommon)
    let updatedAttribute = availableAttributes.filter{$0 != bestAttribute}
    
    var groups: [String: [Attribute]] = [:]
    for item in data {
        let value = getValue(from: item, for: bestAttribute)
        if groups[value] == nil {
            groups[value] = [item]
        } else {
            groups[value, default: []].append(item)
        }
    }
    
    for (branchValue, BranchData) in groups {
        let childNode = buildTree(data: BranchData, availableAttributes: updatedAttribute)
        node.children[branchValue] = childNode
    }
    return node
}

func predict(tree: Node, situation: Attribute) -> (result: String, path: [String]) {
    var currentNode = tree
    var path: [String] = []
    
    while currentNode.result == nil {
        guard let attribute = currentNode.attributeName else { break }
        let value = getValue(from: situation, for: attribute)
        
        path.append("Проверка [\(attribute)]: выбрано значение [\(value)]")
        
        if let nextNode = currentNode.children[value] {
            currentNode = nextNode
        } else {
            let fallback = currentNode.defaultResult ?? "Неизвестно"
            path.append("Ветка не найдена, используем наиболее вероятный вариант")
            return (fallback, path)
        }
    }
    
    let finalResult = currentNode.result ?? "Ошибка"
    return (finalResult, path)
}

