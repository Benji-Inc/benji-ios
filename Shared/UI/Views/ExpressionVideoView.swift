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
            // Only update the video if this is a new expression.
            guard self.expression != oldValue else { return }

            self.videoURL = nil
            self.updatePlayer(with: self.expression)
        }
    }
    
    /// The currently running task that loads the video url.
    private var loadTask: Task<Void, Never>?
    
    private func updatePlayer(with expression: Expression?) {
        self.loadTask?.cancel()

        guard let expression = self.expression else {
            self.videoURL = nil
            return
        }

        self.loadTask = Task { [weak self] in
            guard let videoURL = try? await expression.file?.retrieveCachedPathURL(),
                  videoURL != self?.videoURL else { return }

            guard !Task.isCancelled else { return }

            self?.videoURL = videoURL
        }
    }
}
