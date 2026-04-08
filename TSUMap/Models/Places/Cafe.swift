//
//  Place.swift
//  TSUMap
//
//  Created by Сергей Лихачев on 03.04.2026.
//
import Foundation

struct Cafe: MapItem, Hashable, Codable, Identifiable {
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
    var dishes: [Dish]
    
    enum CodingKeys: String, CodingKey {
            case tempId = "id"
            case name, type, iconCord, entryCord, address, rating, timeEntry, timeClose, dishes
        }
}
