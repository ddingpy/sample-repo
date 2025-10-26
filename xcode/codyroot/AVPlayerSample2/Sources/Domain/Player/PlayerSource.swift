import Foundation

// MARK: - Player Source

struct PlayerSource: Identifiable, Hashable {
    let id: UUID
    let title: String
    let url: URL

    init(id: UUID = UUID(), title: String, url: URL) {
        self.id = id
        self.title = title
        self.url = url
    }
}

extension PlayerSource {
    static let sintelHLS = PlayerSource(
        title: "Sintel HLS",
        url: URL(string: "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8")!
    )

    static let bipBopAdvanced = PlayerSource(
        title: "Apple BipBop",
        url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8")!
    )

    static let demoMP4 = PlayerSource(
        title: "Big Buck Bunny MP4",
        url: URL(string: "https://storage.googleapis.com/avplayer-samples/bbb-1080p.mp4")!
    )

    static let all: [PlayerSource] = [
        .sintelHLS,
        .bipBopAdvanced,
        .demoMP4,
    ]
}
