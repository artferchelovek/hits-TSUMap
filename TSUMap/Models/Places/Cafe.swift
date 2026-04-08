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
    
    init(tempId: String, iconCord: GridPoint, entryCord: GridPoint, name: String, type: PlaceType, address: String, rating: Double, timeEntry: Time, timeClose: Time, dishes: [Dish]) {
            self.tempId = tempId
            self.iconCord = iconCord
            self.entryCord = entryCord
            self.name = name
            self.type = type
            self.address = address
            self.rating = rating
            self.timeEntry = timeEntry
            self.timeClose = timeClose
            self.dishes = dishes
        }
    
    enum CodingKeys: String, CodingKey {
            case tempId = "id"
            case name, type, iconCord, entryCord, address, rating, timeEntry, timeClose, dishes
        }
}
