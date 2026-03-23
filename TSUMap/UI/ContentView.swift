//
//  ContentView.swift
//  TSUMap
//
//  Created by Artem on 17.03.2026.
//

import SwiftUI

struct FloatingSearchBar: View {
    @State private var searchText: String = ""

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            TextField("Найти коворкинг...", text: $searchText)
                .font(.body)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
    }
}

struct ContentView: View {

    @State private var startLocation: GridPoint?
    @State private var endLocation: GridPoint?
    @State private var paths: [GridPoint] = []
    
    @State private var isShowingSheet = false
    
    @State private var treeNode: TreeNode?
    @State private var predictionResult: String?
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            CampusMapView(
                startLocation: $startLocation,
                endLocation: $endLocation,
                paths: $paths
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                if startLocation == nil {
                    HStack {
                        Text("TSUMap")
                            .font(.title)
                            .bold()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15))
                            .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)

                        Spacer()
                    }.transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    HStack {
                        FloatingSearchBar()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                VStack(spacing: 15) {
                    if startLocation == nil {
                        HStack {
                            Text("Укажите, где вы находитесь")
                                .font(.title2).bold()
                                .padding(.horizontal, 24).padding(.vertical, 10)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 30))
                                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
                        }
                    } else {
                        HStack {
                            Button {
                                withAnimation(.spring()) {
                                    isShowingSheet.toggle()
                                }
                            } label: {
                                Text("Куда пойдём?").padding(.vertical, 6).padding(.horizontal, 20)
                            }
                            .buttonStyle(.glassProminent)
                            .sheet(isPresented: $isShowingSheet) {
                                DecisionTreeView(treeNode: treeNode) { prediction in
                                    self.predictionResult = prediction
                                }
                            }

                            Button {
                                withAnimation(.spring()) {
                                    startLocation = nil
                                    endLocation = nil
                                    paths = []
                                    predictionResult = nil
                                }
                            } label: {
                                HStack {
                                    Text("Сбросить маршрут").font(.body).padding(.vertical, 6).padding(.horizontal, 20)
                                }
                            }.buttonStyle(.glass)
                        }
                    }
                }
            }
            .padding()
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: startLocation)
        }
        .onAppear {
            loadTree()
        }
    }
    
    private func loadTree() {
        guard let url = Bundle.main.url(forResource: "data", withExtension: "csv"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return
        }
        
        let data = CVSParser(content: content)
        let attributes = ["location", "budget", "time_available", "food_type", "queue_tolerance", "weather"]
        treeNode = buildTree(data: data, availableAttributes: attributes)
    }
}

#Preview {
    ContentView()
}
