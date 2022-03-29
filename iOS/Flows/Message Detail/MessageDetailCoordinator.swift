//
//  MessageDetailCoordinator.swift
//  Jibber
//
//  Created by Martin Young on 2/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class MessageDetailCoordinator: PresentableCoordinator<Messageable?> {

    private lazy var messageVC = MessageDetailViewController(message: self.message)

    private let message: Messageable

    init(with message: Messageable,
         router: Router,
         deepLink: DeepLinkable?) {

        self.message = message

        super.init(router: router, deepLink: deepLink)
    }
    
    override func start() {
        super.start()
        
        self.messageVC.$selectedItems
            .removeDuplicates()
            .mainSink { items in
            guard let first = items.first else { return }
            switch first {
            case .option(let type):
                switch type {
                case .viewReplies:
                    self.finishFlow(with: self.message)
                case .edit:
                    break
                case .pin:
                    break
                case .more:
                    break
                case .delete:
                    break
                }
            case .read(_):
                break
            case .info(_):
                break
            case .reply(_):
                break
            }
        }.store(in: &self.cancellables)
    }

    override func toPresentable() -> PresentableCoordinator<Messageable?>.DismissableVC {
        return self.messageVC
    }
}
