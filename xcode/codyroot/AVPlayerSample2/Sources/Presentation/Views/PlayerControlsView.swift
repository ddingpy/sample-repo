import SwiftUI

// MARK: - Player Controls View

struct PlayerControlsView: View {
    @ObservedObject var viewModel: PlayerViewModel
    @State private var sliderValue: Double = 0
    @State private var isEditingSlider = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(statusDescription(for: viewModel.playbackStatus))
                    .font(.headline)
                Text(bufferingDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text(viewModel.formattedCurrentTime)
                    .font(.system(.footnote, design: .monospaced))
                Slider(
                    value: Binding(
                        get: {
                            isEditingSlider ? sliderValue : viewModel.displayedProgress
                        },
                        set: { newValue in
                            sliderValue = newValue
                            if isEditingSlider {
                                viewModel.updateScrubPreview(newValue)
                            }
                        }
                    ),
                    in: 0...1
                ) { editing in
                    if editing {
                        isEditingSlider = true
                        sliderValue = viewModel.displayedProgress
                        viewModel.beginScrubbing()
                    } else {
                        isEditingSlider = false
                        viewModel.endScrubbing(at: sliderValue)
                    }
                }
                Text(viewModel.formattedDuration)
                    .font(.system(.footnote, design: .monospaced))
            }

            HStack(spacing: 16) {
                Button(action: viewModel.playTapped) {
                    Label("Play", systemImage: "play.fill")
                        .labelStyle(.iconOnly)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.borderedProminent)

                Button(action: viewModel.pauseTapped) {
                    Label("Pause", systemImage: "pause.fill")
                        .labelStyle(.iconOnly)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)

                Button(action: viewModel.stopTapped) {
                    Label("Stop", systemImage: "stop.fill")
                        .labelStyle(.iconOnly)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)

                Button(action: viewModel.toggleMute) {
                    Label("Mute", systemImage: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .labelStyle(.iconOnly)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 8)
    }

    private var bufferingDescription: String {
        switch viewModel.bufferingState {
        case .unknown:
            return "Buffering state: Unknown"
        case .buffering:
            return "Buffering..."
        case .ready:
            return "Ready"
        }
    }

    private func statusDescription(for status: PlaybackStatus) -> String {
        switch status {
        case .idle:
            return "Idle"
        case .preparing:
            return "Preparing"
        case .ready:
            return "Ready"
        case .playing:
            return "Playing"
        case .paused:
            return "Paused"
        case .finished:
            return "Finished"
        case .failed(let message):
            return "Failed: \(message)"
        }
    }
}
