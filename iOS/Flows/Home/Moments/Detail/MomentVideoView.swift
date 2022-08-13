//
//  MomentVideoView.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/12/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

class MomentVideoView: VideoView {
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.shouldPlay = true 
        self.playerLayer.videoGravity = .resizeAspectFill
    }
    
    func loadPreview(for moment: Moment) {
        guard let preview = moment.preview else { return }
        self.updatePlayer(with: preview)
    }
    
    func loadFullMoment(for moment: Moment) {
        guard let file = moment.file else { return }
        self.updatePlayer(with: file)
    }
    
    /// The currently running task that loads the video url.
    private var loadTask: Task<Void, Never>?
    
    private func updatePlayer(with file: PFFileObject) {
        self.loadTask?.cancel()

        self.loadTask = Task { [weak self] in
            guard let videoURL = try? await file.retrieveCachedPathURL(),
                  videoURL != self?.videoURL else { return }

            guard !Task.isCancelled else { return }

            self?.videoURL = videoURL
        }
    }
}
