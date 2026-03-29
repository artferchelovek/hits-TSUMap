//
//  VenueManager.swift
//  TSUMap
//
//  Created by Artem on 24.03.2026.
//

import Foundation
import SwiftUI
import Combine

struct VenueMetadata: Identifiable {
    let id: String
    let name: String
    var address: String = "Адрес будет доступен после кластеризации"
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    
    static func fetchInfo(for fullID: String) -> VenueMetadata {
        let components = fullID.components(separatedBy: "@")
        let name = components.first ?? fullID
        let id = components.count > 1 ? components.last! : "000"
        return VenueMetadata(id: id, name: name)
    }
}

struct AttributeDTO: Codable {
    var location: String
    var budget: String
    var time_available: String
    var food_type: String
    var queue_tolerance: String
    var weather: String
    var recommended_place: String
    
    init(from attr: Attribute) {
        self.location = attr.location
        self.budget = attr.budget
        self.time_available = attr.time_available
        self.food_type = attr.food_type
        self.queue_tolerance = attr.queue_tolerance
        self.weather = attr.weather
        self.recommended_place = attr.recommended_place
    }
    
    func toAttribute() -> Attribute {
        return Attribute(
            location: location,
            budget: budget,
            time_available: time_available,
            food_type: food_type,
            queue_tolerance: queue_tolerance,
            weather: weather,
            recommended_place: recommended_place
        )
    }
}

final class VenueManager: ObservableObject {
    @Published var allAttributes: [Attribute] = []
    
    private static let fileURL: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("user_data.json")
    }()
    
    init() {
        loadData()
    }
    
    var groupedAttributes: [String: [Attribute]] {
        Dictionary(grouping: allAttributes, by: { $0.recommended_place })
    }
    
    var uniquePlaces: [String] {
        groupedAttributes.keys.sorted()
    }
    
    func loadData() {
        if let data = try? Data(contentsOf: Self.fileURL),
           let decoded = try? JSONDecoder().decode([AttributeDTO].self, from: data) {
            self.allAttributes = decoded.map { $0.toAttribute() }
            return
        }
        resetToDefaults()
    }
    
    func save() {
        let dtos = allAttributes.map { AttributeDTO(from: $0) }
        if let data = try? JSONEncoder().encode(dtos) {
            try? data.write(to: Self.fileURL)
        }
    }
    
    func resetToDefaults() {
        guard let url = Bundle.main.url(forResource: "data", withExtension: "csv"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return
        }
        
        self.allAttributes = CVSParser(content: content)
        save()
    }
    
    func addVenue(_ attribute: Attribute) {
        allAttributes.append(attribute)
        save()
    }
    
    func removeAllEntries(named name: String) {
        allAttributes.removeAll { $0.recommended_place == name }
        save()
    }
    
    func updateVenueScenarios(placeName: String, newScenarios: [Attribute]) {
        allAttributes.removeAll { $0.recommended_place == placeName }
        
        allAttributes.append(contentsOf: newScenarios)
        
        save()
    }
}
