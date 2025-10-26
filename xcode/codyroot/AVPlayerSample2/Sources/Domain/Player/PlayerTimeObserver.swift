import AVFoundation

/// Wraps `AVPlayer`'s periodic time observer so ownership and cleanup mirror KakaoTV's `PlayerTimeObserver`.
final class PlayerTimeObserver {
    private weak var player: AVPlayer?
    private var token: Any?

    init(player: AVPlayer, interval: CMTime, queue: DispatchQueue?, handler: @escaping (CMTime) -> Void) {
        self.player = player
        token = player.addPeriodicTimeObserver(forInterval: interval, queue: queue, using: handler)
    }

    func invalidate() {
        guard let player, let token else { return }
        player.removeTimeObserver(token)
        self.token = nil
    }

    deinit {
        invalidate()
    }
}
