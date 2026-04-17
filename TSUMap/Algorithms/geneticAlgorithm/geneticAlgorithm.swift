//
//  geneticAlgorithm.swift
//  TSUMap
//
//  Created by Екатерина Кондрашова on 12.04.2026.
//
import Foundation

class GeneticAlgorithm {
    var populationSize: Int = 50
    var mutationRate: Double = 0.1
    var generations: Int = 50

    var population: [Route] = []

    let allCafes: [Cafe]
    var aStarCache: AStarCash?
    let grid: [[CellType]]
    private var startDistances: [String: Int] = [:]

    var dishToCafes: [String: [Cafe]] = [:]

    private let penaltyDistance = 10000
    private let fitnessMultiplier = 10000.0

    init(cafes: [Cafe], grid: [[CellType]]) {
        allCafes = cafes
        self.grid = grid

        for cafe in cafes {
            for dish in cafe.dishes {
                dishToCafes[dish.name, default: []].append(cafe)
            }
        }
    }

    private func initStartDistances(startLocation: GridPoint) {
        startDistances.removeAll()
        for cafe in allCafes {
            let path = AStar(graph: grid, start: startLocation, end: cafe.entryCord)
            startDistances[cafe.id] = path.isEmpty ? penaltyDistance : path.count
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
        let currentStartTime = getCurrentTimeInMinutes()

        for i in 0 ..< population.count {
            var route = population[i]
            var totalCost = 0
            var simulatedTime = currentStartTime

            for j in 0 ..< route.cafesToVisit.count {
                let currentCafe = route.cafesToVisit[j]
                    
                guard let schedule = currentCafe.workSchedule[currentDay] else {
                    totalCost += penaltyDistance
                    continue
                }
                if schedule.isDayOff == true {
                    totalCost += penaltyDistance
                    continue
                }

                var distance = 0
                
                if j == 0 {
                    distance = startDistances[currentCafe.id] ?? penaltyDistance
                } else {
                    let prevCafe = route.cafesToVisit[j - 1]
                    if let cache = aStarCache {
                        distance = cache.getDistance(firstPlace: prevCafe, secondPlace: currentCafe)
                    } else {
                        let directPath = AStar(graph: grid, start: prevCafe.entryCord, end: currentCafe.entryCord)
                        distance = directPath.isEmpty ? penaltyDistance : directPath.count
                    }
                }

                let travelTime = calculateTravelTimeInMinutes(cellsCount: distance)
                simulatedTime += travelTime
                totalCost += distance

                let closeTime = parseTimeStringToMinutes(schedule.timeClose)
                    
                if simulatedTime > closeTime {
                    totalCost += penaltyDistance * 2
                }
            }
                
            route.fitness = fitnessMultiplier / Double(totalCost + 1)
            population[i] = route
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
        let dayIndex = Calendar.current.component(.weekday, from: Date())
        return WeekDay(calendarIndex: dayIndex)
    }
    
    private func getCurrentTimeInMinutes() -> Int {
            let date = Date()
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            return hour * 60 + minute
        }

    private func parseTimeStringToMinutes(_ timeComponents: DateComponents?) -> Int {
        guard let components = timeComponents else { return 24 * 60 }
            
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
            
        return hours * 60 + minutes
    }

    private func calculateTravelTimeInMinutes(cellsCount: Int) -> Int {
        let metersPerCell = 4.5
        let distanceMeters = Double(cellsCount) * metersPerCell
        let speedMetersPerMinute = 5000.0 / 60.0
        return Int(distanceMeters / speedMetersPerMinute)
    }

    func startEvolution(neededDishes: [Dish], userLocation: GridPoint, onProgressUpdate: (Route) -> Void) -> Route {
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
