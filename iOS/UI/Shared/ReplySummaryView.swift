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

class LineDotView: BaseView {
    let lineView = BaseView()
    let circleView = BaseView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.lineView)
        self.lineView.set(backgroundColor: .B1)
        self.lineView.width = 1.5
        
        self.addSubview(self.circleView)
        self.circleView.set(backgroundColor: .B1)
        self.circleView.layer.cornerRadius = 1
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.width = 6
        
        self.lineView.height = self.height - 12.5
        self.lineView.pin(.top)
        self.lineView.centerOnX()
        
        self.circleView.squaredSize = self.width
        self.circleView.centerOnX()
        self.circleView.pin(.bottom, offset: .custom(12.5))
    }
}

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
    
    private let lineDotView = LineDotView()
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
    
    private let replyView = ReplyView()
    
    var didTapViewReplies: CompletionOptional = nil
    var didSelectSuggestion: ((SuggestedReply) -> Void)? = nil
    var didSelectEmoji: ((String) -> Void)? = nil
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.replyView)
        self.replyView.isVisible = false
        
        self.addSubview(self.lineDotView)
        self.addSubview(self.promptLabel)
        self.addSubview(self.counter)
        self.addSubview(self.promptButton)
        self.promptButton.menu = self.addMenu()
        self.promptButton.didSelect { [unowned self] in
            self.didTapViewReplies?()
        }
    }
    
    /// The currently running task that is loading.
    private var loadTask: Task<Void, Never>?
    
    func configure(for message: Messageable) {
        self.loadTask?.cancel()
        
        self.promptLabel.isVisible = false
        self.counter.isVisible = false
        self.replyView.isVisible = false
        
        self.setPrompt(for: message)
        
        self.loadTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            guard !Task.isCancelled else { return }
            
            self.controller = ChatClient.shared.messageController(for: message)
            
            if let controller = self.controller,
               controller.message!.replyCount > 0,
                !controller.hasLoadedAllPreviousReplies  {
                try? await controller.loadPreviousReplies()
            }
            
            if let reply = self.controller?.message?.recentReplies.first {
                self.replyView.isVisible = true
                self.replyView.configure(with: reply)
            } else {
                self.replyView.isVisible = false
            }
            
            self.promptButton.showsMenuAsPrimaryAction = self.replyView.isHidden
            
            self.layoutNow()
            self.subscribeToUpdates()
        }
    }
    
    private func setPrompt(for message: Messageable) {
        // Remaining replies minus the one being displayed.
        let remainingReplyCount = clamp(message.totalReplyCount - 1, min: 0)
        
        if message.totalReplyCount == 0 {
            self.promptLabel.isVisible = true
            self.promptLabel.setText("Reply")
            self.counter.isVisible = false
        } else if remainingReplyCount == 0 {
            self.promptLabel.isVisible = true
            self.promptLabel.setText("View thread")
            self.counter.isVisible = false
        } else {
            self.counter.isVisible = true
            self.counter.prefix = "View "
            self.counter.suffix = remainingReplyCount == 1 ? " reply" : " more replies"
            self.promptLabel.isVisible = false
        }
        
        self.counter.setValue(Float(remainingReplyCount), animated: true)
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.lineDotView.pin(.left)
        self.lineDotView.pin(.top)
        
        self.replyView.expandToSuperviewWidth()
        self.replyView.pin(.top)
        self.replyView.match(.left, to: .right, of: self.lineDotView, offset: .standard)
        
        if self.replyView.isVisible {
            self.height = self.replyView.height + 30
        } else {
            self.height = 30
        }
        
        self.promptLabel.setSize(withWidth: 200)
        self.promptLabel.match(.left, to: .right, of: self.lineDotView, offset: .standard)
        self.promptLabel.pin(.bottom, offset: .custom(8))
        
        self.counter.sizeToFit()
        
        if self.promptLabel.isVisible {
            self.counter.match(.left, to: .right, of: self.promptLabel, offset: .standard)
        } else {
            self.counter.match(.left, to: .right, of: self.lineDotView, offset: .standard)
        }
        self.counter.pin(.bottom, offset: .custom(8))
        
        self.promptButton.height = 30
        self.promptButton.width = self.width
        self.promptButton.left = self.lineDotView.left
        self.promptButton.pin(.bottom)
        
        self.lineDotView.expandToSuperviewHeight()
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
    
    private func addMenu() -> UIMenu {
        
        var elements: [UIMenuElement] = []
        
        SuggestedReply.allCases.reversed().forEach { suggestion in
            
            if suggestion == .emoji {
                let reactionElements: [UIMenuElement] = suggestion.emojiReactions.compactMap { emoji in
                    return UIAction(title: emoji, image: nil) { [unowned self] _ in
                        self.didSelectEmoji?(emoji)
                    }
                }
                let reactionMenu = UIMenu(title: suggestion.text,
                                          image: suggestion.image,
                                          children: reactionElements)
                elements.append(reactionMenu)
                
            } else {
                let action = UIAction(title: suggestion.text, image: suggestion.image) { [unowned self] _ in
                    self.didSelectSuggestion?(suggestion)
                }
                elements.append(action)
            }
        }

        return UIMenu(title: "Suggestions", children: elements)
    }
}
