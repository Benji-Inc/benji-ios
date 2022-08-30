//
//  MomentContentView.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/30/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MomentContentView: BaseView {
    
    private let expressionView = MomentExpressiontVideoView()
    private let momentView = MomentVideoView()
    private let blurView = MomentBlurView()
    private let captionTextView = CaptionTextView()
    private var moment: Moment?
    
    var didSelectCapture: CompletionOptional = nil
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.momentView)
        self.addSubview(self.expressionView)
        self.addSubview(self.captionTextView)
        self.addSubview(self.blurView)
        
        self.captionTextView.isEditable = false
        self.captionTextView.isSelectable = false
        
        self.blurView.button.didSelect { [unowned self] in
            self.didSelectCapture?() 
        }
        
        self.clipsToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.blurView.expandToSuperviewSize()
        
        self.expressionView.squaredSize = self.width * 0.25
        self.expressionView.pinToSafeAreaTop()
        self.expressionView.pinToSafeAreaLeft()
        
        let maxWidth = Theme.getPaddedWidth(with: self.width)
        self.captionTextView.setSize(withMaxWidth: maxWidth)
        self.captionTextView.pinToSafeAreaLeft()
        self.captionTextView.bottom = self.momentView.height - self.captionTextView.left
        self.captionTextView.isVisible = !self.captionTextView.placeholderText.isEmpty
    }
    
    func configure(with moment: Moment) {
        self.moment = moment
        self.blurView.configure(for: moment)
        self.expressionView.expression = moment.expression
        
        //            if MomentsStore.shared.hasRecordedToday || self.moment.isFromCurrentUser {
        //                self.blurView.animateBlur(shouldShow: false)
        //                self.momentView.loadFullMoment(for: self.moment)
        //                self.state = .playback
        //            } else {
                        self.blurView.animateBlur(shouldShow: true)
                        self.momentView.loadPreview(for: moment)
        //            }
    }
    
    func beginPlayback() {
        Task {
            guard let moment = try? await self.moment?.retrieveDataIfNeeded() else { return }
            self.captionTextView.animateCaption(text: moment.caption)
        }
    }
    
    func play() {
        self.expressionView.playerLayer.player?.play()
        self.momentView.playerLayer.player?.play()
    }
    
    func pause() {
        self.expressionView.playerLayer.player?.pause()
        self.momentView.playerLayer.player?.pause()
    }
}
