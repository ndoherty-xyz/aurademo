//
//  AuraDemoApp.swift
//  AuraDemo
//
//  Created by nick on 11/4/25.
//

import SwiftUI

@main
struct AuraDemoApp: App {
    @StateObject private var state = WorkoutState()
    var body: some Scene {
        WindowGroup { ContentView().environmentObject(state) }
    }
}
