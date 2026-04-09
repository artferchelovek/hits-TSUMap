//
//  NeuralView.swift
//  TSUMap
//
//  Created by Екатерина Кондрашова on 30.03.2026.
//
import SwiftUI

enum RatingStage {
    case drawing
    case result
    case confirmed
}

struct NeuralView: View {
    let gridSize = 50
    let cellSize = 7.0
    
    @State private var grid: [[Double]]
    @State private var predictedDigit: Int?
    @State private var stage: RatingStage = .drawing
    @State private var oldRating: Double = 0
    @State private var newRating: Double = 0
    @State private var showArrow = false
    
    @ObservedObject private var manager = NeuralManager.shared
    
    @Binding var place: any MapItem
    @Binding var isPresented: Bool

    init(place: Binding<any MapItem>, isPresented: Binding<Bool>) {
        _grid = State(initialValue: Array(repeating: Array(repeating: 0.0, count: gridSize), count: gridSize))
        self._place = place
        self._isPresented = isPresented
    }
    
    fileprivate func placeHeader() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name)
                        .font(.title2)
                        .bold()
                    Text(place.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                    
                    if showArrow {
                        Text("\(oldRating, specifier: "%.1f")")
                            .font(.headline)
                            .strikethrough(true, color: .secondary)
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .transition(.opacity)
                    }
                    
                    Text("\(newRating > 0 ? newRating : place.rating, specifier: "%.1f")")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .scaleEffect(showArrow ? 1.1 : 1)
                        .animation(.spring(response: 0.3), value: showArrow)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
            }
            
            Label("1 оценка", systemImage: "person.fill")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .padding(.horizontal)
    }
    
    private var drawingCanvas: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                if stage == .drawing {
                    Text("Нарисуйте цифру")
                        .font(.title3)
                        .bold()
                    Text("От 0 до 9")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if stage == .result {
                    if let digit = predictedDigit, digit != -1 {
                        Text("Ваша оценка: \(digit)")
                            .font(.title2)
                            .bold()
                            .transition(.opacity)
                    } else {
                        Text("Не удалось распознать")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.red)
                            .transition(.opacity)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: stage)
            
            Canvas { context, _ in
                let canvasRect = CGRect(
                    x: 0, y: 0,
                    width: CGFloat(gridSize) * cellSize,
                    height: CGFloat(gridSize) * cellSize
                )
                context.fill(Path(roundedRect: canvasRect, cornerRadius: 12), with: .color(.secondary.opacity(0.08)))
                
                var drawnPath = Path()
                for row in 0..<gridSize {
                    for col in 0..<gridSize where grid[row][col] == 1.0 {
                        let rect = CGRect(
                            x: CGFloat(col) * cellSize,
                            y: CGFloat(row) * cellSize,
                            width: cellSize,
                            height: cellSize
                        )
                        drawnPath.addRect(rect)
                    }
                }
                context.fill(drawnPath, with: .color(.blue))
            }
            .frame(width: CGFloat(gridSize) * cellSize, height: CGFloat(gridSize) * cellSize)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in handleDrag(at: value.location) }
            )
        }
        .padding()
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        if stage == .drawing {
            Button {
                let networkInput = getNeuralNetworkInput()
                predictedDigit = manager.neuralNetworkPredict(input: networkInput)
                if let digit = predictedDigit, digit != -1 {
                    oldRating = place.rating
                    newRating = (oldRating + Double(digit)) / 2.0
                    withAnimation(.spring(response: 0.4)) {
                        stage = .result
                        showArrow = true
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Оценить")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
        } else if stage == .result {
            HStack(spacing: 12) {
                Button {
                    withAnimation {
                        clearCanvas()
                        predictedDigit = nil
                        stage = .drawing
                        showArrow = false
                        newRating = oldRating
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Нарисовать заново")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                
                Button {
                    withAnimation {
                        stage = .confirmed
                    }
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Подтвердить")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
            }
        } else {
            Button {
                self.isPresented = false
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Готово")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                placeHeader()
                
                Divider()
                    .padding(.horizontal)
                
                drawingCanvas
                
                Spacer(minLength: 20)
                
                actionButtons
                    .padding(.horizontal)
                    .animation(.spring(response: 0.3), value: stage)
            }
            .padding(.vertical)
        }
    }
    
    @Environment(\.dismiss) private var dismiss
}

extension NeuralView {
    
    private func handleDrag(at location: CGPoint) {
        let row = Int(location.y / CGFloat(cellSize))
        let col = Int(location.x / CGFloat(cellSize))
        
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
    NeuralView(
        place: .constant(Cafe(
            tempId: "001",
            iconCord: .init(row: 10, col: 10),
            entryCord: .init(row: 15, col: 21),
            name: "Абрикос",
            type: .cafe,
            address: "Московский тракт, 17",
            rating: 9.0,
            dishes: []
        )),
        isPresented: .constant(true)
    )
}
