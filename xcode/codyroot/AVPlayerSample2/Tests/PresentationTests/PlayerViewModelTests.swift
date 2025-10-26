import XCTest
import Combine
import AVFoundation
import CoreGraphics
@testable import AVPlayerSample2

@MainActor
final class PlayerViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    func testPlayTappedDelegatesToPlayer() {
        let player = MockPlayerOutput()
        let viewModel = PlayerViewModel(player: player, defaultSource: .sintelHLS)

        let baselinePlayCount = player.playCallCount
        viewModel.playTapped()

        XCTAssertEqual(player.playCallCount, baselinePlayCount + 1)
    }

    func testStateUpdateRefreshesProgressAndFormatting() {
        let player = MockPlayerOutput()
        let viewModel = PlayerViewModel(player: player, defaultSource: .sintelHLS)

        let state = PlayerState(
            playbackStatus: .playing,
            bufferingState: .ready,
            isMuted: false,
            rate: 1,
            currentTime: .fromSeconds(30),
            duration: .fromSeconds(120),
            seekableRange: CMTimeRange(start: .zero, duration: .fromSeconds(120)),
            loadedTimeRange: CMTimeRange(start: .zero, duration: .fromSeconds(40)),
            presentationSize: CGSize(width: 1920, height: 1080),
            isExternalPlaybackActive: false
        )

        player.stateSubject.send(state)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        XCTAssertEqual(viewModel.displayedProgress, 0.25, accuracy: 0.01)
        XCTAssertEqual(viewModel.formattedCurrentTime, "00:30")
        XCTAssertEqual(viewModel.formattedDuration, "02:00")
    }
}

// MARK: - Mock

final class MockPlayerOutput: SamplePlayerOutput {
    let stateSubject = CurrentValueSubject<PlayerState, Never>(.empty)
    let playbackSubject = CurrentValueSubject<PlaybackStatus, Never>(.idle)
    let bufferingSubject = CurrentValueSubject<BufferingState, Never>(.unknown)
    let currentTimeSubject = CurrentValueSubject<CMTime, Never>(.zero)
    let durationSubject = CurrentValueSubject<CMTime, Never>(.zero)
    let presentationSubject = CurrentValueSubject<CGSize, Never>(.zero)
    let seekableSubject = CurrentValueSubject<CMTimeRange?, Never>(nil)
    let loadedSubject = CurrentValueSubject<CMTimeRange?, Never>(nil)
    let externalSubject = CurrentValueSubject<Bool, Never>(false)
    let muteSubject = CurrentValueSubject<Bool, Never>(false)
    let rateSubject = CurrentValueSubject<Float, Never>(0)

    private(set) var playCallCount = 0
    private(set) var pauseCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var toggleMuteCallCount = 0
    private(set) var loadCallCount = 0
    private(set) var seekCallCount = 0

    var statePublisher: AnyPublisher<PlayerState, Never> { stateSubject.eraseToAnyPublisher() }
    var playbackStatusPublisher: AnyPublisher<PlaybackStatus, Never> { playbackSubject.eraseToAnyPublisher() }
    var bufferingStatePublisher: AnyPublisher<BufferingState, Never> { bufferingSubject.eraseToAnyPublisher() }
    var currentTimePublisher: AnyPublisher<CMTime, Never> { currentTimeSubject.eraseToAnyPublisher() }
    var durationPublisher: AnyPublisher<CMTime, Never> { durationSubject.eraseToAnyPublisher() }
    var presentationSizePublisher: AnyPublisher<CGSize, Never> { presentationSubject.eraseToAnyPublisher() }
    var seekableRangePublisher: AnyPublisher<CMTimeRange?, Never> { seekableSubject.eraseToAnyPublisher() }
    var loadedTimeRangePublisher: AnyPublisher<CMTimeRange?, Never> { loadedSubject.eraseToAnyPublisher() }
    var externalPlaybackPublisher: AnyPublisher<Bool, Never> { externalSubject.eraseToAnyPublisher() }
    var mutePublisher: AnyPublisher<Bool, Never> { muteSubject.eraseToAnyPublisher() }
    var ratePublisher: AnyPublisher<Float, Never> { rateSubject.eraseToAnyPublisher() }

    func getAVPlayer() -> AVPlayer { AVPlayer() }

    func initialize(rate: Float, mute: Bool) {
        rateSubject.send(rate)
        muteSubject.send(mute)
    }

    func load(url: URL) {
        loadCallCount += 1
    }

    func play() {
        playCallCount += 1
        playbackSubject.send(.playing)
    }

    func pause() {
        pauseCallCount += 1
        playbackSubject.send(.paused)
    }

    func stop() {
        stopCallCount += 1
        stateSubject.send(.empty)
    }

    func seek(to time: CMTime, allowOutOfRange: Bool, completion: ((Bool) -> Void)?) {
        seekCallCount += 1
        currentTimeSubject.send(time)
        completion?(true)
    }

    @MainActor
    func seek(_ time: CMTime) async -> Bool { true }

    func setMute(_ value: Bool) {
        muteSubject.send(value)
    }

    func toggleMute() {
        toggleMuteCallCount += 1
        setMute(!muteSubject.value)
    }
}
