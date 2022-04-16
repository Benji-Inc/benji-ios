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
    
    var didTapViewReplies: CompletionOptional = nil
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.arrowImageView)
        self.arrowImageView.tintColor = ThemeColor.B4.color
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
        
        self.loadTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            guard !Task.isCancelled else { return }
            
            self.controller = ChatClient.shared.messageController(for: message)

            self.setPrompt(for: message)
            
            self.subscribeToUpdates()
            self.setNeedsLayout()
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
        self.counter.centerOnY()
        
        self.promptButton.height = self.arrowImageView.height
        self.promptButton.width = self.width
        self.promptButton.left = self.arrowImageView.left
        self.promptButton.centerY = self.arrowImageView.centerY
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
