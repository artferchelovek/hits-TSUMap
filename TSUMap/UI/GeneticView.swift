import SwiftUI

struct GeneticView: View {
    @ObservedObject var placeManager: PlaceManager
    let startLocation: GridPoint

    @Binding var intermediatePoints: [GridPoint]
    @Binding var paths: [GridPoint]
    @Binding var endLocation: GridPoint?
    @Binding var isPresented: Bool

    @State private var dishes: [DishType: [DishWithCafe]] = [:]
    @State private var selectedDishIds: Set<UUID> = []

    var sortedDishTypes: [DishType] {
        dishes.keys.sorted { $0.rawValue < $1.rawValue }
    }

    var selectedDishesObjects: [DishWithCafe] {
        dishes.values.flatMap(\.self).filter { selectedDishIds.contains($0.dish.id) }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(sortedDishTypes, id: \.self) { type in
                    Section(header: Text(type.rawValue.capitalized)) {
                        if let dishesInGroup = dishes[type] {
                            ForEach(dishesInGroup, id: \.dish.id) { item in
                                DishRowGA(item: item, isSelected: selectedDishIds.contains(item.dish.id)) {
                                    toggleSelection(for: item.dish.id)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Гастро-тур")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CartView(
                        selectedDishes: selectedDishesObjects,
                        placeManager: placeManager,
                        startLocation: startLocation,
                        intermediatePoints: $intermediatePoints,
                        paths: $paths,
                        endLocation: $endLocation,
                        isPresented: $isPresented
                    )) {
                        ToolbarCartButton(count: selectedDishIds.count)
                    }
                    .disabled(selectedDishIds.isEmpty)
                }
            }
        }
        .onAppear {
            dishes = placeManager.getAllDishesGroupedByType()
        }
    }

    private func toggleSelection(for id: UUID) {
        if selectedDishIds.contains(id) {
            selectedDishIds.remove(id)
        } else {
            selectedDishIds.insert(id)
        }
    }
}

struct ToolbarCartButton: View {
    let count: Int
    var body: some View {
        HStack {
            Text("Готово")
            if count > 0 {
                Text("\(count)")
                    .font(.caption2).bold()
                    .padding(6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
        }
    }
}

struct DishRowGA: View {
    let item: DishWithCafe
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.dish.name).font(.headline).foregroundColor(.primary)
                    Text(item.cafeName).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Text("\(item.dish.price, specifier: "%.0f") ₽")
                    .font(.subheadline).foregroundColor(.blue)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray)
                    .font(.title3)
                    .padding(.leading, 8)
            }
        }
    }
}

struct CartView: View {
    let selectedDishes: [DishWithCafe]
    @ObservedObject var placeManager: PlaceManager
    let startLocation: GridPoint

    @Binding var intermediatePoints: [GridPoint]
    @Binding var paths: [GridPoint]
    @Binding var endLocation: GridPoint?
    @Binding var isPresented: Bool

    @State private var bestRoute: Route?
    @State private var isCalculating = false
    @State private var hasRouteGenerated = false

    var body: some View {
        List {
            Section(header: Text("Выбранные блюда")) {
                ForEach(selectedDishes, id: \.dish.id) { item in
                    HStack {
                        Text(item.dish.name)
                        Spacer()
                        Text("\(item.dish.price, specifier: "%.0f") ₽")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if isCalculating {
                Section {
                    HStack {
                        ProgressView()
                        Text("Оптимизация маршрута...").padding(.leading)
                    }
                }
            }

            if let route = bestRoute {
                Section(header: Text("Оптимальный маршрут")) {
                    let uniqueCafes = route.cafesToVisit.reduce(into: [Cafe]()) { result, cafe in
                        if !result.contains(where: { $0.id == cafe.id }) {
                            result.append(cafe)
                        }
                    }

                    ForEach(0 ..< uniqueCafes.count, id: \.self) { index in
                        HStack {
                            Image(systemName: "\(index + 1).circle.fill")
                                .foregroundColor(.blue)

                            VStack(alignment: .leading) {
                                Text(uniqueCafes[index].name)
                                    .font(.headline)

                                let dishesHere = selectedDishes.filter { $0.cafeName == uniqueCafes[index].name }

                                if !dishesHere.isEmpty {
                                    Text(dishesHere.map(\.dish.name).joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            Button(action: runGeneticOptimization) {
                Text(buttonTitle)
            }
            .disabled(isCalculating || selectedDishes.isEmpty)
        }
        .navigationTitle("Корзина")
    }

    private var buttonTitle: String {
        if isCalculating {
            "Считаем..."
        } else if hasRouteGenerated {
            "Показать на карте"
        } else {
            "Построить маршрут"
        }
    }

    func runGeneticOptimization() {
        if hasRouteGenerated, let route = bestRoute {
            showRouteOnMap(route: route)
            return
        }

        isCalculating = true

        let dishesToProcess: [Dish] = selectedDishes.map(\.dish)
        let allWrappers = placeManager.getAllCafes().values

        let cafesToProcess: [Cafe] = allWrappers.compactMap { wrapper in
            (wrapper.item as Any) as? Cafe
        }

        let rawGrid: [[Int]] = tsuCampusGrid
        let processedGrid: [[CellType]] = rawGrid.map { row in
            row.map { $0 == 1 ? .obstacle : .path }
        }

        let userLoc = startLocation
        let cache = placeManager.getAStarCashe()

        DispatchQueue.global(qos: .userInitiated).async {
            let ga = GeneticAlgorithm(cafes: cafesToProcess, grid: processedGrid)
            ga.aStarCache = cache

            let result = ga.startEvolution(
                neededDishes: dishesToProcess,
                userLocation: userLoc,
                onProgressUpdate: { intermediateBest in
                    DispatchQueue.main.async { bestRoute = intermediateBest }
                }
            )

            DispatchQueue.main.async {
                bestRoute = result
                isCalculating = false
                hasRouteGenerated = true
            }
        }
    }

    private func showRouteOnMap(route: Route) {
        var uniqueCafes: [Cafe] = []
        var seenIds = Set<String>()

        for cafe in route.cafesToVisit {
            if !seenIds.contains(cafe.id) {
                seenIds.insert(cafe.id)
                uniqueCafes.append(cafe)
            }
        }

        let rawGrid: [[Int]] = tsuCampusGrid
        let processedGrid: [[CellType]] = rawGrid.map { row in
            row.map { $0 == 1 ? .obstacle : .path }
        }

        var fullPath: [GridPoint] = []
        var previousPoint = startLocation

        for cafe in uniqueCafes {
            let aStarPath = AStar(graph: processedGrid).aStarAlgorithm(start: previousPoint, end: cafe.entryCord)
            fullPath.append(contentsOf: aStarPath)
            previousPoint = cafe.entryCord
        }

        intermediatePoints = uniqueCafes.map(\.entryCord)
        paths = fullPath
        endLocation = uniqueCafes.last?.entryCord

        isPresented = false
    }
}

#Preview {
    GeneticView(
        placeManager: PlaceManager(),
        startLocation: GridPoint(row: 0, col: 0),
        intermediatePoints: .constant([]),
        paths: .constant([]),
        endLocation: .constant(nil),
        isPresented: .constant(true)
    )
}
