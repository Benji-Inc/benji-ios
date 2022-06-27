//
//  ExpressionsCounterView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ExpressionsCounterView: ImageCounterView, MessageConfigureable {
    
    private var controller: MessageController?
    private var expressionsCount = 0
    
    init() {
        super.init(with: .faceSmiling)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// The currently running task that is loading.
    private var loadTask: Task<Void, Never>?
    
    func configure(for message: Messageable) {
        guard let controller = JibberChatClient.shared.messageController(for: message) else { return }

        if let existing = self.controller,
            existing.messageId == controller.messageId,
           self.expressionsCount == controller.message?.expressions.count {
            return
        }
                
        self.loadTask?.cancel()
                
        self.loadTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            guard !Task.isCancelled else { return }
            
            self.controller = controller
            
            self.expressionsCount = controller.message?.expressions.count ?? 0
            
            if self.expressionsCount > 0 {
                self.viewState = .count(self.expressionsCount)
            } else {
                self.viewState = .empty
            }
        }
    }
}
