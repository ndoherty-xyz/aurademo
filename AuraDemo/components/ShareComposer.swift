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

    var body: some View {
        ZStack {
            Color.black
            // Background: image if present, else gradient
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
            }
            VStack(spacing: 6) {
                // Top typography
                VStack(spacing: 3) {
                    Text(title)
                        .font(.system(.title, design: .serif).weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(alignment: .center)
                    Text(subtitle)
                        .font(.system(.callout, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(alignment: .center)
                    
                }
                .frame(alignment: .center)
                .padding(.horizontal, 18)
                .padding(.top, 18)
                
                
                RouteOverlay(route: route)
                    .padding(.bottom, 12)
            }
        }
        .clipped()
    }
    
    public func render(size: CGSize, scale: CGFloat = 3.0) -> UIImage {
        let view = ShareComposer(bgImage: bgImage, title: title, subtitle: subtitle, route: route)
            .frame(width: size.width, height: size.height)
            .transaction { $0.disablesAnimations = true }
        
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        renderer.isOpaque = false
        return renderer.uiImage ?? UIImage()
    }
    
}
