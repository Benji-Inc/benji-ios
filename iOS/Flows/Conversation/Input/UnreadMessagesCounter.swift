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
    
    let imageView = UIImageView(image: UIImage(systemName: "chevron.up"))
    let circle = BaseView()
    
    let countCircle = BaseView()
    
    let counter = NumberScrollCounter(value: 0,
                                      scrollDuration: Theme.animationDurationSlow,
                                      decimalPlaces: 0,
                                      prefix: "",
                                      suffix: nil,
                                      seperator: "",
                                      seperatorSpacing: 0,
                                      font: FontType.small.font,
                                      textColor: ThemeColor.T3.color,
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
        
        self.addSubview(self.circle)
        
        self.circle.set(backgroundColor: .B1withAlpha)
        self.circle.layer.cornerRadius = Theme.innerCornerRadius
        self.circle.layer.borderColor = ThemeColor.BORDER.color.cgColor
        self.circle.layer.borderWidth = 0.5
        
        self.clipsToBounds = false
        
        self.addSubview(self.imageView)
        self.imageView.tintColor = ThemeColor.T1.color.resolvedColor(with: self.traitCollection)
        
        self.addSubview(self.countCircle)
        self.countCircle.set(backgroundColor: .D6)
        
        self.addSubview(self.counter)
                
        ConversationsManager.shared.$activeConversation.mainSink { conversation in
            guard let conversation = conversation else {
                self.animate(shouldShow: false)
                return
            }
            self.counter.setValue(Float(conversation.totalUnread))
        }.store(in: &self.cancellables)
        
        ConversationsManager.shared.$messageEvent.mainSink { event in
            guard let messageEvent = event as? MessageNewEvent,
                  let conversation = ConversationsManager.shared.activeConversation,
                  messageEvent.cid == conversation.cid else { return }
            
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
        
        self.squaredSize = 44
        
        self.circle.expandToSuperviewSize()
        self.circle.makeRound()
        
        self.imageView.sizeToFit()
        self.imageView.centerOnXAndY()
        
        self.counter.sizeToFit()
        
        self.countCircle.squaredSize = 20
        self.countCircle.makeRound()
        
        self.counter.x = self.width - 8
        self.counter.y = 0
        
        self.countCircle.center = self.counter.center
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
