//
//  MessageFooterView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/30/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Combine

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
        
        // Cancel any currently running tasks
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
