import AVFoundation
import Combine
import CoreGraphics

// MARK: - Player Output Contract

protocol SamplePlayerOutput: AnyObject {
    var statePublisher: AnyPublisher<PlayerState, Never> { get }
    var playbackStatusPublisher: AnyPublisher<PlaybackStatus, Never> { get }
    var bufferingStatePublisher: AnyPublisher<BufferingState, Never> { get }
    var currentTimePublisher: AnyPublisher<CMTime, Never> { get }
    var durationPublisher: AnyPublisher<CMTime, Never> { get }
    var presentationSizePublisher: AnyPublisher<CGSize, Never> { get }
    var seekableRangePublisher: AnyPublisher<CMTimeRange?, Never> { get }
    var loadedTimeRangePublisher: AnyPublisher<CMTimeRange?, Never> { get }
    var externalPlaybackPublisher: AnyPublisher<Bool, Never> { get }
    var mutePublisher: AnyPublisher<Bool, Never> { get }
    var ratePublisher: AnyPublisher<Float, Never> { get }

    func getAVPlayer() -> AVPlayer

    func initialize(rate: Float, mute: Bool)
    func load(url: URL)
    func play()
    func pause()
    func stop()

    func seek(to time: CMTime, allowOutOfRange: Bool, completion: ((Bool) -> Void)?)
    @MainActor func seek(_ time: CMTime) async -> Bool

    func setMute(_ value: Bool)
    func toggleMute()
}
