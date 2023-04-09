//
//  ContentView.swift
//  dirty dozen
//
//  Created by David Thomas on 4/9/23.
//

import SwiftUI
import AVKit

struct Item {
    let id: UUID
    let media: AnyView
    let isCorrect: Bool
    
    init(id: UUID, media: AnyView, isCorrect: Bool) {
        self.id = id
        self.media = media
        self.isCorrect = isCorrect
    }
}

struct ContentView: View {
    let items = [
        Item(id: UUID(), media: AnyView(Image("image1")), isCorrect: false),
        Item(id: UUID(), media: AnyView(Image("image2")), isCorrect: false),
        Item(id: UUID(), media: AnyView(Image("image3")), isCorrect: false),
        Item(id: UUID(), media: AnyView(AVPlayerPlayerView(videoFileName: "movie1", muted: true, playAutomatically: true)), isCorrect: true),
        Item(id: UUID(), media: AnyView(AVPlayerPlayerView(videoFileName: "movie2", muted: true, playAutomatically: true)), isCorrect: false),
        Item(id: UUID(), media: AnyView(AVPlayerPlayerView(videoFileName: "movie3", muted: true, playAutomatically: true)), isCorrect: false),
    ].shuffled()
    
    @State var selectedItem: Item?
    
    var body: some View {
        VStack {
            MyGridView(items: items, selectedItem: $selectedItem)
            
            Spacer()
            
            if let selectedItem = selectedItem {
                Text(selectedItem.isCorrect ? "Correct!" : "Incorrect")
                    .foregroundColor(selectedItem.isCorrect ? Color.green : Color.red)
                    .font(.title)
            }
        }
    }
}

struct MyGridView: View {
    let items: [Item]
    @Binding var selectedItem: Item?
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3)) {
            ForEach(items, id: \.id) { item in
                item.media
                    .frame(width: 100, height: 100)
                    .padding(10)
                    .background(selectedItem?.id == item.id ? Color.yellow : Color.clear)
                    .cornerRadius(10)
                    .onTapGesture {
                        selectedItem = item
                    }
            }
        }
    }
}

import Photos

struct AVPlayerPlayerView: UIViewRepresentable {
    let asset: PHAsset
    let muted: Bool
    let playAutomatically: Bool
    
    func makeUIView(context: Context) -> UIView {
        let playerView = UIView()
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { playerItem, _ in
            guard let playerItem = playerItem else { return }
            let player = AVPlayer(playerItem: playerItem)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = playerView.bounds
            playerLayer.videoGravity = .resizeAspectFill
            playerView.layer.addSublayer(playerLayer)
            playerView.clipsToBounds = true

            if playAutomatically {
                player.play()
            }

            if muted {
                player.isMuted = true
            }
        }
        return playerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
