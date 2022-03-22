//
//  ConversationDetailCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/21/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import StreamChat

enum DetailCoordinatorResult {
    case conversation(ConversationId)
}

class ConversationDetailCoordinator: PresentableCoordinator<DetailCoordinatorResult?> {
    
    lazy var detailVC = ConversationDetailViewController(with: self.cid)
    let cid: ConversationId
    
    init(with cid: ConversationId,
         router: Router,
         deepLink: DeepLinkable?) {
        self.cid = cid 
        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> DismissableVC {
        return self.detailVC
    }
    
    override func start() {
        super.start()
        
        self.detailVC.$selectedItems.mainSink { [unowned self] items in
            guard let first = items.first else { return }
            
            switch first {
            case .member(let member):
                guard let person = PeopleStore.shared.people.first(where: { person in
                    return person.personId == member.personId
                }) else { return }

                self.presentProfile(for: person)
            case .add(_):
                break
            case .info(_):
                break
            case .editTopic(_):
                break
            case .detail(_, _):
                break
            }
        }.store(in: &self.cancellables)
    }
    
    func presentProfile(for person: PersonType) {
        self.removeChild()

        let coordinator = ProfileCoordinator(with: person, router: self.router, deepLink: self.deepLink)
        
        self.addChildAndStart(coordinator) { [unowned self] result in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) { [unowned self] in
                self.finishFlow(with: .conversation(result))
            }
        }
        
        self.router.present(coordinator, source: self.detailVC, cancelHandler: nil)
    }
    
    func presentConversationTitleAlert(for conversation: Conversation) {
        let controller = ChatClient.shared.channelController(for: conversation.cid)

        let alertController = UIAlertController(title: "Update Name", message: "", preferredStyle: .alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Name"
        }
        let saveAction = UIAlertAction(title: "Confirm", style: .default, handler: { [unowned self] alert -> Void in
            if let textField = alertController.textFields?.first,
               let text = textField.text,
               !text.isEmpty {

                controller.updateChannel(name: text, imageURL: nil, team: nil) { [unowned self] error in
                    alertController.dismiss(animated: true, completion: {
                    })
                }
            }
        })

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
            
        })

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        self.detailVC.present(alertController, animated: true, completion: nil)
    }
    
    func presentDeleteConversationAlert(cid: ConversationId?) {
        guard let cid = cid else { return }
        
        let controller = ChatClient.shared.channelController(for: cid)
        
        guard controller.conversation.memberCount <= 1 else { return }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete Conversation", style: .destructive, handler: {
            (action : UIAlertAction!) -> Void in
            Task {
                try await controller.deleteChannel()
                // Dismiss???
            }
        })

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
            
        })

        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        self.detailVC.present(alertController, animated: true, completion: nil)
    }
}
