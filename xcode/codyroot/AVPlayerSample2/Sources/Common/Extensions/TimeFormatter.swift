import Foundation
import AVFoundation

/// Produces playback friendly formatting used by the presentation layer.
struct TimeFormatter {
    private let dateComponentsFormatter: DateComponentsFormatter

    init(style: DateComponentsFormatter.UnitsStyle = .positional) {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        formatter.unitsStyle = style
        dateComponentsFormatter = formatter
    }

    func string(from time: CMTime) -> String {
        let seconds = max(0, time.secondsOrZero)
        return dateComponentsFormatter.string(from: seconds) ?? "00:00"
    }

    func string(from seconds: TimeInterval) -> String {
        let sanitized = max(0, seconds)
        return dateComponentsFormatter.string(from: sanitized) ?? "00:00"
    }
}
