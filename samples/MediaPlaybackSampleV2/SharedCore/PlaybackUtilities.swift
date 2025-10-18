// SharedCore/PlaybackUtilities.swift
import Foundation

public enum PlaybackUtilities {
    public static let sampleHLS = URL(string:"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear1/prog_index.m3u8")!

    public static func formatClock(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "--:--" }
        let m = Int(seconds) / 60, s = Int(seconds) % 60
        return String(format: "%02d:%02d", m, s)
    }
}