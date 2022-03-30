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

class MessageFooterView: BaseView {
    
    static let height: CGFloat = 25
    
    let stackedView = StackedPersonView()
        
    let counter = NumberScrollCounter(value: 0,
                                      scrollDuration: Theme.animationDurationFast,
                                      decimalPlaces: 0,
                                      prefix: nil,
                                      suffix: nil,
                                      seperator: "",
                                      seperatorSpacing: 0,
                                      font: FontType.regular.font,
                                      textColor: ThemeColor.T1.color,
                                      animateInitialValue: true,
                                      gradientColor: ThemeColor.B0.color,
                                      gradientStop: 4)
    
    private var controller: MessageController?
    private var subscriptions = Set<AnyCancellable>()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.stackedView)
        self.addSubview(self.counter)
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
            self?.counter.setValue(Float(msg.totalReplyCount), animated: true)
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
            self.counter.setValue(Float(msg.totalReplyCount), animated: true)
        }).store(in: &self.subscriptions)
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.stackedView.pin(.left)
        self.stackedView.centerOnY()
        
        self.counter.sizeToFit()
        self.counter.pin(.right)
        self.counter.centerOnY()
    }
}
