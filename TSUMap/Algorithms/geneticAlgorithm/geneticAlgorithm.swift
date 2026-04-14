//
//  geneticAlgorithm.swift
//  TSUMap
//
//  Created by Екатерина Кондрашова on 12.04.2026.
//
import Foundation

struct RouteChromosome {
    var cafes: [Cafe]
    var fitness: Double = 0.0
    var totalTime: Double = 0.0
}

class FoodGeneticAlgorithm {
    
    private let startPoint: GridPoint
    private let desiredDishes: [Dish]
    private let allCafes: [Cafe]
    
    private let populationSize: Int
    private let generations: Int
    private let mutationRate: Double
    
    private let walkingSpeedKmH: Double = 5.0
    private let metersPerGridCell: Double = 10.0
    
    var onBestRouteUpdated: (([Cafe]) -> Void)?
    
    init(startPoint: GridPoint, desiredDishes: [Dish], allCafes: [Cafe], populationSize: Int = 50, generations: Int = 100, mutationRate: Double = 0.1) {
        self.startPoint = startPoint
        self.desiredDishes = desiredDishes
        self.allCafes = allCafes
        self.populationSize = populationSize
        self.generations = generations
        self.mutationRate = mutationRate
    }
    
    func findOptimalRoute() -> [Cafe] {
        let relevantCafes = filterRelevantCafes(for: desiredDishes, from: allCafes)
        
        guard !relevantCafes.isEmpty else { return [] }
        
        var population = generateInitialPopulation(cafes: relevantCafes)
        var globalBestRoute: RouteChromosome?
        
        for _ in 0..<generations {
            evaluatePopulation(&population)
            
            population.sort(by: { $0.fitness > $1.fitness })
            
            let currentBest = population.first!
            if globalBestRoute == nil || currentBest.fitness > globalBestRoute!.fitness {
                globalBestRoute = currentBest
            }
            
            if let best = globalBestRoute {
                onBestRouteUpdated?(best.cafes)
            }
            
            var newPopulation: [RouteChromosome] = [globalBestRoute!]
            
            while newPopulation.count < populationSize {
                let parent1 = selectParent(from: population)
                let parent2 = selectParent(from: population)
                var child = crossover(parent1: parent1, parent2: parent2)
                mutate(&child, availableCafes: relevantCafes)
                newPopulation.append(child)
            }
            
            population = newPopulation
        }
        
        return globalBestRoute?.cafes ?? []
    }
    
    private func generateInitialPopulation(cafes: [Cafe]) -> [RouteChromosome] {
        var population: [RouteChromosome] = []
        for _ in 0..<populationSize {
            let randomRoute = generateValidRandomRoute(from: cafes)
            population.append(RouteChromosome(cafes: randomRoute))
        }
        return population
    }
    
    private func generateValidRandomRoute(from cafes: [Cafe]) -> [Cafe] {
        var route: [Cafe] = []
        var unsatisfiedDishes = Set(desiredDishes)
        var availableCafes = cafes.shuffled()
        
        for cafe in availableCafes {
            if unsatisfiedDishes.isEmpty { break }
            let cafeDishes = Set(cafe.dishes)
            let intersection = unsatisfiedDishes.intersection(cafeDishes)
            
            if !intersection.isEmpty {
                route.append(cafe)
                unsatisfiedDishes.subtract(intersection)
            }
        }
        return route.shuffled()
    }
    
    private func evaluatePopulation(_ population: inout [RouteChromosome]) {
        for i in 0..<population.count {
            population[i].fitness = calculateFitness(for: population[i])
        }
    }
    
    private func calculateFitness(for route: RouteChromosome) -> Double {
        var totalMinutes: Double = 0.0
        var currentPoint = startPoint
        var penalty: Double = 0.0
        
        let startTime = Date()
        var collectedDishes = Set<String>()
        
        for cafe in route.cafes {
            let distanceMeters = calculateDistance(from: currentPoint, to: cafe.entryCord)
            let travelTime = distanceMeters / 83.3
            totalMinutes += travelTime
            
            let arrivalTime = startTime.addingTimeInterval(totalMinutes * 60)
            
            if isCafeClosed(cafe, at: arrivalTime) {
                penalty += 5000
            }
            
            let dishNames = cafe.dishes.map { $0.name }
            collectedDishes.formUnion(dishNames)
            
            currentPoint = cafe.entryCord
        }
        
        let desiredNames = Set(desiredDishes.map { $0.name })
        let missingCount = desiredNames.subtracting(collectedDishes).count
        
        if missingCount > 0 {
            penalty += Double(missingCount * 2000)
        }
        
        let totalCost = totalMinutes + penalty

        return 100000.0 / (totalCost + 1.0)
    }

    private func isCafeClosed(_ cafe: Cafe, at date: Date) -> Bool {
        let calendar = Calendar.current
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        dateFormatter.locale = Locale(identifier: "en_US")
        let dayName = dateFormatter.string(from: date)
        
        guard let weekDay = WeekDay(rawValue: dayName),
              let schedule = cafe.workSchedule[weekDay] else {
            return true
        }
        
        if schedule.isClosed { return true }
        
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let arrivalMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        
        let openMinutes = (schedule.timeEntry?.hour ?? 0) * 60 + (schedule.timeEntry?.minute ?? 0)
        let closeMinutes = (schedule.timeClose?.hour ?? 23) * 60 + (schedule.timeClose?.minute ?? 59)
        
        return arrivalMinutes < openMinutes || arrivalMinutes >= closeMinutes
    }
    
    private func selectParent(from population: [RouteChromosome]) -> RouteChromosome {
        let tournamentSize = 3
        var best: RouteChromosome?
        for _ in 0..<tournamentSize {
            let randomInd = population.randomElement()!
            if best == nil || randomInd.fitness > best!.fitness {
                best = randomInd
            }
        }
        return best!
    }
    
    private func crossover(parent1: RouteChromosome, parent2: RouteChromosome) -> RouteChromosome {
        guard parent1.cafes.count > 1, parent2.cafes.count > 1 else { return parent1 }
        
        let crossoverPoint = Int.random(in: 1..<min(parent1.cafes.count, parent2.cafes.count))
        let childCafes = Array(parent1.cafes.prefix(crossoverPoint) + parent2.cafes.suffix(from: crossoverPoint))
        
        return RouteChromosome(cafes: NSOrderedSet(array: childCafes).array as! [Cafe])
    }
    
    private func mutate(_ route: inout RouteChromosome, availableCafes: [Cafe]) {
        guard Double.random(in: 0..<1) < mutationRate else { return }
        
        if route.cafes.count > 1 && Bool.random() {
            let idx1 = Int.random(in: 0..<route.cafes.count)
            let idx2 = Int.random(in: 0..<route.cafes.count)
            route.cafes.swapAt(idx1, idx2)
        } else {
            if let randomCafe = availableCafes.randomElement(), !route.cafes.contains(where: { $0.id == randomCafe.id }) {
                route.cafes.append(randomCafe)
            }
        }
    }

    private func filterRelevantCafes(for dishes: [Dish], from cafes: [Cafe]) -> [Cafe] {
        let desiredDishNames = Set(dishes.map { $0.name })
        return cafes.filter { cafe in
            let cafeDishNames = Set(cafe.dishes.map { $0.name })
            return !cafeDishNames.isDisjoint(with: desiredDishNames)
        }
    }
    
    private func calculateDistance(from p1: GridPoint, to p2: GridPoint) -> Double {
        let dRow = Double(p1.row - p2.row)
        let dCol = Double(p1.col - p2.col)
        let cellsDistance = sqrt(dRow * dRow + dCol * dCol)
        return cellsDistance * metersPerGridCell
    }
}
