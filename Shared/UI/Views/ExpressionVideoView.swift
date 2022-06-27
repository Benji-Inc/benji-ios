//
//  File.swift
//  Jibber
//
//  Created by Martin Young on 6/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import AVFoundation

class ExpressionVideoView: VideoView {

    var expression: Expression? {
        didSet {
            self.updatePlayer(with: self.expression)
        }
    }

    private func updatePlayer(with expression: Expression?) {
        guard let videoURLString = expression?.file?.url, let videoURL = URL(string: videoURLString) else {
            self.videoURL = nil
            return
        }

        self.videoURL = videoURL
    }
}
