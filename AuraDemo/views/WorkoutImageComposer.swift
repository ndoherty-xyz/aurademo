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
    
    // Stickers
    @State private var stickers: [StickerData] = []
    @State private var showStickerPicker = false
    
    @State private var selectedColor: Color = Color.white
    @State private var activeStickerId: UUID? = nil  // add this
    
    var availableStickers: [StickerContent] {
        [
            .route(route),
            .stat(label: "Distance", value: String(format: "%.1f mi", workout.distanceMiles)),
            .stat(label: "Time", value: formatTime(duration: workout.duration)),
            .stat(label: "Pace", value: pacePerMile(distance: workout.distanceMiles, duration: workout.duration) + "/mi"),
            .compoundStat(workout),
            .location(locationName ?? ""),
            .customText(locationName.map { $0 + " - Run" } ?? "Run")
        ]
    }
    
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
            composer
            controlsOverlay
        }
        .animation(.easeOut(duration: 0.15), value: aspectRatio)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(pad)
        .photosPicker(isPresented: $showPhotoPicker,
                      selection: $pickedItem,
                      matching: .images)
        .sheet(isPresented: $showStickerPicker) {
            stickerPickerSheet
        }
        .sheet(item: $sharePayload) { payload in
            ShareSheet(items: payload.items)
        }
        .task(id: pickedItem) { await loadPickedImage() }
        .background(Color.black)
        .preferredColorScheme(.dark)
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
        .onChange(of: activeStickerId) { _, newId in
            if let id = newId,
               let sticker = stickers.first(where: { $0.id == id }) {
                selectedColor = sticker.stickerColor
            }
        }
    }

    var composer: some View {
        ShareComposer(bgImage: backgroundImage,
                      title: titleText,
                      subtitle: subtitleText,
                      route: route,
                      stickers: $stickers,
                      selectedColor: $selectedColor,
        activeStickerId: $activeStickerId)
        .frame(width: exportSize.width, height: exportSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    var controlsOverlay: some View {
        HStack(alignment: .top){
            backButton
            Spacer()
            controlButtons
        }
        .padding(16.0)
    }

    var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left").font(.title2)
        }
        .foregroundColor(.white)
    }

    var controlButtons: some View {
        VStack(alignment: .center, spacing: 20) {
            aspectRatioButton
            photoPickerButton
            stickerButton
            shareButton
            if activeStickerId != nil {
                ColorPicker("", selection: $selectedColor)
                    .labelsHidden()
                    .frame(width: 20, height: 20)
                    .onChange(of: selectedColor) { _, newColor in
                        updateActiveStickerColor(newColor)
                    }
            }
        }
    }

    var aspectRatioButton: some View {
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
    }

    var photoPickerButton: some View {
        Button { showPhotoPicker = true } label: {
            Image(systemName: "photo.on.rectangle.angled").font(.title2)
        }
        .foregroundColor(.white)
        .disabled(route.isEmpty)
    }

    var stickerButton: some View {
        Button { showStickerPicker = true } label: {
            Image(systemName: "plus.square").font(.title2)
        }
        .foregroundColor(.white)
        .disabled(route.isEmpty)
    }

    var shareButton: some View {
        Button { Task { await exportAndShare() } }
        label: {
            Image(systemName: "square.and.arrow.up").font(.title2)
        }
        .foregroundColor(.white)
        .disabled(route.isEmpty || backgroundImage == nil)
    }

    var stickerPickerSheet: some View {
        StickerPickerView(
            availableStickers: availableStickers,
            onSelect: { content in
                let newSticker = StickerData(
                    position: CGPoint(x: exportSize.width/2, y: exportSize.height/2),
                    content: content,
                    stickerColor: .white
                )
                stickers.append(newSticker)
                activeStickerId = newSticker.id
                showStickerPicker = false
            }
        )
        .presentationDetents([.medium, .large])
        .presentationBackgroundInteraction(.disabled)
        .presentationBackground(.ultraThinMaterial)
    }
    
    private var titleText: String {
        workout.distanceMiles > 0 ? String(format: "Run · %.1f mi", workout.distanceMiles) : "Run"
    }
    private var subtitleText: String {
        workout.duration > 0 ? (locationName?.appending(" · ") ?? "") + formatTime(duration: workout.duration) : "—"
    }
    
    @MainActor
    private func exportAndShare() async {
        guard backgroundImage != nil else { return }
        let image = ShareComposer(bgImage: backgroundImage, title: titleText, subtitle: subtitleText, route: route, stickers: $stickers, selectedColor: $selectedColor, activeStickerId: $activeStickerId).render(size: exportSize, scale: 2.0)
        sharePayload = SharePayload(items: [tempURL(for: image) as Any])
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
    
    private func updateActiveStickerColor(_ color: Color) {
        guard let id = activeStickerId,
              let index = stickers.firstIndex(where: { $0.id == id }) else { return }
        stickers[index].stickerColor = color
    }
}
