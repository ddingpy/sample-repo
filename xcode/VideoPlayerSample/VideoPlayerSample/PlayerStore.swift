import SwiftUI
import AVKit
import Observation

@Observable
final class PlayerStore {
    let player: AVPlayer
    var isMuted = false
    var rate: Float = 1.0
    var duration: Double = 0
    var current: Double = 0    // seconds
    
    private var timeObserver: Any?
    
    init(url: URL) {
        self.player = AVPlayer(url: url)
        // Update slider as playback progresses (every 0.5s)
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            self.current = time.seconds
            if let item = self.player.currentItem {
                let d = item.duration.seconds
                if d.isFinite { self.duration = d }
            }
        }
    }
    
    deinit {
        if let obs = timeObserver { player.removeTimeObserver(obs) }
    }
}
