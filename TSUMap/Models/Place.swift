//
//  Place.swift
//  TSUMap
//
//  Created by Сергей Лихачев on 03.04.2026.
//
import Foundation

struct Place: Hashable, Codable, Identifiable {
    var id: String
    var iconCord: GridPoint
    var entryCord: GridPoint
    var name: String
    var type: PlaceType
    var address: String
}

enum PlaceType: String, Hashable, Codable {
    case coffee
    case product
    case cafe
    
    func iconName() -> String {
        switch self {
        case .coffee: "cup.and.saucer.fill"
        case .cafe: "fork.knife"
        case .product: "basket"
        }
    }
}
