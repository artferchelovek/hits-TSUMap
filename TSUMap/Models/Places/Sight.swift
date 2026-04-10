//
//  sight.swift
//  TSUMap
//
//  Created by Сергей Лихачев on 08.04.2026.
//

struct Sight: MapItem, Codable, Identifiable, Hashable {
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
    var ratingCount: Int = 0

    enum CodingKeys: String, CodingKey {
        case tempId = "id"
        case iconCord, entryCord, name, type, address, rating
    }
}
