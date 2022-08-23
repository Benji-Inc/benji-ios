//
//  CommentsBadgeView.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/19/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class CommentsLabel: ThemeLabel {
    
    private var controller: MessageSequenceController?
    private var subscriptions = Set<AnyCancellable>()
        
    init() {
        super.init(font: .regular, textColor: .whiteWithAlpha)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeLabel() {
        super.initializeLabel()
        
        self.isUserInteractionEnabled = true 
    }
    
    func configure(with moment: Moment) {
        self.subscriptions.forEach { subscription in
            subscription.cancel()
        }
        
        self.controller = JibberChatClient.shared.conversationController(for: moment.commentsId)
        
        if let sequence = self.controller?.messageSequence {
            self.updateText(for: sequence.totalUnread)
        }
                
        self.controller?.messageSequenceChangePublisher.mainSink(receiveValue: { [unowned self] _ in
            guard let sequence = self.controller?.messageSequence else { return }
            self.updateText(for: sequence.totalUnread)
        }).store(in: &self.subscriptions)
    }
    
    private func updateText(for count: Int) {
        var text = ""
        
        if count == 0 {
            text = "Add comment"
        } else if count == 1 {
            text = "View unread comment"
        } else {
            text = "View \(count) unread comments"
        }
        
        self.setText(text)
    }
}
