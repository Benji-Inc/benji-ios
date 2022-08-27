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
    let commentsLabel = CommentsLabel()
    let expressionsButton = MomentReactionsView()
    let menuButton = ThemeButton()
    let expressionView = MomentExpressiontVideoView()
    let momentView = MomentVideoView()
    let blurView = MomentBlurView()
    
    var didSelectViewProfile: ((PersonType) -> Void)? = nil
    
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
        
        // counter for reactions
        // multi video support
        // add user to comments channel if not added.
        
        self.view.set(backgroundColor: .B0)
        
        self.view.addSubview(self.momentView)
        self.momentView.layer.cornerRadius = self.cornerRadius
        self.momentView.layer.masksToBounds = true
        
        self.view.addSubview(self.controlsContainer)
        self.controlsContainer.addSubview(self.captionTextView)
        self.captionTextView.isEditable = false
        self.captionTextView.isSelectable = false
        
        self.controlsContainer.addSubview(self.commentsLabel)
        self.commentsLabel.configure(with: self.moment)
        
        self.controlsContainer.addSubview(self.expressionsButton)
        self.expressionsButton.configure(with: self.moment)
        
        self.view.addSubview(self.blurView)
        self.view.addSubview(self.expressionView)
        
        self.controlsContainer.addSubview(self.menuButton)
        self.menuButton.set(style: .image(symbol: .ellipsis, palletteColors: [.whiteWithAlpha], pointSize: 22, backgroundColor: .clear))
        self.menuButton.showsMenuAsPrimaryAction = true
        
        self.$state
            .removeDuplicates()
            .mainSink { [unowned self] state in
                self.handle(state: state)
            }.store(in: &self.cancellables)
        
        self.state = .loading
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.momentView.expandToSuperviewWidth()
        self.momentView.height = self.view.height - self.view.safeAreaInsets.bottom - self.view.height * 0.15
        self.momentView.pin(.top)
        self.controlsContainer.expandToSuperviewSize()
        
        self.expressionView.squaredSize = self.view.width * 0.25
        self.expressionView.pinToSafeAreaTop()
        self.expressionView.pinToSafeAreaLeft()
        
        self.menuButton.squaredSize = 44
        self.menuButton.pin(.top)
        self.menuButton.pinToSafeAreaRight()
        
        let maxLabelWidth = Theme.getPaddedWidth(with: self.view.width) - self.expressionsButton.width - Theme.ContentOffset.long.value
        self.commentsLabel.setSize(withWidth: maxLabelWidth)
        self.commentsLabel.match(.top, to: .bottom, of: self.momentView, offset: .xtraLong)
        self.commentsLabel.pinToSafeAreaLeft()
        
        self.expressionsButton.squaredSize = 35
        self.expressionsButton.pinToSafeAreaRight()
        self.expressionsButton.centerY = self.commentsLabel.centerY
        
        let maxWidth = Theme.getPaddedWidth(with: self.view.width)
        self.captionTextView.setSize(withMaxWidth: maxWidth)
        self.captionTextView.pinToSafeAreaLeft()
        self.captionTextView.bottom = self.momentView.height - self.captionTextView.left
        self.captionTextView.isVisible = !self.captionTextView.placeholderText.isEmpty
        
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
                self.view.layoutNow()

                if let person = try? await moment.author?.retrieveDataIfNeeded() {
                    self.menuButton.menu = self.createMenu(for: person)
                }
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
    
    private func createMenu(for person: PersonType) -> UIMenu? {
        guard person.isCurrentUser else { return nil }
        
        let profile = UIAction(title: "View Profile",
                              image: ImageSymbol.personCircle.image,
                              attributes: []) { [unowned self] action in
            self.didSelectViewProfile?(person)
        }

        return UIMenu.init(title: "Menu",
                           image: nil,
                           identifier: nil,
                           options: [],
                           children: [profile])
    }
}
