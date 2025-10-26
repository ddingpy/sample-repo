import AVFoundation
import Combine
import CoreGraphics
import os

// MARK: - Sample AVPlayer Implementation

final class SampleAVPlayer: NSObject, SamplePlayerOutput {
    private let player: AVPlayer
    private var playerObservers: [NSKeyValueObservation] = []
    private var itemObservers: [NSKeyValueObservation] = []
    private var endObserver: Any?
    private var timeObserver: PlayerTimeObserver?

    private let playbackStatusSubject = CurrentValueSubject<PlaybackStatus, Never>(.idle)
    private let bufferingStateSubject = CurrentValueSubject<BufferingState, Never>(.unknown)
    private let currentTimeSubject = CurrentValueSubject<CMTime, Never>(.zero)
    private let durationSubject = CurrentValueSubject<CMTime, Never>(.zero)
    private let presentationSizeSubject = CurrentValueSubject<CGSize, Never>(.zero)
    private let seekableRangeSubject = CurrentValueSubject<CMTimeRange?, Never>(nil)
    private let loadedTimeRangeSubject = CurrentValueSubject<CMTimeRange?, Never>(nil)
    private let externalPlaybackSubject = CurrentValueSubject<Bool, Never>(false)
    private let muteSubject = CurrentValueSubject<Bool, Never>(false)
    private let rateSubject = CurrentValueSubject<Float, Never>(0)
    private let stateSubject = CurrentValueSubject<PlayerState, Never>(.empty)

    private var preferredRate: Float = 1.0
    private let logger = Logger(subsystem: "com.example.AVPlayerSample2", category: "SampleAVPlayer")

    // MARK: Init / Deinit

    init(player: AVPlayer = AVPlayer()) {
        self.player = player
        super.init()
        player.actionAtItemEnd = .pause
        player.automaticallyWaitsToMinimizeStalling = true
        attachPlayerObservers()
        updateState()
    }

    deinit {
        tearDown()
    }

    // MARK: SamplePlayerOutput

    var statePublisher: AnyPublisher<PlayerState, Never> {
        stateSubject.removeDuplicates().eraseToAnyPublisher()
    }

    var playbackStatusPublisher: AnyPublisher<PlaybackStatus, Never> {
        playbackStatusSubject.removeDuplicates().eraseToAnyPublisher()
    }

    var bufferingStatePublisher: AnyPublisher<BufferingState, Never> {
        bufferingStateSubject.removeDuplicates().eraseToAnyPublisher()
    }

    var currentTimePublisher: AnyPublisher<CMTime, Never> {
        currentTimeSubject.eraseToAnyPublisher()
    }

    var durationPublisher: AnyPublisher<CMTime, Never> {
        durationSubject.eraseToAnyPublisher()
    }

    var presentationSizePublisher: AnyPublisher<CGSize, Never> {
        presentationSizeSubject.eraseToAnyPublisher()
    }

    var seekableRangePublisher: AnyPublisher<CMTimeRange?, Never> {
        seekableRangeSubject.eraseToAnyPublisher()
    }

    var loadedTimeRangePublisher: AnyPublisher<CMTimeRange?, Never> {
        loadedTimeRangeSubject.eraseToAnyPublisher()
    }

    var externalPlaybackPublisher: AnyPublisher<Bool, Never> {
        externalPlaybackSubject.removeDuplicates().eraseToAnyPublisher()
    }

    var mutePublisher: AnyPublisher<Bool, Never> {
        muteSubject.removeDuplicates().eraseToAnyPublisher()
    }

    var ratePublisher: AnyPublisher<Float, Never> {
        rateSubject.removeDuplicates().eraseToAnyPublisher()
    }

    func getAVPlayer() -> AVPlayer {
        player
    }

    func initialize(rate: Float, mute: Bool) {
        preferredRate = max(rate, 0)
        setMute(mute)
        rateSubject.send(0)
        playbackStatusSubject.send(.idle)
        bufferingStateSubject.send(.unknown)
        updateState()
    }

    func load(url: URL) {
        logger.debug("Loading URL: \(url.absoluteString, privacy: .public)")
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        playbackStatusSubject.send(.preparing)
        bufferingStateSubject.send(.buffering)
        player.replaceCurrentItem(with: item)
        configureCurrentItem(item)
        updateState()
    }

    func play() {
        guard player.currentItem != nil else { return }
        logger.debug("Play requested")
        if preferredRate != 1.0 {
            player.playImmediately(atRate: preferredRate)
        } else {
            player.play()
        }
        if preferredRate != 1.0 {
            rateSubject.send(preferredRate)
        }
        playbackStatusSubject.send(.playing)
        updateState()
    }

    func pause() {
        logger.debug("Pause requested")
        player.pause()
        playbackStatusSubject.send(.paused)
        rateSubject.send(0)
        updateState()
    }

    func stop() {
        logger.debug("Stop requested")
        player.pause()
        player.seek(to: .zero)
        playbackStatusSubject.send(.ready)
        bufferingStateSubject.send(.ready)
        rateSubject.send(0)
        currentTimeSubject.send(.zero)
        updateState()
    }

    func seek(to time: CMTime, allowOutOfRange: Bool, completion: ((Bool) -> Void)?) {
        guard let item = player.currentItem else {
            completion?(false)
            return
        }
        var target = time
        if !allowOutOfRange {
            let duration = item.duration.isValidAndFinite ? item.duration : item.asset.duration
            if duration.isValidAndFinite {
                target = target.clamped(to: .zero...duration)
            }
        }
        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
            guard let self else {
                completion?(finished)
                return
            }
            if finished {
                self.currentTimeSubject.send(target)
                self.updateState()
            }
            completion?(finished)
        }
    }

    @MainActor
    func seek(_ time: CMTime) async -> Bool {
        await withCheckedContinuation { continuation in
            seek(to: time, allowOutOfRange: false) { success in
                continuation.resume(returning: success)
            }
        }
    }

    func setMute(_ value: Bool) {
        logger.debug("Mute toggled: \(value)")
        player.isMuted = value
        muteSubject.send(value)
        updateState()
    }

    func toggleMute() {
        setMute(!player.isMuted)
    }

    // MARK: - Private Helpers

    private func attachPlayerObservers() {
        playerObservers.append(
            player.observe(\AVPlayer.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
                self?.handleTimeControlStatus(player.timeControlStatus)
            }
        )
        playerObservers.append(
            player.observe(\AVPlayer.rate, options: [.initial, .new]) { [weak self] player, _ in
                self?.handleRateChange(player.rate)
            }
        )
        playerObservers.append(
            player.observe(\AVPlayer.isMuted, options: [.initial, .new]) { [weak self] player, _ in
                self?.muteSubject.send(player.isMuted)
                self?.updateState()
            }
        )
        playerObservers.append(
            player.observe(\AVPlayer.isExternalPlaybackActive, options: [.initial, .new]) { [weak self] player, _ in
                self?.externalPlaybackSubject.send(player.isExternalPlaybackActive)
                self?.updateState()
            }
        )
        playerObservers.append(
            player.observe(\AVPlayer.currentItem, options: [.initial, .new]) { [weak self] player, _ in
                self?.configureCurrentItem(player.currentItem)
            }
        )
    }

    private func configureCurrentItem(_ item: AVPlayerItem?) {
        itemObservers.forEach { $0.invalidate() }
        itemObservers.removeAll()
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        timeObserver?.invalidate()
        timeObserver = nil

        guard let item else {
            durationSubject.send(.zero)
            presentationSizeSubject.send(.zero)
            seekableRangeSubject.send(nil)
            loadedTimeRangeSubject.send(nil)
            bufferingStateSubject.send(.unknown)
            playbackStatusSubject.send(.idle)
            currentTimeSubject.send(.zero)
            updateState()
            return
        }
        currentTimeSubject.send(.zero)

        itemObservers.append(
            item.observe(\AVPlayerItem.status, options: [.initial, .new]) { [weak self] item, _ in
                self?.handleItemStatus(item)
            }
        )
        itemObservers.append(
            item.observe(\AVPlayerItem.presentationSize, options: [.initial, .new]) { [weak self] item, _ in
                self?.presentationSizeSubject.send(item.presentationSize)
                self?.updateState()
            }
        )
        itemObservers.append(
            item.observe(\AVPlayerItem.loadedTimeRanges, options: [.initial, .new]) { [weak self] item, _ in
                self?.handleLoadedTimeRanges(item.loadedTimeRanges)
            }
        )
        itemObservers.append(
            item.observe(\AVPlayerItem.seekableTimeRanges, options: [.initial, .new]) { [weak self] item, _ in
                let range = item.seekableTimeRanges.first?.timeRangeValue
                self?.seekableRangeSubject.send(range)
                self?.updateState()
            }
        )

        endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
            self?.handlePlaybackFinished()
        }

        attachTimeObserver()
        updateState()
    }

    private func attachTimeObserver() {
        guard timeObserver == nil else { return }
        timeObserver = PlayerTimeObserver(
            player: player,
            interval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { [weak self] time in
            self?.currentTimeSubject.send(time)
            self?.updateState()
        }
    }

    private func handleTimeControlStatus(_ status: AVPlayer.TimeControlStatus) {
        switch status {
        case .waitingToPlayAtSpecifiedRate:
            bufferingStateSubject.send(.buffering)
            if case .failed = playbackStatusSubject.value {
                break
            } else {
                playbackStatusSubject.send(.preparing)
            }
        case .paused:
            bufferingStateSubject.send(.ready)
            if rateSubject.value == 0 {
                playbackStatusSubject.send(.paused)
            }
        case .playing:
            bufferingStateSubject.send(.ready)
            playbackStatusSubject.send(.playing)
        @unknown default:
            break
        }
        updateState()
    }

    private func handleRateChange(_ rate: Float) {
        rateSubject.send(rate)
        if rate == 0 {
            if case .playing = playbackStatusSubject.value {
                playbackStatusSubject.send(.paused)
            }
        } else if rate > 0 {
            playbackStatusSubject.send(.playing)
        }
        updateState()
    }

    private func handleItemStatus(_ item: AVPlayerItem) {
        switch item.status {
        case .unknown:
            playbackStatusSubject.send(.preparing)
        case .readyToPlay:
            let duration = item.duration.isValidAndFinite ? item.duration : item.asset.duration
            durationSubject.send(duration)
            if rateSubject.value > 0 {
                playbackStatusSubject.send(.playing)
            } else {
                playbackStatusSubject.send(.ready)
            }
        case .failed:
            let message = item.error?.localizedDescription ?? "Unknown playback failure"
            playbackStatusSubject.send(.failed(message: message))
            logger.error("Player item failure: \(message, privacy: .public)")
        @unknown default:
            playbackStatusSubject.send(.failed(message: "Unhandled item status"))
        }
        updateState()
    }

    private func handleLoadedTimeRanges(_ ranges: [NSValue]) {
        let range = ranges.first?.timeRangeValue
        loadedTimeRangeSubject.send(range)
        if let range, range.duration.secondsOrZero > 0 {
            bufferingStateSubject.send(.ready)
        }
        updateState()
    }

    private func handlePlaybackFinished() {
        logger.debug("Playback finished")
        rateSubject.send(0)
        playbackStatusSubject.send(.finished)
        updateState()
    }

    private func updateState() {
        let snapshot = PlayerState(
            playbackStatus: playbackStatusSubject.value,
            bufferingState: bufferingStateSubject.value,
            isMuted: muteSubject.value,
            rate: rateSubject.value,
            currentTime: currentTimeSubject.value,
            duration: durationSubject.value,
            seekableRange: seekableRangeSubject.value,
            loadedTimeRange: loadedTimeRangeSubject.value,
            presentationSize: presentationSizeSubject.value,
            isExternalPlaybackActive: externalPlaybackSubject.value
        )
        guard !Thread.isMainThread else {
            stateSubject.send(snapshot)
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.stateSubject.send(snapshot)
        }
    }

    private func tearDown() {
        playerObservers.forEach { $0.invalidate() }
        playerObservers.removeAll()
        itemObservers.forEach { $0.invalidate() }
        itemObservers.removeAll()
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil
        timeObserver?.invalidate()
        timeObserver = nil
    }
}
