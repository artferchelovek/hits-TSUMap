//
//  PlaceType.swift
//  TSUMap
//
//  Created by Сергей Лихачев on 08.04.2026.
//

enum PlaceType: String, Hashable, Codable {
    case coffee
    case product
    case cafe
    case sight
    case coworkingSpace
    
    func iconName() -> String {
        switch self {
        case .coffee: "cup.and.saucer.fill"
        case .cafe: "fork.knife"
        case .product: "basket"
        case .sight: "star.fill"
        case .coworkingSpace: "person.3.fill"
        }
    }
}
