//
//  ClusterInfoView.swift
//  TSUMap
//
//  Created by Artem on 07.04.2026.
//

import SwiftUI

struct ClusterInfoView: View {
    @Environment(\.dismiss) var dismiss
    
    let cluster: Cluster
    @Binding var selectedPlace: IdentifiableItem?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Всего: \(cluster.placesInClust.count)")) {
                    ForEach(cluster.placesInClust) { place in
                        PlaceRow(place: place)
                            .onTapGesture {
                                dismiss()
                                selectedPlace = IdentifiableItem(item: place)
                            }
                    }
                }
            }
            .navigationTitle(Text("Заведения в этом районе"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PlaceRow: View {
    let place: Cafe
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(place.name).font(.headline)
                Text(place.address).font(.caption).foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    let mockTime = Time(hour: 9, minute: 0)
    let mockDishes: [Dish] = []

    let mockMedoid = Cafe(
        tempId: "001",
        iconCord: GridPoint(row: 10, col: 10),
        entryCord: GridPoint(row: 11, col: 11),
        name: "Кофейня Абрикос",
        type: PlaceType.coffee,
        address: "пр. Ленина, 36",
        rating: 4.8,
        timeEntry: mockTime,
        timeClose: mockTime,
        dishes: mockDishes
    )

    let mockPlace2 = Cafe(
        tempId: "2",
        iconCord: GridPoint(row: 12, col: 12),
        entryCord: GridPoint(row: 13, col: 13),
        name: "Столовая ТГУ",
        type: .cafe,
        address: "пр. Ленина, 36",
        rating: 4.2,
        timeEntry: mockTime,
        timeClose: mockTime,
        dishes: []
    )
    
    let sampleCluster = Cluster(medoid: mockMedoid, color: .blue)
    sampleCluster.placesInClust = [mockMedoid, mockPlace2]
    
    return ClusterInfoView(cluster: sampleCluster,
                           selectedPlace: .constant(nil as IdentifiableItem?))
}
