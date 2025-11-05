//
//  ShareSheet.swift
//  AuraDemo
//
//  Created by nick on 11/4/25.
//
import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

struct SharePayload: Identifiable { let id = UUID(); let items: [Any] }
