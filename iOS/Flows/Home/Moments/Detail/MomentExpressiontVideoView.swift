//
//  ExpressionMomentVideoView.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/12/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MomentExpressiontVideoView: VideoView {
    
    private let emotionGradientView = EmotionGradientView()
    
    var expression: Expression? {
        didSet {
            // Only update the video if this is a new expression.
            guard self.expression != oldValue else { return }

            self.videoURL = nil
            self.updatePlayer()
        }
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.insertSubview(self.emotionGradientView, at: 0)
        self.emotionGradientView.alpha = 0.75
        
        self.layer.borderColor = ThemeColor.whiteWithAlpha.color.cgColor
        self.layer.borderWidth = 2
        self.clipsToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.emotionGradientView.expandToSuperviewSize()
        self.layer.cornerRadius = self.height * 0.25
    }
    
    /// The currently running task that loads the video url.
    private var loadTask: Task<Void, Never>?
    
    private func updatePlayer() {
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


