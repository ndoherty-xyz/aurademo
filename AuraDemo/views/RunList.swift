//
//  RunList.swift
//  AuraDemo
//
//  Created by nick on 11/5/25.
//

import SwiftUI
import Foundation

struct RunListView: View {
    
    @State private var workouts: [RunSummary] = []
    @State private var isLoading = true
    
    let hk = HealthKitService()
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Your runs")
                    .fontWeight(.semibold)
                    .font(.headline)
                List(workouts, id: \.workout.uuid) { workout in
                    NavigationLink(value: workout) {
                        VStack(alignment: .leading) {
                            Text("\(workout.distanceMiles, specifier: "%.2f") mi")
                            Text(workout.start.formatted())
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }.navigationDestination(for: RunSummary.self) { workout in
                    WorkoutImageComposer(workout: workout)
                }.preferredColorScheme(.dark)
            }
        }.task {
            do {
                try await workouts = hk.runsInPastMonth()
            } catch {
                print("error loading workouts")
            }
        }
    }
}
