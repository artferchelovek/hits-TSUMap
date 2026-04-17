///
///  TreeSession.swift
///  TSUMap
///
///  Created by Екатерина Кондрашова on 17.04.2026.
///
class TreeSession {
    var currentNode: TreeNode
    var path: [TreeNode] = []
    var rootTree: TreeNode

    init(tree: TreeNode) {
        rootTree = tree
        currentNode = tree
        path = [tree]
    }

    func getNextQuestion() -> String? {
        if currentNode.result == nil {
            currentNode.attributeName
        } else {
            nil
        }
    }

    func getFinalResult() -> String? {
        currentNode.result
    }

    func provideAnswer(answer: String) {
        if currentNode.result != nil {
            return
        }

        let nextNode = currentNode.children[answer]

        if nextNode != nil {
            currentNode = nextNode!
        } else {
            let fallback = currentNode.defaultResult
            if fallback != nil {
                currentNode = TreeNode(result: fallback!)
            } else {
                currentNode = TreeNode(result: "Неизвестно")
            }
        }
        path.append(currentNode)
    }
}
