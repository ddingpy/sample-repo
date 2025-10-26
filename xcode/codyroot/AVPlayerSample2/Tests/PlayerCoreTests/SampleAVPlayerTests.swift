import XCTest
import Combine
import AVFoundation
@testable import AVPlayerSample2

final class SampleAVPlayerTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private let sampleURL = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8")!

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testPlayPublishesPlayingStatus() {
        let player = SampleAVPlayer()
        let expectation = expectation(description: "Play emits playing state")

        player.statePublisher
            .dropFirst()
            .sink { state in
                if case .playing = state.playbackStatus {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        player.initialize(rate: 1.0, mute: false)
        player.load(url: sampleURL)
        player.play()

        wait(for: [expectation], timeout: 1.0)
    }

    func testPausePublishesPausedStatus() {
        let player = SampleAVPlayer()
        let expectation = expectation(description: "Pause emits paused state")
        expectation.assertForOverFulfill = false

        player.statePublisher
            .dropFirst()
            .sink { state in
                if case .paused = state.playbackStatus {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        player.initialize(rate: 1.0, mute: false)
        player.load(url: sampleURL)
        player.play()
        player.pause()

        wait(for: [expectation], timeout: 1.0)
    }

    func testStopResetsCurrentTime() {
        let player = SampleAVPlayer()
        let expectation = expectation(description: "Stop resets time")

        var didRequestStop = false

        player.statePublisher
            .dropFirst()
            .sink { state in
                if didRequestStop && state.currentTime == .zero {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        player.initialize(rate: 1.0, mute: false)
        player.load(url: sampleURL)
        player.play()
        didRequestStop = true
        player.stop()

        wait(for: [expectation], timeout: 1.0)
    }
}
