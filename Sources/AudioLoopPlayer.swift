import AVFoundation

final class AudioLoopPlayer: ObservableObject {
    private var player: AVAudioPlayer?

    init(resourceName: String, fileExtension: String) {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: fileExtension) else {
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.prepareToPlay()
        } catch {
            print("Audio load failed: \(error)")
        }
    }

    func play() {
        player?.play()
    }
}
