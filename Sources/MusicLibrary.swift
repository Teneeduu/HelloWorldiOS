import Foundation
import AVFoundation
import MediaPlayer

struct Track: Identifiable, Equatable {
    let id: String
    let title: String
    let url: URL
    let isBundled: Bool
}

final class MusicLibrary: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var tracks: [Track] = []
    @Published private(set) var currentTrackID: String?
    @Published private(set) var isPlaying = false

    private var player: AVAudioPlayer?
    private let orderKey = "musicLibrary.order"
    private let audioExtensions = ["mp3", "m4a", "wav", "aac"]

    override init() {
        super.init()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        setUpRemoteCommands()
        reload()
    }

    private func setUpRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.toggle()
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.next()
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.previous()
            return .success
        }
    }

    private func updateNowPlaying() {
        guard let track = currentTrack, let player else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: "Jo",
            MPMediaItemPropertyPlaybackDuration: player.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: player.isPlaying ? 1.0 : 0.0
        ]
    }

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Re-scans bundled tracks and the Documents folder (which picks up files dropped in
    /// either through the in-app picker or through the computer's file-sharing pane).
    func refresh() {
        reload()
    }

    private func reload() {
        var bundled: [Track] = []
        for ext in audioExtensions {
            let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "Music") ?? []
            for url in urls {
                bundled.append(Track(id: "bundled:\(url.lastPathComponent)", title: url.deletingPathExtension().lastPathComponent, url: url, isBundled: true))
            }
        }
        bundled.sort { $0.title < $1.title }

        var added: [Track] = []
        let contents = (try? FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)) ?? []
        for url in contents where audioExtensions.contains(url.pathExtension.lowercased()) {
            added.append(Track(id: "added:\(url.lastPathComponent)", title: url.deletingPathExtension().lastPathComponent, url: url, isBundled: false))
        }
        added.sort { $0.title < $1.title }

        var all = bundled + added

        if let savedOrder = UserDefaults.standard.stringArray(forKey: orderKey) {
            var ordered: [Track] = []
            for id in savedOrder {
                if let match = all.first(where: { $0.id == id }) {
                    ordered.append(match)
                }
            }
            for track in all where !ordered.contains(where: { $0.id == track.id }) {
                ordered.append(track)
            }
            all = ordered
        }

        tracks = all
        persistOrder()
    }

    private func persistOrder() {
        UserDefaults.standard.set(tracks.map(\.id), forKey: orderKey)
    }

    func addFile(from sourceURL: URL) {
        let name = sourceURL.lastPathComponent
        let destURL = documentsURL.appendingPathComponent(name)
        let accessed = sourceURL.startAccessingSecurityScopedResource()
        defer { if accessed { sourceURL.stopAccessingSecurityScopedResource() } }
        do {
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            reload()
        } catch {
            print("Failed to add file \(name): \(error)")
        }
    }

    func removeTrack(_ track: Track) {
        tracks.removeAll { $0.id == track.id }
        persistOrder()
        if !track.isBundled {
            try? FileManager.default.removeItem(at: track.url)
        }
        if currentTrackID == track.id {
            stop()
        }
    }

    func move(fromOffsets: IndexSet, toOffset: Int) {
        tracks.move(fromOffsets: fromOffsets, toOffset: toOffset)
        persistOrder()
    }

    var currentTrack: Track? {
        tracks.first { $0.id == currentTrackID }
    }

    func play(_ track: Track? = nil) {
        let target = track ?? currentTrack ?? tracks.first
        guard let target else { return }
        if currentTrackID != target.id {
            do {
                player = try AVAudioPlayer(contentsOf: target.url)
                player?.delegate = self
                player?.prepareToPlay()
                currentTrackID = target.id
            } catch {
                print("Failed to play \(target.url): \(error)")
                return
            }
        }
        player?.play()
        isPlaying = true
        updateNowPlaying()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlaying()
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentTrackID = nil
        updateNowPlaying()
    }

    func toggle() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        next()
    }

    func next() {
        step(by: 1)
    }

    func previous() {
        step(by: -1)
    }

    private func step(by offset: Int) {
        guard !tracks.isEmpty else {
            stop()
            return
        }
        guard let current = currentTrack, let index = tracks.firstIndex(where: { $0.id == current.id }) else {
            play(tracks.first)
            return
        }
        let target = (index + offset + tracks.count) % tracks.count
        play(tracks[target])
    }
}
