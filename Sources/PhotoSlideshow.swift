import SwiftUI
import Photos

final class PhotoSlideshow: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var generation = 0
    @Published private(set) var status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
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

    private var assets: PHFetchResult<PHAsset>?
    private var timer: Timer?

    var hasAccess: Bool {
        status == .authorized || status == .limited
    }

    init() {
        let granted = [PHAuthorizationStatus.authorized, .limited]
            .contains(PHPhotoLibrary.authorizationStatus(for: .readWrite))
        // No stored choice means the user has never touched the switch:
        // default it on when access already exists, off otherwise.
        isEnabled = UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? granted
        let saved = UserDefaults.standard.double(forKey: Self.intervalKey)
        interval = saved > 0 ? saved : 30
        if hasAccess {
            loadAssets()
        }
    }

    func requestAccess() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
            DispatchQueue.main.async {
                guard let self else { return }
                self.status = newStatus
                guard self.hasAccess else { return }
                self.isEnabled = true
                self.loadAssets()
            }
        }
    }

    private func loadAssets() {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        let result = PHAsset.fetchAssets(with: options)
        assets = result
        photoCount = result.count
        if isEnabled { start() }
    }

    private func start() {
        stop()
        guard hasAccess, let assets, assets.count > 0 else { return }
        if image == nil { showRandomPhoto() }
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.showRandomPhoto()
        }
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func showRandomPhoto() {
        guard let assets, assets.count > 0 else { return }
        let asset = assets.object(at: Int.random(in: 0..<assets.count))

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
            DispatchQueue.main.async {
                guard let self else { return }
                withAnimation(.easeInOut(duration: 1.4)) {
                    self.image = loaded
                    if !isDegraded { self.generation += 1 }
                }
            }
        }
    }
}
