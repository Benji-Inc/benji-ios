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
    
    /// The currently running.
    private var loadTask: Task<Void, Never>?
    
    private func updatePlayer(with expression: Expression?) {
        self.loadTask?.cancel()

        self.loadTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            guard let videoURL = try? await expression?.file?.retrieveCachedPathURL(),
                  videoURL != self.videoURL,
            !Task.isCancelled else { return }

            self.videoURL = videoURL
        }
    }
}
