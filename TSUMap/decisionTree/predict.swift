import Foundation

func predict(tree: Node, situation: Attribute) -> (result: String, path: [Node]) {
    var currentNode = tree
    var path: [Node] = []
    
    while currentNode.result == nil {
        path.append(currentNode)
        
        guard let attribute = currentNode.attributeName else { break }
        let value = getValue(from: situation, for: attribute)
        
        if let nextNode = currentNode.children[value] {
            currentNode = nextNode
        }
        else {
            let fallback = currentNode.defaultResult ?? "Неизвестно"
            return (fallback, path)
        }
    }
    path.append(currentNode
    )
    let finalResult = currentNode.result ?? "Ошибка"
    return (finalResult, path)
}
