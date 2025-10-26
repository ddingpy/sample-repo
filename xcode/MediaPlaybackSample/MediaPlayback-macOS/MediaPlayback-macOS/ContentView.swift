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
    var current: Double = 0    // seconds
    private var timeObserver: Any?

    init(url: URL) {
        self.player = AVPlayer(url: url)
        // Update slider as playback progresses (every 0.5s)
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

    deinit {
        if let obs = timeObserver { player.removeTimeObserver(obs) }
    }
}

struct ContentView: View {
    @State private var store = PlayerStore(
        url: URL(string:"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear1/prog_index.m3u8")!
    )
    @State private var seeking = false
    @State private var tempValue: Double = 0

    var body: some View {
        VStack(spacing: 12) {
            PlayerViewRepresentable(player: store.player)
                .frame(height: 320)

            HStack {
                Button("Open File…") { openLocalFile() }
                Button("Play Apple HLS Sample") { playSample() }
                Spacer()
                Button(store.isMuted ? "🔈 Unmute" : "🔇 Mute") {
                    store.isMuted.toggle()
                    store.player.isMuted = store.isMuted
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
            )
            .onChange(of: seeking) { _, isSeeking in
                if !isSeeking {
                    let time = CMTime(seconds: tempValue, preferredTimescale: 600)
                    store.player.seek(to: time)
                }
            }

            HStack {
                Button("⏯ Play/Pause") {
                    if store.player.timeControlStatus == .playing { store.player.pause() }
                    else { store.player.play() }
                }
                Spacer()
                Text(timeLabel).monospacedDigit()
            }
        }
        .padding()
        .onAppear { store.player.play() }
    }

    private var timeLabel: String {
        func fmt(_ s: Double) -> String {
            guard s.isFinite else { return "--:--" }
            let m = Int(s) / 60, sec = Int(s) % 60
            return String(format: "%02d:%02d", m, sec)
        }
        return "\(fmt(store.current)) / \(fmt(store.duration))"
    }

    private func playSample() {
        let url = URL(string:"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear1/prog_index.m3u8")!
        let item = AVPlayerItem(url: url)
        store.player.replaceCurrentItem(with: item)
        store.player.play()
    }

    private func openLocalFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .mpeg4Movie, .appleProtectedMPEG4Audio, .audio, .quickTimeMovie]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            // If sandboxed and the URL is security-scoped, start access around playback.
            var needsStop = false
            if url.startAccessingSecurityScopedResource() { needsStop = true }
            defer { if needsStop { url.stopAccessingSecurityScopedResource() } }

            let item = AVPlayerItem(url: url)
            store.player.replaceCurrentItem(with: item)
            store.player.play()
        }
    }
}