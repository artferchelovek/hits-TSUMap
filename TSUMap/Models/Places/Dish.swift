//
//  Dish 2.swift
//  TSUMap
//
//  Created by Сергей Лихачев on 08.04.2026.
//
import Foundation

struct Dish: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var price: Double
    var type: DishType
    
    enum CodingKeys: String, CodingKey {
            case name
            case price
            case type
        }
}

enum DishType: String, Codable, Hashable {
    case breakfast, lunch, dinner, drink, snack, desert
}
