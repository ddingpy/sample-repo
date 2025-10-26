import SwiftUI
import AVKit

struct PlayerViewControllerRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = player
        // Allow PiP to start automatically when the user taps the PiP button on the inline controls.
        vc.canStartPictureInPictureAutomaticallyFromInline = true
        return vc
    }
    func updateUIViewController(_ vc: AVPlayerViewController, context: Context) {
        vc.player = player
    }
}