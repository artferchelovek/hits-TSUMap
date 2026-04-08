import Foundation

struct Coworking: MapItem, Codable, Identifiable {
    private let tempId: String
    var id: String {
         "\(type.rawValue)_\(tempId)"
    }
    var iconCord: GridPoint
    var entryCord: GridPoint
    var name: String
    var type: PlaceType
    var address: String
    var rating: Double
    var timeEntry: Time
    var timeClose: Time
    
    var capacity: Int
    var comfort: Int
    
    enum CodingKeys: String, CodingKey {
        case tempId = "id"
        case iconCord, entryCord, name, type, rating, timeEntry, timeClose, address, capacity, comfort
    }
}
