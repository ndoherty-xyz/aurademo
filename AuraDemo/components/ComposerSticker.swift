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
    case compoundStat(RunSummary)
    case location(String)
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
    
    var stickerColor: Color = Color.white
}

// render different types:
@ViewBuilder
func stickerView(for content: StickerContent, containerSize: CGSize, scaleToFit: Bool = false) -> some View {
    let baseView = Group {
        switch content {
        case .route(let route):
            let maxDim = containerSize.width / 2
            RouteOverlay(route: route, maxDimension: maxDim)
        case .stat(let label, let value):
            VStack {
                Text(label).font(.caption).opacity(0.8)
                Text(value).font(.system(.title, design: .serif)).bold().italic()
            }
        case .compoundStat(let workout):
            VStack(spacing: 6) {
                VStack {
                    Text("Distance").font(.caption).opacity(0.8)
                    Text(String(format: "%.2f mi", workout.distanceMiles)).font(.system(.title, design: .serif)).bold().italic()
                }
                VStack {
                    Text("Pace").font(.caption).opacity(0.8)
                    Text(pacePerMile(distance: workout.distanceMiles, duration: workout.duration) + "/mi").font(.system(.title, design: .serif)).bold().italic()
                }
                VStack {
                    Text("Time").font(.caption).opacity(0.8)
                    Text(formatTime(duration: workout.duration)).font(.system(.title, design: .serif)).bold().italic()
                }
            }
        case .location(let name):
            Text(name)
                .font(.system(.title, design: .serif)).bold().italic()
        case .customText(let text):
            Text(text).font(.system(.title, design: .serif)).bold().italic()
        }
    }
    
    if scaleToFit {
        ScaledStickerView(content: baseView, containerSize: containerSize)
    } else {
        baseView
    }
}


struct ScaledStickerView<Content: View>: View {
    let content: Content
    let containerSize: CGSize
    @State private var intrinsicSize: CGSize = .zero
    
    var body: some View {
        content
            .fixedSize()
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: StickerSizeKey.self,
                        value: geo.size
                    )
                }
            )
            .onPreferenceChange(StickerSizeKey.self) { size in
                intrinsicSize = size
            }
            .scaleEffect(calculateScale())
            .frame(width: containerSize.width, height: containerSize.height)
    }
    
    private func calculateScale() -> CGFloat {
        guard intrinsicSize.width > 0 && intrinsicSize.height > 0 else {
            return 1.0
        }
        
        let padding: CGFloat = 20
        let scaleX = (containerSize.width - padding) / intrinsicSize.width
        let scaleY = (containerSize.height - padding) / intrinsicSize.height
        
        return min(scaleX, scaleY, 1.0)
    }
}

struct StickerSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
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
