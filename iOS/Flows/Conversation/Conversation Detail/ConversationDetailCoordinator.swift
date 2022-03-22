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
            case .editTopic(let cid):
                self.presentConversationTitleAlert(for: cid)
            case .detail(let cid, let option):
                self.presentDetail(option: option, cid: cid)
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
    
    func presentConversationTitleAlert(for cid: ConversationId) {
        let controller = ChatClient.shared.channelController(for: cid)

        let alertController = UIAlertController(title: "Update Name", message: "", preferredStyle: .alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Name"
        }
        let saveAction = UIAlertAction(title: "Confirm", style: .default, handler: { alert -> Void in
            if let textField = alertController.textFields?.first,
               let text = textField.text,
               !text.isEmpty {

                controller.updateChannel(name: text, imageURL: nil, team: nil) { _ in
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
    
    func presentDetail(option: ConversationDetailCollectionViewDataSource.OptionType, cid: ConversationId) {
                
        let controller = ChatClient.shared.channelController(for: cid)
        
        var title: String = ""
        var message: String = ""
        var style: UIAlertAction.Style = .default
        
        switch option {
        case .hide:
            title = "Hide"
            message = "Hiding this conversation will archive the conversation until a new message is sent to it."
        case .leave:
            title = "Leave"
            message = "Leaving the conversation will remove you as a participant."
        case .delete:
            title = "Delete"
            message = "Deleting a conversation will remove all members and data associated with this conversation."
            style = .destructive
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        let primaryAction = UIAlertAction(title: "Confirm", style: style, handler: {
            (action : UIAlertAction!) -> Void in
            
            switch option {
            case .hide:
                Task {
                    try? await controller.hideChannel(clearHistory: false)
                    Task.onMainActor {
                        self.finishFlow(with: nil)
                    }
                }.add(to: self.taskPool)
            case .leave:
                Task {
                    let user = User.current()!.objectId!
                    try? await controller.removeMembers(userIds: Set.init([user]))
                    Task.onMainActor {
                        self.finishFlow(with: nil)
                    }
                }.add(to: self.taskPool)
            case .delete:
                Task {
                    try? await controller.deleteChannel()
                    Task.onMainActor {
                        self.finishFlow(with: nil)
                    }
                }.add(to: self.taskPool)
            }
        })

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
            
        })

        alertController.addAction(primaryAction)
        alertController.addAction(cancelAction)
        
        self.detailVC.present(alertController, animated: true, completion: nil)
    }
}
