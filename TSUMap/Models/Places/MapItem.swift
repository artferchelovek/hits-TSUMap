//
//  PlaceBase.swift
//  TSUMap
//
//  Created by Сергей Лихачев on 08.04.2026.
//

protocol MapItem: Identifiable {
    var id: String {get}
    var iconCord: GridPoint {get}
    var entryCord: GridPoint {get}
    var name: String {get}
    var type: PlaceType {get}
    var address: String {get}
    var rating: Double {get set}
}
