import Foundation
import SwiftUI

class Cluster: Identifiable {
    var id = UUID()
    var medoid: Cafe
    var placesInClust: [Cafe] = []
    var color: Color
    init(medoid: Cafe, color: Color) {
        self.medoid = medoid
        self.color = color
    }
}
