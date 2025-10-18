import SwiftUI
import AVKit

final class PlayerViewBox {
    weak var view: AVPlayerView?
}

struct PlayerViewRepresentable: NSViewRepresentable {
    let player: AVPlayer
    let box: PlayerViewBox

    func makeNSView(context: Context) -> AVPlayerView {
        let v = AVPlayerView()
        v.controlsStyle = .floating
        v.player = player
        v.showsFullScreenToggleButton = true
        box.view = v
        return v
    }

    func updateNSView(_ view: AVPlayerView, context: Context) {
        view.player = player
    }
}