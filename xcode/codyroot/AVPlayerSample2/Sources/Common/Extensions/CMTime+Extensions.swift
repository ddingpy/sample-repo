import AVFoundation

// MARK: - CMTime Helpers

extension CMTime {
    /// Returns true when the time represents a finite, non-negative value.
    var isValidAndFinite: Bool {
        guard isValid && isNumeric else { return false }
        let seconds = CMTimeGetSeconds(self)
        return seconds.isFinite && !seconds.isNaN && seconds >= 0
    }

    /// Convenience for `CMTime(seconds:preferredTimescale:)` using the timescale of 600.
    static func fromSeconds(_ seconds: TimeInterval) -> CMTime {
        CMTime(seconds: seconds, preferredTimescale: 600)
    }

    /// Converts the time to seconds, falling back to zero when invalid.
    var secondsOrZero: TimeInterval {
        guard isValidAndFinite else { return 0 }
        return CMTimeGetSeconds(self)
    }

    /// Clamps the time value so that it lands inside the supplied range.
    func clamped(to range: ClosedRange<CMTime>) -> CMTime {
        guard range.lowerBound.isValidAndFinite || range.upperBound.isValidAndFinite else { return self }
        if self < range.lowerBound { return range.lowerBound }
        if self > range.upperBound { return range.upperBound }
        return self
    }

    /// Returns a human-readable duration string (mm:ss) friendly for UI usage.
    func formattedMinutes() -> String {
        let totalSeconds = Int(secondsOrZero)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

extension CMTimeRange {
    /// Returns the upper bound of the range using the supplied tolerance when the end is indefinite.
    func endTimeOrFallback(_ fallback: CMTime = .positiveInfinity) -> CMTime {
        if duration.isValidAndFinite { return end }
        return fallback
    }
}
