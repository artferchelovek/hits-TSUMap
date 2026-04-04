/*
func getPlaceById(id: String) -> [Place]
*/

import Foundation
import SwiftUI
import Combine
@MainActor
final class PlaceManager: ObservableObject {
    @Published var places: [String: Place] = [:]
    init() {loadData()}
    
    private func loadData() {
        guard let jsonURL = Bundle.main.url(forResource: "dataPlace", withExtension: "json") else {
            print("ВСЕ ЕЩЕ НЕ РАБОТАЕТ")
                    return
                }
        do {
            let data = try Data(contentsOf: jsonURL)
            
            let decoderPlaces = try JSONDecoder().decode([Place].self, from: data)
            var dict: [String: Place] = [:]
            for place in decoderPlaces {
                dict[place.id] = place
            }
            
                self.places = dict
        } catch {
            print(error)
        }
    }
}
