//
//  AntAlgorithm.swift
//  TSUMap
//
//  Created by Сергей Лихачев on 09.04.2026.
//
import Foundation

class ACO {
    
    private let alpha: Double = 2.0
    private let beta: Double = 1.0
    private let Q: Double = 200.0
    private let evaporation: Double = 0.3
    
    private let points: [GridPoint]
    private var pheromones: [[Double]]
    private let grid: [[CellType]]
    private let size: Int
    private var distances: [[Int]]
    private var ants: [Ant] = []
    
    init(start: GridPoint, sightsForVisit: [Sight], grid: [[CellType]]) {
        self.points = [start] + sightsForVisit.map({$0.entryCord})
        
        self.size = self.points.count
        self.grid = grid
        self.pheromones = Array(repeating: Array(repeating: 1.0, count: size), count: size)
        self.distances = Array(repeating: Array(repeating: 0, count: size), count: size)
        
        initDistances()
    }
    
    private func createAnts() {
        for _ in 0..<size {
            ants.append(Ant(start: 0))
        }
    }
    
    public func optimalPath() -> [GridPoint] {
        if points.isEmpty {
            return []
        }
        var path: AntPath = AntPath(dist: Int.max)
        for _ in 1...100 {
            ants.removeAll()
            createAnts()
            
            for i in 0..<ants.count {
                while ants[i].canContinue {
                    ants[i].makeChoice(distances: distances, alpha: alpha, beta: beta, pheromone: pheromones)
                }
                
                let currentAntPath = ants[i].path
                
                if currentAntPath.dist < path.dist {
                    path = currentAntPath
                }
            }
            updatePheromone()
        }
        return createPath(path: path)
    }
    
    private func updatePheromone() {
        for i in 0..<size {
            for j in 0..<size {
                pheromones[i][j] *= (1 - evaporation)
            }
        }
        
        for i in 0..<ants.count {
            let currentPheromone = Q / Double(ants[i].path.dist)
            
            for k in 0..<(ants[i].path.places.count - 1) {
                let from = ants[i].path.places[k]
                let to = ants[i].path.places[k + 1]
                
                pheromones[from][to] += currentPheromone
                pheromones[to][from] += currentPheromone
            }
        }
    }
    private func initDistances() {
        for i in 0..<points.count {
            for j in i + 1..<points.count {
                let firstPoint = points[i]
                let secondPoint = points[j]
                let dist = AStar(graph: grid, start: firstPoint, end: secondPoint).count
                
                distances[i][j] = dist
                distances[j][i] = dist
            }
        }
    }
    
    private func createPath(path: AntPath) -> [GridPoint] {
        let start = points[path.places[0]]
        var intermediatePoint: [GridPoint] = []
        for i in path.places where i != 0 {
            intermediatePoint.append(points[i])
        }
        
        return AStar(graph: grid, start: start, points: intermediatePoint, end: start)
    }
}
