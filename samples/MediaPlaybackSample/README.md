# MediaPlaybackSample

This zip contains a **ready-to-open iOS SwiftUI Xcode project** demonstrating modern media playback:

- HLS playback (VideoPlayer + AVPlayer)
- Inline **AVPlayerViewController** variant (PiP-capable)
- Background audio configured (Info.plist → `UIBackgroundModes: audio`)
- Simple Now Playing + Remote Commands
- HLS downloader skeleton
- Network watcher

## Requirements
- Xcode 26.x (Swift 6.x toolchain)
- iOS 17+ simulator or device

## Run
1. Unzip.
2. Open `MediaPlayback-iOS/MediaPlayback-iOS.xcodeproj` in Xcode.
3. Select **iPhone 15** (or any iOS 17+ simulator) and Run.
4. Try the segmented control to switch between **AVPlayerVC (PiP)** and **SwiftUI VideoPlayer**.
5. Lock the screen or open Control Center to see **Now Playing** after tapping “ℹ️ Update Now Playing”.

> Notes:
> - For PiP with the AVPlayerViewController, tap the PiP button in the inline controls.
> - For background audio on a device, ensure a signing team is selected and run on a physical device.

## Structure
- `MediaPlayback-iOS/MediaPlayback-iOS/*.swift` — Sources
- `MediaPlayback-iOS/MediaPlayback-iOS/Info.plist` — Background audio enabled

Enjoy!

## macOS Project
- Open `MediaPlayback-macOS/MediaPlayback-macOS.xcodeproj` (macOS 14+).
- Click **Play Apple HLS Sample** or **Open File…** to choose a local video.
- Uses `AVPlayerView` via `NSViewRepresentable`.
