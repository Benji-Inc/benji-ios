//
//  MomentVideoView.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/12/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MomentVideoView: VideoView {

    var moment: Moment? {
        didSet {
            // Only update the video if this is a new moment.
            guard self.moment != oldValue else { return }

            self.videoURL = nil
            self.updatePlayer()
        }
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.playerLayer.videoGravity = .resizeAspectFill
    }
    
    /// The currently running task that loads the video url.
    private var loadTask: Task<Void, Never>?
    
    private func updatePlayer() {
        self.loadTask?.cancel()

        guard let moment = self.moment else {
            self.videoURL = nil
            return
        }

        self.loadTask = Task { [weak self] in
            guard let videoURL = try? await moment.file?.retrieveCachedPathURL(),
                  videoURL != self?.videoURL else { return }

            guard !Task.isCancelled else { return }

            self?.videoURL = videoURL
        }
    }
}
