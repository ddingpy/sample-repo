import AVFoundation
import Combine
import os
import SwiftUI

// MARK: - Player View Model

@MainActor
final class PlayerViewModel: ObservableObject {
    // Published UI surface
    @Published private(set) var state: PlayerState = .empty
    @Published private(set) var playbackStatus: PlaybackStatus = .idle
    @Published private(set) var bufferingState: BufferingState = .unknown
    @Published private(set) var formattedCurrentTime: String = "00:00"
    @Published private(set) var formattedDuration: String = "00:00"
    @Published private(set) var displayedProgress: Double = 0
    @Published private(set) var isMuted: Bool = false
    @Published var isFullScreenPresented: Bool = false
    @Published var selectedSource: PlayerSource

    let availableSources: [PlayerSource] = PlayerSource.all

    // Dependencies
    private let player: SamplePlayerOutput
    private let timeFormatter = TimeFormatter()
    private let coordinator: PlayerCoordinator
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.example.AVPlayerSample2", category: "PlayerViewModel")

    private var isScrubbing = false

    init(player: SamplePlayerOutput, defaultSource: PlayerSource = .sintelHLS) {
        self.player = player
        self.selectedSource = defaultSource
        self.coordinator = PlayerCoordinator(player: player)
        bind()
        player.initialize(rate: 1.0, mute: false)
        load(source: defaultSource)
    }

    // MARK: Derived State

    var isBuffering: Bool { bufferingState == .buffering }
    var isPlaying: Bool { state.isPlaying }
    var playerCoordinator: PlayerCoordinator { coordinator }
    var underlyingPlayer: AVPlayer { player.getAVPlayer() }

    // MARK: Intent APIs

    func playTapped() {
        logger.debug("Play tapped")
        player.play()
    }

    func pauseTapped() {
        logger.debug("Pause tapped")
        player.pause()
    }

    func stopTapped() {
        logger.debug("Stop tapped")
        player.stop()
    }

    func toggleMute() {
        logger.debug("Toggle mute tapped")
        player.toggleMute()
    }

    func scrub(to progress: Double) {
        let normalized = progress.clamped(to: 0...1)
        guard state.duration.isValidAndFinite else { return }
        let seconds = state.duration.secondsOrZero * normalized
        let targetTime = CMTime.fromSeconds(seconds)
        logger.debug("Scrubbing to progress \(normalized, privacy: .public)")
        player.seek(to: targetTime, allowOutOfRange: false, completion: nil)
    }

    func beginScrubbing() {
        isScrubbing = true
    }

    func updateScrubPreview(_ progress: Double) {
        displayedProgress = progress.clamped(to: 0...1)
        let seconds = state.duration.secondsOrZero * displayedProgress
        formattedCurrentTime = timeFormatter.string(from: seconds)
    }

    func endScrubbing(at progress: Double) {
        isScrubbing = false
        displayedProgress = progress.clamped(to: 0...1)
        scrub(to: displayedProgress)
    }

    func presentFullScreenPlayer() {
        logger.debug("Present full screen player")
        isFullScreenPresented = true
    }

    func dismissFullScreenPlayer() {
        isFullScreenPresented = false
    }

    func loadSelectedSource() {
        load(source: selectedSource)
    }

    // MARK: Private Helpers

    private func bind() {
        player.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                self.state = state
                self.playbackStatus = state.playbackStatus
                self.bufferingState = state.bufferingState
                if !self.isScrubbing {
                    self.displayedProgress = state.normalizedProgress
                    self.formattedCurrentTime = self.timeFormatter.string(from: state.currentTime)
                }
                self.formattedDuration = self.timeFormatter.string(from: state.duration)
            }
            .store(in: &cancellables)

        player.mutePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isMuted in
                self?.isMuted = isMuted
            }
            .store(in: &cancellables)
    }

    private func load(source: PlayerSource) {
        logger.debug("Loading source: \(source.title, privacy: .public)")
        player.stop()
        player.load(url: source.url)
        player.play()
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(range.upperBound, max(range.lowerBound, self))
    }
}
