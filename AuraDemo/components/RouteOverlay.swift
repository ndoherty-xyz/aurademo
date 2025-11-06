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
    var maxDimension: CGFloat = 200 // or pass this in based on container size
    
    var lineWidth: CGFloat {
        maxDimension * 0.015
    }
    
    var body: some View {
        
        if let bounds = routeBounds {
            pathForRoute(bounds: bounds, in: routeSize)
                .stroke(.white, lineWidth: lineWidth)
                .frame(width: routeSize.width, height: routeSize.height)
        }
        
    }
    
    var routeBounds: RouteBounds? {
        guard route.count > 1 else { return nil }
        let lats = route.map(\.latitude), lons = route.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max(),
              maxLat > minLat, maxLon > minLon
        else { return nil }
        return RouteBounds(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon)
    }
    
    var routeAspect: CGFloat {
        guard let b = routeBounds else { return 1 }
        return CGFloat((b.maxLon - b.minLon) / (b.maxLat - b.minLat))
    }
    
    // calculate tight bounding size
    var routeSize: CGSize {
        let aspect = routeAspect
        
        if aspect > 1 {
            // wider than tall
            let width = min(maxDimension, maxDimension * aspect)
            return CGSize(width: width, height: width / aspect)
        } else {
            // taller than wide
            let height = min(maxDimension, maxDimension / aspect)
            return CGSize(width: height * aspect, height: height)
        }
    }
    
    func pathForRoute(bounds: RouteBounds, in size: CGSize) -> Path {
        let routeW = CGFloat(bounds.maxLon - bounds.minLon)
        let routeH = CGFloat(bounds.maxLat - bounds.minLat)
        let scale = min(size.width / routeW, size.height / routeH)
        
        func toPoint(_ c: CLLocationCoordinate2D) -> CGPoint {
            CGPoint(
                x: CGFloat(c.longitude - bounds.minLon) * scale,
                y: CGFloat(bounds.maxLat - c.latitude) * scale
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
