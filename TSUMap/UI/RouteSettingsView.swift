import SwiftUI
import UniformTypeIdentifiers

struct RouteSettingsView: View {
    @ObservedObject var placeManager: PlaceManager
    
    @State var isShowOptionalView: Bool = false
    @State private var draggedPoint: GridPoint?
    
    @Binding var startLocation: GridPoint?
    @Binding var endLocation: GridPoint?
    @Binding var intermediatePoints: [GridPoint]
    
    private func getPlaceName(for point: GridPoint) -> String {
        if let place = placeManager.places.values.first(where: { $0.entryCord == point }) {
            return place.name
        }
        return "\(point.col), \(point.row)"
    }
    
    fileprivate func Topper() -> some View {
        HStack {
            Text("Изменить маршрут")
                .font(.body)
            Spacer()
            Image(systemName: "chevron.right")
                .rotationEffect(.degrees(isShowOptionalView ? 90 : 0))
                .animation(.snappy, value: isShowOptionalView)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
        .onTapGesture {
            withAnimation(.spring()) {
                isShowOptionalView.toggle()
            }
        }
    }
    
    @ViewBuilder
    private func PointRow(title: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(title).bold()
            Spacer()
        }
    }
    
    var body: some View {
        VStack {
            Topper()
                .zIndex(2)
            
            if isShowOptionalView {
                VStack(spacing: 10) {
                    PointRow(title: "Стартовая позиция", icon: "location.circle.fill", color: .blue)
                    
                    Divider()
                    
                    ForEach(intermediatePoints, id: \.self) { point in
                        HStack {
                            Image(systemName: "arrow.turn.down.right")
                                .font(.title3)
                                .foregroundColor(.primary.opacity(0.7))
                            
                            Text(getPlaceName(for: point))
                                .bold()
                            
                            Spacer()
                            
                            Image(systemName: "list.dash")
                                .foregroundColor(.primary.opacity(0.7))
                            
                            Button {
                                withAnimation {
                                    intermediatePoints.removeAll(where: { $0 == point })
                                }
                            } label: {
                                Image(systemName: "xmark.app")
                                    .font(.title3)
                                    .foregroundColor(.primary.opacity(0.7))
                            }
                            .buttonStyle(.plain) // ВАЖНО: чтобы кнопка четко ловила нажатие
                        }
                        .padding(.vertical, 4) // Добавил чуть отступа для удобства тапа
                        .contentShape(Rectangle()) // ВАЖНО: делает пустое пространство кликабельным
                        .onDrag {
                            self.draggedPoint = point
                            return NSItemProvider(object: "\(point.row)-\(point.col)" as NSString)
                        }
                        .onDrop(of: [.text], delegate: ReorderDropDelegate(
                            item: point,
                            list: $intermediatePoints,
                            draggedItem: $draggedPoint
                        ))
                        
                        Divider()
                    }
                    
                    PointRow(title: "Конечная точка", icon: "mappin.circle.fill", color: .red)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(.regularMaterial)
                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
                .cornerRadius(20)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.95, anchor: .top)),
                        removal: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.95, anchor: .top))
                    )
                )
                .zIndex(1)
            }
        }.animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0), value: isShowOptionalView)
    }
}

// ДЕЛЕГАТ ПЕРЕМЕЩЕНИЯ (Остался таким же)
struct ReorderDropDelegate: DropDelegate {
    let item: GridPoint
    @Binding var list: [GridPoint]
    @Binding var draggedItem: GridPoint?
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem,
              draggedItem != item,
              let from = list.firstIndex(of: draggedItem),
              let to = list.firstIndex(of: item) else {
            return
        }
        
        if list[to] != draggedItem {
            withAnimation(.snappy) {
                list.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        self.draggedItem = nil
        return true
    }
}

#Preview {
    RouteSettingsView(
        placeManager: PlaceManager(),
        startLocation: .constant(.init(row: 12, col: 32)),
        endLocation: .constant(.init(row: 14, col: 32)),
        intermediatePoints: .constant([.init(row: 12, col: 32), .init(row: 13, col: 32)]))
}
