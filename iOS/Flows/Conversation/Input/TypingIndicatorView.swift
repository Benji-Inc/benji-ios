//
//  TypingIndicatorView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/30/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import StreamChat

class TypingIndicatorView: BaseView {
    
    private let label = ThemeLabel(font: .small)
    
    var cancellables = Set<AnyCancellable>()
    var subscriptions = Set<AnyCancellable>()
    
    var controller: ConversationController?
    
    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.label)
        self.label.alpha = 0
        self.label.transform = CGAffineTransform.init(translationX: -5, y: 0)
        
        ConversationsManager.shared.$activeConversation.mainSink { conversation in
            if let cid = conversation?.cid {
                self.subscribeToUpdates(for: cid)
            } else {
                self.hideTyping()
            }
        }.store(in: &self.cancellables)
    }
    
    private func subscribeToUpdates(for cid: ConversationId) {
        guard self.controller?.cid != cid else { return }
        
        self.subscriptions.forEach { cancellable in
            cancellable.cancel()
        }
        
        self.controller = ConversationController.controller(cid)
        
        self.controller?.typingUsersPublisher
            .mainSink(receiveValue: { [unowned self] typingUsers in
                self.showTyping(for: Array(typingUsers))
            }).store(in: &self.cancellables)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: self.width)
        self.label.pin(.left)
        self.label.pin(.bottom)
    }
    
    func showTyping(for people: [PersonType]) {
        let typers = people.filter { person in
            return !person.isCurrentUser
        }
        
        guard typers.count > 0 else {
            // If no one is typying, hide
            self.hideTyping()
            return
        }
        
        var text = ""
        var names: [String] = []
        
        for (index, person) in typers.enumerated() {
            if index == 0 {
                text.append(person.givenName)
            } else {
                text.append(", \(person.givenName)")
            }
            
            names.append(person.givenName)
        }
        
        text.append(" is typing...")
        
        self.label.setText(text)
        names.forEach { highlight in
            self.label.add(attributes: [.font: FontType.smallBold.font], to: highlight)
        }
        
        self.layoutNow()
        
        UIView.animate(withDuration: Theme.animationDurationSlow) {
            self.label.alpha = 1.0
            self.label.transform = .identity
        }
    }
    
    func hideTyping() {
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.label.alpha = 0.0
        } completion: { _ in
            
            // Important to reset the text, to clear out the attributes
            self.label.setText("")
            self.label.transform = CGAffineTransform.init(translationX: -5, y: 0)
        }
    }
}