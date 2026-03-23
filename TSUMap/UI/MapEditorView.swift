//
//  MapEditorView.swift
//  TSUMap
//
//  Created by Artem on 18.03.2026.
//

import SwiftUI

enum CellType {
    case path
    case obstacle
}

struct CellView: View {
    @Binding var cellType: CellType
    let size: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(cellType == .obstacle ? Color.black.opacity(0.4) : Color.clear)
            .frame(width: size, height: size)
            .border(Color.white.opacity(0.1), width: 0.5)
            .contentShape(Rectangle())
            .onTapGesture {
                cellType = cellType == .obstacle ? .path : .obstacle
            }
    }
}

struct MapEditorView: View {
    let columnsCount = 100
    let rowsCount = 170
    let mapWidth: CGFloat = 1500
    
    var cellSize: CGFloat {
        mapWidth / CGFloat(columnsCount)
    }
    
    @State private var grid: [[CellType]]
    @State private var currentScale: CGFloat = 1.0
    @State private var finalScale: CGFloat = 1.0
    
    @State private var isDrawMode: Bool = true
    
    init() {
        _grid = State(initialValue: Array(repeating: Array(repeating: .obstacle, count: columnsCount), count: rowsCount))
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
            
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                ZStack(alignment: .topLeading) {
                    
                    Image("TSUMap")
                        .resizable()
                        .scaledToFit()
                        .frame(width: mapWidth)
                    
                    Canvas { context, size in
                        
                        var gridLines = Path()
                        
                        for col in 0...columnsCount {
                            let x = CGFloat(col) * cellSize
                            gridLines.move(to: CGPoint(x: x, y: 0))
                            gridLines.addLine(to: CGPoint(x: x, y: size.height))
                        }
                        
                        for row in 0...rowsCount {
                            let y = CGFloat(row) * cellSize
                            gridLines.move(to: CGPoint(x: 0, y: y))
                            gridLines.addLine(to: CGPoint(x: size.width, y: y))
                        }
                        
                        context.stroke(gridLines, with: .color(.black.opacity(0.2)), lineWidth: 0.5)
                        
                        for row in 0..<rowsCount {
                            for col in 0..<columnsCount where grid[row][col] == .obstacle {
                                let rect = CGRect(
                                    x: CGFloat(col) * cellSize,
                                    y: CGFloat(row) * cellSize,
                                    width: cellSize,
                                    height: cellSize
                                )
                                context.fill(Path(rect), with: .color(.black.opacity(0.5)))
                            }
                        }
                    }
                    .frame(width: mapWidth, height: CGFloat(rowsCount) * cellSize)
                    
                    if isDrawMode {
                        Color.white.opacity(0.001)
                            .frame(width: mapWidth, height: CGFloat(rowsCount) * cellSize)
                        
                            .onTapGesture(coordinateSpace: .local) { location in
                                let col = Int(location.x / cellSize)
                                let row = Int(location.y / cellSize)
                                
                                if row >= 0 && row < rowsCount && col >= 0 && col < columnsCount {
                                    grid[row][col] = grid[row][col] == .obstacle ? .path : .obstacle
                                }
                            }
                        
                            .gesture(
                                DragGesture(minimumDistance: 5)
                                    .onChanged { value in
                                        let col = Int(value.location.x / cellSize)
                                        let row = Int(value.location.y / cellSize)
                                        
                                        if row >= 0 && row < rowsCount && col >= 0 && col < columnsCount {
                                            grid[row][col] = .path
                                        }
                                    }
                            )
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
