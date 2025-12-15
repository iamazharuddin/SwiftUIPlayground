//
//  CustomVideoPlayer.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 14/12/25.
//

import SwiftUI
import AVKit

let videoURL = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")
struct CustomVideoPlayer: View {

    @State private var player: AVPlayer = {
        let playerItem = AVPlayerItem(url: videoURL!)
        return AVPlayer(playerItem: playerItem)
    }()
          
     var body: some View {
         VideoPlayer(player: player)
             .frame(width: 320, height: 240)
     }
}


#Preview {
    CustomVideoPlayer()
}
