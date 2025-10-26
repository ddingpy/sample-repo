import SwiftUI
import AVKit

struct PlayerViewRepresentable: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let v = AVPlayerView()
        v.controlsStyle = .floating
        v.player = player
        v.showsFullScreenToggleButton = true
        return v
    }

    func updateNSView(_ view: AVPlayerView, context: Context) {
        view.player = player
    }
}