//
//  tree.swift
//  TSUMap
//
//  Created by Екатерина Кондрашова on 20.03.2026.
//

import Foundation

class TreeNode {
    var attributeName: String?
    var children: [String: TreeNode] = [:]
    var result: String?
    var defaultResult: String?

    init(attributeName: String, defaultResult: String? = nil) {
        self.attributeName = attributeName
        self.defaultResult = defaultResult
    }

    init(result: String) {
        self.result = result
    }
}

private func Entropy(_ data: [TreeAttribute]) -> Double {
    var counts: [String: Double] = [:]
    for item in data {
        counts[item.recommended_place, default: 0.0] += 1.0
    }

    let totalCount = Double(data.count)
    var entropy = 0.0
    for count in counts.values {
        let p = count / totalCount
        entropy -= p * log2(p)
    }
    return entropy
}

private func InformationGain(from data: [TreeAttribute], for columnName: String) -> Double {
    let totalEntropy = Entropy(data)

    var groups: [String: [TreeAttribute]] = [:]
    for item in data {
        let value = getTreeAttribute(from: item, for: columnName)
        groups[value, default: []].append(item)
    }
    var entropy = 0.0
    for group in groups.values {
        entropy += Entropy(group) * Double(group.count) / Double(data.count)
    }
    return totalEntropy - entropy
}

func buildTree(data: [TreeAttribute], availableAttributes: [String], minInfoGain: Double = 0.05) -> TreeNode {
    let element = data[0].recommended_place
    let allSame = data.allSatisfy { $0.recommended_place == element }
    if allSame {
        return TreeNode(result: element)
    }

    var counts: [String: Int] = [:]
    for item in data {
        counts[item.recommended_place, default: 0] += 1
    }
    let mostCommon = counts.max(by: { $0.value < $1.value })!.key

    if availableAttributes.isEmpty {
        return TreeNode(result: mostCommon)
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

    if bestGain < minInfoGain {
        return TreeNode(result: mostCommon)
    }

    let node = TreeNode(attributeName: bestAttribute, defaultResult: mostCommon)
    let updatedAttribute = availableAttributes.filter { $0 != bestAttribute }

    var groups: [String: [TreeAttribute]] = [:]
    for item in data {
        let value = getTreeAttribute(from: item, for: bestAttribute)
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

func predictTree(tree: TreeNode, situation: TreeAttribute) -> (result: String, path: [TreeNode]) {
    var currentNode = tree
    var path: [TreeNode] = []

    while currentNode.result == nil {
        path.append(currentNode)

        guard let attribute = currentNode.attributeName else { break }
        let value = getTreeAttribute(from: situation, for: attribute)

        if let nextNode = currentNode.children[value] {
            currentNode = nextNode
        } else {
            let fallback = currentNode.defaultResult ?? "Неизвестно"
            return (fallback, path)
        }
    }
    path.append(currentNode)
    let finalResult = currentNode.result ?? "Ошибка"
    return (finalResult, path)
}
