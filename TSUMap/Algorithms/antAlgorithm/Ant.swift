//
//  Ant.swift
//  TSUMap
//
//  Created by Сергей Лихачев on 09.04.2026.
//
import Foundation

struct Ant {
    var path: AntPath
    var visited: [Int]
    var startPlace: Int
    var currentPlace: Int
    var canContinue: Bool
    
    init(start: Int) {
        startPlace = start
        visited = []
        currentPlace = startPlace
        path = AntPath()
        canContinue = true
    }
    
    func getNeighbors(amountPoints: Int) -> [Int] {
        var neighbors: [Int] = []
        for i in 0..<amountPoints where !visited.contains(i) {
                neighbors.append(i)
        }
        return neighbors
    }

    mutating func makeChoice(distances: [[Int]], alpha: Double, beta: Double, pheromone: [[Double]]) {
        if path.places.isEmpty {
            path.places.append(currentPlace)
            visited.append(currentPlace)
        }
        let neighbors = getNeighbors(amountPoints: distances.count)
        
        if neighbors.isEmpty {
            canContinue = false
            if currentPlace != startPlace {
                path.places.append(startPlace)
                path.dist += distances[currentPlace][startPlace]
            }
            return
        }
        
        var wish: [Double] = Array(repeating: 0.0, count: distances.count)
        var sumAllWish = 0.0
        
        for neighbor in neighbors {
             let pheromon = pheromone[currentPlace][neighbor]
             let dist = distances[currentPlace][neighbor]
            
            let n: Double = 1 / Double(dist)
            let currentWish = pow(n, alpha) * pow(pheromon, beta)
            wish[neighbor] = currentWish
            sumAllWish += currentWish
        }
        
        let choosingProb = Double.random(in: 0...1)
        var currentProb = 0.0
        var nextPlace = 0
        
        for neighbor in neighbors {
            currentProb += wish[neighbor] / sumAllWish
            if currentProb >= choosingProb {
                nextPlace = neighbor
                path.dist += distances[currentPlace][neighbor]
                self.currentPlace = nextPlace
                self.visited.append(nextPlace)
                self.path.places.append(nextPlace)
                return
            }
        }
    }
}
