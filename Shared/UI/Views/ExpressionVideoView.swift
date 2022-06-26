//
//  File.swift
//  Jibber
//
//  Created by Martin Young on 6/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import AVFoundation

class ExpressionVideoView: BaseView {

    var expression: Expression? {
        didSet {
            self.updatePlayer(with: self.expression)
        }
    }

    private let playerLayer = AVPlayerLayer(player: nil)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.layer.addSublayer(self.playerLayer)

        self.set(backgroundColor: .red)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.playerLayer.frame = self.bounds
    }

    private func updatePlayer(with expression: Expression?) {
        guard let videoURLString = expression?.file?.url, let videoURL = URL(string: videoURLString) else {
            self.playerLayer.player = nil
            return
        }

        let player = AVPlayer(url: videoURL)
        self.playerLayer.player = player

        player.play()
    }
}
