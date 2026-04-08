import Foundation
import SwiftUI

class Cluster: Identifiable {
    var id = UUID()
    var medoid: Place
    var placesInClust: [Place] = []
    var color: Color
    init(medoid: Place, color: Color) {
        self.medoid = medoid
        self.color = color
    }
}
