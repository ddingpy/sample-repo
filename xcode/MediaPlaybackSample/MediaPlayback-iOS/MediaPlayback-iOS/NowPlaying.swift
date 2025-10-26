import Foundation
import MediaPlayer
import AVFoundation
import UIKit

final class NowPlaying {
    private let center = MPNowPlayingInfoCenter.default()
    private let player: AVPlayer

    init(player: AVPlayer) { self.player = player }

    func update(title: String, artist: String? = nil, artwork: UIImage? = nil) {
        var info: [String : Any] = [
            MPMediaItemPropertyTitle: title,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime().seconds,
            MPMediaItemPropertyPlaybackDuration: player.currentItem?.duration.seconds ?? 0,
            MPNowPlayingInfoPropertyPlaybackRate: player.rate
        ]
        if let artist { info[MPMediaItemPropertyArtist] = artist }
        if let artwork { info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artwork.size) { _ in artwork } }
        center.nowPlayingInfo = info
        wireCommands()
    }

    private func wireCommands() {
        let cmd = MPRemoteCommandCenter.shared()
        cmd.playCommand.isEnabled = true
        cmd.pauseCommand.isEnabled = true
        cmd.togglePlayPauseCommand.isEnabled = true
        cmd.playCommand.addTarget { [weak player] _ in player?.play(); return .success }
        cmd.pauseCommand.addTarget { [weak player] _ in player?.pause(); return .success }
        cmd.togglePlayPauseCommand.addTarget { [weak player] _ in
            guard let p = player else { return .commandFailed }
            p.timeControlStatus == .playing ? p.pause() : p.play()
            return .success
        }
    }
}