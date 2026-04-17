//
//  LocationManager.swift
//  TSUMap
//
//  Created by Artem on 17.04.2026.
//

import Combine
import CoreLocation
import Foundation

enum MapBounds {
    static let minLat = MapConfig.minLat
    static let maxLat = MapConfig.maxLat
    static let minLon = MapConfig.minLon
    static let maxLon = MapConfig.maxLon
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        if location.horizontalAccuracy > 0, location.horizontalAccuracy <= 20 {
            userLocation = location
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}

func convertToGrid(location: CLLocation) -> GridPoint? {
    let lat = location.coordinate.latitude
    let lon = location.coordinate.longitude

    guard lat >= MapBounds.minLat, lat <= MapBounds.maxLat,
          lon >= MapBounds.minLon, lon <= MapBounds.maxLon
    else {
        return nil
    }

    let rowPercent = (MapBounds.maxLat - lat) / (MapBounds.maxLat - MapBounds.minLat)
    let colPercent = (lon - MapBounds.minLon) / (MapBounds.maxLon - MapBounds.minLon)

    let calculatedRow = rowPercent * Double(rowsCount)
    let calculatedCol = colPercent * Double(columnsCount)

    let clampedRow = max(0, min(Int(calculatedRow), rowsCount - 1))
    let clampedCol = max(0, min(Int(calculatedCol), columnsCount - 1))

    return GridPoint(row: clampedRow, col: clampedCol)
}

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
