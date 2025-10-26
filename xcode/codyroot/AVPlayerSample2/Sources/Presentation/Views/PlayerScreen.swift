import SwiftUI
import AVFoundation
import Combine

// MARK: - Player Screen

struct PlayerScreen: View {
    
    @StateObject private var viewModel: PlayerViewModel

    init(viewModel: PlayerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    @MainActor
    init() {
        _viewModel = StateObject(wrappedValue: PlayerViewModel(player: SampleAVPlayer()))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PlayerContainerView(viewModel: viewModel)

                    Picker("Source", selection: $viewModel.selectedSource) {
                        ForEach(viewModel.availableSources) { source in
                            Text(source.title).tag(source)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.selectedSource) { _ in
                        viewModel.loadSelectedSource()
                    }

                    PlayerControlsView(viewModel: viewModel)

                    diagnostics
                }
                .padding()
            }
            .navigationTitle("AVPlayer Sample 2")
        }
    }

    private var diagnostics: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Playback rate: \(String(format: "%.2f", viewModel.state.rate))")
            Text("Presentation size: \(Int(viewModel.state.presentationSize.width)) x \(Int(viewModel.state.presentationSize.height))")
            Text("External playback: \(viewModel.state.isExternalPlaybackActive ? "Active" : "Off")")
            if let range = viewModel.state.loadedTimeRange {
                let start = range.start.secondsOrZero
                let end = range.end.secondsOrZero
                Text(String(format: "Loaded range: %.1fs - %.1fs", start, end))
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

// MARK: - Preview Support

struct PlayerScreen_Previews: PreviewProvider {
    static var previews: some View {
        PlayerScreen(viewModel: PlayerViewModel(player: PreviewPlayer()))
    }

    private final class PreviewPlayer: SamplePlayerOutput {
        private let stateSubject = CurrentValueSubject<PlayerState, Never>(.empty)
        private let playbackSubject = CurrentValueSubject<PlaybackStatus, Never>(.paused)
        private let bufferingSubject = CurrentValueSubject<BufferingState, Never>(.ready)
        private let currentTimeSubject = CurrentValueSubject<CMTime, Never>(.fromSeconds(12))
        private let durationSubject = CurrentValueSubject<CMTime, Never>(.fromSeconds(180))
        private let presentationSizeSubject = CurrentValueSubject<CGSize, Never>(CGSize(width: 1280, height: 720))
        private let seekableSubject = CurrentValueSubject<CMTimeRange?, Never>(CMTimeRange(start: .zero, duration: .fromSeconds(180)))
        private let loadedSubject = CurrentValueSubject<CMTimeRange?, Never>(CMTimeRange(start: .zero, duration: .fromSeconds(45)))
        private let externalSubject = CurrentValueSubject<Bool, Never>(false)
        private let muteSubject = CurrentValueSubject<Bool, Never>(false)
        private let rateSubject = CurrentValueSubject<Float, Never>(1)
        private let player = AVPlayer()

        init() {
            updateState()
        }

        var statePublisher: AnyPublisher<PlayerState, Never> { stateSubject.eraseToAnyPublisher() }
        var playbackStatusPublisher: AnyPublisher<PlaybackStatus, Never> { playbackSubject.eraseToAnyPublisher() }
        var bufferingStatePublisher: AnyPublisher<BufferingState, Never> { bufferingSubject.eraseToAnyPublisher() }
        var currentTimePublisher: AnyPublisher<CMTime, Never> { currentTimeSubject.eraseToAnyPublisher() }
        var durationPublisher: AnyPublisher<CMTime, Never> { durationSubject.eraseToAnyPublisher() }
        var presentationSizePublisher: AnyPublisher<CGSize, Never> { presentationSizeSubject.eraseToAnyPublisher() }
        var seekableRangePublisher: AnyPublisher<CMTimeRange?, Never> { seekableSubject.eraseToAnyPublisher() }
        var loadedTimeRangePublisher: AnyPublisher<CMTimeRange?, Never> { loadedSubject.eraseToAnyPublisher() }
        var externalPlaybackPublisher: AnyPublisher<Bool, Never> { externalSubject.eraseToAnyPublisher() }
        var mutePublisher: AnyPublisher<Bool, Never> { muteSubject.eraseToAnyPublisher() }
        var ratePublisher: AnyPublisher<Float, Never> { rateSubject.eraseToAnyPublisher() }

        func getAVPlayer() -> AVPlayer { player }
        func initialize(rate: Float, mute: Bool) {}
        func load(url: URL) {}
        func play() {}
        func pause() {}
        func stop() {}
        func seek(to time: CMTime, allowOutOfRange: Bool, completion: ((Bool) -> Void)?) { completion?(true) }
        @MainActor func seek(_ time: CMTime) async -> Bool { true }
        func setMute(_ value: Bool) { muteSubject.send(value) }
        func toggleMute() { setMute(!muteSubject.value) }

        private func updateState() {
            let snapshot = PlayerState(
                playbackStatus: playbackSubject.value,
                bufferingState: bufferingSubject.value,
                isMuted: muteSubject.value,
                rate: rateSubject.value,
                currentTime: currentTimeSubject.value,
                duration: durationSubject.value,
                seekableRange: seekableSubject.value,
                loadedTimeRange: loadedSubject.value,
                presentationSize: presentationSizeSubject.value,
                isExternalPlaybackActive: externalSubject.value
            )
            stateSubject.send(snapshot)
        }
    }
}
