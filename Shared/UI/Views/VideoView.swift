//
//  VideoView.swift
//  Jibber
//
//  Created by Martin Young on 6/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import AVFoundation

class VideoView: BaseView {

    var videoURL: URL? {
        didSet {
            self.updatePlayer(with: self.videoURL)
        }
    }

    var shouldLoop = true
    /// How long, in seconds, to wait before playing the video again.
    var loopDelay: CGFloat = 1

    let playerLayer = AVPlayerLayer(player: nil)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.layer.addSublayer(self.playerLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.playerLayer.frame = self.bounds
    }

    private var repeatTask: Task<Void, Never>?

    private func updatePlayer(with url: URL?) {
        self.repeatTask?.cancel()

        guard let videoURL = url else {
            self.playerLayer.player = nil
            return
        }

        let player = AVPlayer(url: videoURL)
        self.playerLayer.player = player

        player.play()

        self.repeatTask = Task { [weak self] in
            // Loop the video until a new video is set.
            while !Task.isCancelled && self.exists {
                await Task.sleep(seconds: 6)
                await player.seek(to: .zero)
                player.play()
            }
        }
    }
}
