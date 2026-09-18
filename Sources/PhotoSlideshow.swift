import SwiftUI
import Photos

@MainActor
final class PhotoSlideshow: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var generation = 0
    @Published private(set) var status = PHPhotoLibrary.authorizationStatus(for: .readOnly)
    @Published private(set) var photoCount = 0

    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
            isEnabled ? start() : stop()
        }
    }

    @Published var interval: TimeInterval {
        didSet {
            UserDefaults.standard.set(interval, forKey: Self.intervalKey)
            if isEnabled { start() }
        }
    }

    private static let enabledKey = "slideshow.enabled"
    private static let intervalKey = "slideshow.interval"

    private var assets: [PHAsset] = []
    private var timer: Timer?

    var hasAccess: Bool {
        status == .authorized || status == .limited
    }

    init() {
        let granted = [PHAuthorizationStatus.authorized, .limited]
            .contains(PHPhotoLibrary.authorizationStatus(for: .readOnly))
        // No stored choice yet means the user has never touched the switch:
        // default it on when access already exists, off otherwise.
        isEnabled = UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? granted
        let saved = UserDefaults.standard.double(forKey: Self.intervalKey)
        interval = saved > 0 ? saved : 30
        if hasAccess {
            loadAssets()
        }
    }

    func requestAccess() {
        PHPhotoLibrary.requestAuthorization(for: .readOnly) { [weak self] newStatus in
            Task { @MainActor in
                guard let self else { return }
                self.status = newStatus
                if self.hasAccess {
                    self.isEnabled = true
                    self.loadAssets()
                }
            }
        }
    }

    private func loadAssets() {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        let result = PHAsset.fetchAssets(with: options)
        var found: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in found.append(asset) }
        assets = found
        photoCount = found.count
        if isEnabled { start() }
    }

    private func start() {
        stop()
        guard hasAccess, !assets.isEmpty else { return }
        if image == nil { showRandomPhoto() }
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.showRandomPhoto() }
        }
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func showRandomPhoto() {
        guard let asset = assets.randomElement() else { return }
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 1400, height: 2800),
            contentMode: .aspectFill,
            options: options
        ) { [weak self] loaded, info in
            guard let loaded else { return }
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            Task { @MainActor in
                guard let self else { return }
                withAnimation(.easeInOut(duration: 1.4)) {
                    self.image = loaded
                    if !isDegraded { self.generation += 1 }
                }
            }
        }
    }
}
