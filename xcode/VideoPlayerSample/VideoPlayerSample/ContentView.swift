//
//  ContentView.swift
//  VideoPlayerSample
//
//  Created by ryan on 10/25/25.
//

import SwiftUI
import AVKit

struct ContentView: View {
    @State private var store = PlayerStore(
        url: URL(string:"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear1/prog_index.m3u8")!
    )
    @State private var seeking = false
    @State private var tempValue: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            VideoPlayer(player: store.player)
                .frame(height: 240)
            
            Slider(value: Binding(
                get: { seeking ? tempValue : store.current },
                set: { newValue in
                    seeking = true; tempValue = newValue
                }),
                in: 0...(store.duration > 0 ? store.duration : 1)
            )
            .onChange(of: seeking) { _, isSeeking in
                if !isSeeking {
                    let time = CMTime(seconds: tempValue, preferredTimescale: 600)
                    store.player.seek(to: time)
                }
            }
            .onChange(of: tempValue) { _, _ in } // keeps binding live
            
            HStack {
                Button("⏯ Play/Pause") {
                    if store.player.timeControlStatus == .playing { store.player.pause() }
                    else { store.player.play() }
                }
                Button(store.isMuted ? "🔈 Unmute" : "🔇 Mute") {
                    store.isMuted.toggle()
                    store.player.isMuted = store.isMuted
                }
                Menu("Rate \(String(format: "%.1fx", store.rate))") {
                    ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { r in
                        Button("\(r)x") { store.rate = Float(r); store.player.rate = Float(r) }
                    }
                }
            }
        }
        .padding()
        .onAppear { store.player.play() }
    }
}

#Preview {
    ContentView()
}
