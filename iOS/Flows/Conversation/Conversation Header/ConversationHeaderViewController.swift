//
//  ConversationHeaderView.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Combine
import Lottie
import UIKit

class ConversationHeaderViewController: ViewController, ActiveConversationable {

    lazy var membersVC = MembersViewController()
    let button = Button()

    private var state: ConversationUIState = .read

    var didTapAddPeople: CompletionOptional = nil
    var didTapUpdateTopic: CompletionOptional = nil

    override func initializeViews() {
        super.initializeViews()

        self.addChild(viewController: self.membersVC)

        if !isRelease {
            self.view.addSubview(self.button)
        }

        let add = UIAction.init(title: "Add people",
                                image: UIImage(systemName: "person.badge.plus")) { [unowned self] _ in
            self.didTapAddPeople?()
        }

        let topic = UIAction.init(title: "Update topic",
                                 image: UIImage(systemName: "pencil")) { [unowned self] _ in
             self.didTapUpdateTopic?()
        }

        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { action in }

        let confirmDelete = UIAction(title: "Confirm",
                                     image: UIImage(systemName: "trash"),
                                     attributes: .destructive) { [unowned self] action in
            Task {
                let controller = ChatClient.shared.channelController(for: self.activeConversation!.cid)
                do {
                    try await controller.deleteChannel()
                } catch {
                    logDebug(error)
                }
            }.add(to: self.taskPool)
        }

        let deleteMenu = UIMenu(title: "Delete Conversation",
                                image: UIImage(systemName: "trash"),
                                options: .destructive,
                                children: [confirmDelete, neverMind])

        let menu = UIMenu(title: "Menu",
                          image: UIImage(systemName: "ellipsis.circle"),
                          identifier: nil,
                          options: [],
                          children: [topic, add, deleteMenu])

        self.button.set(style: .noborder(image: UIImage(systemName: "ellipsis")!, color: .white))
        self.button.showsMenuAsPrimaryAction = true
        self.button.menu = menu

        ConversationsManager.shared.$activeConversation
            .removeDuplicates()
            .mainSink { conversation in

            guard let convo = conversation else { return }
            self.button.isVisible = convo.isOwnedByMe
            self.view.setNeedsLayout()
        }.store(in: &self.cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.membersVC.view.height = 43
        self.membersVC.view.expandToSuperviewWidth()
        self.membersVC.view.pin(.bottom)

        self.button.height = self.view.height - self.membersVC.view.height
        self.button.width = 44
        self.button.pin(.right, offset: .xtraLong)
        self.button.pin(.top)
    }

    func update(for state: ConversationUIState) {
        self.state = state

        UIView.animate(withDuration: Theme.animationDurationStandard) {
            self.view.layoutNow()
        } completion: { completed in

        }
    }
}
