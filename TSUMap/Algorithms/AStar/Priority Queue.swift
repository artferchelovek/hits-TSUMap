//
//  Priority Queue.swift
//  TSUMap
//
//  Created by Сергей Лихачев on 05.04.2026.
//

struct PriorityQueue {
    private var elements: [AStarNode]
    private var priorityFunc: (AStarNode, AStarNode) -> Bool = {a, b in a < b}
    
    init(elements: [AStarNode] = []) {
        self.elements = elements
        buildHeap()
    }
    
    mutating func buildHeap() {
     for index in (0 ..< count / 2).reversed() {
     siftDown(parentInd: index)
     }
    }
    
    var count: Int {
        return elements.count
    }
    var isEmpty: Bool {
        return elements.isEmpty
    }

    private func leftChild(_ parentInd: Int) -> Int {
        return parentInd * 2 + 1
    }
    
    private func rightChild(_ parentInd: Int) -> Int {
        return parentInd * 2 + 2
    }
    
    private func parentInd(_ child: Int) -> Int {
        return (child - 1) / 2
    }
    
    public func first() -> AStarNode? {
        return elements.first
    }
    
    func isRoot(_ index: Int) -> Bool {
      return (index == 0)
    }
    
    func isHigherPriority(_ firstIndex: Int, _ secondIndex: Int) -> Bool {
      return priorityFunc(elements[firstIndex], elements[secondIndex])
    }
    
    func highestPriorityIndex(_ parentIndex: Int, _ childIndex: Int) -> Int {
      guard childIndex < count && isHigherPriority(childIndex, parentIndex)
        else { return parentIndex }
      return childIndex
    }
        
    func highestPriorityIndex(_ parent: Int) -> Int {
      return highestPriorityIndex(highestPriorityIndex(parent, leftChild(parent)), rightChild(parent))
    }
    
    mutating func swapElem(firstInd: Int, secondInd: Int) {
        guard firstInd != secondInd else { return }
        elements.swapAt(firstInd, secondInd)
    }
    mutating func siftUp(childInd: Int) {
        let parent: Int = parentInd(childInd)
        let proiority = isHigherPriority(childInd, parent)
        
        guard !isRoot(childInd) else {
            return
        }
        
        if proiority {
            swapElem(firstInd: childInd, secondInd: parent)
            siftUp(childInd: parent)
        } else {return}
    }
    
    mutating func siftDown(parentInd: Int) {
      let maxPriorityInd = highestPriorityIndex(parentInd)
        
        swapElem(firstInd: parentInd, secondInd: maxPriorityInd)
        if parentInd == maxPriorityInd {
            return
        }
        
        siftDown(parentInd: maxPriorityInd)
    }
    
    mutating func addElem(newElem: AStarNode) {
        elements.append(newElem)
        siftUp(childInd: count - 1)
    }
    
    mutating func pop() -> AStarNode? {
        guard !isEmpty else { return nil }
        swapElem(firstInd: 0, secondInd: count - 1)
        
        let element = elements.removeLast()
        
        if !isEmpty {
            siftDown(parentInd: 0)
        }
        return element
    }
}
