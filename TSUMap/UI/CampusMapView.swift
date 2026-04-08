//
//  CampusMapView.swift
//  TSUMap
//

import SwiftUI
import MapKit

struct AnimatedPathShape: Shape {
    var path: Path
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let trimmed = path.trim(from: 0, to: progress)
        return trimmed.path(in: rect)
    }
}

struct GridPoint: Equatable, Hashable, Codable {
    let row: Int
    let col: Int
}

enum CellType {
    case path
    case obstacle
}

let columnsCount = 150
let rowsCount = 150

let cellSize: CGFloat = 14.0

var mapWidth: CGFloat { CGFloat(columnsCount) * cellSize }
var mapHeight: CGFloat { CGFloat(rowsCount) * cellSize }

struct CampusMapView: View {
    @State private var grid: [[CellType]]
    
    @Binding var startLocation: GridPoint?
    @Binding var endLocation: GridPoint?
    @Binding var intermediatePoints: [GridPoint]
    @Binding var paths: [GridPoint]
    @Binding var selectedPlace: IdentifiableItem?
    @Binding var selectedCluster: Cluster?
    
    @State private var pathProgress: CGFloat = 0.0
    
    @ObservedObject var placeManager: PlaceManager
    @Binding var clusters: [Cluster]

    @State private var hasAutoFitRoute: Bool = false

    @State private var baseScale: CGFloat = 1.0
    @State private var baseOffset: CGSize = .zero

    @State private var activePan: CGSize = .zero
    @State private var activeZoom: CGFloat = 1.0
    @State private var pinchAnchor: CGPoint = .zero

    @State private var viewSize: CGSize = .zero

    var currentScale: CGFloat {
        clamp(baseScale * activeZoom, min: 0.5, max: 4.0)
    }

    var currentOffset: CGSize {
        var off = baseOffset

        if activeZoom != 1.0 && baseScale > 0 {
            let scale = clamp(baseScale * activeZoom, min: 0.5, max: 4.0)
            off.width = pinchAnchor.x - ((pinchAnchor.x - off.width) / baseScale) * scale
            off.height = pinchAnchor.y - ((pinchAnchor.y - off.height) / baseScale) * scale
        }

        off.width += activePan.width
        off.height += activePan.height

        return clampOffset(off)
    }
    
    init(
        startLocation: Binding<GridPoint?>,
        endLocation: Binding<GridPoint?>,
        intermediatePoints: Binding<[GridPoint]>,
        paths: Binding<[GridPoint]>,
        placeManager: PlaceManager,
        selectedPlace: Binding<IdentifiableItem?>,
        selectedCluster: Binding<Cluster?>,
        clusters: Binding<[Cluster]>
    ) {
        self._startLocation = startLocation
        self._endLocation = endLocation
        self._intermediatePoints = intermediatePoints
        self._paths = paths
        self.placeManager = placeManager
        self._selectedPlace = selectedPlace
        
        if tsuCampusGrid.isEmpty {
            _grid = State(initialValue: Array(repeating: Array(repeating: .obstacle, count: columnsCount), count: rowsCount))
        } else {
            let loadedGrid = tsuCampusGrid.map { row in
                row.map { value in value == 1 ? CellType.obstacle : CellType.path }
            }
            _grid = State(initialValue: loadedGrid)
        }
        self._selectedCluster = selectedCluster
        self._clusters = clusters
        self.placeManager.setGrid(grid: grid)
    }

    fileprivate func staticCanvas() -> some View {
        Canvas { context, _ in
            if !clusters.isEmpty {
                for cluster in clusters {
                    let point: GridPoint = cluster.medoid.iconCord
                    let (x, y) = Normalize(point: point)
                    let size: CGFloat = 45
                    let rect = CGRect(x: x - size / 2, y: y - size / 2, width: size, height: size)
                    
                    context.drawLayer { dotContext in
                        dotContext.addFilter(.shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3))
                        let mainPath = Path(ellipseIn: rect)
                        dotContext.fill(mainPath, with: .color(cluster.color.opacity(0.8)))
                        dotContext.stroke(mainPath, with: .color(.white), lineWidth: 3)
                    }
                }
            } else {
                PrintPlaces(in: context)
            }
            
            if let start = startLocation { drawStartPoint(start, context) }
            if let end = endLocation { drawEndPoint(end, context) }
            
            for point in intermediatePoints {
                drawIntermediatePoint(point, context)
            }
        } symbols: {
            Image(systemName: "cup.and.saucer.fill").resizable().scaledToFit().frame(width: 25, height: 25).foregroundStyle(.white).tag(PlaceType.coffee)
            Image(systemName: "fork.knife").resizable().scaledToFit().frame(width: 25, height: 25).foregroundStyle(.white).tag(PlaceType.cafe)
            Image(systemName: "basket").resizable().scaledToFit().frame(width: 25, height: 25).foregroundStyle(.white).tag(PlaceType.product)
            Image(systemName: "mappin.and.ellipse").resizable().scaledToFit().frame(width: 30, height: 30).foregroundStyle(.red).tag("endPin")
        }
        .frame(width: mapWidth, height: mapHeight)
    }
    
    var body: some View {
        VStack {
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    Map(
                        initialPosition: .region(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: 56.4690, longitude: 84.9470),
                            span: MKCoordinateSpan(latitudeDelta: 0.007, longitudeDelta: 0.007)
                        )),
                        interactionModes: []
                    )
                    .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
                    .allowsHitTesting(false)
                    .frame(width: mapWidth, height: mapHeight)

                    staticCanvas()
                    
                    if paths.count > 1 {
                        AnimatedPathShape(path: buildRoutePath(), progress: pathProgress)
                            .stroke(
                                LinearGradient(colors: [Color.blue, Color.blue.opacity(0.8)], startPoint: .top, endPoint: .bottom),
                                style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                            )
                    }

                    Color.white.opacity(0.001)
                        .frame(width: mapWidth, height: CGFloat(rowsCount) * cellSize)
                        .onTapGesture(coordinateSpace: .local) { location in
                            Tap(at: location)
                        }
                }
                .frame(width: mapWidth, height: mapHeight, alignment: .topLeading)

                .scaleEffect(currentScale, anchor: .topLeading)
                .offset(currentOffset)

                .gesture(mapGesture)
                .onAppear {
                    viewSize = geo.size
                }
                .onChange(of: geo.size) { _, newValue in
                    viewSize = newValue
                }
            }
            .defaultScrollAnchor(.center)
            .task(id: endLocation) { calculatePath() }
            .task(id: intermediatePoints) { calculatePath() }
        }
    }
    
    private var mapGesture: some Gesture {
        SimultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    activePan = value.translation
                }
                .onEnded { value in
                    activePan = value.translation
                    commitTransform()
                },
            MagnifyGesture()
                .onChanged { value in
                    activeZoom = value.magnification
                    if pinchAnchor == .zero {
                        pinchAnchor = value.startLocation
                    }
                }
                .onEnded { value in
                    activeZoom = value.magnification
                    commitTransform()
                }
        )
    }

    private func commitTransform() {
        let newScale = clamp(baseScale * activeZoom, min: 0.5, max: 4.0)

        if newScale != baseScale && baseScale > 0 && pinchAnchor != .zero {
            let scaleFactor = newScale / baseScale
            baseOffset.width = pinchAnchor.x - (pinchAnchor.x - baseOffset.width) * scaleFactor
            baseOffset.height = pinchAnchor.y - (pinchAnchor.y - baseOffset.height) * scaleFactor
        }
        baseScale = newScale

        baseOffset.width += activePan.width
        baseOffset.height += activePan.height

        let scale = currentScale
        let scaledWidth = mapWidth * scale
        let scaledHeight = mapHeight * scale

        if scaledWidth > viewSize.width {
            baseOffset.width = clamp(baseOffset.width, min: viewSize.width - scaledWidth, max: 0)
        } else {
            baseOffset.width = (viewSize.width - scaledWidth) / 2
        }

        if scaledHeight > viewSize.height {
            baseOffset.height = clamp(baseOffset.height, min: viewSize.height - scaledHeight, max: 0)
        } else {
            baseOffset.height = (viewSize.height - scaledHeight) / 2
        }

        activePan = .zero
        activeZoom = 1.0
        pinchAnchor = .zero
    }
    
    private func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        Swift.max(minValue, Swift.min(value, maxValue))
    }

    private func clampOffset(_ offset: CGSize) -> CGSize {
        let scale = currentScale
        let scaledWidth = mapWidth * scale
        let scaledHeight = mapHeight * scale

        var clampedWidth: CGFloat
        var clampedHeight: CGFloat

        if scaledWidth > viewSize.width {
            clampedWidth = clamp(offset.width, min: viewSize.width - scaledWidth, max: 0)
        } else {
            clampedWidth = (viewSize.width - scaledWidth) / 2
        }

        if scaledHeight > viewSize.height {
            clampedHeight = clamp(offset.height, min: viewSize.height - scaledHeight, max: 0)
        } else {
            clampedHeight = (viewSize.height - scaledHeight) / 2
        }

        return CGSize(width: clampedWidth, height: clampedHeight)
    }
    
    private func calculatePath() {
        guard let start = startLocation, let end = endLocation else {
            if startLocation == nil {
                hasAutoFitRoute = false
            }
            return
        }

        self.pathProgress = 0.0
        let newPath = AStar(graph: grid, start: start, points: intermediatePoints, end: end)
        self.paths = newPath

        if !hasAutoFitRoute {
            autoFitToPath(newPath)
        }

        withAnimation(.easeInOut(duration: 1.5)) {
            self.pathProgress = 1.0
        }
    }

    private func autoFitToPath(_ path: [GridPoint]) {
        guard !path.isEmpty else { return }

        var minRow = path[0].row
        var maxRow = path[0].row
        var minCol = path[0].col
        var maxCol = path[0].col

        for point in path {
            minRow = min(minRow, point.row)
            maxRow = max(maxRow, point.row)
            minCol = min(minCol, point.col)
            maxCol = max(maxCol, point.col)
        }

        let padding: CGFloat = 0.25
        let rowRange = CGFloat(maxRow - minRow) + 1
        let colRange = CGFloat(maxCol - minCol) + 1
        let paddedRowRange = rowRange * (1 + padding) * cellSize
        let paddedColRange = colRange * (1 + padding) * cellSize

        let screenWidth = viewSize.width > 0 ? viewSize.width : 400
        let screenHeight = viewSize.height > 0 ? viewSize.height : 700
        let scaleByWidth = screenWidth / paddedColRange
        let scaleByHeight = screenHeight / paddedRowRange
        let targetScale = min(scaleByWidth, scaleByHeight)

        let clampedScale = clamp(targetScale, min: 0.5, max: 3.0)

        let centerCol = CGFloat(minCol + maxCol + 1) / 2 * cellSize
        let centerRow = CGFloat(minRow + maxRow + 1) / 2 * cellSize

        let offsetX = screenWidth / 2 - centerCol * clampedScale
        let offsetY = screenHeight / 2 - centerRow * clampedScale

        withAnimation(.easeInOut(duration: 0.6)) {
            baseScale = clampedScale
            baseOffset = CGSize(width: offsetX, height: offsetY)
            hasAutoFitRoute = true
        }
    }

    private func PrintPlaces(in context: GraphicsContext) {
        let places = placeManager.cafes
        
        for place in places.values {
            let point: GridPoint = place.iconCord
            let x = CGFloat(point.col) * cellSize + (cellSize / 2)
            let y = CGFloat(point.row) * cellSize + (cellSize / 2)
            if let symbol = context.resolveSymbol(id: place.type) {
                let targetColor: Color = .black
                var tintedContext = context
                tintedContext.addFilter(.colorMultiply(targetColor))
                tintedContext.draw(symbol, at: CGPoint(x: x, y: y), anchor: .center)
            }
            let label = Text(place.name).font(.system(size: 15)).fontWeight(.semibold)
            context.draw(label, at: CGPoint(x: x + 15, y: y - 5), anchor: .leading)
        }
    }
    
    private func buildRoutePath() -> Path {
        guard paths.count > 1 else { return Path() }
        
        var routePath = Path()
        let points = paths.map { CGPoint(x: CGFloat($0.col) * cellSize + cellSize / 2, y: CGFloat($0.row) * cellSize + cellSize / 2) }

        routePath.move(to: points[0])
        for i in 1..<points.count - 1 {
            let current = points[i]
            let next = points[i + 1]
            let midPoint = CGPoint(x: (current.x + next.x) / 2, y: (current.y + next.y) / 2)
            routePath.addQuadCurve(to: midPoint, control: current)
        }
        if let last = points.last { routePath.addLine(to: last) }
        
        return routePath
    }

    private func PrintPath(in context: GraphicsContext, progress: CGFloat) {
        guard paths.count > 1 else { return }
        let myPath = buildRoutePath()

        let fullRect = CGRect(x: 0, y: 0, width: mapWidth, height: mapHeight)
        let trimmedPath = myPath.trim(from: 0, to: progress).path(in: fullRect)

        let style = StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
        let appleGradient = LinearGradient(colors: [Color.blue, Color.blue.opacity(0.8)], startPoint: .top, endPoint: .bottom)
        context.stroke(trimmedPath, with: .style(appleGradient), style: style)
    }
    
    private func Normalize(point: GridPoint) -> (Double, Double) {
        let x = CGFloat(point.col) * cellSize + (cellSize / 2)
        let y = CGFloat(point.row) * cellSize + (cellSize / 2)
        return (x, y)
    }
}

extension CampusMapView {
    fileprivate func drawStartPoint(_ start: GridPoint, _ context: GraphicsContext) {
        let (x, y) = Normalize(point: start)
        let rect = CGRect(x: x - 10, y: y - 10, width: 20, height: 20)
        context.fill(Path(ellipseIn: rect), with: .color(.blue))
        context.stroke(Path(ellipseIn: rect), with: .color(.white), lineWidth: 3)
    }
    
    fileprivate func drawIntermediatePoint(_ point: GridPoint, _ context: GraphicsContext) {
        let (x, y) = Normalize(point: point)
        let size: CGFloat = 12
        let rect = CGRect(x: x - size / 2, y: y - size / 2, width: size, height: size)
        context.stroke(Path(ellipseIn: rect), with: .color(.blue), lineWidth: 2)
        context.fill(Path(ellipseIn: rect.insetBy(dx: 2, dy: 2)), with: .color(.white))
    }
    
    fileprivate func drawEndPoint(_ end: GridPoint, _ context: GraphicsContext) {
        let (x, y) = Normalize(point: end)
        if let pin = context.resolveSymbol(id: "endPin") {
            context.draw(pin, at: CGPoint(x: x, y: y), anchor: .bottom)
        }
    }
    
    private func Tap(at location: CGPoint) {
        let col = Int(location.x / cellSize)
        let row = Int(location.y / cellSize)
        
        if startLocation != nil {
            let tapThreshold: CGFloat = 22.0
            if clusters.isEmpty {
                if let tappedPlace = placeManager.getAllPlaces().values.first(where: { place in
                    let (x, y) = Normalize(point: place.item.iconCord)
                    return hypot(x - location.x, y - location.y) < tapThreshold
                }) {
                    withAnimation { selectedPlace = tappedPlace}
                    return
                }
            } else {
                if let tappedCluster = clusters.first(where: { cluster in
                    let (x, y) = Normalize(point: cluster.medoid.iconCord)
                    return hypot(x - location.x, y - location.y) < tapThreshold
                }) {
                    withAnimation { selectedCluster = tappedCluster }
                    return
                }
            }
        }
        
        guard row >= 0 && row < rowsCount && col >= 0 && col < columnsCount else { return }
        if tsuCampusGrid[row][col] == 1 { return }
        let tappedPoint = GridPoint(row: row, col: col)
        
        if startLocation == nil {
            withAnimation(.spring()) { startLocation = tappedPoint }
        } else if endLocation == nil {
            endLocation = tappedPoint
        } else {
            if !intermediatePoints.contains(tappedPoint) {
                withAnimation(.snappy) { intermediatePoints.append(tappedPoint) }
            }
        }
    }
}

#Preview {
    CampusMapView(
        startLocation: .constant(nil as GridPoint?),
        endLocation: .constant(nil as GridPoint?),
        intermediatePoints: .constant([]),
        paths: .constant([]),
        placeManager: PlaceManager(),
        selectedPlace: .constant(nil as IdentifiableItem?),
        selectedCluster: .constant(nil as Cluster?),
        clusters: .constant([])
    )
}
