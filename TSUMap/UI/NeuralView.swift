//
//  Untitled.swift
//  TSUMap
//
//  Created by Екатерина Кондрашова on 30.03.2026.
//
import SwiftUI

struct NeuralView: View {
    let gridSize = 50
    let cellSize = 7.0
    
    @State private var grid: [[Double]]
    @State private var predictedDigit: Int?
    
    @ObservedObject private var manager = NeuralManager.shared
    
    init() {
        _grid = State(initialValue: Array(repeating: Array(repeating: 0.0, count: gridSize), count: gridSize))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(manager.isTraining ? "Идёт обучение сети..." : "Нарисуйте оценку от 0 до 9")
                .font(.title2)
                .bold()
            
            Canvas { context, _ in
                var drawnPath = Path()
                
                for row in 0..<gridSize {
                    for col in 0..<gridSize where grid[row][col] == 1.0 {
                        let rect = CGRect(
                            x: CGFloat(col) * CGFloat(cellSize),
                            y: CGFloat(row) * CGFloat(cellSize),
                            width: CGFloat(cellSize),
                            height: CGFloat(cellSize)
                        )
                        drawnPath.addRect(rect)
                    }
                }
                context.fill(drawnPath, with: .color(.primary))
            }
            .frame(width: CGFloat(gridSize) * CGFloat(cellSize), height: CGFloat(gridSize) * CGFloat(cellSize))
            .border(Color.blue, width: 1)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let row = Int(value.location.y / CGFloat(cellSize))
                        let col = Int(value.location.x / CGFloat(cellSize))
                        fillPixel(row: row, col: col)
                        fillPixel(row: row + 1, col: col)
                        fillPixel(row: row - 1, col: col)
                        fillPixel(row: row, col: col + 1)
                        fillPixel(row: row, col: col - 1)
                        fillPixel(row: row + 1, col: col + 1)
                        fillPixel(row: row - 1, col: col - 1)
                        fillPixel(row: row + 1, col: col - 1)
                        fillPixel(row: row - 1, col: col + 1)
                        
                    }
            )
            
            if let digit = predictedDigit {
                Text(digit == -1 ? "Ошибка: Сеть выдала NaN" : "Ваша оценка: \(digit)")
                    .font(.title)
                    .bold()
                    .foregroundColor(digit == -1 ? .red : .blue)
            }
            
            HStack(spacing: 15) {
                Button("Очистить") {
                    clearCanvas()
                    predictedDigit = nil
                }
                .buttonStyle(.bordered)
                
                Button("Оценить") {
                    let networkInput = getNeuralNetworkInput()
                    predictedDigit = manager.network.predict(input: networkInput)
                }
                .buttonStyle(.borderedProminent)
                .disabled(manager.isTraining)
            }
            
            Button("Переобучить заново") {
                manager.trainFromScratch()
            }
            .buttonStyle(.bordered)
            .tint(.orange)
            .disabled(manager.isTraining)
        }
        .padding()
    }
    
    private func fillPixel(row: Int, col: Int) {
        if row >= 0 && row < gridSize && col >= 0 && col < gridSize {
            grid[row][col] = 1.0
        }
    }
    
    private func clearCanvas() {
        grid = Array(repeating: Array(repeating: 0.0, count: gridSize), count: gridSize)
    }
    
    private func getNeuralNetworkInput() -> [Double] {
        return grid.flatMap { $0 }
    }
}
#Preview {
    ContentView()
}

