//
//  CampusMapView.swift
//  TSUMap
//
//  Created by Artem on 18.03.2026.
//

import SwiftUI

struct GridPoint: Equatable {
    let row: Int
    let col: Int
}

struct CampusMapView: View {
    let columnsCount = 100
    let rowsCount = 120
    let mapWidth: CGFloat = 1500
    
    var cellSize: CGFloat {
        mapWidth / CGFloat(columnsCount)
    }
    
    @State private var startLocation: GridPoint? = nil
    
    @State private var currentScale: CGFloat = 1.0
    @State private var finalScale: CGFloat = 1.0
    
    var body: some View {
        VStack {
            
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                ZStack(alignment: .topLeading) {

                    Image("TSUMap")
                        .resizable()
                        .scaledToFit()
                        .frame(width: mapWidth)
                    
                    Canvas { context, size in
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
        }
    }
    
    private func Tap(at location: CGPoint) {
        let col = Int(location.x / cellSize)
        let row = Int(location.y / cellSize)
        
        guard row >= 0 && row < rowsCount && col >= 0 && col < columnsCount else { return }
        
        if tsuCampusGrid[row][col] == 1 { return }
        startLocation = GridPoint(row: row, col: col)
    }
}

#Preview {
    CampusMapView()
}
