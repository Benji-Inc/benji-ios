//
//  CommentsBadgeView.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/19/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class CommentsButton: MomentButton {
    
    private var controller: MessageSequenceController?
    private var subscriptions = Set<AnyCancellable>()
        
    init() {
        super.init(with: .rectangleStack)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with moment: Moment) {
        self.subscriptions.forEach { subscription in
            subscription.cancel()
        }
        
        self.controller = JibberChatClient.shared.conversationController(for: moment.commentsId)
        
        if let sequence = self.controller?.messageSequence {
            self.counter.setValue(Float(sequence.totalUnread))
            self.counter.isVisible = sequence.totalUnread > 0
        }
                
        self.controller?.messageSequenceChangePublisher.mainSink(receiveValue: { [unowned self] _ in
            guard let sequence = self.controller?.messageSequence else { return }
            self.counter.setValue(Float(sequence.totalUnread))
            self.counter.isVisible = sequence.totalUnread > 0
        }).store(in: &self.subscriptions)
    }
}
