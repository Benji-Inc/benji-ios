//
//  ExpressionButton.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/20/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class ExpressionButton: MomentButton {
    
    private var controller: ConversationController?
    private var subscriptions = Set<AnyCancellable>()
        
    init() {
        super.init(with: .faceSmiling)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with moment: Moment) {
        self.subscriptions.forEach { subscription in
            subscription.cancel()
        }
        
        self.controller = JibberChatClient.shared.conversationController(for: moment.commentsId)
        if let expressions = self.controller?.conversation?.expressions {
            self.counter.setValue(Float(expressions.count))
            self.counter.isVisible = expressions.count > 0
        }
        
        self.controller?.channelChangePublisher.mainSink(receiveValue: { [unowned self] _ in
            if let expressions = self.controller?.conversation?.expressions {
                self.counter.setValue(Float(expressions.count))
                self.counter.isVisible = expressions.count > 0
            } else {
                self.counter.isVisible = false
            }
        }).store(in: &self.subscriptions)
    }
}
