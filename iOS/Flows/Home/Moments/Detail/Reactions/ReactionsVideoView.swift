//
//  ReactionsVideoView.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ReactionsVideoView: VideoView {

    var expressions: [Expression] = [] {
        didSet {
            // Only update the video if this is a new set of expressions.
            guard self.expressions != oldValue else { return }

            self.reset()
            self.updatePlayer()
        }
    }
    
    /// The currently running task that loads the video url.
    private var loadTask: Task<Void, Never>?
    
    private func updatePlayer() {
        self.loadTask?.cancel()

        self.loadTask = Task { [weak self] in
            
            var allURLs: [URL] = []
            
            await self?.expressions.asyncForEach { expression in
                guard let videoURL = try? await expression.file?.retrieveCachedPathURL() else { return }
                guard !Task.isCancelled else { return }

                allURLs.append(videoURL)
            }
            
            self?.updatePlayer(with: allURLs)
        }
    }
}
