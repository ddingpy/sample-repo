import AVKit

// MARK: - Player Coordinator

@MainActor
final class PlayerCoordinator: ObservableObject {
    private let player: SamplePlayerOutput

    init(player: SamplePlayerOutput) {
        self.player = player
    }

    var avPlayer: AVPlayer {
        player.getAVPlayer()
    }

    func makeAVPlayerViewController() -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player.getAVPlayer()
        controller.entersFullScreenWhenPlaybackBegins = false
        controller.exitsFullScreenWhenPlaybackEnds = true
        return controller
    }
}
