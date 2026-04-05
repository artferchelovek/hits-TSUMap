//
//  CampusMapView.swift
//  TSUMap
//
//  Created by Artem on 18.03.2026.
//

import SwiftUI
import MapKit

struct GridPoint: Equatable, Hashable, Codable {
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
    @Binding var paths: [GridPoint]
    @Binding var selectedPlace: Place?
    
    @ObservedObject var placeManager: PlaceManager
    
    @State private var currentScale: CGFloat = 1.0
    @State private var finalScale: CGFloat = 1.0
    
    init(
        startLocation: Binding<GridPoint?>,
        endLocation: Binding<GridPoint?>,
        paths: Binding<[GridPoint]>,
        placeManager: PlaceManager,
        selectedPlace: Binding<Place?>
    ) {
        
        self._startLocation = startLocation
        self._endLocation = endLocation
        self._paths = paths
        self.placeManager = placeManager
        self._selectedPlace = selectedPlace
        
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
        self.placeManager.setGrid(grid: grid)
    }
    
    private func CanvasGrid() -> some View {
        return Canvas { context, _ in
            if let start = startLocation {
                let (x, y) = Normalize(point: start)
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
                let (x, y) = Normalize(point: end)
                let rect = CGRect(x: x - 10, y: y - 10, width: 20, height: 20)
                context.fill(Path(ellipseIn: rect), with: .color(.red))
                context.stroke(Path(ellipseIn: rect), with: .color(.white), lineWidth: 3)
                
                let coordinateText = Text("[\(end.row), \(end.col)]")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                context.draw(coordinateText, at: CGPoint(x: x, y: y - 15), anchor: .bottom)
            }
            if paths.count > 1 {
                PrintPath(in: context)
            }
            PrintPlaces(in: context)
        }
        symbols: {
            Image(systemName: "cup.and.saucer.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
                .foregroundStyle(.white)
                .tag(PlaceType.coffee)
            Image(systemName: "fork.knife")
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
                .foregroundStyle(.white)
                .tag(PlaceType.cafe)
            Image(systemName: "basket")
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
                .foregroundStyle(.white)
                .tag(PlaceType.product)
        }
        .frame(width: mapWidth, height: CGFloat(rowsCount) * cellSize)
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
                    
                    CanvasGrid()
                    
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
            .onChange(of: endLocation) { calculatePath() }
        }
    }
    
    private func calculatePath() {
        guard let start = startLocation, let end = endLocation else { return }
        
        let newPath = AStar(graph: grid, start: start, end: end)
        
        withAnimation(.spring()) {
            self.paths = newPath
        }
    }
    
    private func PrintPlaces(in context: GraphicsContext) {
        let places = placeManager.places
        for place in places.values {
            let point: GridPoint = place.iconCord
            let x = CGFloat(point.col) * cellSize + (cellSize / 2)
            let y = CGFloat(point.row) * cellSize + (cellSize / 2)
            if let symbol = context.resolveSymbol(id: place.type) {
                let targetColor: Color = .black
                var tintedContext = context
                tintedContext.addFilter(.colorMultiply(targetColor))
                tintedContext.draw(
                    symbol,
                    at: CGPoint(x: x, y: y),
                    anchor: .center
                )
            }
            let label = Text(place.name)
                .font(.system(size: 15))
                .fontWeight(.semibold)
            context.draw(label, at: CGPoint(x: x + 15, y: y - 5), anchor: .leading)
        }
    }
    
    private func PrintPath(in context: GraphicsContext) {
        var myPath = Path()
        guard let first = paths.first else {return}
        myPath.move(to: CGPoint(x: CGFloat(first.col) * cellSize + cellSize / 2, y: CGFloat(first.row) * cellSize + cellSize / 2))
        for i in 1..<paths.count {
            myPath.addLine(to: CGPoint(x: CGFloat(paths[i].col) * cellSize + cellSize / 2, y: CGFloat(paths[i].row) * cellSize + cellSize / 2))
        }
        context.stroke(myPath, with: .color(.blue), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round, dash: [5, 10]))
    }
    
    private func Normalize(point: GridPoint) -> (Double, Double) {
        let x = CGFloat(point.col) * cellSize + (cellSize / 2)
        let y = CGFloat(point.row) * cellSize + (cellSize / 2)
        return (x, y)
    }
    
    private func Tap(at location: CGPoint) {
        let col = Int(location.x / cellSize)
        let row = Int(location.y / cellSize)
        
        if startLocation != nil {
            let tapThreshold: CGFloat = 22.0
            if let tappedPlace = placeManager.places.values.first(where: { place in
                print(place.entryCord)
                let (x, y) = Normalize(point: place.iconCord)
                let distance = sqrt(pow(x - location.x, 2) + pow(y - location.y, 2))
                return distance < tapThreshold
            }) {
                withAnimation {
                    selectedPlace = tappedPlace
                }
                return
            }
        }
        
        guard row >= 0 && row < rowsCount && col >= 0 && col < columnsCount else { return }
        if tsuCampusGrid[row][col] == 1 { return }
        
        if startLocation == nil {
            withAnimation(.spring()) {
                startLocation = GridPoint(row: row, col: col)
            }
        } else if endLocation == nil {
            endLocation = GridPoint(row: row, col: col)
        }
    }
}

#Preview {
    CampusMapView(
        startLocation: .constant(nil as GridPoint?),
        endLocation: .constant(nil as GridPoint?),
        paths: .constant([]),
        placeManager: PlaceManager(),
        selectedPlace: .constant(nil as Place?)
    )
}
