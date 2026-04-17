//
//  TSUMapApp.swift
//  TSUMap
//
//  Created by Artem on 17.03.2026.
//

import SwiftUI

@main
struct TSUMapApp: App {
    @StateObject private var placeManager = PlaceManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var manager = VenueManager()
    @State private var isReady = false
    @State private var treeNode: TreeNode?

    private func loadTree() {
        let data = manager.allAttributes
        guard !data.isEmpty else { return }
        treeNode = buildTree(data: data, availableAttributes: AppConfig.aviableTreeAttributes)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isReady {
                    ContentView(treeNode: treeNode, onLoadTree: nil)
                        .environmentObject(placeManager)
                        .environmentObject(locationManager)
                } else {
                    SplashScreenView(
                        isReady: $isReady,
                        placeManager: placeManager,
                        locationManager: locationManager,
                        onReady: loadTree
                    )
                }
            }
        }
    }
}
