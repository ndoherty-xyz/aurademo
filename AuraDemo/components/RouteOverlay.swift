//
//  RouteOverlay.swift
//  AuraDemo
//
//  Created by nick on 11/4/25.
//

import SwiftUI
import CoreLocation

struct RouteBounds {
    let minLat: Double, maxLat: Double
    let minLon: Double, maxLon: Double
}

struct RouteOverlay: View {
    let route: [CLLocationCoordinate2D]
    let innerPad: CGFloat = 14
    let lineMin: CGFloat = 3

    var body: some View {
        GeometryReader { geo in
            if let bounds = routeBounds {
                pathForRoute(bounds: bounds, in: geo.size)
                    .stroke(.white, lineWidth: max(min(geo.size.width, geo.size.height) * 0.012, lineMin))
            }
        }
        .aspectRatio(max(routeAspect, 0.6), contentMode: .fit) // width drives height
        .frame(maxWidth: .infinity)
    }
    
    // func to get lat/long bounds of the route
    var routeBounds: RouteBounds? {
            guard route.count > 1 else { return nil }
            let lats = route.map(\.latitude), lons = route.map(\.longitude)
            guard let minLat = lats.min(), let maxLat = lats.max(),
                  let minLon = lons.min(), let maxLon = lons.max(),
                  maxLat > minLat, maxLon > minLon
            else { return nil }
            return RouteBounds(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon)
        }

    // func to calculate aspect ratio of the route
    var routeAspect: CGFloat {
        guard let b = routeBounds else { return 1 }
        return CGFloat((b.maxLon - b.minLon) / (b.maxLat - b.minLat))
    }
    
    // func to draw the path for the route
    func pathForRoute(bounds: RouteBounds, in size: CGSize) -> Path {
        let contentW = size.width - 2*innerPad
        let contentH = size.height - 2*innerPad
        
        let routeW = CGFloat(bounds.maxLon - bounds.minLon)
        let routeH = CGFloat(bounds.maxLat - bounds.minLat)
        let scale = min(contentW / routeW, contentH / routeH)
        
        let scaledW = routeW * scale
        let scaledH = routeH * scale
        let offsetX = (size.width - scaledW) / 2
        let offsetY = (size.height - scaledH) / 2
        
        func toPoint(_ c: CLLocationCoordinate2D) -> CGPoint {
            CGPoint(
                x: CGFloat(c.longitude - bounds.minLon) * scale + offsetX,
                y: CGFloat(bounds.maxLat - c.latitude) * scale + offsetY
            )
        }
        
        var path = Path()
        path.move(to: toPoint(route[0]))
        for coord in route.dropFirst() {
            path.addLine(to: toPoint(coord))
        }
        return path
    }
}
