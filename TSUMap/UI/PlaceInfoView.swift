//
//  PlaceInfoView.swift
//  TSUMap
//
//  Created by Artem on 04.04.2026.
//
import SwiftUI

private struct Place: Identifiable {
    var id: String
    var iconCord: GridPoint
    var entryCord: GridPoint
    var name: String
    var type: PlaceType
    var address: String
    var rating: Double
}

enum PlaceType: String, Hashable, Codable {
    case coffee
    case product
    case cafe
    
    func iconName() -> String {
        switch self {
        case .coffee: "cup.and.saucer.fill"
        case .cafe: "fork.knife"
        case .product: "basket"
        }
    }
}

private var newPlace: Place = .init(id: "001", iconCord: .init(row: 10, col: 10), entryCord: .init(row: 15, col: 21), name: "Абрикос", type: .cafe, address: "Московский тракт, 17", rating: 9.0)

struct PlaceInfoView: View {
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
                    print("добавить оценку")
                } label: {
                    Text("Добавить оценку")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    fileprivate func PlaceFooter() -> HStack<some View> {
        return HStack {
            Button {
                print("построить маршрут")
            } label: {
                HStack(alignment: .center) {
                    Image(systemName: "figure.walk")
                        .symbolEffect(.drawOn.individually, options: .nonRepeating, isActive: false)
                    Text("Маршрут")
                        .font(.title3)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PlaceInfo()
            
            Spacer()
            
            PlaceFooter()
        }
        .padding(.horizontal)
    }
}

#Preview {
    PlaceInfoView()
}
