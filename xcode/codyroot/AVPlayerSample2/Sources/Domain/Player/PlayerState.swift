import AVFoundation
import CoreGraphics

// MARK: - Playback Models

enum PlaybackStatus: Equatable {
    case idle
    case preparing
    case ready
    case playing
    case paused
    case finished
    case failed(message: String)
}

enum BufferingState: Equatable {
    case unknown
    case buffering
    case ready
}

struct PlayerState: Equatable {
    var playbackStatus: PlaybackStatus
    var bufferingState: BufferingState
    var isMuted: Bool
    var rate: Float
    var currentTime: CMTime
    var duration: CMTime
    var seekableRange: CMTimeRange?
    var loadedTimeRange: CMTimeRange?
    var presentationSize: CGSize
    var isExternalPlaybackActive: Bool

    var isPlaying: Bool { playbackStatus == .playing || rate > 0 }

    static let empty = PlayerState(
        playbackStatus: .idle,
        bufferingState: .unknown,
        isMuted: false,
        rate: 0,
        currentTime: .zero,
        duration: .zero,
        seekableRange: nil,
        loadedTimeRange: nil,
        presentationSize: .zero,
        isExternalPlaybackActive: false
    )

    /// Represents progress in the range 0.0...1.0.
    var normalizedProgress: Double {
        guard duration.isValidAndFinite && duration.secondsOrZero > 0 else { return 0 }
        return min(1.0, max(0, currentTime.secondsOrZero / duration.secondsOrZero))
    }
}
