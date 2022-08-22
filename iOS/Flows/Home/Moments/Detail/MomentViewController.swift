//
//  MomentDetailViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/3/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MomentViewController: ViewController {
    
    private let moment: Moment
    
    private let controlsContainer = BaseView()
    private let captionTextView = CaptionTextView()
    let personView = BorderedPersonView()
    let commentsButton = CommentsButton()
    let expressionsButton = ExpressionButton()
    private let expressionView = MomentExpressiontVideoView()
    private let momentView = MomentVideoView()
    let blurView = MomentBlurView()
    
    let cornerRadius: CGFloat = 30
    
    enum State {
        case initial
        case loading
        case playback
    }
    
    @Published var state: State = .initial
    
    init(with moment: Moment) {
        self.moment = moment
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeViews() {
        super.initializeViews()
        
        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            sheet.preferredCornerRadius = self.cornerRadius
        }
        
        self.view.set(backgroundColor: .B0)
        
        self.view.addSubview(self.momentView)
        self.view.addSubview(self.controlsContainer)
        self.controlsContainer.addSubview(self.captionTextView)
        self.captionTextView.isEditable = false
        self.captionTextView.isSelectable = false
        
        self.controlsContainer.addSubview(self.personView)
        self.controlsContainer.addSubview(self.commentsButton)
        self.commentsButton.configure(with: self.moment)
        
        self.controlsContainer.addSubview(self.expressionsButton)
        
        self.view.addSubview(self.blurView)
        self.view.addSubview(self.expressionView)
        
        self.$state
            .removeDuplicates()
            .mainSink { [unowned self] state in
                self.handle(state: state)
            }.store(in: &self.cancellables)
        
        self.state = .loading
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.momentView.expandToSuperviewSize()
        self.controlsContainer.expandToSuperviewSize()
        
        self.expressionView.squaredSize = self.view.width * 0.25
        self.expressionView.pinToSafeAreaTop()
        self.expressionView.pinToSafeAreaLeft()
        
        self.personView.squaredSize = 35
        self.personView.pinToSafeAreaRight()
        self.personView.pinToSafeAreaBottom()
        
        self.commentsButton.squaredSize = self.personView.height
        self.commentsButton.centerX = self.personView.centerX
        self.commentsButton.match(.bottom, to: .top, of: self.personView, offset: .negative(.custom(30)))
        
        self.expressionsButton.squaredSize = self.personView.height
        self.expressionsButton.centerX = self.personView.centerX
        self.expressionsButton.match(.bottom, to: .top, of: self.commentsButton, offset: .negative(.custom(30)))
        
        let maxWidth = Theme.getPaddedWidth(with: self.view.width) - self.personView.width - Theme.ContentOffset.xtraLong.value
        self.captionTextView.setSize(withMaxWidth: maxWidth)
        self.captionTextView.pinToSafeAreaLeft()
        self.captionTextView.pinToSafeAreaBottom()
        
        self.blurView.expandToSuperviewSize()
    }
    
    private func handle(state: State) {
        switch state {
        case .initial:
            break
        case .loading:
            
            self.blurView.configure(for: self.moment)
            self.expressionView.expression = self.moment.expression
            
            if MomentsStore.shared.hasRecordedToday || self.moment.isFromCurrentUser {
                self.blurView.animateBlur(shouldShow: false)
                self.momentView.loadFullMoment(for: self.moment)
                self.state = .playback
            } else {
                self.blurView.animateBlur(shouldShow: true)
                self.momentView.loadPreview(for: self.moment)
            }
        case .playback:
            Task {
                guard let moment = try? await self.moment.retrieveDataIfNeeded() else { return }
                self.captionTextView.animateCaption(text: moment.caption)
                self.personView.set(expression: nil, person: moment.author)
                self.view.layoutNow()
            } 
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard self.state == .playback else { return }
        
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.controlsContainer.alpha = 0.0
        }

        self.expressionView.playerLayer.player?.pause()
        self.momentView.playerLayer.player?.pause()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard self.state == .playback else { return }
        
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.controlsContainer.alpha = 1.0
        }
        
        self.expressionView.playerLayer.player?.play()
        self.momentView.playerLayer.player?.play()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        guard self.state == .playback else { return }
        
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.controlsContainer.alpha = 1.0
        }
        
        self.expressionView.playerLayer.player?.play()
        self.momentView.playerLayer.player?.play()
    }
}
