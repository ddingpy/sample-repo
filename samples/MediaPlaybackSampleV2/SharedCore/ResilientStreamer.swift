// SharedCore/ResilientStreamer.swift
import Foundation
import AVFoundation

public actor ResilientStreamer {
    public private(set) var player: AVPlayer?
    public init() {}

    /// Plays a URL with up to 3 retries and exponential backoff.
    @discardableResult
    public func play(_ url: URL) async -> AVPlayer {
        var delay: UInt64 = 1_000_000_000 // 1s
        for attempt in 1...3 {
            let item = AVPlayerItem(url: url)
            let p = AVPlayer(playerItem: item)
            p.automaticallyWaitsToMinimizeStalling = true
            player = p; p.play()
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if item.status == .readyToPlay { return p }
            p.pause()
            try? await Task.sleep(nanoseconds: delay)
            delay *= 2
        }
        // Return best-effort player anyway.
        return player ?? AVPlayer(url: url)
    }
}