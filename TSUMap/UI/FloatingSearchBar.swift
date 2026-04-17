//
//  FloatingSearchBar.swift
//  TSUMap
//
//  Created by Artem on 04.04.2026.
//

import SwiftUI

struct FloatingSearchBar: View {
    @State private var searchText: String = ""
    @State private var isShowingList = false
    @State private var isShowingSightSelection = false
    @State private var selectedSights: Set<String> = []
    @State private var isBuildingRoute = false
    @State private var isShowingGA = false

    @ObservedObject var placeManager: PlaceManager
    @ObservedObject var settingsManager: SettingsManager

    @Binding var clusters: [Cluster]
    @Binding var startLocation: GridPoint?
    @Binding var endLocation: GridPoint?
    @Binding var intermediatePoints: [GridPoint]
    @Binding var paths: [GridPoint]
    @Binding var isShowSettings: Bool

    private var searchResults: [any MapItem] {
        guard !searchText.isEmpty else { return [] }

        let query = searchText.lowercased()
        var results: [any MapItem] = []

        for cafe in placeManager.cafes.values {
            if cafe.name.lowercased().contains(query) || cafe.address.lowercased().contains(query) {
                results.append(cafe)
            }
        }

        for coworking in placeManager.coworkings.values {
            if coworking.name.lowercased().contains(query) || coworking.address.lowercased().contains(query) {
                results.append(coworking)
            }
        }

        for sight in placeManager.sights.values {
            if sight.name.lowercased().contains(query) || sight.address.lowercased().contains(query) {
                results.append(sight)
            }
        }

        return Array(results.prefix(20))
    }

    var body: some View {
        VStack {
            HStack(spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    TextField("Поиск места...", text: $searchText, onEditingChanged: { editing in
                        if editing {
                            withAnimation(.spring()) {
                                isShowingList = true
                            }
                        }
                    })
                    .font(.body)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                    if !searchText.isEmpty {
                        Image(systemName: "xmark.circle")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    searchText = ""
                                }
                            }
                    } else if !isShowingList {
                        Image(systemName: "xmark.circle")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .symbolEffect(.drawOn.individually, options: .nonRepeating, isActive: !isShowingList)
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    searchText = ""
                                    isShowingList = false
                                    UIApplication.shared.sendAction(
                                        #selector(UIResponder.resignFirstResponder),
                                        to: nil,
                                        from: nil,
                                        for: nil
                                    )
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.regularMaterial, in: Capsule())
                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)

                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        isShowSettings.toggle()
                    }
                } label: {
                    Image(systemName: "gear")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(isShowSettings ? 90 : 0))
                }
                .background(.regularMaterial, in: Circle())
                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
            }

            if isShowingList {
                VStack(spacing: 5) {
                    if !searchText.isEmpty, !searchResults.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: 5) {
                                ForEach(searchResults, id: \.id) { item in
                                    SearchResultRow(item: item) {
                                        selectPlace(item)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 250)
                    } else if !searchText.isEmpty, searchResults.isEmpty {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            Text("Ничего не найдено")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }

                    VStack(spacing: 10) {
                        Button {
                            clusters = placeManager.clustering(
                                numberClusters: 5,
                                typeClustering: settingsManager.clusterType,
                                typeAlgorithm: settingsManager.clusterAlgorithm,
                                data: Array(placeManager.cafes.values)
                            )
                            withAnimation(.spring()) {
                                isShowingList = false
                                UIApplication.shared.sendAction(
                                    #selector(UIResponder.resignFirstResponder),
                                    to: nil,
                                    from: nil,
                                    for: nil
                                )
                            }
                        } label: {
                            HStack {
                                Image(systemName: "fork.knife")
                                    .foregroundStyle(.orange)
                                Text("Определить зоны еды")
                                Spacer()
                            }
                        }
                        .disabled(isBuildingRoute)

                        Button {
                            selectedSights = Set(placeManager.sights.values.map(\.id))
                            isShowingSightSelection = true
                        } label: {
                            HStack {
                                Image(systemName: "figure.walk")
                                    .foregroundStyle(.blue)
                                Text("Построить туристический маршрут")
                                Spacer()
                            }
                        }
                        .disabled(isBuildingRoute)

                        Button {
                            isShowingGA.toggle()
                        } label: {
                            Image(systemName: "figure.walk")
                            Text("Гастро-тур")
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(.regularMaterial)
                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
                .cornerRadius(20)
                .transition(.move(edge: .top).combined(with: .blurReplace))
            }
        }
        .sheet(isPresented: $isShowingSightSelection) {
            SightSelectionView(
                sights: Array(placeManager.sights.values),
                selectedSights: $selectedSights,
                isBuildingRoute: $isBuildingRoute
            ) { selected in
                buildTouristRoute(with: selected)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingGA) {
            GeneticView(
                placeManager: placeManager,
                startLocation: startLocation ?? GridPoint(row: 10, col: 10),
                intermediatePoints: $intermediatePoints,
                paths: $paths,
                endLocation: $endLocation,
                isPresented: $isShowingGA
            )
        }
    }

    private func buildTouristRoute(with sights: [Sight]) {
        guard let startLocation else { return }
        let start = findNearestPathPoint(from: startLocation)

        isBuildingRoute = true
        withAnimation { isShowingList = false }

        let aco = ACO(start: start, sightsForVisit: sights, grid: loadedGrid)
        let acoPath = aco.optimalPath()

        let visitedSightCoords = Set(sights.map(\.entryCord))
        var optimizedOrder: [GridPoint] = []

        for point in acoPath {
            if visitedSightCoords.contains(point), !optimizedOrder.contains(point) {
                optimizedOrder.append(point)
            }
        }

        withAnimation(.spring()) {
            paths = []
            intermediatePoints = optimizedOrder
            endLocation = start
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isBuildingRoute = false
        }
    }

    private func selectPlace(_ item: any MapItem) {
        withAnimation(.spring()) {
            searchText = ""
            isShowingList = false
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }

        let gridPoint = findNearestPathPoint(from: item.entryCord)

        if startLocation == nil {
            startLocation = gridPoint
        } else {
            endLocation = gridPoint
        }
    }
}

struct SightSelectionView: View {
    @Environment(\.dismiss) var dismiss

    let sights: [Sight]
    @Binding var selectedSights: Set<String>
    @Binding var isBuildingRoute: Bool
    let onConfirm: ([Sight]) -> Void

    private var selectedSightsList: [Sight] {
        sights.filter { selectedSights.contains($0.id) }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    Section(header: Text("Достопримечательности")) {
                        ForEach(sights) { sight in
                            Button {
                                if selectedSights.contains(sight.id) {
                                    selectedSights.remove(sight.id)
                                } else {
                                    selectedSights.insert(sight.id)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: selectedSights
                                        .contains(sight.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedSights.contains(sight.id) ? .blue : .secondary
                                            .opacity(0.3))
                                        .font(.title3)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(sight.name)
                                            .font(.body)
                                            .foregroundStyle(selectedSights.contains(sight.id) ? .blue : .primary)
                                        Text(sight.address)
                                            .font(.caption)
                                            .foregroundStyle(selectedSights.contains(sight.id) ? .blue : .secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)

                if !selectedSightsList.isEmpty {
                    Button {
                        onConfirm(selectedSightsList)
                        dismiss()
                    } label: {
                        HStack {
                            if isBuildingRoute {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "map")
                            }
                            Text("Построить маршрут (\(selectedSights.count))")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(isBuildingRoute)
                    .padding()
                }
            }
            .navigationTitle("Выберите места")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if selectedSights.count == sights.count {
                            selectedSights = []
                        } else {
                            selectedSights = Set(sights.map(\.id))
                        }
                    } label: {
                        Text(selectedSights.count == sights.count ? "Снять все" : "Выбрать все")
                    }
                }
            }
        }
    }
}

struct SearchResultRow: View {
    let item: any MapItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                Image(systemName: item.type.iconName())
                    .foregroundStyle(iconColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.body)
                        .foregroundStyle(iconColor)
                        .lineLimit(1)
                    Text(item.address)
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }

    private var iconColor: Color {
        switch item.type {
        case .coffee: .orange
        case .cafe: .red
        case .product: .green
        case .sight: .purple
        case .coworkingSpace: .blue
        }
    }
}

#Preview {
    FloatingSearchBar(
        placeManager: PlaceManager(),
        settingsManager: SettingsManager(),
        clusters: .constant([]),
        startLocation: .constant(GridPoint(row: 10, col: 10)),
        endLocation: .constant(GridPoint(row: 11, col: 10)),
        intermediatePoints: .constant([]),
        paths: .constant([]),
        isShowSettings: .constant(false)
    )
}
