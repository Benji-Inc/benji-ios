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
    //private let captionTextView = CaptionTextView()
    
    private let nameLabel = ThemeLabel(font: .smallBold)
    private let dateLabel = ThemeLabel(font: .xtraSmall)
    private let viewedLabel = ViewedLabel()
    private let detailsContainer = BaseView()
    
    let commentsLabel = CommentsLabel()
    let reactionsView = MomentReactionsView()
    let menuButton = ThemeButton()
//    let expressionView = MomentExpressiontVideoView()
//    let momentView = MomentVideoView()
//    let blurView = MomentBlurView()
    let contentView = MomentContentView()
    
    var didSelectViewProfile: ((PersonType) -> Void)? = nil
    
    static let cornerRadius: CGFloat = 30
    
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
            sheet.preferredCornerRadius = MomentViewController.cornerRadius
        }
        
        self.view.set(backgroundColor: .B0)
        
        self.view.addSubview(self.contentView)
        self.contentView.layer.cornerRadius = MomentViewController.cornerRadius
        self.contentView.layer.masksToBounds = true
        
        self.view.addSubview(self.detailsContainer)
        self.detailsContainer.addSubview(self.nameLabel)
        self.detailsContainer.addSubview(self.dateLabel)
        self.dateLabel.setText(self.moment.createdAt?.getTimeAgoString() ?? "")
        
        self.detailsContainer.addSubview(self.viewedLabel)
        
        self.detailsContainer.alpha = 0
        
        self.view.addSubview(self.controlsContainer)
        //self.controlsContainer.addSubview(self.captionTextView)
//        self.captionTextView.isEditable = false
//        self.captionTextView.isSelectable = false
        
        self.controlsContainer.addSubview(self.commentsLabel)
        self.commentsLabel.configure(with: self.moment)
        
        self.controlsContainer.addSubview(self.reactionsView)
        self.reactionsView.configure(with: self.moment)
        
//        self.view.addSubview(self.blurView)
//        self.view.addSubview(self.expressionView)
        
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
        
        self.contentView.expandToSuperviewWidth()
        self.contentView.height = self.view.height - self.view.safeAreaInsets.bottom - self.view.height * 0.15
        self.contentView.pin(.top)
        
        self.controlsContainer.expandToSuperviewSize()
        
//        self.expressionView.squaredSize = self.view.width * 0.25
//        self.expressionView.pinToSafeAreaTop()
//        self.expressionView.pinToSafeAreaLeft()
        
        self.menuButton.squaredSize = 44
        self.menuButton.pin(.top)
        self.menuButton.pinToSafeAreaRight()
        
        let maxLabelWidth = Theme.getPaddedWidth(with: self.view.width) - self.reactionsView.width - Theme.ContentOffset.long.value
        self.commentsLabel.setSize(withWidth: maxLabelWidth)
        self.commentsLabel.match(.top, to: .bottom, of: self.contentView, offset: .xtraLong)
        self.commentsLabel.pinToSafeAreaLeft()
        
        self.reactionsView.squaredSize = 35
        self.reactionsView.pinToSafeAreaRight()
        self.reactionsView.centerY = self.commentsLabel.centerY
        
//        let maxWidth = Theme.getPaddedWidth(with: self.view.width)
//        self.captionTextView.setSize(withMaxWidth: maxWidth)
//        self.captionTextView.pinToSafeAreaLeft()
//        self.captionTextView.bottom = self.momentView.height - self.captionTextView.left
//        self.captionTextView.isVisible = !self.captionTextView.placeholderText.isEmpty
        
        self.detailsContainer.expandToSuperviewWidth()
        self.detailsContainer.height = 30
        self.detailsContainer.match(.bottom, to: .bottom, of: self.contentView)
        
        self.nameLabel.setSize(withWidth: self.view.width)
        self.nameLabel.pinToSafeAreaLeft()
        self.nameLabel.pin(.bottom, offset: .xtraLong)
        
        self.dateLabel.setSize(withWidth: self.view.width)
        self.dateLabel.pinToSafeAreaLeft()
        self.dateLabel.match(.bottom, to: .top, of: self.nameLabel, offset: .negative(.short))
        
        self.viewedLabel.pinToSafeAreaRight()
        self.viewedLabel.centerY = self.nameLabel.centerY
    }
    
    private func handle(state: State) {
        switch state {
        case .initial:
            break
        case .loading:
            self.contentView.configure(with: self.moment)
            self.detailsContainer.isVisible = self.moment.isAvailable
        case .playback:
            Task {
                guard let moment = try? await self.moment.retrieveDataIfNeeded() else { return }
                //self.captionTextView.animateCaption(text: moment.caption)
                self.viewedLabel.configure(with: moment)
                if let person = try? await moment.author?.retrieveDataIfNeeded() {
                    self.nameLabel.setText(person.fullName.capitalized)
                    self.menuButton.menu = self.createMenu(for: person)
                    self.view.layoutNow()
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard self.state == .playback, self.shouldHandleTouch(for: touches, event: event) else { return }
        
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.contentView.alpha = 0.5
            self.controlsContainer.alpha = 0.0
            self.detailsContainer.alpha = 1.0
        }

        self.contentView.pause()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard self.state == .playback else { return }
        
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.contentView.alpha = 1.0
            self.controlsContainer.alpha = 1.0
            self.detailsContainer.alpha = 0.0
        }
        
        self.contentView.play()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        guard self.state == .playback else { return }
    
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.contentView.alpha = 1.0
            self.controlsContainer.alpha = 1.0
            self.detailsContainer.alpha = 0.0
        }
        
        self.contentView.play()
    }
    
    func shouldHandleTouch(for touches: Set<UITouch>, event: UIEvent?) -> Bool {
        guard let firstTouch = touches.first else { return false }
        let location = firstTouch.location(in: self.view)
        return location.y <= self.contentView.bottom
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
