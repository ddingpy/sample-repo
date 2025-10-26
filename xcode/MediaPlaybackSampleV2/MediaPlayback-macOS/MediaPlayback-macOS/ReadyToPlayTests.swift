import XCTest
import AVFoundation

final class ReadyToPlayTests_macOS: XCTestCase {
    func testReadyToPlayAppleSample() {
        let exp = expectation(description: "ready")
        let url = URL(string:"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear1/prog_index.m3u8")!
        let item = AVPlayerItem(url: url)
        let obs = item.observe(\.status, options: [.new]) { item, _ in
            if item.status == .readyToPlay { exp.fulfill() }
        }
        _ = AVPlayer(playerItem: item)
        wait(for: [exp], timeout: 15.0)
        obs.invalidate()
    }
}