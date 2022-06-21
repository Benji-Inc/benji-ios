//
//  ContextCueView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmojiCircleView: BaseView {
    
    enum Scale {
        case large
        case small
    }
    
    lazy var label = ThemeLabel(font: self.scale == .small ? .xtraSmall : .regular)
    var scale: Scale = .large {
        didSet {
            self.label.setFont(self.scale == .small ? .xtraSmall : .regular)
            self.layoutNow()
        }
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.label)
        self.label.textAlignment = .center
        self.set(backgroundColor: .white)
    }
    
    func set(text: String) {
        self.label.setText(text)
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        self.squaredSize = self.scale == .small ? 16 : 30
        self.makeRound()

        self.label.expandToSuperviewSize()
        self.label.centerY = self.halfHeight + 0.5
        self.label.centerX = self.halfWidth + 0.5
    }
}

class ContextCueView: EmojiCircleView {
    
    var shouldStayHidden: Bool = false
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.isHidden = true
    }
    
    private var newContextCueTask: Task<Void, Never>?
    private var animateContextCueTask: Task<Void, Never>?
    
    func configure(with person: PersonType) {
        // Cancel any currently running swipe hint tasks so we don't trigger the animation multiple times.
        self.newContextCueTask?.cancel()
        self.animateContextCueTask?.cancel()
        
        self.newContextCueTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            guard let user = person as? User,
                  let updated = try? await user.latestContextCue?.retrieveDataIfNeeded(),
                  let createdAt = updated.createdAt,
                  createdAt.isSameDay(as: Date.today),
                  !updated.emojis.isEmpty else {
                      self.isHidden = true
                      return
                  }
            if !self.shouldStayHidden {
                self.isHidden = false
            }
            await self.animate(emojiIndex: 0, for: updated)
        }
    }
    
    
    private func animate(emojiIndex: Int, for contextCue: ContextCue) async {
        self.animateContextCueTask?.cancel()
        
        guard !contextCue.emojis.isEmpty else { return }
        
        self.animateContextCueTask = Task { [weak self] in
            if let emoji = contextCue.emojis[safe: emojiIndex] {
                
                await UIView.awaitSpringAnimation(with: .slow,
                                                  damping: 0.7,
                                                  velocity: 0.5,
                                                  animations: {
                    self?.label.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
                    self?.label.alpha = 0
                })
                
                self?.label.setText(emoji)
                self?.layoutNow()
                
                guard !Task.isCancelled else { return }
                
                await UIView.awaitSpringAnimation(with: .standard,
                                                  damping: 0.7,
                                                  velocity: 0.5,
                                                  animations: {
                    self?.label.transform = .identity
                    self?.label.alpha = 1.0
                })
                
                guard !Task.isCancelled else { return }

                await Task.sleep(seconds: 2)
                
                guard !Task.isCancelled else { return }

                if contextCue.emojis.count > 1 {
                    await self?.animate(emojiIndex: emojiIndex + 1, for: contextCue)
                }

            } else {
               await self?.animate(emojiIndex: 0, for: contextCue)
            }
        }
    }
}
