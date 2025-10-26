import AVFoundation
import AVKit
import SwiftUI

// MARK: - Player Container View

struct PlayerContainerView: View {
    @ObservedObject var viewModel: PlayerViewModel

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PlayerLayerRepresentable(player: viewModel.underlyingPlayer)
                .aspectRatio(16 / 9, contentMode: .fit)
                .background(Color.black)
                .overlay(alignment: .center) {
                    if viewModel.isBuffering {
                        ProgressView("Buffering...")
                            .progressViewStyle(.circular)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }

            Button(action: viewModel.presentFullScreenPlayer) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.body.weight(.semibold))
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding()
        }
        .sheet(isPresented: $viewModel.isFullScreenPresented, onDismiss: viewModel.dismissFullScreenPlayer) {
            PlayerViewControllerRepresentable(coordinator: viewModel.playerCoordinator)
                .ignoresSafeArea()
        }
    }
}

// MARK: - UIViewRepresentable Bridge

private struct PlayerLayerRepresentable: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerHostingView {
        let view = PlayerHostingView()
        view.playerLayer.videoGravity = .resizeAspect
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ uiView: PlayerHostingView, context: Context) {
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
    }
}

private final class PlayerHostingView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
}

// MARK: - AVPlayerViewController bridge

private struct PlayerViewControllerRepresentable: UIViewControllerRepresentable {
    @ObservedObject var coordinator: PlayerCoordinator

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        coordinator.makeAVPlayerViewController()
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        if controller.player !== coordinator.avPlayer {
            controller.player = coordinator.avPlayer
        }
    }
}
