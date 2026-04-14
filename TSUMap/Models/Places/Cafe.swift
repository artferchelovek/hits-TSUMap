//
//  Place.swift
//  TSUMap
//
//  Created by Сергей Лихачев on 03.04.2026.
//
import Foundation

struct Cafe: MapItem, Hashable, Codable, Identifiable {
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
    var dishes: [Dish]

    init(
        tempId: String,
        iconCord: GridPoint,
        entryCord: GridPoint,
        name: String,
        type: PlaceType,
        address: String,
        rating: Double,
        ratingCount: Int = 0,
        dishes: [Dish]
    ) {
        self.tempId = tempId
        self.iconCord = iconCord
        self.entryCord = entryCord
        self.name = name
        self.type = type
        self.address = address
        self.rating = rating
        self.ratingCount = ratingCount
        self.dishes = dishes
        tempWorkSchedule = [:]
    }

    enum CodingKeys: String, CodingKey {
        case tempId = "id"
        case tempWorkSchedule = "workSchedule"
        case name, type, iconCord, entryCord, address, rating, dishes
    }
}
