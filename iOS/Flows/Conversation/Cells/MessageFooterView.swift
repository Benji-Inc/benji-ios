//
//  MessageFooterView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/30/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import ScrollCounter
import Combine

class ReplyCountView: BaseView {
    private let counter = NumberScrollCounter(value: 0,
                                              scrollDuration: Theme.animationDurationFast,
                                              decimalPlaces: 0,
                                              prefix: nil,
                                              suffix: nil,
                                              seperator: "",
                                              seperatorSpacing: 0,
                                              font: FontType.small.font,
                                              textColor: ThemeColor.T1.color,
                                              animateInitialValue: true,
                                              gradientColor: ThemeColor.B0.color,
                                              gradientStop: 4)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.set(backgroundColor: .B1withAlpha)
        self.layer.cornerRadius = Theme.innerCornerRadius
        self.layer.borderColor = ThemeColor.BORDER.color.cgColor
        self.layer.borderWidth = 0.5
        
        self.addSubview(self.counter)
    }
    
    func set(count: Int) {
        self.counter.setValue(Float(count), animated: true)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.counter.sizeToFit()
        self.counter.centerOnXAndY()
    }
}

class MessageFooterView: BaseView {
    
    static let height: CGFloat = 25
    
    let stackedView = StackedPersonView()
    let replyCount = ReplyCountView()
    
    private var controller: MessageController?
    private var subscriptions = Set<AnyCancellable>()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.stackedView)
        self.addSubview(self.replyCount)
    }
    
    private var messageTask: Task<Void, Never>?
    
    func configure(for message: Messageable) {
        self.controller = ChatClient.shared.messageController(for: message)
        
        // Cancel any currently running swipe hint tasks so we don't trigger the animation multiple times.
        self.messageTask?.cancel()
        
        self.messageTask = Task { [weak self] in
            
            try? await self?.controller?.synchronize()
            
            guard !Task.isCancelled, let msg = self?.controller?.message else { return }
            
            self?.stackedView.configure(with: msg.nonMeConsumers)
            self?.replyCount.set(count: msg.replyCount)
            self?.replyCount.isVisible = msg.replyCount > 0
        }
        
        self.subscribeToUpdates()
    }
    
    private func subscribeToUpdates() {
        
        self.subscriptions.forEach { cancellable in
            cancellable.cancel()
        }
        
        guard let msg = self.controller?.message else { return }
        
        self.controller?.reactionsPublisher.mainSink(receiveValue: { [unowned self] _ in
            self.stackedView.configure(with: msg.nonMeConsumers)
            self.setNeedsLayout()
        }).store(in: &self.subscriptions)
        
        self.controller?.repliesChangesPublisher.mainSink(receiveValue: { [unowned self] _ in
            self.replyCount.set(count: msg.replyCount)
            self.replyCount.isVisible = msg.replyCount > 0
        }).store(in: &self.subscriptions)
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.stackedView.pin(.left)
        self.stackedView.centerOnY()
        
        self.replyCount.squaredSize = self.stackedView.height
        self.replyCount.pin(.right)
        self.replyCount.centerOnY()
    }
}
