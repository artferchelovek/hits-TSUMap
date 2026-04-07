//
//  FloatingSearchBar.swift
//  TSUMap
//
//  Created by Artem on 04.04.2026.
//

import SwiftUI

private struct TempVenue: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let type: String
}

private let tempVenues: [TempVenue] = [
    TempVenue(name: "Ярче", icon: "person.crop.circle", type: "Еда"),
    TempVenue(name: "Кафе Минутка", icon: "pills", type: "Еда"),
    TempVenue(name: "Черничка", icon: "figure.roll", type: "Еда")
]

struct FloatingSearchBar: View {
    @State private var searchText: String = ""
    @State private var isShowingList = false
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                TextField("Найти коворкинг...", text: $searchText, onEditingChanged: { editing in
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
                    ForEach(tempVenues) { venue in
                        Button {
                            print(venue.name)
                            withAnimation { isShowingList = false }
                        } label: {
                            HStack {
                                Image(systemName: venue.icon)
                                Text(venue.name)
                                Spacer()
                                Text("230 м")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundColor(.primary)
                        .padding(.vertical, 5)
                        
                        if venue.id != tempVenues.last?.id {
                                        Divider()
                                    }
                    }
                    
                    VStack {
                        Button {
                            print("Кластеризация")
                        } label: {
                            HStack {
                                Image(systemName: "fork.knife")
                                Text("Определить зоны еды")
                                Spacer()
                            }
                        }
                    }.padding(.top, 10)
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
    }
}

#Preview {
    FloatingSearchBar()
}
