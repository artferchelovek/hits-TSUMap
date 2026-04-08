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
    
    @State private var animationStartDate: Date?
    
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
    
    fileprivate func drawStartPoint(_ start: GridPoint, _ context: GraphicsContext) {
        let (x, y) = Normalize(point: start)
        let rect = CGRect(x: x - 10, y: y - 10, width: 20, height: 20)
        
        context.fill(Path(ellipseIn: rect), with: .color(.blue))
        context.stroke(Path(ellipseIn: rect), with: .color(.white), lineWidth: 3)
    }
    
    fileprivate func drawEndPoint(_ end: GridPoint, _ context: GraphicsContext) {
        let (x, y) = Normalize(point: end)
        
        if let pin = context.resolveSymbol(id: "endPin") {
                context.draw(pin, at: CGPoint(x: x, y: y), anchor: .bottom)
            }
    }
    
    private func CanvasGrid() -> some View {
        TimelineView(.animation) { timeline in
            Canvas { context, _ in
                
                let progress = calculateProgress(at: timeline.date)
                
                if paths.count > 1 {
                    PrintPath(in: context, progress: progress)
                }
                
                PrintPlaces(in: context)
                
                if let start = startLocation {
                    drawStartPoint(start, context)
                }
                
                if let end = endLocation {
                    drawEndPoint(end, context)
                }
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
                Image(systemName: "mappin.and.ellipse")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(.red)
                        .tag("endPin")
            }
            .frame(width: mapWidth, height: CGFloat(rowsCount) * cellSize)
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
        self.paths = newPath
        self.animationStartDate = Date()
    }
    
    private func calculateProgress(at now: Date) -> CGFloat {
        guard let start = animationStartDate else { return 0 }
        let duration: TimeInterval = 1.5
        let elapsed = now.timeIntervalSince(start)
        return min(CGFloat(elapsed / duration), 1.0)
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
    
    private func PrintPath(in context: GraphicsContext, progress: CGFloat) {
        guard paths.count > 1 else { return }
        
        var myPath = Path()
        
        let points = paths.map { CGPoint(
            x: CGFloat($0.col) * cellSize + cellSize / 2,
            y: CGFloat($0.row) * cellSize + cellSize / 2
        )}
        
        myPath.move(to: points[0])
        
        for i in 1..<points.count - 1 {
            let current = points[i]
            let next = points[i + 1]
            let midPoint = CGPoint(
                x: (current.x + next.x) / 2,
                y: (current.y + next.y) / 2
            )

            myPath.addQuadCurve(to: midPoint, control: current)
        }
        
        if let last = points.last {
            myPath.addLine(to: last)
        }
        
        let fullRect = CGRect(x: 0, y: 0, width: mapWidth, height: mapHeight)
        let trimmedPath = myPath.trim(from: 0, to: progress).path(in: fullRect)
        
        let style = StrokeStyle(
            lineWidth: 5,
            lineCap: .round,
            lineJoin: .round
        )
        
        let appleGradient = LinearGradient(
            colors: [Color.blue, Color.blue.opacity(0.8)],
            startPoint: .top, endPoint: .bottom
        )
        
        context.stroke(trimmedPath, with: .style(appleGradient), style: style)
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
