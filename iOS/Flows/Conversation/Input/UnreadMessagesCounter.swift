//
//  UnreadMessagesCounter.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ScrollCounter
import Combine
import StreamChat

class UnreadMessagesCounter: BaseView {
    
    let counter = NumberScrollCounter(value: 0,
                                      scrollDuration: Theme.animationDurationSlow,
                                      decimalPlaces: 0,
                                      prefix: "Unread: ",
                                      suffix: nil,
                                      seperator: "",
                                      seperatorSpacing: 0,
                                      font: FontType.small.font,
                                      textColor: ThemeColor.T1.color,
                                      animateInitialValue: true,
                                      gradientColor: nil,
                                      gradientStop: nil)
    
    var cancellables = Set<AnyCancellable>()
    
    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.set(backgroundColor: .B1withAlpha)
        self.layer.cornerRadius = Theme.innerCornerRadius
        self.layer.borderColor = ThemeColor.BORDER.color.cgColor
        self.layer.borderWidth = 0.5
        
        self.addSubview(self.counter)
                
        ConversationsManager.shared.$activeConversation.mainSink { conversation in
            guard let conversation = conversation else {
                self.animate(shouldShow: false)
                return
            }
            self.counter.setValue(Float(conversation.totalUnread))
        }.store(in: &self.cancellables)
        
        ConversationsManager.shared.$reactionEvent.mainSink { event in
            guard let reactionEvent = event as? ReactionNewEvent,
                  let conversation = ConversationsManager.shared.activeConversation,
                  reactionEvent.cid == conversation.cid else { return }
            
            self.counter.setValue(Float(conversation.totalUnread))
        }.store(in: &self.cancellables)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.height = 30
        self.counter.sizeToFit()
        
        self.width = self.counter.width + Theme.ContentOffset.long.value.doubled
        self.counter.centerOnXAndY()
    }
    
    func updateVisibility(for state: SwipeableInputAccessoryViewController.InputState) {
        switch state {
        case .collapsed:
            self.animate(shouldShow: true)
        case .expanded:
            self.animate(shouldShow: false)
        }
    }
    
    private func animate(shouldShow: Bool) {
        UIView.animate(withDuration: Theme.animationDurationFast, delay: 0.0) {
            self.alpha = shouldShow ? 1.0 : 0.0
        }
    }
}
