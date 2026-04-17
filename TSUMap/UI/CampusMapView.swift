//
//  CampusMapView.swift
//  TSUMap
//

import MapKit
import SwiftUI

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

func findNearestPathPoint(from point: GridPoint) -> GridPoint {
    guard loadedGrid[point.row][point.col] == .obstacle else { return point }

    var queue: [GridPoint] = [point]
    var visited: Set<GridPoint> = [point]

    let directions = [(0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (1, -1), (-1, 1), (-1, -1)]

    var head = 0
    while head < queue.count {
        let current = queue[head]
        head += 1

        for dir in directions {
            let newRow = current.row + dir.0
            let newCol = current.col + dir.1

            if newRow >= 0, newRow < rowsCount, newCol >= 0, newCol < columnsCount {
                let nextPoint = GridPoint(row: newRow, col: newCol)
                if !visited.contains(nextPoint) {
                    if loadedGrid[newRow][newCol] == .path {
                        return nextPoint
                    }
                    visited.insert(nextPoint)
                    queue.append(nextPoint)
                }
            }
        }
        if queue.count > 400 { break }
    }
    return point
}

let columnsCount = 150
let rowsCount = 150

let cellSize: CGFloat = 14.0

var mapWidth: CGFloat {
    CGFloat(columnsCount) * cellSize
}

var mapHeight: CGFloat {
    CGFloat(rowsCount) * cellSize
}

struct CampusMapView: View {
    @Binding var startLocation: GridPoint?
    @Binding var endLocation: GridPoint?
    @Binding var intermediatePoints: [GridPoint]
    @Binding var obstaclePoints: [GridPoint]
    @Binding var startObstacle: GridPoint?
    @Binding var endObstacle: GridPoint?
    @Binding var paths: [GridPoint]
    @Binding var selectedPlace: IdentifiableItem?
    @Binding var selectedCluster: Cluster?
    @Binding var isCreateObstacle: Bool
    @State private var pathProgress: CGFloat = 0.0
    @Binding private var isCalculatingPath: Bool
    @State private var pathCalculationTask: Task<Void, any Error>?

    @Binding var visitedPoints: Set<GridPoint>
    @Binding var pointsInQueue: [GridPoint]
    @Binding var pathToCurrentPoint: Set<GridPoint>

    @ObservedObject var placeManager: PlaceManager
    @StateObject var locationManager = LocationManager()
    @Binding var clusters: [Cluster]
    @Binding var showLocationAlert: Bool
    @Binding var isFollowingUser: Bool

    @State private var hasAutoFitRoute: Bool = false
    @State private var userProgressOnPath: Int = 0

    @State private var baseScale: CGFloat = 1.0
    @State private var baseOffset: CGSize = .zero
    @State private var activePan: CGSize = .zero
    @State private var activeZoom: CGFloat = 1.0
    @State private var pinchAnchor: CGPoint = .zero

    @State private var viewSize: CGSize = .zero

    @ObservedObject var settingsManager: SettingsManager

    var currentScale: CGFloat {
        clamp(baseScale * activeZoom, min: 0.5, max: 4.0)
    }

    var currentOffset: CGSize {
        var off = baseOffset

        if activeZoom != 1.0, baseScale > 0 {
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
        clusters: Binding<[Cluster]>,
        showLocationAlert: Binding<Bool>,
        isFollowingUser: Binding<Bool>,
        visitedPoints: Binding<Set<GridPoint>>,
        correctPoints: Binding<[GridPoint]>,
        pathToCurrentPoint: Binding<Set<GridPoint>>,
        settingsManager: SettingsManager,
        obstaclePoints: Binding<[GridPoint]>,
        isCreateObstacle: Binding<Bool>,
        startObstacle: Binding<GridPoint?>,
        endObstacle: Binding<GridPoint?>,
        isCalculatingPath: Binding<Bool>

    ) {
        _startLocation = startLocation
        _endLocation = endLocation
        _intermediatePoints = intermediatePoints
        _paths = paths
        self.placeManager = placeManager
        _selectedPlace = selectedPlace
        _showLocationAlert = showLocationAlert
        _isFollowingUser = isFollowingUser
        _visitedPoints = visitedPoints
        _pointsInQueue = correctPoints
        _pathToCurrentPoint = pathToCurrentPoint
        _selectedCluster = selectedCluster
        _clusters = clusters
        _obstaclePoints = obstaclePoints
        _isCreateObstacle = isCreateObstacle
        self.settingsManager = settingsManager
        _endObstacle = endObstacle
        _startObstacle = startObstacle
        _isCalculatingPath = isCalculatingPath
        self.placeManager.setGrid(grid: loadedGrid)
    }

    fileprivate func staticCanvas() -> some View {
        Canvas { context, _ in
            if isCreateObstacle {
                drawObstacles(context)
            }
            drawVisitedPoints(context)
            drawPointsInQueue(context)
            drawPathToCurrentPoint(context)
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
            }
            if let start = startLocation { drawStartPoint(start, context) }
            if let end = endLocation { drawEndPoint(end, context) }
            if let startObs = startObstacle { drawStartObs(startObs, context) }
            if let endObs = endObstacle { drawStartObs(endObs, context) }
            for point in intermediatePoints {
                drawIntermediatePoint(point, context)
            }
        } symbols: {
            Image(systemName: "cup.and.saucer.fill").resizable().scaledToFit().frame(width: 25, height: 25)
                .foregroundStyle(.white).tag(PlaceType.coffee)
            Image(systemName: "fork.knife").resizable().scaledToFit().frame(width: 25, height: 25)
                .foregroundStyle(.white).tag(PlaceType.cafe)
            Image(systemName: "basket").resizable().scaledToFit().frame(width: 25, height: 25).foregroundStyle(.white)
                .tag(PlaceType.product)
            Image(systemName: "star.fill").resizable().scaledToFit().frame(width: 25, height: 25)
                .foregroundStyle(.white).tag(PlaceType.sight)
            Image(systemName: "person.3.fill").resizable().scaledToFit().frame(width: 25, height: 25)
                .foregroundStyle(.white).tag(PlaceType.coworkingSpace)
            Image(systemName: "mappin.and.ellipse").resizable().scaledToFit().frame(width: 30, height: 30)
                .foregroundStyle(.red).tag("endPin")
        }
        .frame(width: mapWidth, height: mapHeight)
    }

    var body: some View {
        VStack {
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    Map(
                        initialPosition: .region(MapConfig.region),
                        interactionModes: []
                    )
                    .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
                    .allowsHitTesting(false)
                    .frame(width: mapWidth, height: mapHeight)
                    .aspectRatio(1, contentMode: .fit)

                    staticCanvas()

                    if paths.count > 1 {
                        CompletedPathView(paths: paths, userProgress: userProgressOnPath)
                        RemainingPathView(paths: paths, userProgress: userProgressOnPath)
                    }

                    if clusters.isEmpty {
                        PlaceMarkersOverlay()
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
                    locationManager.requestLocation()
                }
                .onChange(of: geo.size) { _, newValue in
                    viewSize = newValue
                }
                .onChange(of: locationManager.userLocation) { _, newValue in
                    if let location = newValue, let gridPoint = convertToGrid(location: location) {
                        updateUserProgress(gridPoint: gridPoint)
                        if isFollowingUser {
                            centerOnGridPoint(gridPoint)
                        }
                    }
                }
                .onChange(of: isFollowingUser) { _, newValue in
                    if newValue {
                        centerOnUser()
                    }
                }
            }
            .defaultScrollAnchor(.center)
            .task(id: endLocation) { calculatePath() }
            .task(id: intermediatePoints) { calculatePath() }
            .onChange(of: endLocation) { _, newValue in
                if newValue == nil {
                    pathCalculationTask?.cancel()
                    pathCalculationTask = nil
                    isCalculatingPath = false
                    intermediatePoints = []
                    userProgressOnPath = 0
                }
            }
            .onChange(of: paths) { _, newPaths in
                if newPaths.isEmpty {
                    userProgressOnPath = 0
                }
            }
        }
    }

    private var mapGesture: some Gesture {
        SimultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    activePan = value.translation
                    if abs(value.translation.width) > 2 || abs(value.translation.height) > 2 {
                        if isFollowingUser {
                            isFollowingUser = false
                        }
                    }
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
                    if isFollowingUser {
                        isFollowingUser = false
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

        if newScale != baseScale, baseScale > 0, pinchAnchor != .zero {
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

    private func centerOnUser() {
        guard let location = locationManager.userLocation,
              let gridPoint = convertToGrid(location: location) else { return }

        centerOnGridPoint(gridPoint)
    }

    private func centerOnGridPoint(_ point: GridPoint) {
        let targetScale: CGFloat = 1.3
        let screenWidth = viewSize.width > 0 ? viewSize.width : 400
        let screenHeight = viewSize.height > 0 ? viewSize.height : 700

        let centerCol = CGFloat(point.col) * cellSize + cellSize / 2
        let centerRow = CGFloat(point.row) * cellSize + cellSize / 2

        let offsetX = screenWidth / 2 - centerCol * targetScale
        let offsetY = screenHeight / 2 - centerRow * targetScale

        withAnimation(.easeInOut(duration: 0.6)) {
            baseScale = targetScale
            baseOffset = CGSize(width: offsetX, height: offsetY)
        }
    }

    private func calculatePath() {
        guard endLocation != nil else { return }

        let task = Task {
            isCalculatingPath = true
            defer { isCalculatingPath = false }

            guard let rawStart = startLocation, let rawEnd = endLocation else {
                if startLocation == nil {
                    hasAutoFitRoute = false
                }
                return
            }

            let start = findNearestPathPoint(from: rawStart)
            let end = findNearestPathPoint(from: rawEnd)
            let adjustedIntermediates = intermediatePoints.map { findNearestPathPoint(from: $0) }

            pointsInQueue = []
            visitedPoints = []
            pathToCurrentPoint = []
            paths = []

            let points = [start] + adjustedIntermediates + [end]
            var newPath: [GridPoint] = []
            for j in 0 ..< points.count - 1 {
                let startPoint = points[j]
                let endPoint = points[j + 1]
                let stream = AStar(graph: loadedGrid, obstacle: obstaclePoints).aStarGenerator(start: startPoint, end: endPoint)
                for await i in stream {
                    if Task.isCancelled {
                        pointsInQueue = []
                        visitedPoints = []
                        pathToCurrentPoint = []
                        return
                    }
                    if settingsManager.isBuildPath {
                        await MainActor.run {
                            visitedPoints.insert(i.point)
                            pointsInQueue = i.openPoints
                            pathToCurrentPoint = []
                            i.pathToPoint.forEach { pathToCurrentPoint.insert($0) }
                        }
                        try await Task.sleep(nanoseconds: 10_000_000 * UInt64(settingsManager.buildPathSpeed))
                    }

                    if i.isEnd {
                        newPath += i.path
                    }
                }
            }

            if Task.isCancelled {
                pointsInQueue = []
                visitedPoints = []
                pathToCurrentPoint = []
            }

            pathProgress = 0.0
            pointsInQueue = []
            visitedPoints = []
            pathToCurrentPoint = []

            if newPath.isEmpty {
                endLocation = nil
                return
            }

            paths = newPath
            if !hasAutoFitRoute {
                autoFitToPath(newPath)
            }

            withAnimation(.easeInOut(duration: 1.5)) {
                pathProgress = 1.0
            }
        }
        pathCalculationTask = task
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

    @ViewBuilder
    private func PlaceMarkersOverlay() -> some View {
        ForEach(Array(placeManager.cafes.values), id: \.id) { place in
            PlaceMarker(place: place, currentScale: currentScale) {
                withAnimation { selectedPlace = IdentifiableItem(item: place) }
            }
            .position(
                x: CGFloat(place.iconCord.col) * cellSize + cellSize / 2,
                y: CGFloat(place.iconCord.row) * cellSize + cellSize / 2
            )
        }

        ForEach(Array(placeManager.coworkings.values), id: \.id) { place in
            PlaceMarker(place: place, currentScale: currentScale) {
                withAnimation { selectedPlace = IdentifiableItem(item: place) }
            }
            .position(
                x: CGFloat(place.iconCord.col) * cellSize + cellSize / 2,
                y: CGFloat(place.iconCord.row) * cellSize + cellSize / 2
            )
        }

        ForEach(Array(placeManager.sights.values), id: \.id) { place in
            PlaceMarker(place: place, currentScale: currentScale) {
                withAnimation { selectedPlace = IdentifiableItem(item: place) }
            }
            .position(
                x: CGFloat(place.iconCord.col) * cellSize + cellSize / 2,
                y: CGFloat(place.iconCord.row) * cellSize + cellSize / 2
            )
        }
    }

    private func buildRoutePath() -> Path {
        guard paths.count > 1 else { return Path() }

        var routePath = Path()
        let points = paths.map { CGPoint(
            x: CGFloat($0.col) * cellSize + cellSize / 2,
            y: CGFloat($0.row) * cellSize + cellSize / 2
        ) }

        routePath.move(to: points[0])
        for i in 1 ..< points.count - 1 {
            let current = points[i]
            let next = points[i + 1]
            let midPoint = CGPoint(x: (current.x + next.x) / 2, y: (current.y + next.y) / 2)
            routePath.addQuadCurve(to: midPoint, control: current)
        }
        if let last = points.last { routePath.addLine(to: last) }

        return routePath
    }
}

private struct CompletedPathShape: Shape {
    let paths: [GridPoint]
    let userProgress: Int
    let cellSize: CGFloat

    func path(in _: CGRect) -> Path {
        var routePath = Path()
        guard userProgress > 0, userProgress < paths.count else { return routePath }

        let startPoint = paths[0]
        routePath.move(to: CGPoint(
            x: CGFloat(startPoint.col) * cellSize + cellSize / 2,
            y: CGFloat(startPoint.row) * cellSize + cellSize / 2
        ))

        for i in 1 ... userProgress {
            guard i < paths.count else { break }
            let current = paths[i]
            routePath.addLine(to: CGPoint(
                x: CGFloat(current.col) * cellSize + cellSize / 2,
                y: CGFloat(current.row) * cellSize + cellSize / 2
            ))
        }

        return routePath
    }
}

private struct RemainingPathShape: Shape {
    let paths: [GridPoint]
    let userProgress: Int
    let cellSize: CGFloat

    func path(in _: CGRect) -> Path {
        var routePath = Path()
        guard userProgress < paths.count - 1 else { return routePath }

        let startPoint = paths[userProgress]
        routePath.move(to: CGPoint(
            x: CGFloat(startPoint.col) * cellSize + cellSize / 2,
            y: CGFloat(startPoint.row) * cellSize + cellSize / 2
        ))

        for i in userProgress + 1 ..< paths.count {
            let current = paths[i]
            routePath.addLine(to: CGPoint(
                x: CGFloat(current.col) * cellSize + cellSize / 2,
                y: CGFloat(current.row) * cellSize + cellSize / 2
            ))
        }

        return routePath
    }
}

private extension CampusMapView {
    func Normalize(point: GridPoint) -> (Double, Double) {
        let x = CGFloat(point.col) * cellSize + (cellSize / 2)
        let y = CGFloat(point.row) * cellSize + (cellSize / 2)
        return (x, y)
    }

    private func updateUserProgress(gridPoint: GridPoint) {
        guard !paths.isEmpty else { return }

        var closestIndex = 0
        var closestDistance: CGFloat = .infinity

        for (index, pathPoint) in paths.enumerated() {
            let dx = CGFloat(pathPoint.col - gridPoint.col)
            let dy = CGFloat(pathPoint.row - gridPoint.row)
            let distance = sqrt(dx * dx + dy * dy)
            if distance < closestDistance {
                closestDistance = distance
                closestIndex = index
            }
        }

        if closestDistance < 3 {
            withAnimation { userProgressOnPath = max(userProgressOnPath, closestIndex) }
        } else if closestDistance > 8, paths.count > 1 {
            let pathPoint = paths[userProgressOnPath]
            let fromCurrentToPath = sqrt(
                pow(CGFloat(pathPoint.col - gridPoint.col), 2) +
                    pow(CGFloat(pathPoint.row - gridPoint.row), 2)
            )
            if fromCurrentToPath > 8 {
                withAnimation {
                    startLocation = gridPoint
                    endLocation = paths.last
                }
            }
        }
    }

    private func buildCompletedPath() -> Path {
        guard paths.count > 1, userProgressOnPath > 0 else { return Path() }

        _ = min(CGFloat(userProgressOnPath) / CGFloat(paths.count - 1), 1.0)
        let points = paths.map { CGPoint(
            x: CGFloat($0.col) * cellSize + cellSize / 2,
            y: CGFloat($0.row) * cellSize + cellSize / 2
        ) }

        var routePath = Path()
        let endIndex = min(userProgressOnPath, points.count - 1)
        routePath.move(to: points[0])

        for i in 1 ... endIndex {
            if i >= points.count { break }
            let current = points[i]
            if i + 1 < points.count {
                let next = points[i + 1]
                let midPoint = CGPoint(x: (current.x + next.x) / 2, y: (current.y + next.y) / 2)
                routePath.addQuadCurve(to: midPoint, control: current)
            } else {
                routePath.addLine(to: current)
            }
        }

        return routePath
    }

    private func buildRemainingPath() -> Path {
        guard paths.count > 1, userProgressOnPath < paths.count - 1 else { return Path() }

        let points = paths.map { CGPoint(
            x: CGFloat($0.col) * cellSize + cellSize / 2,
            y: CGFloat($0.row) * cellSize + cellSize / 2
        ) }

        var routePath = Path()
        routePath.move(to: points[userProgressOnPath])

        for i in userProgressOnPath + 1 ..< points.count - 1 {
            let current = points[i]
            let next = points[i + 1]
            let midPoint = CGPoint(x: (current.x + next.x) / 2, y: (current.y + next.y) / 2)
            routePath.addQuadCurve(to: midPoint, control: current)
        }
        if let last = points.last { routePath.addLine(to: last) }

        return routePath
    }
}

private extension CampusMapView {
    func drawStartPoint(_ start: GridPoint, _ context: GraphicsContext) {
        let (x, y) = Normalize(point: start)
        let size: CGFloat = 20
        let rect = CGRect(x: x - size / 2, y: y - size / 2, width: size, height: size)
        context.fill(Path(ellipseIn: rect), with: .color(.blue))
        context.stroke(Path(ellipseIn: rect), with: .color(.white), lineWidth: 3)
    }

    func drawIntermediatePoint(_ point: GridPoint, _ context: GraphicsContext) {
        let (x, y) = Normalize(point: point)
        let size: CGFloat = 12
        let rect = CGRect(x: x - size / 2, y: y - size / 2, width: size, height: size)
        context.stroke(Path(ellipseIn: rect), with: .color(.blue), lineWidth: 2)
        context.fill(Path(ellipseIn: rect.insetBy(dx: 2, dy: 2)), with: .color(.white))
    }

    func drawVisitedPoints(_ context: GraphicsContext) {
        for point in visitedPoints where !pathToCurrentPoint.contains(point) {
            let (x, y) = Normalize(point: point)
            let rect = CGRect(x: x - cellSize / 2 + 1, y: y - cellSize / 2 + 1, width: cellSize - 2, height: cellSize - 2)
            context.fill(Path(rect), with: .color(.blue.opacity(0.3)))
        }
    }

    func drawObstacles(_ context: GraphicsContext) {
        for point in obstaclePoints {
            let (x, y) = Normalize(point: point)
            let size = cellSize - 4
            let rect = CGRect(x: x - size / 2, y: y - size / 2, width: size, height: size)
            let path = Path(roundedRect: rect, cornerRadius: size * 0.2)
            context.fill(path, with: .color(.red.opacity(0.8)))
            context.stroke(path, with: .color(.white.opacity(0.3)), lineWidth: 1.5)
        }
    }

    func drawStartObs(_ startObstacle: GridPoint, _ context: GraphicsContext) {
        let (x, y) = Normalize(point: startObstacle)
        let size: CGFloat = 20
        let rect = CGRect(x: x - size / 2, y: y - size / 2, width: size, height: size)
        context.fill(Path(ellipseIn: rect), with: .color(.red))
        context.stroke(Path(ellipseIn: rect), with: .color(.white), lineWidth: 3)
    }

    func drawPointsInQueue(_ context: GraphicsContext) {
        for point in pointsInQueue where !pathToCurrentPoint.contains(point) {
            let (x, y) = Normalize(point: point)
            let rect = CGRect(x: x - cellSize / 2 + 1, y: y - cellSize / 2 + 1, width: cellSize - 2, height: cellSize - 2)
            context.fill(Path(rect), with: .color(.red.opacity(0.6)))
        }
    }

    func drawPathToCurrentPoint(_ context: GraphicsContext) {
        for point in pathToCurrentPoint {
            let (x, y) = Normalize(point: point)
            let rect = CGRect(x: x - cellSize / 2 + 1, y: y - cellSize / 2 + 1, width: cellSize - 2, height: cellSize - 2)
            context.fill(Path(rect), with: .color(.blue.opacity(1)))
        }
    }

    func drawEndPoint(_ end: GridPoint, _ context: GraphicsContext) {
        let (x, y) = Normalize(point: end)
        if let pin = context.resolveSymbol(id: "endPin") {
            context.draw(pin, at: CGPoint(x: x, y: y), anchor: .bottom)
        }
    }

    func findNeighborsPoints(_ start: GridPoint, _ allPoints: [GridPoint]) -> Set<GridPoint> {
        var connected = Set<GridPoint>()
        var queue = [start]
        let allPointsSet = Set(allPoints)

        while !queue.isEmpty {
            let current = queue.removeFirst()

            if connected.insert(current).inserted {
                let neighbors = allPointsSet.filter { point in
                    abs(point.row - current.row) <= 1 && abs(point.col - current.col) <= 1
                }

                for neighbor in neighbors {
                    if !connected.contains(neighbor) {
                        queue.append(neighbor)
                    }
                }
            }
        }
        return connected
    }

    private func Tap(at location: CGPoint) {
        let col = Int(location.x / cellSize)
        let row = Int(location.y / cellSize)

        print(row, col)

        if startLocation != nil {
            let tapThreshold: CGFloat = 22.0
            if clusters.isEmpty {
                if let tappedPlace = placeManager.getAllPlaces().values.first(where: { place in
                    let (x, y) = Normalize(point: place.item.iconCord)
                    return hypot(x - location.x, y - location.y) < tapThreshold
                }) {
                    withAnimation { selectedPlace = tappedPlace }
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

        guard row >= 0, row < rowsCount, col >= 0, col < columnsCount else { return }
        if tsuCampusGrid[row][col] == 1 { return }
        let tappedPoint = GridPoint(row: row, col: col)
        if isCreateObstacle {
            if obstaclePoints.contains(tappedPoint) {
                let connectedRegion = findNeighborsPoints(tappedPoint, obstaclePoints)
                obstaclePoints.removeAll(where: { connectedRegion.contains($0) })
                return
            }
            if startObstacle == nil {
                startObstacle = tappedPoint
            } else {
                endObstacle = tappedPoint
            }
            if let start = startObstacle, let end = endObstacle {
                obstaclePoints += AStar(graph: loadedGrid).aStarAlgorithm(start: start, end: end)
                startObstacle = nil
                endObstacle = nil
            }

        } else {
            if isCalculatingPath { return }
            if startLocation == nil {
                withAnimation(.spring()) { startLocation = tappedPoint }
            } else if endLocation == nil || paths.isEmpty {
                endLocation = tappedPoint
            } else {
                if !intermediatePoints.contains(tappedPoint) {
                    withAnimation(.snappy) { intermediatePoints.append(tappedPoint) }
                }
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
        clusters: .constant([]),
        showLocationAlert: .constant(false),
        isFollowingUser: .constant(true),
        visitedPoints: .constant([]),
        correctPoints: .constant([]),
        pathToCurrentPoint: .constant([]),
        settingsManager: SettingsManager(),
        obstaclePoints: .constant([]),
        isCreateObstacle: .constant(false),
        startObstacle: .constant(nil as GridPoint?),
        endObstacle: .constant(nil as GridPoint?),
        isCalculatingPath: .constant(false)
    )
}

struct PlaceMarker: View {
    let place: any MapItem
    let currentScale: CGFloat
    let onTap: () -> Void

    private var iconSize: CGFloat {
        Swift.max(9, Swift.min(44 - currentScale * 8, 44))
    }

    private var fontSize: CGFloat {
        Swift.max(6, Swift.min(12 - currentScale * 3, 13))
    }

    private var nameLines: [String] {
        let words = place.name.split(separator: " ")
        var lines: [String] = []
        var currentLine = ""

        for word in words {
            if currentLine.isEmpty {
                currentLine = String(word)
            } else if currentLine.count + word.count + 1 <= 16 {
                currentLine += " " + word
            } else {
                lines.append(currentLine)
                currentLine = String(word)
            }
        }
        if !currentLine.isEmpty { lines.append(currentLine) }
        return lines.isEmpty ? [place.name] : lines
    }

    var placeColor: Color {
        switch place.type {
        case .coffee: .orange
        case .cafe: .red
        case .product: .green
        case .sight: .purple
        case .coworkingSpace: .blue
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: place.type.iconName())
                .font(.system(size: iconSize * 0.44, weight: .semibold))
                .foregroundStyle(placeColor)

            if nameLines.count > 1 {
                VStack(spacing: 1) {
                    ForEach(Array(nameLines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(size: fontSize, weight: .bold))
                            .lineLimit(1)
                            .foregroundStyle(placeColor)
                            .bold()
                    }
                }
            } else {
                Text(nameLines.first ?? place.name)
                    .font(.system(size: fontSize, weight: .bold))
                    .lineLimit(1)
                    .foregroundStyle(placeColor)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.regularMaterial)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1)
        .onTapGesture {
            onTap()
        }
    }
}

private struct CompletedPathView: View {
    let paths: [GridPoint]
    let userProgress: Int
    let cellSize: CGFloat = 14.0

    var body: some View {
        if userProgress > 0 {
            CompletedPathShape(paths: paths, userProgress: userProgress, cellSize: cellSize)
                .stroke(Color.gray.opacity(0.6), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
        }
    }
}

private struct RemainingPathView: View {
    let paths: [GridPoint]
    let userProgress: Int
    let cellSize: CGFloat = 14.0

    var body: some View {
        if userProgress < paths.count - 1 {
            RemainingPathShape(paths: paths, userProgress: userProgress, cellSize: cellSize)
                .stroke(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                )
        } else {
            RemainingPathShape(paths: paths, userProgress: userProgress, cellSize: cellSize)
                .stroke(Color.blue.opacity(0.8), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
        }
    }
}
