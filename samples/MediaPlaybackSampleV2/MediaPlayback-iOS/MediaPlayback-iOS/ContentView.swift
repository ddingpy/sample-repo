import SwiftUI
import AVKit
import Observation

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
    @State private var useAVPlayerVC = true   // switch between SwiftUI VideoPlayer and AVPlayerViewController

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Renderer", selection: $useAVPlayerVC) {
                    Text("AVPlayerVC (PiP)").tag(true)
                    Text("SwiftUI VideoPlayer").tag(false)
                }
                .pickerStyle(.segmented)

                Group {
                    if useAVPlayerVC {
                        PlayerViewControllerRepresentable(player: store.player)
                            .frame(height: 240)
                    } else {
                        VideoPlayer(player: store.player)
                            .frame(height: 240)
                    }
                }

                Slider(value: Binding(
                    get: { seeking ? tempValue : store.current },
                    set: { newValue in
                        seeking = true; tempValue = newValue
                    }),
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
                .buttonStyle(.borderedProminent)

                HStack {
                    Button("ℹ️ Update Now Playing") {
                        NowPlaying(player: store.player).update(title: "Sample HLS", artist: "Apple", artwork: nil)
                    }
                    Button("▶️ Start PiP") {
                        // If using AVPlayerVC, PiP can start automatically from inline via system button.
                        // For custom layers, see PiPBridge sample in the guide.
                    }
                }
                .buttonStyle(.bordered)

                Spacer()
            }
            .padding()
            .navigationTitle("Media Playback Sample")
            .onAppear { store.player.play() }
        }
    }
}