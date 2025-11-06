//
//  ComposerSticker.swift
//  AuraDemo
//
//  Created by nick on 11/5/25.
//

import Foundation
import MapKit
import SwiftUI

enum StickerContent {
    case route([CLLocationCoordinate2D])
    case stat(label: String, value: String)
    case location(String)
    case pace(String)
    case customText(String)
}

struct StickerData: Identifiable {
    let id = UUID()
    var position: CGPoint
    var rotation: Angle = .zero
    var scale: CGFloat = 1.0
    var size: CGSize = .zero
    let content: StickerContent
    
    var baseRotation: Angle = .zero
    var baseScale: CGFloat = 1.0
}

// render different types:
@ViewBuilder
func stickerView(for content: StickerContent, containerSize: CGSize) -> some View {
    switch content {
    case .route(let route):
        let maxDim = containerSize.width / 2
        RouteOverlay(route: route, maxDimension: maxDim)
    case .stat(let label, let value):
        VStack {
            Text(label).font(.caption).opacity(0.8)
            Text(value).font(.system(.title, design: .serif)).bold()
        }
        .foregroundColor(.white)
    case .location(let name):
        Text(name)
            .font(.system(.headline, design: .serif))
            .foregroundColor(.white)
    case .pace(let pace):
        HStack {
            Image(systemName: "gauge")
            Text(pace)
        }
        .foregroundColor(.white)
    case .customText(let text):
        Text(text).foregroundColor(.white)
    }
}

// helper to calculate rotated bounding box
func stickerBoundingBox(for sticker: StickerData) -> CGRect {
    let w = sticker.size.width * sticker.scale
    let h = sticker.size.height * sticker.scale
    let angle = sticker.rotation.radians
    
    // bounding box dimensions after rotation
    let newWidth = abs(w * cos(angle)) + abs(h * sin(angle))
    let newHeight = abs(w * sin(angle)) + abs(h * cos(angle))
    
    return CGRect(
        x: sticker.position.x - newWidth / 2,
        y: sticker.position.y - newHeight / 2,
        width: newWidth,
        height: newHeight
    )
}
