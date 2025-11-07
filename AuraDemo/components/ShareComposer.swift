//
//  ShareComposer.swift
//  AuraDemo
//
//  Created by nick on 11/4/25.
//

import SwiftUI
import MapKit

struct ShareComposer: View {
    let bgImage: UIImage?
    let title: String
    let subtitle: String
    let route: [CLLocationCoordinate2D]
    @Binding var stickers: [StickerData]  // receive binding
    @Binding var selectedColor: Color
    @Binding var activeStickerId: UUID?
    
    @State private var activeGuidelines: Set<Guideline> = []
    @State private var deletingStickerId: UUID? = nil
    
    var image: some View {
        Group {
            if let img = bgImage {
                GeometryReader{ geo in
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
                        .overlay(
                            // readability gradient
                            LinearGradient(
                                stops: [
                                    .init(color: .black.opacity(0.35), location: 0.0),
                                    .init(color: .black.opacity(0.1), location: 0.5),
                                    .init(color: .black.opacity(0.45), location: 1.0)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .clipped()
                }
            } else {
                EmptyView()
            }
        }
    }
    
    var stickerOverlay: some View {
        GeometryReader {geo in
            ForEach($stickers) { $sticker in
                stickerView(for: sticker.content, containerSize: geo.size)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    if sticker.size == .zero {
                                        sticker.size = geo.size
                                    }
                                }
                        }
                    )
                    .foregroundColor(sticker.stickerColor)
                    .scaleEffect(sticker.scale)
                    .rotationEffect(sticker.rotation)
                    .position(sticker.position)
                    .onLongPressGesture(minimumDuration: 0.5) {
                        SendSuccessHaptic()
                        stickers.removeAll { $0.id == sticker.id }
                        deletingStickerId = nil
                    }
                    .onTapGesture {
                        activeStickerId = sticker.id
                    }
                    .gesture(DragGesture()
                        .onChanged { value in
                            activeStickerId = sticker.id
                            
                            let snapThreshold: CGFloat = 5
                            let padding: CGFloat = 20
                            
                            var newPos = value.location
                            var guidelines: Set<Guideline> = []
                            
                            // calculate potential bounding box at drag location
                            let w = sticker.size.width * sticker.scale
                            let h = sticker.size.height * sticker.scale
                            let angle = sticker.rotation.radians
                            
                            let boxWidth = abs(w * cos(angle)) + abs(h * sin(angle))
                            let boxHeight = abs(w * sin(angle)) + abs(h * cos(angle))
                            
                            let potentialBox = CGRect(
                                x: newPos.x - boxWidth / 2,
                                y: newPos.y - boxHeight / 2,
                                width: boxWidth,
                                height: boxHeight
                            )
                            
                            let centerX = geo.size.width / 2
                            let centerY = geo.size.height / 2
                            
                            if abs(potentialBox.maxX - (geo.size.width - padding)) < snapThreshold {
                                newPos.x = geo.size.width - padding - potentialBox.width / 2
                                guidelines.insert(.right)
                                
                                if sticker.position.x != newPos.x {
                                    SendLightImpactHaptic()
                                }
                            }
                            else if abs(potentialBox.minX - padding) < snapThreshold {
                                
                                newPos.x = padding + potentialBox.width / 2
                                guidelines.insert(.left)
                                
                                if sticker.position.x != newPos.x {
                                    SendLightImpactHaptic()
                                }
                            }
                            
                            if abs(potentialBox.maxY - (geo.size.height - padding)) < snapThreshold {
                                newPos.y = geo.size.height - padding - potentialBox.height / 2
                                guidelines.insert(.bottom)
                                
                                if sticker.position.y != newPos.y {
                                    SendLightImpactHaptic()
                                }
                            }
                            else if abs(potentialBox.minY - padding) < snapThreshold {
                                newPos.y = padding + potentialBox.height / 2
                                guidelines.insert(.top)
                                
                                if sticker.position.y != newPos.y {
                                    SendLightImpactHaptic()
                                }
                            }
                            
                            if abs(newPos.x - centerX) < snapThreshold {
                                newPos.x = centerX
                                guidelines.insert(.centerVertical)
                                
                                if sticker.position.x != newPos.x {
                                    SendLightImpactHaptic()
                                }
                            }
                            if abs(newPos.y - centerY) < snapThreshold {
                                newPos.y = centerY
                                guidelines.insert(.centerHorizontal)
                                
                                if sticker.position.y != newPos.y {
                                    SendLightImpactHaptic()
                                }
                            }
                            
                            
                            
                            activeGuidelines = guidelines
                            sticker.position = newPos
                        }.onEnded({ _ in
                            activeGuidelines = []
                        })
                    )
                    .simultaneousGesture(MagnificationGesture()
                        .onChanged { value in
                            activeStickerId = sticker.id
                            sticker.scale = sticker.baseScale * value
                        }
                        .onEnded { _ in
                            sticker.baseScale = sticker.scale
                        }
                    )
                    .simultaneousGesture( RotationGesture()
                        .onChanged { value in
                            activeStickerId = sticker.id
                            
                            let newRotation = sticker.baseRotation + value
                            let threshold: Double = 10 // degrees
                            var degrees = newRotation.degrees.truncatingRemainder(dividingBy: 360)
                            
                            // normalize to 0-360
                            if degrees < 0 { degrees += 360 }
                            
                            // snap to 0, 90, 180, 270
                            let snapAngles: [Double] = [0, 90, 180, 270, 360]
                            for snapAngle in snapAngles {
                                if abs(degrees - snapAngle) < threshold {
                                    let newAngle = Angle(degrees: snapAngle == 360 ? 0 : snapAngle)
                                    if (sticker.rotation != newAngle) {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                    sticker.rotation = newAngle
                                    return
                                }
                            }
                            
                            sticker.rotation = newRotation
                        }
                        .onEnded { _ in
                            sticker.baseRotation = sticker.rotation
                        }
                    )
            }
            ForEach(Array(activeGuidelines), id: \.self) { guide in
                guidelineView(for: guide, in: geo.size)
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.black
            // Background: image if present, else gradient
            image
            stickerOverlay
        }
        .onTapGesture {
            activeStickerId = nil
        }
        .clipped()
    }
    
    public func render(size: CGSize, scale: CGFloat = 3.0) -> UIImage {
        let view = ShareComposer(bgImage: bgImage, title: title, subtitle: subtitle, route: route, stickers: $stickers, selectedColor: $selectedColor, activeStickerId: $activeStickerId)
            .frame(width: size.width, height: size.height)
            .transaction { $0.disablesAnimations = true }
        
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        renderer.isOpaque = false
        return renderer.uiImage ?? UIImage()
    }
    
}


enum Guideline: Hashable {
    case centerVertical, centerHorizontal
    case left, right, top, bottom
}

@ViewBuilder
func guidelineView(for guide: Guideline?, in size: CGSize) -> some View {
    if let guide = guide {
        switch guide {
        case .centerVertical:
            Rectangle()
                .fill(.blue.opacity(0.6))
                .frame(width: 1)
                .position(x: size.width / 2, y: size.height / 2)
        case .centerHorizontal:
            Rectangle()
                .fill(.blue.opacity(0.6))
                .frame(height: 1)
                .position(x: size.width / 2, y: size.height / 2)
        case .left:
            Rectangle()
                .fill(.blue.opacity(0.6))
                .frame(width: 1, height: size.height)
                .position(x: 20, y: size.height / 2)
        case .right:
            Rectangle()
                .fill(.blue.opacity(0.6))
                .frame(width: 1, height: size.height)
                .position(x: size.width - 20, y: size.height / 2)
        case .top:
            Rectangle()
                .fill(.blue.opacity(0.6))
                .frame(height: 1)
                .position(x: size.width / 2, y: 20)
        case .bottom:
            Rectangle()
                .fill(.blue.opacity(0.6))
                .frame(height: 1)
                .position(x: size.width / 2, y: size.height - 20)
        }
    }
}
