//
//  LocationName.swift
//  AuraDemo
//
//  Created by nick on 11/4/25.
//

import Foundation
import CoreLocation

// func to get name of place the run was in
func getRouteLocationName(route: [CLLocationCoordinate2D]) async -> String? {
    guard let first = route.first else { return nil }
    let geocoder = CLGeocoder()
    do {
        let placemarks = try await geocoder.reverseGeocodeLocation(.init(latitude: first.latitude, longitude: first.longitude))
        let p = placemarks.first
        return p?.locality ?? p?.subLocality ?? p?.name
    } catch { return nil }
}
