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

    private var repeatTask: Task<Void, Never>?

    private func updatePlayer(with expression: Expression?) {
        self.repeatTask?.cancel()

        guard let videoURLString = expression?.file?.url, let videoURL = URL(string: videoURLString) else {
            self.videoURL = nil
            return
        }

        self.videoURL = videoURL

        self.repeatTask = Task { [weak self] in
            // Loop the video until a new video is set.
            while !Task.isCancelled && self.exists {
                await Task.sleep(seconds: 6)
                await self?.player?.seek(to: .zero)
                self?.player?.play()
            }
        }
    }
}
