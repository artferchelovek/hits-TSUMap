import MapKit
import SwiftUI

struct MapEditorView: View {
    let columnsCount = 150
    let rowsCount = 150

    let baseCellSize: CGFloat = 14.0

    var baseWidth: CGFloat {
        CGFloat(columnsCount) * baseCellSize
    }

    var baseHeight: CGFloat {
        CGFloat(rowsCount) * baseCellSize
    }

    @State private var grid: [[CellType]]
    @State private var isDrawMode: Bool = true
    @State private var currentScale: CGFloat = 1.0
    @State private var finalScale: CGFloat = 1.0

    init() {
        if tsuCampusGrid.isEmpty {
            _grid = State(initialValue: Array(
                repeating: Array(repeating: .obstacle, count: columnsCount),
                count: rowsCount
            ))
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
            HStack {
                Picker("Режим", selection: $isDrawMode) {
                    Text("Двигать").tag(false)
                    Text("Рисовать").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)

                Spacer()

                Button("Экспорт") {
                    exportGrid()
                }.buttonStyle(.borderedProminent)
            }
            .padding()

            let maxScale: CGFloat = 1.3
            let minScale: CGFloat = 0.5
            let currentTotalScale = min(maxScale, max(minScale, finalScale * currentScale))

            ScrollView([.horizontal, .vertical], showsIndicators: true) {
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
                    .frame(width: baseWidth, height: baseHeight)

                    Canvas { context, size in
                        var gridLines = Path()
                        for col in 0 ... columnsCount {
                            let x = CGFloat(col) * baseCellSize
                            gridLines.move(to: CGPoint(x: x, y: 0))
                            gridLines.addLine(to: CGPoint(x: x, y: size.height))
                        }
                        for row in 0 ... rowsCount {
                            let y = CGFloat(row) * baseCellSize
                            gridLines.move(to: CGPoint(x: 0, y: y))
                            gridLines.addLine(to: CGPoint(x: size.width, y: y))
                        }
                        context.stroke(gridLines, with: .color(.black.opacity(0.15)), lineWidth: 0.3)

                        var obstaclesPath = Path()
                        for row in 0 ..< rowsCount {
                            for col in 0 ..< columnsCount where grid[row][col] == .obstacle {
                                let rect = CGRect(
                                    x: CGFloat(col) * baseCellSize,
                                    y: CGFloat(row) * baseCellSize,
                                    width: baseCellSize,
                                    height: baseCellSize
                                )
                                obstaclesPath.addRect(rect)
                            }
                        }
                        context.fill(obstaclesPath, with: .color(.black.opacity(0.4)))
                    }
                    .frame(width: baseWidth, height: baseHeight)

                    if isDrawMode {
                        Color.white.opacity(0.001)
                            .frame(width: baseWidth, height: baseHeight)
                            .onTapGesture(coordinateSpace: .local) { location in
                                let col = Int(location.x / baseCellSize)
                                let row = Int(location.y / baseCellSize)
                                if row >= 0, row < rowsCount, col >= 0, col < columnsCount {
                                    grid[row][col] = grid[row][col] == .obstacle ? .path : .obstacle
                                }
                            }
                            .gesture(
                                DragGesture(minimumDistance: 2)
                                    .onChanged { value in
                                        let col = Int(value.location.x / baseCellSize)
                                        let row = Int(value.location.y / baseCellSize)
                                        if row >= 0, row < rowsCount, col >= 0, col < columnsCount {
                                            grid[row][col] = .path
                                        }
                                    }
                            )
                    }
                }
                .scaleEffect(currentTotalScale, anchor: .topLeading)
                .frame(
                    width: baseWidth * currentTotalScale,
                    height: baseHeight * currentTotalScale,
                    alignment: .topLeading
                )
            }
            .defaultScrollAnchor(.center)
            .gesture(
                MagnificationGesture()
                    .onChanged { amount in currentScale = amount }
                    .onEnded { amount in
                        finalScale = min(maxScale, max(minScale, finalScale * amount))
                        currentScale = 1.0
                    }
            )
        }
    }

    private func exportGrid() {
        print("let tsuCampusGrid = [")
        for row in grid {
            let rowString = row.map { $0 == .obstacle ? "1" : "0" }.joined(separator: ", ")
            print("    [\(rowString)],")
        }
        print("]")
    }
}

#Preview {
    MapEditorView()
}
