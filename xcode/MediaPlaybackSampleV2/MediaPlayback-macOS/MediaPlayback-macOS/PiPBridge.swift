import Foundation
import AVKit

final class PiPBridge: NSObject, AVPictureInPictureControllerDelegate {
    private var pip: AVPictureInPictureController?
    private weak var playerLayer: AVPlayerLayer?

    init?(playerLayer: AVPlayerLayer?) {
        guard AVPictureInPictureController.isPictureInPictureSupported(),
              let layer = playerLayer else { return nil }
        self.playerLayer = layer
        super.init()
        let source = AVPictureInPictureController.ContentSource(playerLayer: layer)
        pip = AVPictureInPictureController(contentSource: source)
        pip?.delegate = self
    }

    func start() { pip?.startPictureInPicture() }
    func stop()  { pip?.stopPictureInPicture() }

    func pictureInPictureControllerWillStartPictureInPicture(_ controller: AVPictureInPictureController) {}
    func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {}
}