//
//  WorkoutState.swift
//  AuraDemo
//
//  Created by nick on 11/4/25.
//

import SwiftUI
import CoreLocation

@MainActor
final class WorkoutState: ObservableObject {
    enum Phase { case idle, loading, ready, error(String) }
    @Published var phase: Phase = .idle
    @Published var route: [CLLocationCoordinate2D] = []
    @Published var distanceMiles: Double = 0
    @Published var duration: TimeInterval = 0
    @Published var locationName: String? = nil
    
    private let hk = HealthKitService()
    
    func loadLastRun(onSuccess: () -> Void) async {
        phase = .loading
        do {
            try await hk.requestAuthorization()
            if let last = try await hk.lastRun() {
                distanceMiles = last.distanceMiles
                duration = last.duration
                route = try await hk.route(for: last.workout)
                locationName = await getRouteLocationName(route: route)
                phase = .ready
                // Prompt for a photo as soon as data is ready
                onSuccess()
            } else {
                phase = .error("No recent runs found.")
            }
        } catch {
            phase = .error(error.localizedDescription)
        }
    }
}
