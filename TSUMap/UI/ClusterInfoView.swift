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
    @Binding var selectedPlace: Place?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Всего: \(cluster.placesInClust.count)")) {
                    ForEach(cluster.placesInClust) { place in
                        PlaceRow(place: place)
                            .onTapGesture {
                                dismiss()
                                selectedPlace = place
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
    let place: Place
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
    let mockMedoid = Place(
        id: "1",
        iconCord: GridPoint(row: 10, col: 10),
        entryCord: GridPoint(row: 11, col: 11),
        name: "Кофейня Абрикос",
        type: .coffee,
        address: "пр. Ленина, 36",
        rating: 4.8
    )
    
    let mockPlace2 = Place(
        id: "2",
        iconCord: GridPoint(row: 12, col: 12),
        entryCord: GridPoint(row: 13, col: 13),
        name: "Столовая ТГУ",
        type: .cafe,
        address: "Научная библиотека",
        rating: 4.2
    )
    
    let sampleCluster = Cluster(medoid: mockMedoid, color: .blue)
    sampleCluster.placesInClust = [mockMedoid, mockPlace2]
    
    return ClusterInfoView(cluster: sampleCluster,
                           selectedPlace: .constant(nil as Place?))
}
