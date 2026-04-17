//
//  ContentView.swift
//  TSUMap
//
//  Created by Artem on 17.03.2026.
//

import SwiftUI

struct IdentifiableItem: Identifiable {
    var item: any MapItem
    var id: String {
        item.id
    }
}

struct ContentView: View {
    var treeNode: TreeNode?
    var onLoadTree: (() -> Void)?

    @State private var startLocation: GridPoint?
    @State private var endLocation: GridPoint?
    @State private var intermediatePoints: [GridPoint] = []
    @State private var obstaclePoints: [GridPoint] = []
    @State private var startObstacle: GridPoint?
    @State private var endObstacle: GridPoint?
    @State private var paths: [GridPoint] = []
    @State private var isShowingDecisionSheet = false
    @State private var selectedPlace: IdentifiableItem?
    @State private var selectedCluster: Cluster?
    @State private var sheetDetent: PresentationDetent = .height(180)
    @State private var showLocationAlert = false
    @State private var isCalculatingPath: Bool = false
    @StateObject var locationManager = LocationManager()
    @State private var isFollowingUser = true

    @State private var visitedPoints: Set<GridPoint> = []
    @State private var pointsInQueue: [GridPoint] = []
    @State private var pathToCurrentPoint: Set<GridPoint> = []
    @State private var isCreateObstacle: Bool = false
    @State private var clusters: [Cluster] = []
    @State private var predictionResult: String?
    @State private var isShowingSettings: Bool = false

    @State private var animatePlusMinus = true

    @StateObject var manager = VenueManager()
    @StateObject var placeManager = PlaceManager()
    @StateObject var settingsManager = SettingsManager()

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
                                .symbolEffect(
                                    .drawOn.individually,
                                    options: .nonRepeating,
                                    isActive: animatePlusMinus
                                )
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
                    visitedPoints = []
                    pointsInQueue = []
                    pathToCurrentPoint = []
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
                clusters: $clusters,
                showLocationAlert: $showLocationAlert,
                isFollowingUser: $isFollowingUser,
                visitedPoints: $visitedPoints,
                correctPoints: $pointsInQueue,
                pathToCurrentPoint: $pathToCurrentPoint,
                settingsManager: settingsManager,
                obstaclePoints: $obstaclePoints,
                isCreateObstacle: $isCreateObstacle,
                startObstacle: $startObstacle,
                endObstacle: $endObstacle,
                isCalculatingPath: $isCalculatingPath
            )
            .ignoresSafeArea()
            .overlay(alignment: .bottomTrailing) {
                if isCalculatingPath {
                    VStack {
                        Button {
                            withAnimation {
                                endLocation = nil
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                Text("Отмена")
                                    .font(.headline)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.red.opacity(0.9))
                            .clipShape(Capsule())
                        }
                        .padding()
                    }
                }
            }
            .sheet(item: $selectedPlace) { place in
                PlaceInfoView(
                    newPlace: place.item,
                    placeManager: placeManager,
                    currentDetent: $sheetDetent,
                    endLocation: $endLocation,
                    intermediatePoints: $intermediatePoints,
                    clusters: $clusters
                )
                .presentationDetents([.height(200), .large], selection: $sheetDetent)
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedCluster) { cluster in
                ClusterInfoView(cluster: cluster, selectedPlace: $selectedPlace)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isShowingSettings) {
                AppSettingsView(settingsManager: settingsManager)
                    .presentationDetents([.large])
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
                                intermediatePoints: $intermediatePoints
                            )
                        } else {
                            FloatingSearchBar(
                                placeManager: placeManager,
                                settingsManager: settingsManager,
                                clusters: $clusters,
                                startLocation: $startLocation,
                                endLocation: $endLocation,
                                intermediatePoints: $intermediatePoints,
                                paths: $paths,
                                isShowSettings: $isShowingSettings
                            )
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
                        VStack {
                            VStack(spacing: 5) {
                                Spacer()

                                Button(action: {
                                    isCreateObstacle.toggle()
                                    endObstacle = nil
                                    startObstacle = nil
                                }) {
                                    Image(systemName: "figure.walk.triangle.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.yellow)
                                        .padding(12)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                                }

                                if !isFollowingUser, locationManager.userLocation != nil,!isCreateObstacle {
                                    Button(action: {
                                        withAnimation(.spring()) {
                                            isFollowingUser = true
                                        }
                                    }) {
                                        Image(systemName: "location.fill")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.blue)
                                            .padding(12)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                                    }
                                }
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                            .transition(.scale.combined(with: .opacity))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            if !isCreateObstacle {
                                HStack(spacing: 10) {
                                    Button {
                                        withAnimation(.spring()) {
                                            isShowingDecisionSheet.toggle()
                                        }
                                    } label: {
                                        Text("Куда пойдём?")
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 6)
                                    }
                                    .buttonStyle(.glassProminent)
                                    .sheet(isPresented: $isShowingDecisionSheet) {
                                        DecisionTreeView(
                                            manager: manager,
                                            placeManager: placeManager,
                                            treeNode: treeNode,
                                            endLocation: $endLocation
                                        ) { prediction in
                                            predictionResult = prediction
                                        }
                                        .presentationDragIndicator(.visible)
                                    }

                                    Button {
                                        withAnimation(.spring()) {
                                            startLocation = nil
                                            paths = []
                                            intermediatePoints = []
                                            endLocation = nil
                                        }
                                    } label: {
                                        Text("Очистить место старта")
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 6)
                                    }
                                    .buttonStyle(.glass)
                                }
                            }
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
            locationManager.requestLocation()
            if onLoadTree != nil {
                onLoadTree?()
            }
        }
        .onChange(of: locationManager.userLocation) { _, newUserLocation in
            if let location = newUserLocation {
                if let gridPoint = convertToGrid(location: location) {
                    print("в кампусе это точка: \(gridPoint)")
                    withAnimation(.spring()) {
                        startLocation = gridPoint
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView(treeNode: nil, onLoadTree: nil)
}
