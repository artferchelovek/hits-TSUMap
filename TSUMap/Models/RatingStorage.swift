//
//  RatingStorage.swift
//  TSUMap
//

import Combine
import Foundation
import SwiftUI

struct PlaceRating: Codable {
    let placeId: String
    let rating: Double
    let ratingCount: Int
}

@MainActor
final class RatingStorage: ObservableObject {
    @Published var ratings: [String: PlaceRating] = [:]

    private static let fileURL: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("place_ratings.json")
    }()

    init() {
        loadRatings()
    }

    private func loadRatings() {
        if let data = try? Data(contentsOf: Self.fileURL),
           let decoded = try? JSONDecoder().decode([String: PlaceRating].self, from: data)
        {
            ratings = decoded
            return
        }
        ratings = [:]
    }

    func save() {
        if let data = try? JSONEncoder().encode(ratings) {
            try? data.write(to: Self.fileURL)
        }
    }

    func updateRating(for placeId: String, newRating: Double) {
        guard let existing = ratings[placeId] else {
            ratings[placeId] = PlaceRating(placeId: placeId, rating: newRating, ratingCount: 1)
            save()
            return
        }

        let totalRating = existing.rating * Double(existing.ratingCount) + newRating
        let newCount = existing.ratingCount + 1
        let averageRating = totalRating / Double(newCount)

        ratings[placeId] = PlaceRating(
            placeId: placeId,
            rating: averageRating,
            ratingCount: newCount
        )
        save()
    }

    func getRating(for placeId: String) -> PlaceRating? {
        ratings[placeId]
    }
}
