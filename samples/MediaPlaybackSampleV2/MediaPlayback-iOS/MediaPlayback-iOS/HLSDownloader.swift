import Foundation
import AVFoundation

final class HLSDownloader: NSObject, AVAssetDownloadDelegate {
    private lazy var session: AVAssetDownloadURLSession = {
        let cfg = URLSessionConfiguration.background(withIdentifier: "com.example.hlsdownloads")
        return AVAssetDownloadURLSession(configuration: cfg, assetDownloadDelegate: self, delegateQueue: .main)
    }()

    func start(url: URL, title: String) {
        let asset = AVURLAsset(url: url)
        let task = session.makeAssetDownloadTask(
            asset: asset, assetTitle: title, assetArtworkData: nil,
            options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 265_000]
        )
        task?.resume()
    }

    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask,
                    didFinishDownloadingTo location: URL) {
        print("Downloaded to:", location)
    }

    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask,
                    didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loaded: [CMTimeRange],
                    timeRangeExpectedToLoad: CMTimeRange) {
        let loadedSeconds = loaded.reduce(0) { $0 + $1.duration.seconds }
        let pct = loadedSeconds / timeRangeExpectedToLoad.duration.seconds
        print("Progress:", pct)
    }
}