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

    let newPlace: (any MapItem)
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
    
    fileprivate func ExpandedContent() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
            Text("О заведении")
                .font(.headline)
            Text("тут будет дикий флекс с меню")
                .foregroundColor(.secondary)
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 150)
                .overlay(Text("Здесь будет фото булочки из ярче").foregroundColor(.secondary))
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 150)
                .overlay(Text("а здесь фото шаурмы из безумно").foregroundColor(.secondary))
        }
        .padding(.top)
    }
    
    fileprivate func PlaceFooter() -> some View {
        HStack {
            if endLocation == nil {
                Button {
                    self.clusters = []
                    endLocation = newPlace.entryCord
                    dismiss()
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
            } else {
                Button {
                    intermediatePoints.append(newPlace.entryCord)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "plus.app")
                        Text("Зайти по пути")
                            .font(.title3)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            PlaceInfo()
                .padding(.top, 20)
            
            if currentDetent == .large {
                ScrollView {
                    ExpandedContent()
                }
                .transition(.opacity)
                
                Spacer()
            } else {
                Color.clear.frame(height: 20)
            }
            
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

#Preview {
    PlaceInfoView(newPlace: Cafe(
        tempId: "001",
        iconCord: GridPoint(row: 10, col: 10),
        entryCord: GridPoint(row: 11, col: 11),
        name: "Абрикос",
        type: PlaceType.coffee,
        address: "пр. Ленина, 36",
        rating: 4.8,
        dishes: []
    ),
                  placeManager: PlaceManager(),
                  currentDetent: .constant(.large),
                  endLocation: .constant(nil as GridPoint?),
                  intermediatePoints: .constant([]),
                  clusters: .constant([]),
    )
}
