//
//  PlaceInfoView.swift
//  TSUMap
//
//  Created by Artem on 04.04.2026.
//

import SwiftUI

struct PlaceInfoView: View {
    @Environment(\.dismiss) var dismiss

    @State private var isShowingNeuralSheet = false

    let newPlace: any MapItem
    let placeManager: PlaceManager

    @Binding var currentDetent: PresentationDetent
    @Binding var endLocation: GridPoint?
    @Binding var intermediatePoints: [GridPoint]
    @Binding var clusters: [Cluster]

    fileprivate func PlaceInfo() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(newPlace.name)
                .font(.title)
                .bold()

            Text(newPlace.address)
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .symbolEffect(.appear.down.byLayer, options: .nonRepeating, isActive: false)

                Text("\(newPlace.rating, specifier: "%.1f")")
                    .fontWeight(.medium)

                Button {
                    isShowingNeuralSheet.toggle()
                } label: {
                    Text("Добавить оценку")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func menuSection(for cafe: Cafe) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Меню")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(cafe.dishes) { dish in
                    DishRow(dish: dish)
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            PlaceInfo()
                .padding(.top, 20)

            Divider()

            if currentDetent == .large {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if let cafe = newPlace as? Cafe, !cafe.dishes.isEmpty {
                            menuSection(for: cafe)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top)
                }
                .transition(.opacity)
            } else {
                Color.clear.frame(height: 20)
            }

            Spacer()

            PlaceFooter()
        }
        .padding(.horizontal)
        .padding(.vertical)
        .sheet(isPresented: $isShowingNeuralSheet) {
            NeuralView(
                place: .constant(newPlace),
                placeManager: placeManager,
                isPresented: $isShowingNeuralSheet
            )
            .presentationDragIndicator(.visible)
        }
    }
}

struct DishRow: View {
    let dish: Dish

    private var dishIcon: String {
        switch dish.type {
        case .breakfast: "sun.max.fill"
        case .lunch: "fork.knife"
        case .dinner: "fork.knife"
        case .drink: "cup.and.heat.waves.fill"
        case .snack: "bag.fill"
        case .desert: "star.fill"
        }
    }

    private var dishIconColor: Color {
        switch dish.type {
        case .breakfast: .orange
        case .lunch, .dinner: .green
        case .drink: .brown
        case .snack: .yellow
        case .desert: .pink
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: dishIcon)
                .font(.title2)
                .foregroundStyle(dishIconColor)
                .frame(width: 32, height: 32)
                .background(dishIconColor.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(dish.name)
                    .font(.body)
                Text("\(dish.price, specifier: "%.0f") ₽")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

private extension PlaceInfoView {
    func PlaceFooter() -> some View {
        HStack(spacing: 12) {
            if endLocation == nil {
                Button {
                    self.clusters = []
                    endLocation = newPlace.entryCord
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "figure.walk")
                        Text("Маршрут")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
            } else {
                Button {
                    intermediatePoints.append(newPlace.entryCord)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "plus.app")
                        Text("Зайти по пути")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
            }
        }
    }
}

#Preview {
    PlaceInfoView(
        newPlace: Cafe(
            tempId: "001",
            iconCord: GridPoint(row: 10, col: 10),
            entryCord: GridPoint(row: 11, col: 11),
            name: "Абрикос",
            type: PlaceType.cafe,
            address: "пр. Ленина, 36",
            rating: 4.8,
            dishes: [
                Dish(name: "Флэт уайт", price: 199, type: .drink),
                Dish(name: "Круассан с миндалём", price: 179, type: .breakfast),
                Dish(name: "Боул с лососем", price: 420, type: .lunch),
                Dish(name: "Тирамису", price: 280, type: .desert),
            ]
        ),
        placeManager: PlaceManager(),
        currentDetent: .constant(.large),
        endLocation: .constant(nil as GridPoint?),
        intermediatePoints: .constant([]),
        clusters: .constant([])
    )
}
