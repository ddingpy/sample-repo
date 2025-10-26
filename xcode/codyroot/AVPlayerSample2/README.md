# AVPlayerSample2

AVPlayerSample2 is a SwiftUI-driven sample app that demonstrates how KakaoTV-style playback infrastructure can power both custom `AVFoundation` rendering and `AVKit` full-screen experiences. The project wraps `AVPlayer` behind a Combine-friendly domain layer so the UI only talks to a `SamplePlayerOutput` abstraction.

## Architecture

- **Common** - Formatting helpers used by the view model (e.g., `CMTime` utilities, `TimeFormatter`).
- **Domain / Player** - `SampleAVPlayer` mirrors KakaoTVPlayer's `CoreAVPlayer` approach: it wraps `AVPlayer`, bridges KVO via Combine, emits `PlayerState`, and exposes thin control methods (`play`, `pause`, `stop`, `seek`, `setMute`). The `SamplePlayerOutput` protocol defines the contract used by higher layers.
- **Presentation** - `PlayerViewModel` converts domain publishers into `@Published` properties, applies UI formatting, and surfaces intents. SwiftUI views (`PlayerContainerView`, `PlayerControlsView`, `PlayerScreen`) compose the experience and hand off full-screen presentation to a thin `PlayerCoordinator` that hosts `AVPlayerViewController`.

The folder layout intentionally mirrors KakaoTVPlayer's separation of responsibilities, annotating large types with `// MARK:` to keep sections clear.

## Getting Started

1. Open `AVPlayerSample2/AVPlayerSample2.xcodeproj` in Xcode 15 or newer.
2. Select the **AVPlayerSample2** scheme and run on an iOS 16+ simulator or device.
3. Use the segmented control to swap between the bundled sample streams:
   - https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8
   - https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8
   - https://storage.googleapis.com/avplayer-samples/bbb-1080p.mp4

> **Note:** The app streams remote content and therefore requires network access. If connectivity is unavailable, playback will remain in the buffering state.

## Feature Highlights

- Inline playback rendered via `AVPlayerLayer` (SwiftUI `UIViewRepresentable`).
- Full-screen playback delegated to `AVPlayerViewController` while reusing the same underlying `AVPlayer` instance.
- Combine-backed state propagation with debounced time updates and buffering awareness.
- Simple analytics-style logging (`Logger`) inside the player and view model to mimic KakaoTV's diagnostic hooks.

## Testing

The project ships with two XCTest targets:

- **PlayerCoreTests** – Verifies that `SampleAVPlayer` publishes state changes for `play`, `pause`, and `stop` interactions.
- **PresentationTests** – Exercises `PlayerViewModel` using a mock player to confirm formatting and delegation logic.

Run the full suite from Xcode or via the command line:

```bash
xcodebuild test \
  -project AVPlayerSample2.xcodeproj \
  -scheme AVPlayerSample2 \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Limitations

- Streams are public demonstration URLs and may change or become unavailable.
- No offline fallback asset is bundled; if you need guaranteed playback, point `PlayerSource` to packaged media.

Enjoy exploring how a KakaoTV-inspired player core can live happily inside a modern SwiftUI surface!
