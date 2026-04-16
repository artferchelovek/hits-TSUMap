//
//  geneticAlgorithm.swift
//  TSUMap
//
//  Created by Екатерина Кондрашова on 12.04.2026.
//
import Foundation

struct Route {
    var cafesToVisit: [Cafe]
    var fitness: Double
}

class GeneticAlgorithm {
    var populationSize: Int = 50
    var mutationRate: Double = 0.1
    var generations: Int = 100

    var population: [Route] = []

    let allCafes: [Cafe]
    var aStarCache: AStarCash?
    let grid: [[CellType]]
    private var startDistances: [String: Int] = [:]

    var dishToCafes: [String: [Cafe]] = [:]

    init(cafes: [Cafe], grid: [[CellType]]) {
        allCafes = cafes
        self.grid = grid

        for cafe in cafes {
            for dish in cafe.dishes {
                if dishToCafes[dish.name] != nil {
                    dishToCafes[dish.name]?.append(cafe)
                } else {
                    dishToCafes[dish.name] = [cafe]
                }
            }
        }
    }

    private func initStartDistances(startLocation: GridPoint) {
        startDistances.removeAll()
        for cafe in allCafes {
            let path = AStar(graph: grid, start: startLocation, end: cafe.entryCord)
            startDistances[cafe.id] = path.isEmpty ? 10000 : path.count
        }
    }

    private func generateInitialPopulation(neededDishes: [Dish]) {
        population.removeAll()

        for _ in 0 ..< populationSize {
            var randomPath: [Cafe] = []

            for dish in neededDishes {
                if let availableCafes = dishToCafes[dish.name], !availableCafes.isEmpty {
                    let randomCafe = availableCafes.randomElement()!
                    randomPath.append(randomCafe)
                }
            }

            population.append(Route(cafesToVisit: randomPath, fitness: 0.0))
        }
    }

    private func calculateFitnessForAll() {
        let currentDay = getCurrentWeekDay()

        for i in 0 ..< population.count {
            let route = population[i]
            var totalCost = 0.0

            var uniqueCafes: [Cafe] = []
            for cafe in route.cafesToVisit {
                if !uniqueCafes.contains(where: { $0.id == cafe.id }) {
                    uniqueCafes.append(cafe)
                }
            }

            if let firstCafe = uniqueCafes.first {
                let distToFirst = Double(startDistances[firstCafe.id] ?? 10000)
                totalCost += (distToFirst * 4.5) / 1.38
            }

            if uniqueCafes.count > 1 {
                for index in 0 ..< (uniqueCafes.count - 1) {
                    let cafeA = uniqueCafes[index]
                    let cafeB = uniqueCafes[index + 1]

                    let distance = Double(aStarCache?.getDistance(firstPlace: cafeA, secondPlace: cafeB) ?? 10000)

                    totalCost += (distance * 4.5) / 1.38

                    if cafeB.workSchedule[currentDay]?.isClosed == true {
                        totalCost += 100_000.0
                    }
                }
            }

            population[i].fitness = 10000.0 / (totalCost + 1.0)
        }
    }

    private func crossover(parent1: Route, parent2: Route) -> Route {
        let splitIndex = Int.random(in: 0 ..< parent1.cafesToVisit.count)
        var childCafes: [Cafe] = []

        for i in 0 ..< parent1.cafesToVisit.count {
            if i < splitIndex {
                childCafes.append(parent1.cafesToVisit[i])
            } else {
                childCafes.append(parent2.cafesToVisit[i])
            }
        }
        return Route(cafesToVisit: childCafes, fitness: 0.0)
    }

    private func mutate(route: inout Route, neededDishes: [Dish]) {
        if Double.random(in: 0 ... 1) < mutationRate {
            let mutateIndex = Int.random(in: 0 ..< route.cafesToVisit.count)
            let dishToMutate = neededDishes[mutateIndex]

            if let availableCafes = dishToCafes[dishToMutate.name] {
                let randomCafe = availableCafes.randomElement()!
                route.cafesToVisit[mutateIndex] = randomCafe
            }
        }
    }

    private func selectParent() -> Route {
        let contender1 = population.randomElement()!
        let contender2 = population.randomElement()!
        return contender1.fitness > contender2.fitness ? contender1 : contender2
    }
    
    private func getCurrentWeekDay() -> WeekDay {
        let calendar = Calendar.current
        let dayIndex = calendar.component(.weekday, from: Date())

        switch dayIndex {
        case 1: return .Sunday
        case 2: return .Monday
        case 3: return .Tuesday
        case 4: return .Wednesday
        case 5: return .Thursday
        case 6: return .Friday
        case 7: return .Saturday
        default: return .Monday
        }
    }

    func startEvolution(neededDishes: [Dish], userLocation: GridPoint, onProgressUpdate: @escaping (Route) -> Void) -> Route? {
        if neededDishes.isEmpty { return nil }

        initStartDistances(startLocation: userLocation)
        generateInitialPopulation(neededDishes: neededDishes)

        var bestRouteOverall = population[0]

        for _ in 1 ... generations {
            calculateFitnessForAll()

            var currentBest = population[0]
            for route in population {
                if route.fitness > currentBest.fitness {
                    currentBest = route
                }
            }

            if currentBest.fitness > bestRouteOverall.fitness {
                bestRouteOverall = currentBest
            }

            onProgressUpdate(bestRouteOverall)

            var newPopulation: [Route] = [bestRouteOverall]
            while newPopulation.count < populationSize {
                let parent1 = selectParent()
                let parent2 = selectParent()

                var child = crossover(parent1: parent1, parent2: parent2)
                mutate(route: &child, neededDishes: neededDishes)
                newPopulation.append(child)
            }
            population = newPopulation
        }

        return bestRouteOverall
    }
}
