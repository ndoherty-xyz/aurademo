//
//  WorkoutImageComposer.swift
//  AuraDemo
//
//  Created by nick on 11/5/25.
//

import Foundation
import SwiftUI
import PhotosUI

let pad = 8.0

enum AspectRatioOption {
    case story
    case square
    
    var ratio: CGFloat {
        switch self {
        case .story: return 9.0 / 16.0
        case .square: return 1.0
        }
    }
}

struct WorkoutImageComposer: View {
    @Environment(\.dismiss) var dismiss
    let workout: RunSummary
    
    
    let hk = HealthKitService()
    
    @State private var route: [CLLocationCoordinate2D] = []
    @State private var locationName: String?
    
    @State private var showPhotoPicker = false
    @State private var pickedItem: PhotosPickerItem?
    @State private var backgroundImage: UIImage?
    
    @State private var sharePayload: SharePayload?
    
    @State private var aspectRatio: AspectRatioOption = .story
    private var exportSize: CGSize {
        let width = UIScreen.main.bounds.width - (pad * 2.0)
        return CGSize(width: width, height: width / aspectRatio.ratio)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ShareComposer(bgImage: backgroundImage,
                          title: titleText,
                          subtitle: subtitleText,
                          route: route)
            .frame(width: exportSize.width, height: exportSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            //            .animation(.easeOut(duration: 0.15), value: aspectRatio)
            
            HStack(alignment: .top){
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left").font(.title2)
                }
                .foregroundColor(.white)
                Spacer()
                VStack(alignment: .center, spacing: 20) {
                    Button {
                        aspectRatio = aspectRatio == .story ? .square : .story
                        
                    } label: {
                        ZStack {
                            Image(systemName: "square")
                                .opacity(aspectRatio == .story ? 1 : 0)
                            Image(systemName: "rectangle.portrait")
                                .opacity(aspectRatio == .square ? 1 : 0)
                        }
                        .font(.title2)
                        .animation(.easeOut(duration: 0.15), value: aspectRatio)
                        
                    }
                    .foregroundColor(.white)
                    Button { showPhotoPicker = true } label: {
                        Image(systemName: "photo.on.rectangle.angled").font(.title2)
                    }
                    .foregroundColor(.white)
                    .disabled(route.isEmpty)
                    
                    Button { Task { await exportAndShare() } }
                    label: {
                        Image(systemName: "square.and.arrow.up").font(.title2)
                    }
                    .foregroundColor(.white)
                    .disabled(route.isEmpty || backgroundImage == nil)
                    .sheet(item: $sharePayload) { payload in
                        ShareSheet(items: payload.items)
                    }
                }
            }
            .padding(16.0)
        }
        .animation(.easeOut(duration: 0.15), value: aspectRatio)
        .frame(maxWidth: .infinity, maxHeight: .infinity)  // add this
        .padding(pad)
        // Photos picker
        .photosPicker(isPresented: $showPhotoPicker,
                      selection: $pickedItem,
                      matching: .images)
        .task(id: pickedItem) { await loadPickedImage() } // loads into backgroundImage
        .background(Color.black)           // ← black canvas behind everything
        .preferredColorScheme(.dark)       // nicer status bar/icons
        .task {
            do {
                route = try await hk.route(for: workout.workout)
                locationName = await getRouteLocationName(route: route)
                showPhotoPicker = true
            } catch {
                print("Error loading route")
            }
        }
        .navigationBarHidden(true)
        
    }
    
    private var titleText: String {
        workout.distanceMiles > 0 ? String(format: "Run · %.1f mi", workout.distanceMiles) : "Run"
    }
    private var subtitleText: String {
        workout.duration > 0 ? (locationName?.appending(" · ") ?? "") + format(duration: workout.duration) : "—"
    }
    
    @MainActor
    private func exportAndShare() async {
        guard backgroundImage != nil else { return }
        let image = ShareComposer(bgImage: backgroundImage, title: titleText, subtitle: subtitleText, route: route).render(size: exportSize)
        sharePayload = SharePayload(items: [tempURL(for: image) as Any])
    }
    
    private func format(duration: TimeInterval) -> String {
        let m = Int(duration) / 60, s = Int(duration) % 60
        return String(format: "%dm %02ds", m, s)
    }
    
    @MainActor
    private func loadPickedImage() async {
        guard let item = pickedItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let img = UIImage(data: data) {
            backgroundImage = img
        }
    }
    
    @MainActor
    func tempURL(for image: UIImage) -> URL? {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("aura-\(UUID().uuidString).png")
        guard let data = image.pngData() else { return nil }
        try? data.write(to: url)
        return url
    }
}
