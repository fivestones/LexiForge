import SwiftUI
import AVKit

struct VideoPlayerView: UIViewRepresentable {
    var videoName: String

    func makeUIView(context: Context) -> UIView {
        return PlayerUIView(frame: .zero, videoName: videoName)
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    class PlayerUIView: UIView {
        private let playerLayer = AVPlayerLayer()
        private var playerLooper: AVPlayerLooper?

        init(frame: CGRect, videoName: String) {
            super.init(frame: frame)

            guard let videoURL = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
                return
            }
            let playerItem = AVPlayerItem(url: videoURL)
            let queuePlayer = AVQueuePlayer(playerItem: playerItem)

            playerLayer.player = queuePlayer
            playerLayer.videoGravity = .resizeAspectFill
            layer.addSublayer(playerLayer)

            let looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
            playerLooper = looper

            queuePlayer.play()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer.frame = bounds
        }
    }
}
