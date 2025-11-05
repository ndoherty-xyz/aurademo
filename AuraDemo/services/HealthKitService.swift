//
//  HealthKitService.swift
//  AuraDemo
//
//  Created by nick on 11/4/25.
//

import HealthKit
import CoreLocation

// Type to form runs into
struct RunSummary: Hashable {
    let distanceMiles: Double
    let duration: TimeInterval
    let start: Date
    let end: Date
    let workout: HKWorkout
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(workout.uuid)
    }
    
    static func == (lhs: RunSummary, rhs: RunSummary) -> Bool {
        lhs.workout.uuid == rhs.workout.uuid
    }
}

final class HealthKitService {
    private let store = HKHealthStore()

    // func to request auth for healthkit data
    func requestAuthorization() async throws {
        let routeType = HKSeriesType.workoutRoute()

        let readTypes = Set<HKObjectType>([
            HKObjectType.workoutType(),
            routeType,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ])

        try await store.requestAuthorization(toShare: [], read: readTypes)
    }

    // func to get the most recent run activity from healthkit
    func lastRun() async throws -> RunSummary? {
        let predicate = HKQuery.predicateForWorkouts(with: .running)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<RunSummary?, Error>) in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    cont.resume(throwing: error)
                    return
                }

                guard let w = samples?.first as? HKWorkout else {
                    cont.resume(returning: nil);
                    return
                }

                let meters = w.totalDistance?.doubleValue(for: .meter()) ?? 0
                cont.resume(returning: RunSummary(
                    distanceMiles: meters / 1609.34,
                    duration: w.duration,
                    start: w.startDate,
                    end: w.endDate,
                    workout: w
                ))
            }

            self.store.execute(query)
        }
    }
    
    
    // func to get the runs in the past month
    func runsInPastMonth() async throws -> [RunSummary] {
        let calendar = Calendar.current
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date())
        
        let typePredicate = HKQuery.predicateForWorkouts(with: .running)
        let datePredicate = HKQuery.predicateForSamples(withStart: oneMonthAgo, end: Date())
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [typePredicate, datePredicate])
        
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { cont in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: 50,
                sortDescriptors: [sort]
            ) { _, samples, error in
                
                if let error {
                    cont.resume(throwing: error)
                    return
                }
                
                guard let workouts = samples as? [HKWorkout] else {
                    cont.resume(returning: [])
                    return
                }
                
                let summaries = workouts.map { w in
                    let meters = w.totalDistance?.doubleValue(for: .meter()) ?? 0
                    return RunSummary(distanceMiles: meters / 1609.34, duration: w.duration, start: w.startDate, end: w.endDate, workout: w)
                }
                
                cont.resume(returning: summaries)
            }
            
            self.store.execute(query)
        }
    }

    // func to get the route coordinates of a workout
    func route(for workout: HKWorkout) async throws -> [CLLocationCoordinate2D] {
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)

        // fetch the route object
        let routeSample: HKWorkoutRoute? = try await withCheckedThrowingContinuation { cont in
            let q = HKSampleQuery(
                sampleType: routeType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, error in
                if let e = error { cont.resume(throwing: e); return }
                cont.resume(returning: samples?.first as? HKWorkoutRoute)
            }
            self.store.execute(q)
        }

        guard let route = routeSample else { return [] }

        // get the actual location points from the route
        return try await withCheckedThrowingContinuation { cont in
            var coords: [CLLocationCoordinate2D] = []
            let q = HKWorkoutRouteQuery(route: route) { _, locationsOrNil, done, err in
                if let err = err { cont.resume(throwing: err); return }
                if let locationsOrNil {
                    coords.append(contentsOf: locationsOrNil.map(\.coordinate))
                }
                if done { cont.resume(returning: coords) }
            }
            self.store.execute(q)
        }
    }
}
