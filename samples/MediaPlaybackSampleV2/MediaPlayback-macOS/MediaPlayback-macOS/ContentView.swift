import SwiftUI
import AVKit
import Observation
import AppKit

@Observable
final class PlayerStore {
    let player: AVPlayer
    var isMuted = false
    var rate: Float = 1.0
    var duration: Double = 0
    var current: Double = 0
    private var timeObserver: Any?

    init(url: URL) {
        self.player = AVPlayer(url: url)
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            self.current = time.seconds
            if let item = self.player.currentItem {
                let d = item.duration.seconds
                if d.isFinite { self.duration = d }
            }
        }
    }
    deinit { if let obs = timeObserver { player.removeTimeObserver(obs) } }
}

struct ContentView: View {
    @State private var store = PlayerStore(url: PlaybackUtilities.sampleHLS)
    @State private var seeking = false
    @State private var tempValue: Double = 0
    @State private var pip: PiPBridge?
    private let box = PlayerViewBox()

    var body: some View {
        VStack(spacing: 12) {
            PlayerViewRepresentable(player: store.player, box: box)
                .frame(height: 320)
                .background(Color(nsColor: .windowBackgroundColor))

            HStack {
                Button("Open File…") { openLocalFile() }
                Button("Play Sample") { playSample() }
                Button("Start PiP") { startPiP() }
                Spacer()
                Button(store.isMuted ? "🔈 Unmute" : "🔇 Mute") {
                    store.isMuted.toggle(); store.player.isMuted = store.isMuted
                }
                Menu("Rate \(String(format: "%.1fx", store.rate))") {
                    ForEach([0.5, 1.0, 1.5, 2.0], id: \.\self) { r in
                        Button("\(r)x") { store.rate = Float(r); store.player.rate = Float(r) }
                    }
                }
            }

            Slider(value: Binding(
                get: { seeking ? tempValue : store.current },
                set: { newValue in seeking = true; tempValue = newValue }),
                   in: 0...(store.duration > 0 ? store.duration : 1)
            ).onChange(of: seeking) { _, isSeeking in
                if !isSeeking {
                    let time = CMTime(seconds: tempValue, preferredTimescale: 600)
                    store.player.seek(to: time)
                }
            }

            HStack {
                Button("⏯ Play/Pause") {
                    store.player.timeControlStatus == .playing ? store.player.pause() : store.player.play()
                }
                Spacer()
                Text("\(PlaybackUtilities.formatClock(store.current)) / \(PlaybackUtilities.formatClock(store.duration))").monospacedDigit()
            }
        }
        .padding()
        .onAppear { store.player.play() }
    }

    private func startPiP() {
        if pip == nil {
            pip = PiPBridge(playerLayer: box.view?.playerLayer)
        }
        pip?.start()
    }

    private func playSample() {
        let item = AVPlayerItem(url: PlaybackUtilities.sampleHLS)
        store.player.replaceCurrentItem(with: item)
        store.player.play()
    }

    private func openLocalFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .mpeg4Movie, .appleProtectedMPEG4Audio, .audio, .quickTimeMovie]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            var needsStop = false
            if url.startAccessingSecurityScopedResource() { needsStop = true }
            defer { if needsStop { url.stopAccessingSecurityScopedResource() } }

            let item = AVPlayerItem(url: url)
            store.player.replaceCurrentItem(with: item)
            store.player.play()
        }
    }
}