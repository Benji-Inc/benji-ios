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

    let playerLayer = AVPlayerLayer(player: nil)
    /// An object that keeps looping the video back to the beginning.
    private var looper: AVPlayerLooper?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.layer.addSublayer(self.playerLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.playerLayer.frame = self.bounds
    }

    private func updatePlayer(with url: URL?) {
        guard let videoURL = url else {
            self.playerLayer.player = nil
            return
        }

        let videoItem = AVPlayerItem(url: videoURL)
        let player = AVQueuePlayer(items: [videoItem])
        self.looper = AVPlayerLooper(player: player, templateItem: videoItem)

        self.playerLayer.player = player

        player.play()
    }
}
