import SwiftUI
import Photos

/// Background photos come from two places: the system photo library (needs
/// permission) and a `Photos` folder inside the app's own documents, which the
/// user can fill through the Files app without granting anything.
final class PhotoSlideshow: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var generation = 0
    @Published private(set) var status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @Published private(set) var libraryCount = 0
    @Published private(set) var folderCount = 0

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
    private static let imageExtensions = ["jpg", "jpeg", "png", "heic"]

    private var assets: PHFetchResult<PHAsset>?
    private var folderPhotos: [URL] = []
    private var timer: Timer?

    private enum Source {
        case library(PHAsset)
        case file(URL)
    }

    var hasAccess: Bool {
        status == .authorized || status == .limited
    }

    var photoCount: Int {
        libraryCount + folderCount
    }

    var photosFolder: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("Photos", isDirectory: true)
    }

    init() {
        // No stored choice means the user has never touched the switch, so let
        // the switch follow whether there is anything to show.
        isEnabled = UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
        let saved = UserDefaults.standard.double(forKey: Self.intervalKey)
        interval = saved > 0 ? saved : 30
        try? FileManager.default.createDirectory(at: photosFolder, withIntermediateDirectories: true)
        refresh()
    }

    func requestAccess() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
            DispatchQueue.main.async {
                guard let self else { return }
                self.status = newStatus
                self.isEnabled = true
                self.refresh()
            }
        }
    }

    func refresh() {
        if hasAccess {
            let options = PHFetchOptions()
            options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            let result = PHAsset.fetchAssets(with: options)
            assets = result
            libraryCount = result.count
        } else {
            assets = nil
            libraryCount = 0
        }

        let contents = (try? FileManager.default.contentsOfDirectory(at: photosFolder, includingPropertiesForKeys: nil)) ?? []
        folderPhotos = contents.filter { Self.imageExtensions.contains($0.pathExtension.lowercased()) }
        folderCount = folderPhotos.count

        if isEnabled { start() }
    }

    private func start() {
        stop()
        guard photoCount > 0 else { return }
        if image == nil { showRandomPhoto() }
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.showRandomPhoto()
        }
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func randomSource() -> Source? {
        guard photoCount > 0 else { return nil }
        let pick = Int.random(in: 0..<photoCount)
        if pick < libraryCount, let assets {
            return .library(assets.object(at: pick))
        }
        return .file(folderPhotos[pick - libraryCount])
    }

    private func showRandomPhoto() {
        switch randomSource() {
        case .file(let url):
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let data = try? Data(contentsOf: url), let loaded = UIImage(data: data) else { return }
                DispatchQueue.main.async { self?.apply(loaded) }
            }

        case .library(let asset):
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
                DispatchQueue.main.async { self?.apply(loaded, countsAsNew: !isDegraded) }
            }

        case nil:
            return
        }
    }

    private func apply(_ loaded: UIImage, countsAsNew: Bool = true) {
        withAnimation(.easeInOut(duration: 1.4)) {
            image = loaded
            if countsAsNew { generation += 1 }
        }
    }
}
