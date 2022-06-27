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
    private(set) var player: AVPlayer?

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

        self.player = AVPlayer(url: videoURL)
        self.playerLayer.player = self.player

        self.player?.play()
    }
}
