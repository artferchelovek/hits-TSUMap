//
//  CampusMapView.swift
//  TSUMap
//
//  Created by Artem on 18.03.2026.
//

import SwiftUI
import MapKit

struct GridPoint: Equatable, Hashable {
    let row: Int
    let col: Int
}

enum CellType {
    case path
    case obstacle
}

struct CampusMapView: View {
    let columnsCount = 150
    let rowsCount = 150
    
    let cellSize: CGFloat = 14.0
    
    var mapWidth: CGFloat { CGFloat(columnsCount) * cellSize }
    var mapHeight: CGFloat { CGFloat(rowsCount) * cellSize }
    
    @State private var grid: [[CellType]]
    
    @Binding var startLocation: GridPoint?
    @Binding var endLocation: GridPoint?
    
    @State private var currentScale: CGFloat = 1.0
    @State private var finalScale: CGFloat = 1.0
    
    init(startLocation: Binding<GridPoint?>, endLocation: Binding<GridPoint?>) {
        
        self._startLocation = startLocation
        self._endLocation = endLocation
        
        if tsuCampusGrid.isEmpty {
            _grid = State(initialValue: Array(repeating: Array(repeating: .obstacle, count: columnsCount), count: rowsCount))
        } else {
            let loadedGrid = tsuCampusGrid.map { row in
                row.map { value in
                    value == 1 ? CellType.obstacle : CellType.path
                }
            }
            _grid = State(initialValue: loadedGrid)
        }
    }
    
    var body: some View {
        VStack {
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    
                    Map(
                        initialPosition: .region(
                            MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: 56.4690, longitude: 84.9470),
                                span: MKCoordinateSpan(latitudeDelta: 0.007, longitudeDelta: 0.007)
                            )
                        ),
                        interactionModes: []
                    )
                    .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
                    .allowsHitTesting(false)
                    .frame(width: mapWidth, height: mapHeight)
                    
                    Canvas { context, _ in
                        if let start = startLocation {
                            let x = CGFloat(start.col) * cellSize + (cellSize / 2)
                            let y = CGFloat(start.row) * cellSize + (cellSize / 2)
                            
                            let rect = CGRect(x: x - 10, y: y - 10, width: 20, height: 20)
                            
                            context.fill(Path(ellipseIn: rect), with: .color(.blue))
                            context.stroke(Path(ellipseIn: rect), with: .color(.white), lineWidth: 3)
                            
                            let coordinateText = Text("[\(start.row), \(start.col)]")
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            context.draw(coordinateText, at: CGPoint(x: x, y: y - 15), anchor: .bottom)
                        }
                        
                        if let end = endLocation {
                            let x = CGFloat(end.col) * cellSize + (cellSize / 2)
                            let y = CGFloat(end.row) * cellSize + (cellSize / 2)
                            let rect = CGRect(x: x - 10, y: y - 10, width: 20, height: 20)
                            context.fill(Path(ellipseIn: rect), with: .color(.red))
                            context.stroke(Path(ellipseIn: rect), with: .color(.white), lineWidth: 3)
                            
                            let coordinateText = Text("[\(end.row), \(end.col)]")
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            
                            context.draw(coordinateText, at: CGPoint(x: x, y: y - 15), anchor: .bottom)
                        }
                    }
                    .frame(width: mapWidth, height: CGFloat(rowsCount) * cellSize)
                    
                    Color.white.opacity(0.001)
                        .frame(width: mapWidth, height: CGFloat(rowsCount) * cellSize)
                        .onTapGesture(coordinateSpace: .local) { location in
                            Tap(at: location)
                        }
                }
                .scaleEffect(finalScale * currentScale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { amount in currentScale = amount }
                        .onEnded { amount in
                            finalScale = max(0.5, min(finalScale * amount, 4.0))
                            currentScale = 1.0
                        }
                )
            }
            .defaultScrollAnchor(.center)
        }
    }
    
    private func Tap(at location: CGPoint) {
        let col = Int(location.x / cellSize)
        let row = Int(location.y / cellSize)
        guard row >= 0 && row < rowsCount && col >= 0 && col < columnsCount else { return }
        if tsuCampusGrid[row][col] == 1 { return }
        
        if startLocation == nil {
            withAnimation(.spring()) {
                startLocation = GridPoint(row: row, col: col)
            }
        } else if endLocation == nil {
            endLocation = GridPoint(row: row, col: col)
        }
        
        guard let startLocation, let endLocation else { return }
    }
}

#Preview {
    CampusMapView(
        startLocation: .constant(nil as GridPoint?),
        endLocation: .constant(nil as GridPoint?))
}
