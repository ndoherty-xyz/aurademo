//
//  StatHelpers.swift
//  AuraDemo
//
//  Created by nick on 11/7/25.
//

import Foundation


func pacePerMile(distance: Double, duration: TimeInterval) -> String {
    let secondsPerMile = duration / distance
    let minutes = Int(secondsPerMile / 60)
    let seconds = Int(secondsPerMile.truncatingRemainder(dividingBy: 60))
    return String(format: "%d:%02d", minutes, seconds)
}

func formatTime(duration: TimeInterval) -> String {
    let m = Int(duration) / 60, s = Int(duration) % 60
    return String(format: "%dm %02ds", m, s)
}
