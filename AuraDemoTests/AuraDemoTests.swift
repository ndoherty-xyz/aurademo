//
//  AuraDemoTests.swift
//  AuraDemoTests
//
//  Created by nick on 11/4/25.
//

import Testing
import SwiftUI
import CoreLocation
@testable import AuraDemo

struct RouteOverlayTests {
    
    @Test func calculatesRouteAspectCorrectly() {
        let route = [
            CLLocationCoordinate2D(latitude: 39.0, longitude: -104.0),
            CLLocationCoordinate2D(latitude: 39.02, longitude: -104.04)
        ]
        
        let overlay = RouteOverlay(route: route)
        let aspect = overlay.routeAspect
        
        #expect(aspect > 1.9 && aspect < 2.1)  // approximately 2.0
    }
    
    @Test func returnsNilAspectForEmptyRoute() {
        let overlay = RouteOverlay(route: [])
        #expect(overlay.routeAspect == 1)
    }
    
    @Test func returnsNilAspectForSinglePoint() {
        let route = [CLLocationCoordinate2D(latitude: 39.0, longitude: -104.0)]
        let overlay = RouteOverlay(route: route)
        #expect(overlay.routeAspect == 1)
    }
}

struct RenderTests {
    
    @MainActor
    @Test func rendersValidImage() {
        let route = [
            CLLocationCoordinate2D(latitude: 39.75, longitude: -104.99),
            CLLocationCoordinate2D(latitude: 39.76, longitude: -104.98)
        ]
        let size = CGSize(width: 390, height: 844)
        
        let image = ShareComposer(bgImage: nil, title: "Test", subtitle: "5 mi", route: route).render(size: size, scale: 1.0)
        
        #expect(image.size.width == 390)
        #expect(image.size.height == 844)
    }
}
