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
    
    @State private var isShowingDecisionSheet = false
    
    @State private var treeNode: TreeNode?
    @State private var predictionResult: String?
    
    @StateObject var manager = VenueManager()
    
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
                            .font(.system(.title2, design: .rounded)).bold()
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                            .shadow(color: .black.opacity(0.1), radius: 4)
                        
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
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text("Где вы находитесь?")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                        .background(.regularMaterial)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.1), radius: 10)
                    } else {
                        HStack {
                            Button {
                                withAnimation(.spring()) {
                                    isShowingDecisionSheet.toggle()
                                }
                            } label: {
                                Text("Куда пойдём?").padding(.vertical, 6).padding(.horizontal, 20)
                            }
                            .buttonStyle(.glassProminent)
                            .sheet(isPresented: $isShowingDecisionSheet) {
                                DecisionTreeView(manager: manager, treeNode: treeNode) { prediction in
                                    self.predictionResult = prediction
                                }
                                .presentationDragIndicator(.visible)
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
        let data = manager.allAttributes
        
        guard !data.isEmpty else {
            print("Данных для построения дерева нет")
            return
        }
        
        let attributes = ["location", "budget", "time_available", "food_type", "queue_tolerance", "weather"]
        
        treeNode = buildTree(data: data, availableAttributes: attributes)
        
        print("Дерево перестроено на основе \(data.count) записей")
    }
}

#Preview {
    ContentView()
}
