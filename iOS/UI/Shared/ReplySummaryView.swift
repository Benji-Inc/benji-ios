//
//  ReplyCountView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/30/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ScrollCounter
import StreamChat
import Combine
import Localization

class ReplyView: BaseView {

    let personView = BorderedPersonView()
    let dateLabel = ThemeLabel(font: .xtraSmall)
    let label = ThemeLabel(font: .small)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.height = 24

        self.addSubview(self.personView)
        self.addSubview(self.label)
        self.addSubview(self.dateLabel)
        self.dateLabel.alpha = 0.25
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.personView.squaredSize = self.height
        self.personView.pin(.left)
        self.personView.pin(.top)

        self.label.setSize(withWidth: self.width - self.personView.width - Theme.ContentOffset.standard.value)
        self.label.match(.bottom, to: .bottom, of: self.personView)
        self.label.match(.left, to: .right, of: self.personView, offset: .standard)

        self.dateLabel.setSize(withWidth: self.width - self.personView.width - Theme.ContentOffset.standard.value)
        self.dateLabel.match(.top, to: .top, of: self.personView)
        self.dateLabel.match(.left, to: .right, of: self.personView, offset: .standard)
    }

    func configure(with message: Messageable) {
        if message.kind.hasText {
            self.label.setText(message.kind.text)
        } else {
            self.label.setText("View reply")
        }
        self.personView.set(person: message.person)
        self.dateLabel.text = message.createdAt.getTimeAgoString()
        self.layoutNow()
    }
}

class ReplySummaryView: BaseView {
    
    private var controller: MessageController?
    
    var cancellables = Set<AnyCancellable>()
    
    private let arrowImageView = UIImageView(image: UIImage(systemName: "arrow.turn.down.right"))
    private let promptLabel = ThemeLabel(font: .smallBold, textColor: .D1)
    private let promptButton = ThemeButton()
    private let counter = NumberScrollCounter(value: 0,
                                              scrollDuration: Theme.animationDurationFast,
                                              decimalPlaces: 0,
                                              prefix: nil,
                                              suffix: nil,
                                              seperator: "",
                                              seperatorSpacing: 0,
                                              font: FontType.smallBold.font,
                                              textColor: ThemeColor.D1.color,
                                              animateInitialValue: true,
                                              gradientColor: ThemeColor.B0.color,
                                              gradientStop: 4)
    
   // private let replyView = ReplyView()
    
    var didTapViewReplies: CompletionOptional = nil
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
//        self.addSubview(self.replyView)
        
        self.addSubview(self.arrowImageView)
        self.arrowImageView.tintColor = ThemeColor.B1.color
        self.arrowImageView.contentMode = .scaleAspectFit

        self.addSubview(self.promptLabel)
        self.addSubview(self.counter)
        self.addSubview(self.promptButton)
        self.promptButton.didSelect { [unowned self] in
            self.didTapViewReplies?()
        }
    }
    
    /// The currently running task that is loading.
    private var loadTask: Task<Void, Never>?
    
    func configure(for message: Messageable) {
        self.loadTask?.cancel()
        self.setPrompt(for: message)
        self.setNeedsLayout()

        self.loadTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            guard !Task.isCancelled else { return }
            
            self.controller = ChatClient.shared.messageController(for: message)
            
//            if let controller = self.controller,
//               controller.message!.replyCount > 0,
//                !controller.hasLoadedAllPreviousReplies  {
//                try? await controller.loadPreviousReplies()
//            }
//            logDebug(self.controller!.message!.replyCount)
//            logDebug(self.controller!.hasLoadedAllPreviousReplies)
//            
//            if let reply = self.controller?.message?.recentReplies.first {
//                self.replyView.configure(with: reply)
//            }
            self.subscribeToUpdates()

        }
    }
    
    private func setPrompt(for message: Messageable) {
        if message.totalReplyCount == 0 {
            self.promptLabel.isVisible = true
            self.promptLabel.setText("Reply")
            self.counter.isVisible = false
        } else {
            self.counter.isVisible = true
            self.counter.prefix = "View "
            self.counter.suffix = message.totalReplyCount == 1 ? " reply" : " more replies"
            self.promptLabel.isVisible = false
        }
        self.counter.setValue(Float(message.totalReplyCount), animated: true)
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
//        self.replyView.expandToSuperviewWidth()
//        self.replyView.pin(.top)
        
        self.arrowImageView.squaredSize = 20
        self.arrowImageView.pin(.left)
        self.arrowImageView.pin(.top)
        
        self.promptLabel.setSize(withWidth: 200)
        self.promptLabel.match(.left, to: .right, of: self.arrowImageView, offset: .standard)
        self.promptLabel.centerY = self.arrowImageView.centerY
        
        self.counter.sizeToFit()
        if self.promptLabel.isVisible {
            self.counter.match(.left, to: .right, of: self.promptLabel, offset: .standard)
        } else {
            self.counter.match(.left, to: .right, of: self.arrowImageView, offset: .standard)
        }
        self.counter.centerY = self.arrowImageView.centerY
        
        self.promptButton.height = self.arrowImageView.height
        self.promptButton.width = self.width
        self.promptButton.left = self.arrowImageView.left
        self.promptButton.centerY = self.arrowImageView.centerY
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var width: CGFloat = 20 + Theme.ContentOffset.standard.value

        if self.promptLabel.isVisible {
            width += self.promptLabel.getSize(withWidth: 200).width
        } else {
            self.counter.sizeToFit()
            width += self.counter.width
        }

        return CGSize(width: width, height: 30)
    }

    private func subscribeToUpdates() {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
        
        self.controller?.repliesChangesPublisher.mainSink { [unowned self] _ in
            guard let message = self.controller?.message else { return }
            self.setPrompt(for: message)
        }.store(in: &self.cancellables)
    }
}
