import SwiftUI
import MapKit
import PhotosUI



struct ContentView: View {
    @EnvironmentObject var workoutState: WorkoutState

    @State private var showPhotoPicker = false
    @State private var pickedItem: PhotosPickerItem?
    @State private var backgroundImage: UIImage?
    
    @State private var sharePayload: SharePayload?

    private let storyAspect: CGFloat = 9.0 / 16.0
    private var exportSize: CGSize {
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: width / storyAspect)
    }

    var body: some View {
        VStack(spacing: 16) {
            ShareComposer(bgImage: backgroundImage,
                              title: titleText,
                              subtitle: subtitleText,
                              route: workoutState.route)
            .frame(width: UIScreen.main.bounds.width)
            .aspectRatio(storyAspect, contentMode: .fit)
            
            HStack {
                Button("Load Last Run") {
                    Task {
                        await workoutState.loadLastRun(onSuccess: {
                            SendSuccessHaptic()
                            showPhotoPicker = true
                        })
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Pick Photo") { showPhotoPicker = true }
                    .buttonStyle(.bordered)
                    .disabled(workoutState.route.isEmpty)

                Button("Export") { Task { await exportAndShare() } }
                    .buttonStyle(.bordered)
                    .disabled(workoutState.route.isEmpty || backgroundImage == nil)
                .buttonStyle(.borderedProminent)
                // …
                .sheet(item: $sharePayload) { payload in
                    ShareSheet(items: payload.items)
                }
            }
            .controlSize(.large)
            .padding(20)
        }
        // Photos picker
        .photosPicker(isPresented: $showPhotoPicker,
                      selection: $pickedItem,
                      matching: .images)
        .task(id: pickedItem) { await loadPickedImage() } // loads into backgroundImage
        .background(Color.black)           // ← black canvas behind everything
        .preferredColorScheme(.dark)       // nicer status bar/icons
    }

    private var titleText: String {
        workoutState.distanceMiles > 0 ? String(format: "Run · %.1f mi", workoutState.distanceMiles) : "Run"
    }
    private var subtitleText: String {
        workoutState.duration > 0 ? (workoutState.locationName?.appending(" · ") ?? "") + format(duration: workoutState.duration) : "—"
    }
    
    @MainActor
    private func exportAndShare() async {
        guard backgroundImage != nil else { return }
        let image = ShareComposer(bgImage: backgroundImage, title: titleText, subtitle: subtitleText, route: workoutState.route).render(size: exportSize)
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


#Preview {
    let mock = WorkoutState()
    ContentView()
        .environmentObject(mock)
        .preferredColorScheme(.dark)
}
