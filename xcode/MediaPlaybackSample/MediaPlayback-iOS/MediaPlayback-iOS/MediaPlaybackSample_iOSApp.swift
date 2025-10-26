import SwiftUI
import AVFAudio

@main
struct MediaPlaybackSample_iOSApp: App {
    init() {
        // Configure audio session for playback & background audio
        try? configurePlaybackSession()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

@MainActor
func configurePlaybackSession() throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .allowBluetooth])
    try session.setActive(true)
}