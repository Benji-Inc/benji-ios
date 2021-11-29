//
//  MessageContentView+Udpates.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/29/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension MessageContentView {
    
    func subscribeToUpdates(for message: Message) {

        self.publisherCancellables.forEach { cancellable in
            cancellable.cancel()
        }

        self.messageController = ChatClient.shared.messageController(cid: message.cid!, messageId: message.id)

        self.messageController?.messageChangePublisher.mainSink { [unowned self] output in
            switch output {
            case .create(_):
                break
            case .update(let item):
                self.configure(with: item)
            case .remove(_):
                break
            }
        }.store(in: &self.publisherCancellables)

        self.messageController?.reactionsPublisher.mainSink { [unowned self] _ in
            #if IOS
            if let msg = self.message as? Message {
                self.reactionsView.configure(with: msg.latestReactions)
            }
            #endif
        }.store(in: &self.publisherCancellables)
    }
}
