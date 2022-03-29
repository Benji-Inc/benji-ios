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
                    self.presentAlert(for: type)
                case .more:
                    break
                }
            case .read(_):
                break
            case .info(_):
                break
            case .reply(_):
                break
            case .more(_):
                break
            }
        }.store(in: &self.cancellables)
        
        self.messageVC.dataSource.didTapDelete = { [unowned self] in
            self.handleDelete()
        }
        
        self.messageVC.dataSource.didTapEdit = { [unowned self] in
            self.handleEdit()
        }
    }

    override func toPresentable() -> PresentableCoordinator<Messageable?>.DismissableVC {
        return self.messageVC
    }
    
    private func handleEdit() {
        self.presentAlert(for: .edit)
    }
    
    private func handleDelete() {
        Task {
            let controller = ChatClient.shared.messageController(cid: self.message.streamCid, messageId: self.message.id)
            try? await controller.deleteMessage()
            
            await ToastScheduler.shared.schedule(toastType: .basic(identifier: UUID().uuidString,
                                                             displayable: User.current()!,
                                                             title: "Message Deleted",
                                                             description: "Your message has successfully been deleted",
                                                             deepLink: nil))
            
            self.finishFlow(with: nil)
        }
    }
    
    private func presentAlert(for option: MessageDetailDataSource.OptionType) {
        
        let alertController = UIAlertController(title: option.title,
                                                message: "(Coming Soon)",
                                                preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Got it", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
        })

        alertController.addAction(cancelAction)
        self.messageVC.present(alertController, animated: true, completion: nil)
    }
}
