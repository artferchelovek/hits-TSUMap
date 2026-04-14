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

    @ObservedObject var placeManager: PlaceManager

    @Binding var clusters: [Cluster]
    @Binding var startLocation: GridPoint?
    @Binding var endLocation: GridPoint?
    @Binding var intermediatePoints: [GridPoint]
    @Binding var paths: [GridPoint]

    var body: some View {
        VStack {
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

                Image(systemName: "xmark.circle")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .symbolEffect(.drawOn.individually, options: .nonRepeating, isActive: !isShowingList)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            searchText = ""
                            isShowingList = false
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)

            if isShowingList {
                VStack {
                    VStack(spacing: 10) {
                        Button {
                            self.clusters = placeManager.clustering(numberClusters: 5, typeClustering: .byStraight, data: Array(placeManager.cafes.values))
                            withAnimation(.spring()) {
                                isShowingList = false
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
                        .disabled(isBuildingRoute || startLocation == nil)
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
    }

    private func buildTouristRoute(with sights: [Sight]) {
        guard let start = startLocation else { return }

        isBuildingRoute = true
        withAnimation { isShowingList = false }

        let cellGrid = tsuCampusGrid.map { row in
            row.map { $0 == 1 ? CellType.obstacle : CellType.path }
        }

        let aco = ACO(start: start, sightsForVisit: sights, grid: cellGrid)
        let acoPath = aco.optimalPath()

        let visitedSightCoords = Set(sights.map(\.entryCord))
        var optimizedOrder: [GridPoint] = []

        for point in acoPath {
            if visitedSightCoords.contains(point) && !optimizedOrder.contains(point) {
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
                                    Image(systemName: selectedSights.contains(sight.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedSights.contains(sight.id) ? .blue : .secondary.opacity(0.3))
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

#Preview {
    FloatingSearchBar(
        placeManager: PlaceManager(),
        clusters: .constant([]),
        startLocation: .constant(GridPoint(row: 10, col: 10)),
        endLocation: .constant(nil),
        intermediatePoints: .constant([]),
        paths: .constant([])
    )
}
