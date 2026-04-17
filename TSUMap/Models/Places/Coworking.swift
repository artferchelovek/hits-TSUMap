import Foundation

struct Coworking: MapItem, Codable, Identifiable {
    private let tempId: String
    private let tempWorkSchedule: [String: Time]
    var id: String {
        "\(type.rawValue)_\(tempId)"
    }

    var workSchedule: [WeekDay: Time] {
        var dict: [WeekDay: Time] = [:]
        for (day, time) in tempWorkSchedule {
            if let currentDay = WeekDay(rawValue: day) {
                dict[currentDay] = time
            }
        }
        return dict
    }

    var iconCord: GridPoint
    var entryCord: GridPoint
    var name: String
    var type: PlaceType
    var address: String
    var rating: Double
    var ratingCount: Int = 0

    var capacity: Int
    var comfort: Int

    enum CodingKeys: String, CodingKey {
        case tempId = "id"
        case tempWorkSchedule = "workSchedule"
        case iconCord, entryCord, name, type, rating, address, capacity, comfort
    }
}
