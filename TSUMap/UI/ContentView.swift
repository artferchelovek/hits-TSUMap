//
//  ContentView.swift
//  TSUMap
//
//  Created by Artem on 17.03.2026.
//

import SwiftUI

struct IdentifiableItem: Identifiable {
    var item: any MapItem
    var id: String {item.id}
}
struct ContentView: View {
    
    @State private var startLocation: GridPoint?
    @State private var endLocation: GridPoint?
    @State private var intermediatePoints: [GridPoint] = []
    @State private var paths: [GridPoint] = []
    @State private var isShowingDecisionSheet = false
    @State private var selectedPlace: IdentifiableItem?
    @State private var selectedCluster: Cluster?
    @State private var sheetDetent: PresentationDetent = .height(180)
    
    @State private var clusters: [Cluster] = []
    
    @State private var treeNode: TreeNode?
    @State private var predictionResult: String?
    
    @State private var animatePlusMinus = true
    
    @StateObject var manager = VenueManager()
    @StateObject var placeManager = PlaceManager()
    
    fileprivate func PathsView() -> some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Маршрут построен")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Text("\(Double(paths.count) * AppConfig.cellScale / 83, specifier: "%.0f") мин")
                            .font(.title2).bold()
                        Spacer()
                        HStack {
                            Image(systemName: "plusminus")
                                .symbolEffect(.drawOn.individually,
                                              options: .nonRepeating,
                                              isActive: animatePlusMinus)
                                .font(.title2)
                                .foregroundStyle(Color.primary)
                            Text("\(Double(paths.count) * AppConfig.cellScale, specifier: "%.0f") м")
                                .font(.title3).fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.blue.opacity(0.1), in: Capsule())
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        animatePlusMinus = false
                    }
                }
            }
            
            Button {
                withAnimation(.spring()) {
                    paths = []
                    endLocation = nil
                    intermediatePoints = []
                    animatePlusMinus = true
                }
            } label: {
                Text("Сбросить")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            CampusMapView(
                startLocation: $startLocation,
                endLocation: $endLocation,
                intermediatePoints: $intermediatePoints,
                paths: $paths,
                placeManager: placeManager,
                selectedPlace: $selectedPlace,
                selectedCluster: $selectedCluster,
                clusters: $clusters
            )
            .ignoresSafeArea()
            .sheet(item: $selectedPlace) { place in
                PlaceInfoView(newPlace: place.item,
                              placeManager: placeManager,
                              currentDetent: $sheetDetent,
                              endLocation: $endLocation,
                              intermediatePoints: $intermediatePoints,
                              clusters: $clusters)
                    .presentationDetents([.height(200), .large], selection: $sheetDetent)
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedCluster) { cluster in
                ClusterInfoView(cluster: cluster, selectedPlace: $selectedPlace)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            
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
                        if !intermediatePoints.isEmpty {
                            RouteSettingsView(
                                placeManager: placeManager,
                                startLocation: $startLocation,
                                endLocation: $endLocation,
                                intermediatePoints: $intermediatePoints)
                        } else {
                            FloatingSearchBar(placeManager: placeManager,
                                              clusters: $clusters,
                                              startLocation: $startLocation,
                                              endLocation: $endLocation,
                                              intermediatePoints: $intermediatePoints,
                                              paths: $paths)
                        }
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
                    } else if endLocation == nil {
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
                                DecisionTreeView(
                                    manager: manager,
                                    placeManager: placeManager,
                                    treeNode: treeNode,
                                    endLocation: $endLocation
                                ) { prediction in
                                    self.predictionResult = prediction
                                }
                                .presentationDragIndicator(.visible)
                            }
                            
                            Button {
                                withAnimation(.spring()) {
                                    startLocation = nil
                                }
                            } label: {
                                Text("Изменить старт").padding(.vertical, 6).padding(.horizontal, 20)
                            }
                            .buttonStyle(.glass)
                        }
                    } else {
                        PathsView()
                            .background(.ultraThinMaterial)
                            .cornerRadius(30)
                            .shadow(color: .black.opacity(0.1), radius: 10)
                            .offset(y: !paths.isEmpty ? 0 : 600)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: paths.isEmpty)
                    }
                }
            }
            .padding()
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: paths.isEmpty)
            .animation(.spring(), value: startLocation)
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
        
        treeNode = buildTree(data: data, availableAttributes: AppConfig.aviableTreeAttributes)
        
        print("Дерево перестроено на основе \(data.count) записей")
    }
}

#Preview {
    ContentView()
}
